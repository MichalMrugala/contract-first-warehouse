-- =============================================================================
-- CONTRACT FIRST — Weekend 2: Automated Quality Gates
-- =============================================================================
-- File: sql/quality/04_quality_gates.sql
-- Purpose: Transform manual quality checks into automated, repeatable gates.
--          No data passes through without validation against the contract.
--          Every rejected row has a documented reason.
-- =============================================================================
-- HOW TO RUN:
-- duckdb warehouse.duckdb
-- .timer on
-- .read sql/quality/04_quality_gates.sql
-- =============================================================================

-- Drop previous results if re-running
DROP TABLE IF EXISTS quality_gate_results;

-- =============================================================================
-- QUALITY GATE: Run all contract rules in one pass
-- =============================================================================
-- Architecture: each CTE tests one rule independently.
-- Adding a new rule = adding one CTE + one row in the UNION ALL.
-- The gate is DECLARATIVE — it mirrors the contract, not the data.
-- =============================================================================

CREATE TABLE quality_gate_results AS

WITH total AS (
    SELECT COUNT(*) AS total_rows FROM raw_energy
),

-- ─── STRUCTURAL CHECKS ─────────────────────────────────────────────
-- These must pass 100% or the data cannot be trusted at all.

rule_no_null_geo AS (
    SELECT
        'no_null_geo' AS rule_name,
        'structural' AS check_type,
        'critical' AS severity,
        COUNT(*) FILTER (WHERE geo IS NOT NULL) AS pass_count,
        COUNT(*) FILTER (WHERE geo IS NULL) AS fail_count
    FROM raw_energy
),

rule_no_null_nrg_bal AS (
    SELECT
        'no_null_nrg_bal' AS rule_name,
        'structural' AS check_type,
        'critical' AS severity,
        COUNT(*) FILTER (WHERE nrg_bal IS NOT NULL) AS pass_count,
        COUNT(*) FILTER (WHERE nrg_bal IS NULL) AS fail_count
    FROM raw_energy
),

rule_no_null_unit AS (
    SELECT
        'no_null_unit' AS rule_name,
        'structural' AS check_type,
        'critical' AS severity,
        COUNT(*) FILTER (WHERE unit IS NOT NULL) AS pass_count,
        COUNT(*) FILTER (WHERE unit IS NULL) AS fail_count
    FROM raw_energy
),

rule_no_null_siec AS (
    SELECT
        'no_null_siec' AS rule_name,
        'structural' AS check_type,
        'critical' AS severity,
        COUNT(*) FILTER (WHERE siec IS NOT NULL) AS pass_count,
        COUNT(*) FILTER (WHERE siec IS NULL) AS fail_count
    FROM raw_energy
),

rule_valid_year_range AS (
    SELECT
        'valid_year_range' AS rule_name,
        'structural' AS check_type,
        'critical' AS severity,
        COUNT(*) FILTER (WHERE TIME_PERIOD >= 1990 AND TIME_PERIOD <= 2024) AS pass_count,
        COUNT(*) FILTER (WHERE TIME_PERIOD < 1990 OR TIME_PERIOD > 2024) AS fail_count
    FROM raw_energy
),

rule_valid_units AS (
    SELECT
        'valid_units_only' AS rule_name,
        'structural' AS check_type,
        'warning' AS severity,
        COUNT(*) FILTER (WHERE unit IN ('TJ', 'KTOE', 'GWH')) AS pass_count,
        COUNT(*) FILTER (WHERE unit NOT IN ('TJ', 'KTOE', 'GWH')) AS fail_count
    FROM raw_energy
),

rule_annual_freq AS (
    SELECT
        'annual_frequency_only' AS rule_name,
        'structural' AS check_type,
        'warning' AS severity,
        COUNT(*) FILTER (WHERE freq = 'A') AS pass_count,
        COUNT(*) FILTER (WHERE freq != 'A' OR freq IS NULL) AS fail_count
    FROM raw_energy
),

rule_geo_length AS (
    SELECT
        'geo_code_length' AS rule_name,
        'structural' AS check_type,
        'warning' AS severity,
        COUNT(*) FILTER (WHERE LENGTH(geo) <= 10) AS pass_count,
        COUNT(*) FILTER (WHERE LENGTH(geo) > 10) AS fail_count
    FROM raw_energy
),

-- ─── COMPLETENESS CHECKS ───────────────────────────────────────────
-- These measure data quality beyond structure.
-- They don't reject rows — they document coverage.

rule_obs_value_present AS (
    SELECT
        'obs_value_not_null' AS rule_name,
        'completeness' AS check_type,
        'info' AS severity,
        COUNT(*) FILTER (WHERE OBS_VALUE IS NOT NULL) AS pass_count,
        COUNT(*) FILTER (WHERE OBS_VALUE IS NULL) AS fail_count
    FROM raw_energy
),

rule_obs_flag_coverage AS (
    SELECT
        'obs_flag_documented' AS rule_name,
        'completeness' AS check_type,
        'info' AS severity,
        COUNT(*) FILTER (WHERE OBS_FLAG IS NOT NULL OR OBS_VALUE IS NOT NULL) AS pass_count,
        COUNT(*) FILTER (WHERE OBS_FLAG IS NULL AND OBS_VALUE IS NULL) AS fail_count
    FROM raw_energy
),

rule_conf_status_present AS (
    SELECT
        'conf_status_present' AS rule_name,
        'completeness' AS check_type,
        'info' AS severity,
        COUNT(*) FILTER (WHERE CONF_STATUS IS NOT NULL) AS pass_count,
        COUNT(*) FILTER (WHERE CONF_STATUS IS NULL) AS fail_count
    FROM raw_energy
),

-- ─── CONSISTENCY CHECKS ────────────────────────────────────────────
-- Cross-field logic: do related columns make sense together?

rule_missing_flagged AS (
    -- If OBS_VALUE is NULL, OBS_FLAG should explain why
    SELECT
        'missing_has_flag' AS rule_name,
        'consistency' AS check_type,
        'warning' AS severity,
        COUNT(*) FILTER (WHERE OBS_VALUE IS NOT NULL OR OBS_FLAG IS NOT NULL) AS pass_count,
        COUNT(*) FILTER (WHERE OBS_VALUE IS NULL AND OBS_FLAG IS NULL) AS fail_count
    FROM raw_energy
),

-- ─── COMBINE ALL RULES ─────────────────────────────────────────────

all_rules AS (
    SELECT * FROM rule_no_null_geo
    UNION ALL SELECT * FROM rule_no_null_nrg_bal
    UNION ALL SELECT * FROM rule_no_null_unit
    UNION ALL SELECT * FROM rule_no_null_siec
    UNION ALL SELECT * FROM rule_valid_year_range
    UNION ALL SELECT * FROM rule_valid_units
    UNION ALL SELECT * FROM rule_annual_freq
    UNION ALL SELECT * FROM rule_geo_length
    UNION ALL SELECT * FROM rule_obs_value_present
    UNION ALL SELECT * FROM rule_obs_flag_coverage
    UNION ALL SELECT * FROM rule_conf_status_present
    UNION ALL SELECT * FROM rule_missing_flagged
)

SELECT
    rule_name,
    check_type,
    severity,
    (SELECT total_rows FROM total) AS total_rows,
    pass_count,
    fail_count,
    ROUND(100.0 * pass_count / (SELECT total_rows FROM total), 2) AS pass_rate_pct,
    CASE WHEN fail_count = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    CURRENT_TIMESTAMP AS checked_at
FROM all_rules
ORDER BY
    CASE check_type
        WHEN 'structural' THEN 1
        WHEN 'consistency' THEN 2
        WHEN 'completeness' THEN 3
    END,
    CASE severity
        WHEN 'critical' THEN 1
        WHEN 'warning' THEN 2
        WHEN 'info' THEN 3
    END,
    rule_name;


-- =============================================================================
-- RESULTS DISPLAY
-- =============================================================================

-- Full results table
SELECT rule_name, check_type, severity, total_rows, pass_count, fail_count, pass_rate_pct, result
FROM quality_gate_results
ORDER BY
    CASE check_type WHEN 'structural' THEN 1 WHEN 'consistency' THEN 2 WHEN 'completeness' THEN 3 END,
    rule_name;

-- Summary by check type
SELECT
    check_type,
    COUNT(*) AS rules_count,
    SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END) AS rules_passing,
    SUM(CASE WHEN result = 'FAIL' THEN 1 ELSE 0 END) AS rules_failing
FROM quality_gate_results
GROUP BY check_type
ORDER BY CASE check_type WHEN 'structural' THEN 1 WHEN 'consistency' THEN 2 WHEN 'completeness' THEN 3 END;

-- Overall verdict
SELECT
    CASE
        WHEN SUM(CASE WHEN check_type = 'structural' AND result = 'FAIL' THEN 1 ELSE 0 END) > 0
        THEN '❌ GATE FAILED — structural issues found'
        WHEN SUM(CASE WHEN check_type = 'consistency' AND result = 'FAIL' THEN 1 ELSE 0 END) > 0
        THEN '⚠️ GATE PASSED WITH WARNINGS — consistency issues found'
        ELSE '✅ GATE PASSED — all structural and consistency checks clear'
    END AS overall_verdict,
    COUNT(*) AS total_rules,
    SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN result = 'FAIL' THEN 1 ELSE 0 END) AS failed
FROM quality_gate_results;
```

