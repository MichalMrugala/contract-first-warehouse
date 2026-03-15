-- =============================================================================
-- CONTRACT FIRST — Week 1: Staging Views (SQL-First Transformations)
-- =============================================================================
-- File: sql/staging/03_staging_views.sql
-- Purpose: Clean and standardize the raw data based on the data contract rules.
-- Everything that needs to happen to the data happens HERE in SQL —
-- before it ever touches Power BI. This IS "SQL First" in practice.
-- =============================================================================
-- Architecture decision:
-- These are VIEWS, not tables. The data stays in raw_energy.
-- Views are recomputed on every query — no stale copies.
-- If the raw data updates, staging updates automatically.
-- In Week 2, we'll consider materializing for performance.
-- =============================================================================
-- HOW TO RUN:
-- duckdb warehouse.duckdb
-- .read sql/staging/03_staging_views.sql
-- =============================================================================


-- =============================================================================
-- VIEW 1: stg_energy_balance
-- =============================================================================
-- The main staging view. Takes raw data, applies contract rules,
-- and produces clean, typed, deduplicated output.
--
-- What happens here (and why):
-- 1. SELECT only analytical columns → drop SDMX metadata (DATAFLOW, LAST UPDATE)
-- 2. Rename columns → clean, lowercase, readable names
-- 3. TRIM + UPPER on strings → standardize for consistent joins
-- 4. CAST TIME_PERIOD to INTEGER → enable year arithmetic
-- 5. Filter by contract rules → reject NULLs and invalid ranges
-- 6. Add row_hash → MD5 of natural key for deduplication tracking
-- 7. Add loaded_at → audit trail timestamp
-- =============================================================================

CREATE OR REPLACE VIEW stg_energy_balance AS

WITH deduplicated AS (
    -- If duplicate keys exist, take the row with a value over NULL,
    -- or the first row if both have values.
    -- ROW_NUMBER partitioned by the natural key ensures one row per key.
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY geo, nrg_bal, siec, unit, TIME_PERIOD
            ORDER BY
                CASE WHEN OBS_VALUE IS NOT NULL THEN 0 ELSE 1 END,  -- prefer non-NULL
                OBS_FLAG NULLS LAST  -- prefer flagged over unflagged if tie
        ) AS rn
    FROM raw_energy
)

SELECT
    -- Dimension keys (standardized)
    UPPER(TRIM(geo))                    AS country_code,
    UPPER(TRIM(nrg_bal))                AS balance_item,
    UPPER(TRIM(siec))                   AS energy_product,
    UPPER(TRIM(unit))                   AS unit_code,

    -- Time dimension
    CAST(TIME_PERIOD AS INTEGER)        AS year,

    -- Measure
    OBS_VALUE                           AS value,

    -- Metadata
    TRIM(OBS_FLAG)                      AS observation_flag,
    UPPER(TRIM(freq))                   AS frequency,

    -- Audit fields
    MD5(
        COALESCE(UPPER(TRIM(geo)), '') || '|' ||
        COALESCE(UPPER(TRIM(nrg_bal)), '') || '|' ||
        COALESCE(UPPER(TRIM(siec)), '') || '|' ||
        COALESCE(UPPER(TRIM(unit)), '') || '|' ||
        COALESCE(CAST(TIME_PERIOD AS VARCHAR), '')
    )                                   AS row_hash,
    CURRENT_TIMESTAMP                   AS loaded_at

FROM deduplicated
WHERE
    -- Contract rule: no_null_geo
    geo IS NOT NULL

    -- Contract rule: valid_year_range
    AND TIME_PERIOD >= 1990
    AND TIME_PERIOD <= 2024

    -- Contract rule: no_null_nrg_bal
    AND nrg_bal IS NOT NULL

    -- Contract rule: no_null_unit
    AND unit IS NOT NULL

    -- Deduplication: keep only the first row per natural key
    AND rn = 1
;


-- =============================================================================
-- VIEW 2: stg_energy_balance_quality_rejected
-- =============================================================================
-- Shows every row filtered out by the staging view and WHY.
-- This is critical for auditability: you must know what you dropped.
--
-- Architecture decision: rejected rows are not deleted. They sit here
-- as evidence. In Week 7 (governance), this view feeds the data lineage
-- documentation — proof that we made conscious decisions about data quality.
-- =============================================================================

CREATE OR REPLACE VIEW stg_energy_balance_quality_rejected AS

SELECT
    geo                                 AS country_code,
    nrg_bal                             AS balance_item,
    siec                                AS energy_product,
    unit                                AS unit_code,
    TIME_PERIOD                         AS year,
    OBS_VALUE                           AS value,
    OBS_FLAG                            AS observation_flag,

    -- Why was this row rejected?
    CASE
        WHEN geo IS NULL THEN 'NULL country code (contract rule: no_null_geo)'
        WHEN TIME_PERIOD < 1990 THEN 'Year before 1990 (contract rule: valid_year_range)'
        WHEN TIME_PERIOD > 2024 THEN 'Year after 2024 (contract rule: valid_year_range)'
        WHEN nrg_bal IS NULL THEN 'NULL balance item (contract rule: no_null_nrg_bal)'
        WHEN unit IS NULL THEN 'NULL unit code (contract rule: no_null_unit)'
        ELSE 'Unknown rejection reason'
    END AS rejection_reason,

    CURRENT_TIMESTAMP                   AS rejected_at

FROM raw_energy
WHERE
    geo IS NULL
    OR TIME_PERIOD < 1990
    OR TIME_PERIOD > 2024
    OR nrg_bal IS NULL
    OR unit IS NULL
;


-- =============================================================================
-- VIEW 3: stg_country_reference
-- =============================================================================
-- A reference view showing all distinct country/geo codes in the dataset.
-- This becomes the basis for Dim_Country in Week 3.
--
-- Why this matters:
-- Eurostat mixes real countries (DE, FR, PL) with aggregates (EU27_2020, EA20).
-- We need to know which is which before building the dimension table.
-- A 2-character code is almost always a country. Longer codes are aggregates.
-- =============================================================================

CREATE OR REPLACE VIEW stg_country_reference AS

SELECT
    UPPER(TRIM(geo))                    AS country_code,
    LENGTH(TRIM(geo))                   AS code_length,
    CASE
        WHEN LENGTH(TRIM(geo)) = 2 THEN 'country'
        ELSE 'aggregate'
    END                                 AS geo_type,
    COUNT(*)                            AS total_rows,
    COUNT(OBS_VALUE)                    AS rows_with_value,
    COUNT(*) - COUNT(OBS_VALUE)         AS rows_without_value,
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 2) AS data_completeness_pct,
    MIN(TIME_PERIOD)                    AS first_year,
    MAX(TIME_PERIOD)                    AS last_year,
    COUNT(DISTINCT TIME_PERIOD)         AS years_covered

FROM raw_energy
WHERE geo IS NOT NULL
GROUP BY geo
ORDER BY geo_type, total_rows DESC;


-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================
-- Run these after creating the views to confirm they work.
-- =============================================================================

-- How many rows survived staging?
SELECT
    'stg_energy_balance' AS view_name,
    COUNT(*) AS row_count
FROM stg_energy_balance;

-- How many rows were rejected?
SELECT
    'stg_energy_balance_quality_rejected' AS view_name,
    COUNT(*) AS row_count
FROM stg_energy_balance_quality_rejected;

-- Rejection reasons breakdown:
SELECT
    rejection_reason,
    COUNT(*) AS rejected_rows
FROM stg_energy_balance_quality_rejected
GROUP BY rejection_reason
ORDER BY rejected_rows DESC;

-- Country reference summary:
SELECT
    geo_type,
    COUNT(*) AS geo_codes,
    SUM(total_rows) AS total_rows
FROM stg_country_reference
GROUP BY geo_type;

-- Sanity check: staged + rejected should equal raw
SELECT
    (SELECT COUNT(*) FROM raw_energy) AS raw_total,
    (SELECT COUNT(*) FROM stg_energy_balance) AS staged,
    (SELECT COUNT(*) FROM stg_energy_balance_quality_rejected) AS rejected,
    (SELECT COUNT(*) FROM stg_energy_balance) +
    (SELECT COUNT(*) FROM stg_energy_balance_quality_rejected) AS staged_plus_rejected;

-- NOTE: staged + rejected may not perfectly equal raw_total because
-- deduplication removes extra copies of duplicate keys. The difference
-- is the number of duplicate rows removed. This is expected and documented.


-- =============================================================================
-- STAGING VIEWS COMPLETE
-- =============================================================================
-- SQL First in action:
-- - All cleaning happens in SQL (not Power Query, not DAX)
-- - All filtering traces back to a contract rule
-- - All rejections are documented with reasons
-- - The star schema in Week 3 will read from stg_energy_balance
-- - Power BI in Week 4 will connect to the star schema
-- - DAX will have almost nothing left to do
-- =============================================================================
