-- =============================================================================
-- CONTRACT FIRST — Weekend 5: Star Schema Quality Tests
-- =============================================================================
-- File: sql/quality/15_star_schema_tests.sql
-- Purpose: Automated tests validating the star schema BEFORE Power BI touches it.
-- This is CI/CD for data. Every test traces to a contract rule.
-- Run: duckdb warehouse.duckdb → .read sql/quality/15_star_schema_tests.sql
-- =============================================================================

-- Drop previous results if re-running
DROP TABLE IF EXISTS star_schema_test_results;

CREATE TABLE star_schema_test_results AS

-- ─── TEST 1: Fact table row count stability ─────────────────────────
-- Expected: 20,709,414 rows (established in Weekend 3)
-- If this changes without a known data reload, something broke.
WITH test_row_count AS (
    SELECT
        'T01_fact_row_count' AS test_name,
        '20709414' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) = 20709414 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
),

-- ─── TEST 2: No NULL foreign keys in fact table ────────────────────
-- Every row must link to every dimension. A NULL key = orphan row.
test_null_country AS (
    SELECT
        'T02a_null_country_key' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) FILTER (WHERE country_key IS NULL) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) FILTER (WHERE country_key IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
),
test_null_product AS (
    SELECT
        'T02b_null_product_key' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) FILTER (WHERE product_key IS NULL) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) FILTER (WHERE product_key IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
),
test_null_balance AS (
    SELECT
        'T02c_null_balance_key' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) FILTER (WHERE balance_key IS NULL) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) FILTER (WHERE balance_key IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
),
test_null_unit AS (
    SELECT
        'T02d_null_unit_key' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) FILTER (WHERE unit_key IS NULL) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) FILTER (WHERE unit_key IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
),
test_null_year AS (
    SELECT
        'T02e_null_year_key' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) FILTER (WHERE year_key IS NULL) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) FILTER (WHERE year_key IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
),

-- ─── TEST 3: Referential integrity ─────────────────────────────────
-- Every foreign key in fact must exist in its dimension.
-- An orphan key means the JOIN will drop rows silently.
test_orphan_country AS (
    SELECT
        'T03a_orphan_country' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance f
    LEFT JOIN dim_country dc ON f.country_key = dc.country_key
    WHERE dc.country_key IS NULL
),
test_orphan_product AS (
    SELECT
        'T03b_orphan_product' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance f
    LEFT JOIN dim_energy_product dp ON f.product_key = dp.product_key
    WHERE dp.product_key IS NULL
),
test_orphan_balance AS (
    SELECT
        'T03c_orphan_balance' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance f
    LEFT JOIN dim_balance_item db ON f.balance_key = db.balance_key
    WHERE db.balance_key IS NULL
),
test_orphan_unit AS (
    SELECT
        'T03d_orphan_unit' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance f
    LEFT JOIN dim_unit du ON f.unit_key = du.unit_key
    WHERE du.unit_key IS NULL
),

-- ─── TEST 4: Grain uniqueness ──────────────────────────────────────
-- One row per: country + product + balance + unit + year.
-- Duplicates = double-counting in every aggregation.
test_grain AS (
    SELECT
        'T04_grain_unique' AS test_name,
        CAST((SELECT COUNT(*) FROM fact_energy_balance) AS VARCHAR) AS expected,
        CAST(COUNT(DISTINCT
            country_key::VARCHAR || '|' || product_key::VARCHAR || '|' ||
            balance_key::VARCHAR || '|' || unit_key::VARCHAR || '|' ||
            year_key::VARCHAR
        ) AS VARCHAR) AS actual,
        CASE WHEN (SELECT COUNT(*) FROM fact_energy_balance) = COUNT(DISTINCT
            country_key::VARCHAR || '|' || product_key::VARCHAR || '|' ||
            balance_key::VARCHAR || '|' || unit_key::VARCHAR || '|' ||
            year_key::VARCHAR
        ) THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
),

-- ─── TEST 5: No negative primary production ────────────────────────
-- Negative obs_value is valid for exports (EXP) and stock changes (STK_CHG).
-- But primary production (PPRD) should NEVER be negative.
test_negative_pprd AS (
    SELECT
        'T05_no_negative_pprd' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance f
    JOIN dim_balance_item db ON f.balance_key = db.balance_key
    WHERE db.balance_code = 'PPRD'
      AND f.obs_value < 0
),

-- ─── TEST 6: Year range validation ─────────────────────────────────
test_year_min AS (
    SELECT
        'T06a_year_min' AS test_name,
        '1990' AS expected,
        CAST(MIN(year_key) AS VARCHAR) AS actual,
        CASE WHEN MIN(year_key) = 1990 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
),
test_year_max AS (
    SELECT
        'T06b_year_max' AS test_name,
        '2024' AS expected,
        CAST(MAX(year_key) AS VARCHAR) AS actual,
        CASE WHEN MAX(year_key) = 2024 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
),
test_year_count AS (
    SELECT
        'T06c_year_count' AS test_name,
        '35' AS expected,
        CAST(COUNT(DISTINCT year_key) AS VARCHAR) AS actual,
        CASE WHEN COUNT(DISTINCT year_key) = 35 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
),

-- ─── TEST 7: Dimension completeness ────────────────────────────────
test_dim_country AS (
    SELECT
        'T07a_dim_country' AS test_name,
        '40' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) = 40 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM dim_country
),
test_dim_product AS (
    SELECT
        'T07b_dim_product' AS test_name,
        '>65' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) >= 65 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM dim_energy_product
),
test_dim_balance AS (
    SELECT
        'T07c_dim_balance' AS test_name,
        '>130' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) >= 130 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM dim_balance_item
),
test_dim_unit AS (
    SELECT
        'T07d_dim_unit' AS test_name,
        '3' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) = 3 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM dim_unit
),
test_dim_year AS (
    SELECT
        'T07e_dim_year' AS test_name,
        '35' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) = 35 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM dim_year
),
test_dim_obs AS (
    SELECT
        'T07f_dim_obs_status' AS test_name,
        '2' AS expected,
        CAST(COUNT(*) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) = 2 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM dim_obs_status
),

-- ─── TEST 8: Cross-unit consistency ────────────────────────────────
-- If an observation exists in TJ, it should also exist in KTOE and GWH.
-- Check: for each country+product+balance+year, count how many units exist.
-- Expected: always 3 (or 0). Never 1 or 2.
test_unit_consistency AS (
    SELECT
        'T08_cross_unit_consistency' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) FILTER (WHERE unit_count NOT IN (3)) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) FILTER (WHERE unit_count NOT IN (3)) = 0 THEN 'PASS' ELSE 'WARN' END AS status
    FROM (
        SELECT country_key, product_key, balance_key, year_key,
               COUNT(DISTINCT unit_key) AS unit_count
        FROM fact_energy_balance
        GROUP BY country_key, product_key, balance_key, year_key
    )
),

-- ─── TEST 9: Germany renewables 2024 accuracy ──────────────────────
-- Known value from Week 3 analysis: ~3,100,000 TJ
-- Tolerance: +/- 5% (2,945,000 to 3,255,000)
test_germany_renewables AS (
    SELECT
        'T09_germany_renewables_2024' AS test_name,
        '~3100000 TJ (±5%)' AS expected,
        CAST(ROUND(SUM(f.obs_value), 0) AS VARCHAR) AS actual,
        CASE
            WHEN SUM(f.obs_value) BETWEEN 2945000 AND 3255000 THEN 'PASS'
            ELSE 'FAIL'
        END AS status
    FROM fact_energy_balance f
    JOIN dim_country dc ON f.country_key = dc.country_key
    JOIN dim_energy_product dp ON f.product_key = dp.product_key
    JOIN dim_unit du ON f.unit_key = du.unit_key
    JOIN dim_balance_item db ON f.balance_key = db.balance_key
    JOIN dim_year dy ON f.year_key = dy.year_key
    WHERE dc.geo_code = 'DE'
      AND dp.level1_category = 'Renewables'
      AND du.unit_code = 'TJ'
      AND db.balance_code = 'PPRD'
      AND dy.year = 2024
),

-- ─── TEST 10: No NULL obs_values ───────────────────────────────────
-- The fact table should contain ONLY measured observations.
-- NULLs were excluded during staging (stg_energy_missing).
test_no_null_values AS (
    SELECT
        'T10_no_null_obs_value' AS test_name,
        '0' AS expected,
        CAST(COUNT(*) FILTER (WHERE obs_value IS NULL) AS VARCHAR) AS actual,
        CASE WHEN COUNT(*) FILTER (WHERE obs_value IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM fact_energy_balance
)

-- ─── COMBINE ALL TESTS ─────────────────────────────────────────────
SELECT * FROM test_row_count
UNION ALL SELECT * FROM test_null_country
UNION ALL SELECT * FROM test_null_product
UNION ALL SELECT * FROM test_null_balance
UNION ALL SELECT * FROM test_null_unit
UNION ALL SELECT * FROM test_null_year
UNION ALL SELECT * FROM test_orphan_country
UNION ALL SELECT * FROM test_orphan_product
UNION ALL SELECT * FROM test_orphan_balance
UNION ALL SELECT * FROM test_orphan_unit
UNION ALL SELECT * FROM test_grain
UNION ALL SELECT * FROM test_negative_pprd
UNION ALL SELECT * FROM test_year_min
UNION ALL SELECT * FROM test_year_max
UNION ALL SELECT * FROM test_year_count
UNION ALL SELECT * FROM test_dim_country
UNION ALL SELECT * FROM test_dim_product
UNION ALL SELECT * FROM test_dim_balance
UNION ALL SELECT * FROM test_dim_unit
UNION ALL SELECT * FROM test_dim_year
UNION ALL SELECT * FROM test_dim_obs
UNION ALL SELECT * FROM test_unit_consistency
UNION ALL SELECT * FROM test_germany_renewables
UNION ALL SELECT * FROM test_no_null_values
;

-- =============================================================================
-- RESULTS
-- =============================================================================

SELECT test_name, expected, actual, status
FROM star_schema_test_results
ORDER BY test_name;

-- Summary
SELECT
    COUNT(*) AS total_tests,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN status = 'WARN' THEN 1 ELSE 0 END) AS warnings,
    CASE
        WHEN SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) = 0
        THEN '✅ ALL TESTS PASSED'
        ELSE '❌ FAILURES DETECTED'
    END AS verdict
FROM star_schema_test_results;
