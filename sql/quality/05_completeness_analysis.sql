-- =============================================================================
-- CONTRACT FIRST — Weekend 2: Completeness Analysis
-- =============================================================================
-- File: sql/quality/05_completeness_analysis.sql
-- The 46% missing data is the STORY of this weekend.
-- Every query answers: "what does this mean for the star schema?"
-- =============================================================================

-- ─── 1. MISSING BY COUNTRY ─────────────────────────────────────────
-- Which countries have the most missing data?
-- If a country is 80% NULL, including it in averages distorts everything.

SELECT
    geo AS country_code,
    LENGTH(geo) AS code_len,
    CASE WHEN LENGTH(geo) = 2 THEN 'country' ELSE 'aggregate' END AS geo_type,
    COUNT(*) AS total_rows,
    COUNT(OBS_VALUE) AS rows_with_value,
    COUNT(*) - COUNT(OBS_VALUE) AS rows_missing,
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 2) AS completeness_pct
FROM raw_energy
GROUP BY geo
ORDER BY completeness_pct ASC
LIMIT 15;


-- ─── 2. MISSING BY YEAR ────────────────────────────────────────────
-- Is older data more incomplete? When does coverage improve?
-- This determines whether we need a "reliable data starts from year X" rule.

SELECT
    TIME_PERIOD AS year,
    COUNT(*) AS total_rows,
    COUNT(OBS_VALUE) AS rows_with_value,
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 2) AS completeness_pct
FROM raw_energy
WHERE LENGTH(geo) = 2  -- countries only, exclude aggregates
GROUP BY TIME_PERIOD
ORDER BY TIME_PERIOD;


-- ─── 3. MISSING BY ENERGY PRODUCT (top 15 most sparse) ─────────────
-- Are some products universally measured while others are sparse?
-- Sparse products may need to be excluded from the dashboard or flagged.

SELECT
    siec AS energy_product,
    COUNT(*) AS total_rows,
    COUNT(OBS_VALUE) AS rows_with_value,
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 2) AS completeness_pct
FROM raw_energy
WHERE LENGTH(geo) = 2  -- countries only
GROUP BY siec
ORDER BY completeness_pct ASC
LIMIT 15;


-- ─── 4. MISSING BY ENERGY PRODUCT (top 15 most complete) ───────────
-- Which products are reliably measured across all countries/years?
-- These are the "safe" products for the dashboard.

SELECT
    siec AS energy_product,
    COUNT(*) AS total_rows,
    COUNT(OBS_VALUE) AS rows_with_value,
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 2) AS completeness_pct
FROM raw_energy
WHERE LENGTH(geo) = 2
GROUP BY siec
ORDER BY completeness_pct DESC
LIMIT 15;


-- ─── 5. MISSING BY BALANCE ITEM (most sparse) ──────────────────────
-- Which balance categories are most affected?

SELECT
    nrg_bal AS balance_item,
    COUNT(*) AS total_rows,
    COUNT(OBS_VALUE) AS rows_with_value,
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 2) AS completeness_pct
FROM raw_energy
WHERE LENGTH(geo) = 2
GROUP BY nrg_bal
ORDER BY completeness_pct ASC
LIMIT 15;


-- ─── 6. COUNTRY x YEAR COMPLETENESS HEATMAP ────────────────────────
-- Pivot: rows = countries, columns = decades, values = completeness %
-- Shows at a glance which country-decade combinations are reliable.

SELECT
    geo AS country_code,
    ROUND(100.0 * COUNT(OBS_VALUE) FILTER (WHERE TIME_PERIOD BETWEEN 1990 AND 1999)
        / NULLIF(COUNT(*) FILTER (WHERE TIME_PERIOD BETWEEN 1990 AND 1999), 0), 1) AS "1990s_%",
    ROUND(100.0 * COUNT(OBS_VALUE) FILTER (WHERE TIME_PERIOD BETWEEN 2000 AND 2009)
        / NULLIF(COUNT(*) FILTER (WHERE TIME_PERIOD BETWEEN 2000 AND 2009), 0), 1) AS "2000s_%",
    ROUND(100.0 * COUNT(OBS_VALUE) FILTER (WHERE TIME_PERIOD BETWEEN 2010 AND 2019)
        / NULLIF(COUNT(*) FILTER (WHERE TIME_PERIOD BETWEEN 2010 AND 2019), 0), 1) AS "2010s_%",
    ROUND(100.0 * COUNT(OBS_VALUE) FILTER (WHERE TIME_PERIOD BETWEEN 2020 AND 2024)
        / NULLIF(COUNT(*) FILTER (WHERE TIME_PERIOD BETWEEN 2020 AND 2024), 0), 1) AS "2020s_%",
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 1) AS "overall_%"
FROM raw_energy
WHERE LENGTH(geo) = 2
GROUP BY geo
ORDER BY "overall_%" ASC;


-- ─── 7. THE SILENT KILLER: NAIVE AVG vs CORRECT AVG ────────────────
-- If you naively AVG(OBS_VALUE) including NULLs vs only non-NULLs,
-- SQL handles NULLs correctly (ignores them in AVG).
-- BUT: the REAL danger is COUNT-based metrics and coverage assumptions.
--
-- Show: for each country, what % of possible observations actually exist?
-- A country with 53% coverage looks "complete" in a bar chart
-- but is missing nearly half its data points.

SELECT
    geo AS country_code,
    COUNT(*) AS total_possible_observations,
    COUNT(OBS_VALUE) AS actual_observations,
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 2) AS coverage_pct,
    ROUND(AVG(OBS_VALUE), 2) AS avg_value,
    ROUND(SUM(OBS_VALUE), 2) AS sum_value,
    -- The trap: if someone counts rows to estimate "how many data points
    -- does Germany have?" they get 1,050,840. But only 558,915 have values.
    -- Their estimate is off by 88%.
    ROUND(100.0 * (COUNT(*) - COUNT(OBS_VALUE)) / NULLIF(COUNT(OBS_VALUE), 0), 2)
        AS overcount_error_pct
FROM raw_energy
WHERE LENGTH(geo) = 2
GROUP BY geo
ORDER BY overcount_error_pct DESC
LIMIT 10;


-- ─── 8. THE UNIT TRAP ──────────────────────────────────────────────
-- Same observation exists in 3 units (TJ, KTOE, GWH).
-- That means 1/3 of our rows are "duplicates" by design — same fact,
-- different unit. This is a critical star schema decision:
-- do we keep all 3, pick one, or make unit a dimension?

SELECT
    unit,
    COUNT(*) AS total_rows,
    COUNT(OBS_VALUE) AS with_value,
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 2) AS completeness_pct,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw_energy), 2) AS pct_of_dataset
FROM raw_energy
GROUP BY unit
ORDER BY total_rows DESC;


-- ─── 9. OBSERVATION FLAGS DEEP DIVE ────────────────────────────────
-- What do the flags tell us about data reliability?

SELECT
    OBS_FLAG,
    CASE OBS_FLAG
        WHEN 'p' THEN 'provisional'
        WHEN 'e' THEN 'estimated'
        WHEN 'c' THEN 'confidential'
        WHEN 'n' THEN 'not significant'
        WHEN 'd' THEN 'definition differs'
        WHEN 'u' THEN 'low reliability'
        WHEN 'z' THEN 'not applicable'
        WHEN 'm' THEN 'missing'
        ELSE 'no flag (validated)'
    END AS flag_meaning,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw_energy), 2) AS pct_of_total,
    COUNT(OBS_VALUE) AS has_value,
    COUNT(*) - COUNT(OBS_VALUE) AS missing_value
FROM raw_energy
GROUP BY OBS_FLAG
ORDER BY row_count DESC;


-- ─── 10. DESIGN DECISION SUPPORT: FACT TABLE STRATEGY ──────────────
-- How many rows would we have in the fact table under 3 strategies?

SELECT 'Strategy A: All rows (including NULLs)' AS strategy,
    COUNT(*) AS fact_table_rows
FROM raw_energy
WHERE LENGTH(geo) = 2  -- exclude aggregates

UNION ALL

SELECT 'Strategy B: Only rows with values' AS strategy,
    COUNT(*) AS fact_table_rows
FROM raw_energy
WHERE LENGTH(geo) = 2 AND OBS_VALUE IS NOT NULL

UNION ALL

SELECT 'Strategy C: Only rows with values, single unit (TJ)' AS strategy,
    COUNT(*) AS fact_table_rows
FROM raw_energy
WHERE LENGTH(geo) = 2 AND OBS_VALUE IS NOT NULL AND unit = 'TJ';
