-- =============================================================================
-- CONTRACT FIRST — Weekend 3: Fact_EnergyBalance
-- =============================================================================
-- Grain: one row = one measured energy observation
-- Composite key: country_key + product_key + balance_key + unit_key + year_key
-- Source: stg_energy_clean (21.3M rows with values)
-- Excludes: EU27_2020 aggregate (Decision 1: aggregates out)
-- Includes: all 3 units (Decision 5: unit as dimension)
-- =============================================================================

CREATE OR REPLACE TABLE fact_energy_balance AS

SELECT
    dc.country_key,
    dp.product_key,
    db.balance_key,
    du.unit_key,
    dy.year_key,
    s.value AS obs_value,
    1 AS obs_status_key  -- all rows in fact table are 'measured'
FROM stg_energy_clean s
JOIN dim_country dc ON s.country_code = dc.geo_code
JOIN dim_energy_product dp ON s.energy_product = dp.product_code
JOIN dim_balance_item db ON s.balance_item = db.balance_code
JOIN dim_unit du ON s.unit_code = du.unit_code
JOIN dim_year dy ON s.year = dy.year_key
WHERE LENGTH(s.country_code) = 2  -- exclude aggregates
;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

-- 1. Row count
SELECT 'Fact table rows' AS check, COUNT(*) AS result FROM fact_energy_balance;

-- 2. No NULL obs_values (should be impossible)
SELECT 'NULL obs_values' AS check, COUNT(*) AS result FROM fact_energy_balance WHERE obs_value IS NULL;

-- 3. Grain uniqueness
SELECT
    'Grain unique' AS check,
    CASE WHEN COUNT(*) = COUNT(DISTINCT (
        country_key::VARCHAR || '|' || product_key::VARCHAR || '|' ||
        balance_key::VARCHAR || '|' || unit_key::VARCHAR || '|' ||
        year_key::VARCHAR
    )) THEN 'YES' ELSE 'NO — DUPLICATES FOUND' END AS result
FROM fact_energy_balance;

-- 4. No orphan keys
SELECT 'Orphan countries' AS check, COUNT(*) AS result
FROM fact_energy_balance f LEFT JOIN dim_country dc ON f.country_key = dc.country_key WHERE dc.country_key IS NULL;

SELECT 'Orphan products' AS check, COUNT(*) AS result
FROM fact_energy_balance f LEFT JOIN dim_energy_product dp ON f.product_key = dp.product_key WHERE dp.product_key IS NULL;

SELECT 'Orphan balance' AS check, COUNT(*) AS result
FROM fact_energy_balance f LEFT JOIN dim_balance_item db ON f.balance_key = db.balance_key WHERE db.balance_key IS NULL;

SELECT 'Orphan units' AS check, COUNT(*) AS result
FROM fact_energy_balance f LEFT JOIN dim_unit du ON f.unit_key = du.unit_key WHERE du.unit_key IS NULL;

-- 5. Top 5 countries by total energy (TJ, primary production)
SELECT
    dc.country_name,
    ROUND(SUM(f.obs_value), 0) AS total_energy_tj
FROM fact_energy_balance f
JOIN dim_country dc ON f.country_key = dc.country_key
JOIN dim_unit du ON f.unit_key = du.unit_key
JOIN dim_balance_item db ON f.balance_key = db.balance_key
WHERE du.unit_code = 'TJ'
    AND db.balance_code = 'PPRD'
GROUP BY dc.country_name
ORDER BY total_energy_tj DESC
LIMIT 5;

-- 6. Germany renewables trend (TJ, primary production, by year)
SELECT
    dy.year,
    ROUND(SUM(f.obs_value), 0) AS renewable_energy_tj
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
GROUP BY dy.year
ORDER BY dy.year;
