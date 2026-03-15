-- =============================================================================
-- CONTRACT FIRST — Week 1: Quality Checks Against the Data Contract
-- =============================================================================
-- File: sql/quality/02_quality_checks.sql
-- Purpose: Test every quality rule defined in the data contract
--          (contracts/energy_balance_raw.yaml) against the actual data.
--
-- The contract made predictions. Now reality confirms or contradicts them.
-- Every failing rule = content for the LinkedIn post.
-- =============================================================================
-- HOW TO RUN:
-- duckdb warehouse.duckdb
-- .read sql/quality/02_quality_checks.sql
-- =============================================================================


-- RULE 1: no_null_geo (CRITICAL)
-- Contract says: geo column must never be NULL.
-- A NULL country code means we cannot attribute energy consumption
-- to any geography — the row is useless for dimensional analysis.
SELECT
    'no_null_geo' AS rule_name,
    'critical' AS severity,
    COUNT(*) FILTER (WHERE geo IS NOT NULL) AS rows_passing,
    COUNT(*) FILTER (WHERE geo IS NULL) AS rows_failing,
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE geo IS NOT NULL) / COUNT(*), 2) AS pass_rate_pct
FROM raw_energy;


-- RULE 2: valid_year_range (CRITICAL)
-- Contract says: TIME_PERIOD must be between 1990 and 2024.
-- Values outside this range indicate loading errors or future projections.
SELECT
    'valid_year_range' AS rule_name,
    'critical' AS severity,
    COUNT(*) FILTER (WHERE TIME_PERIOD >= 1990 AND TIME_PERIOD <= 2024) AS rows_passing,
    COUNT(*) FILTER (WHERE TIME_PERIOD < 1990 OR TIME_PERIOD > 2024) AS rows_failing,
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE TIME_PERIOD >= 1990 AND TIME_PERIOD <= 2024) / COUNT(*), 2) AS pass_rate_pct
FROM raw_energy;


-- RULE 3: no_null_nrg_bal (CRITICAL)
-- Contract says: Balance item code must never be NULL.
-- Without it, we don't know what this row measures.
SELECT
    'no_null_nrg_bal' AS rule_name,
    'critical' AS severity,
    COUNT(*) FILTER (WHERE nrg_bal IS NOT NULL) AS rows_passing,
    COUNT(*) FILTER (WHERE nrg_bal IS NULL) AS rows_failing,
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE nrg_bal IS NOT NULL) / COUNT(*), 2) AS pass_rate_pct
FROM raw_energy;


-- RULE 4: no_null_unit (CRITICAL)
-- Contract says: Unit must never be NULL.
-- A value without a unit is meaningless.
SELECT
    'no_null_unit' AS rule_name,
    'critical' AS severity,
    COUNT(*) FILTER (WHERE unit IS NOT NULL) AS rows_passing,
    COUNT(*) FILTER (WHERE unit IS NULL) AS rows_failing,
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE unit IS NOT NULL) / COUNT(*), 2) AS pass_rate_pct
FROM raw_energy;


-- RULE 5: valid_units_only (WARNING)
-- Contract says: Unit must be TJ, KTOE, or GWH.
-- Unknown units indicate format changes or loading errors.
SELECT
    'valid_units_only' AS rule_name,
    'warning' AS severity,
    COUNT(*) FILTER (WHERE unit IN ('TJ', 'KTOE', 'GWH')) AS rows_passing,
    COUNT(*) FILTER (WHERE unit NOT IN ('TJ', 'KTOE', 'GWH')) AS rows_failing,
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE unit IN ('TJ', 'KTOE', 'GWH')) / COUNT(*), 2) AS pass_rate_pct
FROM raw_energy;


-- RULE 6: annual_frequency_only (WARNING)
-- Contract says: freq must be 'A' (annual).
-- Mixed frequencies would break time-series aggregation.
SELECT
    'annual_frequency_only' AS rule_name,
    'warning' AS severity,
    COUNT(*) FILTER (WHERE freq = 'A') AS rows_passing,
    COUNT(*) FILTER (WHERE freq != 'A' OR freq IS NULL) AS rows_failing,
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE freq = 'A') / COUNT(*), 2) AS pass_rate_pct
FROM raw_energy;


-- RULE 7: no_duplicate_keys (CRITICAL)
-- Contract says: Natural key (geo + nrg_bal + siec + unit + TIME_PERIOD) must be unique.
-- Duplicates cause double-counting in the fact table.
SELECT
    'no_duplicate_keys' AS rule_name,
    'critical' AS severity,
    COUNT(*) - COALESCE(SUM(excess), 0) AS rows_passing,
    COALESCE(SUM(excess), 0) AS rows_failing,
    COUNT(*) AS total_rows,
    ROUND(100.0 * (COUNT(*) - COALESCE(SUM(excess), 0)) / COUNT(*), 2) AS pass_rate_pct
FROM (
    SELECT
        COUNT(*) AS total_rows
    FROM raw_energy
)
CROSS JOIN (
    SELECT
        SUM(cnt - 1) AS excess
    FROM (
        SELECT COUNT(*) AS cnt
        FROM raw_energy
        GROUP BY geo, nrg_bal, siec, unit, TIME_PERIOD
        HAVING COUNT(*) > 1
    )
);

-- Simpler duplicate check — just the count:
SELECT
    'no_duplicate_keys_detail' AS rule_name,
    (SELECT COUNT(*) FROM raw_energy) AS total_rows,
    (SELECT COUNT(*) FROM (
        SELECT geo, nrg_bal, siec, unit, TIME_PERIOD
        FROM raw_energy
        GROUP BY geo, nrg_bal, siec, unit, TIME_PERIOD
        HAVING COUNT(*) > 1
    )) AS duplicate_key_combinations,
    (SELECT SUM(cnt) FROM (
        SELECT COUNT(*) AS cnt
        FROM raw_energy
        GROUP BY geo, nrg_bal, siec, unit, TIME_PERIOD
        HAVING COUNT(*) > 1
    )) AS rows_in_duplicates;


-- RULE 8: row_count_minimum (CRITICAL)
-- Contract says: At least 100,000 rows.
-- Fewer means truncated download or wrong dataset.
SELECT
    'row_count_minimum' AS rule_name,
    'critical' AS severity,
    COUNT(*) AS total_rows,
    CASE WHEN COUNT(*) >= 100000 THEN 'PASS' ELSE 'FAIL' END AS result,
    100000 AS minimum_expected;


-- RULE 9: geo_code_length (WARNING)
-- Contract says: geo codes should not exceed 10 characters.
-- Excessively long codes indicate parsing errors.
SELECT
    'geo_code_length' AS rule_name,
    'warning' AS severity,
    COUNT(*) FILTER (WHERE LENGTH(geo) <= 10) AS rows_passing,
    COUNT(*) FILTER (WHERE LENGTH(geo) > 10) AS rows_failing,
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE LENGTH(geo) <= 10) / COUNT(*), 2) AS pass_rate_pct
FROM raw_energy;


-- RULE 10: obs_value_coverage (INFORMATIONAL)
-- Not in the contract as a hard rule, but critical to track.
-- How many rows have an actual measured value?
-- High NULL rate in OBS_VALUE = structural data gaps, not loading errors.
SELECT
    'obs_value_coverage' AS rule_name,
    'info' AS severity,
    COUNT(*) FILTER (WHERE OBS_VALUE IS NOT NULL) AS rows_with_value,
    COUNT(*) FILTER (WHERE OBS_VALUE IS NULL) AS rows_without_value,
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE OBS_VALUE IS NOT NULL) / COUNT(*), 2) AS value_coverage_pct
FROM raw_energy;


-- =============================================================================
-- SUMMARY: Overall Quality Score
-- =============================================================================
-- Combines all critical rules into one pass/fail overview.
-- This goes in the quality report and the LinkedIn post.
-- =============================================================================

WITH checks AS (
    SELECT 'no_null_geo' AS rule, 'critical' AS severity,
        COUNT(*) FILTER (WHERE geo IS NULL) AS failures FROM raw_energy
    UNION ALL
    SELECT 'valid_year_range', 'critical',
        COUNT(*) FILTER (WHERE TIME_PERIOD < 1990 OR TIME_PERIOD > 2024) FROM raw_energy
    UNION ALL
    SELECT 'no_null_nrg_bal', 'critical',
        COUNT(*) FILTER (WHERE nrg_bal IS NULL) FROM raw_energy
    UNION ALL
    SELECT 'no_null_unit', 'critical',
        COUNT(*) FILTER (WHERE unit IS NULL) FROM raw_energy
    UNION ALL
    SELECT 'valid_units_only', 'warning',
        COUNT(*) FILTER (WHERE unit NOT IN ('TJ', 'KTOE', 'GWH')) FROM raw_energy
    UNION ALL
    SELECT 'annual_frequency', 'warning',
        COUNT(*) FILTER (WHERE freq != 'A' OR freq IS NULL) FROM raw_energy
    UNION ALL
    SELECT 'geo_code_length', 'warning',
        COUNT(*) FILTER (WHERE LENGTH(geo) > 10) FROM raw_energy
)
SELECT
    rule,
    severity,
    failures,
    CASE WHEN failures = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM checks
ORDER BY
    CASE severity WHEN 'critical' THEN 1 WHEN 'warning' THEN 2 ELSE 3 END,
    rule;

-- Final overall score:
SELECT
    (SELECT COUNT(*) FROM raw_energy) AS total_rows,
    (SELECT COUNT(*) FROM raw_energy WHERE geo IS NOT NULL
        AND TIME_PERIOD >= 1990 AND TIME_PERIOD <= 2024
        AND nrg_bal IS NOT NULL
        AND unit IS NOT NULL) AS rows_passing_all_critical,
    ROUND(100.0 *
        (SELECT COUNT(*) FROM raw_energy WHERE geo IS NOT NULL
            AND TIME_PERIOD >= 1990 AND TIME_PERIOD <= 2024
            AND nrg_bal IS NOT NULL
            AND unit IS NOT NULL)
        / (SELECT COUNT(*) FROM raw_energy), 2) AS overall_pass_rate_pct;


-- =============================================================================
-- QUALITY CHECKS COMPLETE
-- =============================================================================
-- Update docs/quality-report-week1.md with actual numbers.
-- The failures ARE the content. No failures = boring post.
-- =============================================================================
