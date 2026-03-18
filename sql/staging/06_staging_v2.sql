-- =============================================================================
-- CONTRACT FIRST — Weekend 2: Enhanced Staging Views (v2)
-- =============================================================================
-- File: sql/staging/06_staging_v2.sql
-- The completeness analysis revealed the data needs 3-tier separation:
--   1. CLEAN  — rows with values, ready for the star schema
--   2. MISSING — structurally valid but no measured value (documented)
--   3. REJECTED — rows that fail structural quality gates
-- =============================================================================

-- ─── VIEW 1: stg_energy_clean ───────────────────────────────────────
-- Rows that pass ALL quality gates AND have a non-null OBS_VALUE.
-- These are the ONLY rows that should enter the fact table.
-- Each row is deduplicated by natural key.

CREATE OR REPLACE VIEW stg_energy_clean AS

WITH deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY geo, nrg_bal, siec, unit, TIME_PERIOD
            ORDER BY CASE WHEN OBS_VALUE IS NOT NULL THEN 0 ELSE 1 END
        ) AS rn
    FROM raw_energy
)
SELECT
    UPPER(TRIM(geo))                    AS country_code,
    UPPER(TRIM(nrg_bal))                AS balance_item,
    UPPER(TRIM(siec))                   AS energy_product,
    UPPER(TRIM(unit))                   AS unit_code,
    CAST(TIME_PERIOD AS INTEGER)        AS year,
    OBS_VALUE                           AS value,
    TRIM(OBS_FLAG)                      AS observation_flag,
    TRIM(CONF_STATUS)                   AS confidentiality_status,
    LENGTH(TRIM(geo)) = 2               AS is_country,
    MD5(
        COALESCE(UPPER(TRIM(geo)), '') || '|' ||
        COALESCE(UPPER(TRIM(nrg_bal)), '') || '|' ||
        COALESCE(UPPER(TRIM(siec)), '') || '|' ||
        COALESCE(UPPER(TRIM(unit)), '') || '|' ||
        COALESCE(CAST(TIME_PERIOD AS VARCHAR), '')
    )                                   AS row_hash,
    CURRENT_TIMESTAMP                   AS loaded_at
FROM deduplicated
WHERE rn = 1
    AND geo IS NOT NULL
    AND nrg_bal IS NOT NULL
    AND unit IS NOT NULL
    AND siec IS NOT NULL
    AND TIME_PERIOD >= 1990
    AND TIME_PERIOD <= 2024
    AND OBS_VALUE IS NOT NULL;


-- ─── VIEW 2: stg_energy_missing ─────────────────────────────────────
-- Rows that pass structural checks but have NULL OBS_VALUE.
-- These are "missing by design" — Eurostat flagged them as unavailable.
-- They do NOT go into the fact table but must be documented.
-- The star schema needs to know: which observations SHOULD exist but don't.

CREATE OR REPLACE VIEW stg_energy_missing AS

WITH deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY geo, nrg_bal, siec, unit, TIME_PERIOD
            ORDER BY OBS_FLAG NULLS LAST
        ) AS rn
    FROM raw_energy
)
SELECT
    UPPER(TRIM(geo))                    AS country_code,
    UPPER(TRIM(nrg_bal))                AS balance_item,
    UPPER(TRIM(siec))                   AS energy_product,
    UPPER(TRIM(unit))                   AS unit_code,
    CAST(TIME_PERIOD AS INTEGER)        AS year,
    TRIM(OBS_FLAG)                      AS observation_flag,
    TRIM(CONF_STATUS)                   AS confidentiality_status,
    LENGTH(TRIM(geo)) = 2               AS is_country,
    CASE
        WHEN OBS_FLAG = 'm' THEN 'Missing — Eurostat flag m (unavailable/confidential)'
        WHEN OBS_FLAG IS NULL AND OBS_VALUE IS NULL THEN 'Missing — no flag, no value'
        ELSE 'Missing — flag: ' || COALESCE(OBS_FLAG, 'none')
    END                                 AS missing_reason
FROM deduplicated
WHERE rn = 1
    AND geo IS NOT NULL
    AND nrg_bal IS NOT NULL
    AND unit IS NOT NULL
    AND siec IS NOT NULL
    AND TIME_PERIOD >= 1990
    AND TIME_PERIOD <= 2024
    AND OBS_VALUE IS NULL;


-- ─── VIEW 3: stg_energy_rejected ────────────────────────────────────
-- Rows that FAIL structural quality gates.
-- These are genuine data problems, not missing-by-design.

CREATE OR REPLACE VIEW stg_energy_rejected AS

SELECT
    geo                                 AS country_code,
    nrg_bal                             AS balance_item,
    siec                                AS energy_product,
    unit                                AS unit_code,
    TIME_PERIOD                         AS year,
    OBS_VALUE                           AS value,
    OBS_FLAG                            AS observation_flag,
    CASE
        WHEN geo IS NULL THEN 'NULL country code'
        WHEN nrg_bal IS NULL THEN 'NULL balance item'
        WHEN unit IS NULL THEN 'NULL unit'
        WHEN siec IS NULL THEN 'NULL energy product'
        WHEN TIME_PERIOD < 1990 THEN 'Year before 1990'
        WHEN TIME_PERIOD > 2024 THEN 'Year after 2024'
        ELSE 'Unknown rejection reason'
    END                                 AS rejection_reason,
    CURRENT_TIMESTAMP                   AS rejected_at
FROM raw_energy
WHERE geo IS NULL
    OR nrg_bal IS NULL
    OR unit IS NULL
    OR siec IS NULL
    OR TIME_PERIOD < 1990
    OR TIME_PERIOD > 2024;


-- ─── VIEW 4: stg_completeness_summary ───────────────────────────────
-- Aggregated completeness by country, year, and energy product.
-- This feeds the "data coverage" section of the dashboard in Week 6.

CREATE OR REPLACE VIEW stg_completeness_summary AS

SELECT
    UPPER(TRIM(geo))                    AS country_code,
    CAST(TIME_PERIOD AS INTEGER)        AS year,
    UPPER(TRIM(siec))                   AS energy_product,
    UPPER(TRIM(unit))                   AS unit_code,
    COUNT(*)                            AS total_observations,
    COUNT(OBS_VALUE)                    AS observations_with_value,
    COUNT(*) - COUNT(OBS_VALUE)         AS observations_missing,
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 2) AS completeness_pct
FROM raw_energy
WHERE geo IS NOT NULL
    AND LENGTH(geo) = 2  -- countries only
    AND unit = 'TJ'      -- single unit to avoid triple-counting
GROUP BY geo, TIME_PERIOD, siec, unit;


-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Row counts for each tier
SELECT 'raw_energy' AS source, COUNT(*) AS rows FROM raw_energy
UNION ALL
SELECT 'stg_energy_clean', COUNT(*) FROM stg_energy_clean
UNION ALL
SELECT 'stg_energy_missing', COUNT(*) FROM stg_energy_missing
UNION ALL
SELECT 'stg_energy_rejected', COUNT(*) FROM stg_energy_rejected;

-- Sanity check: clean + missing + rejected should equal raw
SELECT
    (SELECT COUNT(*) FROM raw_energy) AS raw_total,
    (SELECT COUNT(*) FROM stg_energy_clean) AS clean,
    (SELECT COUNT(*) FROM stg_energy_missing) AS missing,
    (SELECT COUNT(*) FROM stg_energy_rejected) AS rejected,
    (SELECT COUNT(*) FROM stg_energy_clean) +
    (SELECT COUNT(*) FROM stg_energy_missing) +
    (SELECT COUNT(*) FROM stg_energy_rejected) AS sum_of_tiers;

-- Clean rows: countries only, single unit (TJ) — preview of fact table size
SELECT
    'Fact table preview (countries, TJ only)' AS description,
    COUNT(*) AS rows
FROM stg_energy_clean
WHERE is_country = true AND unit_code = 'TJ';

-- Completeness summary sample
SELECT * FROM stg_completeness_summary
WHERE country_code = 'PL' AND year = 2023
ORDER BY completeness_pct ASC
LIMIT 10;
