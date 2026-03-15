-- =============================================================================
-- CONTRACT FIRST — Week 1: Data Exploration
-- =============================================================================
-- File: sql/explore/01_exploration.sql
-- Purpose: Understand the Eurostat nrg_bal_c dataset before writing the contract.
-- Every surprise found here becomes a rule in the data contract.
-- Every quality issue becomes content for the LinkedIn post.
-- =============================================================================
-- Dataset: Eurostat Complete Energy Balances (nrg_bal_c)
-- Format: SDMX-CSV
-- Expected columns: DATAFLOW, LAST UPDATE, freq, nrg_bal, siec, unit, geo,
--                   TIME_PERIOD, OBS_VALUE, OBS_FLAG
-- =============================================================================

-- HOW TO RUN:
-- 1. Open DuckDB:  duckdb warehouse.duckdb
-- 2. Load data:    CREATE TABLE raw_energy AS SELECT * FROM read_csv_auto('raw/nrg_bal_c.csv');
-- 3. Run this:     .read sql/explore/01_exploration.sql
-- =============================================================================


-- QUERY 1: What did we actually load?
-- First thing: check column names and types. SDMX-CSV has specific naming.
-- If column names look wrong, the CSV format is different than expected.
DESCRIBE raw_energy;


-- QUERY 2: How big is this dataset?
-- This number goes in the LinkedIn post and the quality report.
-- Eurostat energy balances should be 500K-2M+ rows depending on download params.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geo) AS unique_countries,
    COUNT(DISTINCT nrg_bal) AS unique_balance_items,
    COUNT(DISTINCT siec) AS unique_energy_products,
    COUNT(DISTINCT unit) AS unique_units,
    MIN(TIME_PERIOD) AS earliest_year,
    MAX(TIME_PERIOD) AS latest_year
FROM raw_energy;


-- QUERY 3: Column-by-column NULL analysis
-- A NULL in geo = useless row (can't attribute to any country).
-- A NULL in OBS_VALUE = observation exists but has no measurement.
-- The contract needs rules for each.
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(geo) AS null_geo,
    COUNT(*) - COUNT(nrg_bal) AS null_nrg_bal,
    COUNT(*) - COUNT(siec) AS null_siec,
    COUNT(*) - COUNT(unit) AS null_unit,
    COUNT(*) - COUNT(TIME_PERIOD) AS null_time_period,
    COUNT(*) - COUNT(OBS_VALUE) AS null_obs_value,
    COUNT(*) - COUNT(OBS_FLAG) AS null_obs_flag,
    ROUND(100.0 * (COUNT(*) - COUNT(OBS_VALUE)) / COUNT(*), 2) AS pct_null_obs_value
FROM raw_energy;


-- QUERY 4: What geo codes exist?
-- Are these ISO 3166-1 alpha-2 country codes? Or Eurostat aggregates (EU27_2020, EA20)?
-- Aggregates will need special handling — they aren't real countries.
SELECT
    geo,
    COUNT(*) AS row_count,
    MIN(TIME_PERIOD) AS first_year,
    MAX(TIME_PERIOD) AS last_year,
    COUNT(DISTINCT TIME_PERIOD) AS years_covered
FROM raw_energy
GROUP BY geo
ORDER BY row_count DESC;


-- QUERY 5: Duplicate key detection — CRITICAL
-- If the same country + balance_item + energy_product + unit + year appears
-- more than once, our fact table will double-count.
-- Natural key: geo + nrg_bal + siec + unit + TIME_PERIOD
SELECT
    geo,
    nrg_bal,
    siec,
    unit,
    TIME_PERIOD,
    COUNT(*) AS duplicate_count
FROM raw_energy
GROUP BY geo, nrg_bal, siec, unit, TIME_PERIOD
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 20;


-- QUERY 6: How many duplicates total?
-- One number for the quality report: "X rows are part of duplicate key combinations"
SELECT
    COUNT(*) AS rows_in_duplicate_keys
FROM (
    SELECT geo, nrg_bal, siec, unit, TIME_PERIOD
    FROM raw_energy
    GROUP BY geo, nrg_bal, siec, unit, TIME_PERIOD
    HAVING COUNT(*) > 1
) dupes
JOIN raw_energy r
    ON r.geo = dupes.geo
    AND r.nrg_bal = dupes.nrg_bal
    AND r.siec = dupes.siec
    AND r.unit = dupes.unit
    AND r.TIME_PERIOD = dupes.TIME_PERIOD;


-- QUERY 7: Year coverage and gaps
-- Which years are in the dataset? Are there gaps?
-- Missing years = missing data points that could break time-series analysis.
SELECT
    TIME_PERIOD AS year,
    COUNT(*) AS row_count,
    COUNT(DISTINCT geo) AS countries_reporting
FROM raw_energy
GROUP BY TIME_PERIOD
ORDER BY TIME_PERIOD;


-- QUERY 8: Energy balance item inventory
-- nrg_bal codes like NRGSUP, PPRD, IMP, EXP, GIC, etc.
-- These become the vocabulary of our fact table.
SELECT
    nrg_bal,
    COUNT(*) AS row_count,
    COUNT(DISTINCT geo) AS countries_using,
    COUNT(DISTINCT TIME_PERIOD) AS years_covered
FROM raw_energy
GROUP BY nrg_bal
ORDER BY row_count DESC;


-- QUERY 9: Energy product inventory (siec codes)
-- TOTAL, SOLID_FF, O4000XBIO, RA000, etc.
-- How many products? Are there aggregates mixed with detail items?
SELECT
    siec,
    COUNT(*) AS row_count,
    COUNT(DISTINCT geo) AS countries_with_product
FROM raw_energy
GROUP BY siec
ORDER BY row_count DESC
LIMIT 30;


-- QUERY 10: Unit variety
-- TJ (terajoules), KTOE (kilotonnes of oil equivalent), GWH, etc.
-- If multiple units exist for the same metric, we need conversion or filtering.
SELECT
    unit,
    COUNT(*) AS row_count,
    COUNT(DISTINCT geo) AS countries_using,
    COUNT(DISTINCT siec) AS products_using
FROM raw_energy
GROUP BY unit
ORDER BY row_count DESC;


-- QUERY 11: Negative values — should energy consumption be negative?
-- In energy balances: YES for some items (exports = negative, stock changes).
-- But for production/consumption items, negatives might signal data errors.
SELECT
    nrg_bal,
    COUNT(*) AS negative_count,
    MIN(OBS_VALUE) AS most_negative,
    AVG(OBS_VALUE) AS avg_value
FROM raw_energy
WHERE OBS_VALUE < 0
GROUP BY nrg_bal
ORDER BY negative_count DESC
LIMIT 15;


-- QUERY 12: Observation flags — what do they mean?
-- OBS_FLAG codes: 'p' = provisional, 'e' = estimated, 'c' = confidential,
-- 'n' = not significant, 'd' = definition differs, etc.
-- Flagged data might need special treatment in the dashboard.
SELECT
    OBS_FLAG,
    COUNT(*) AS flag_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw_energy), 2) AS pct_of_total
FROM raw_energy
GROUP BY OBS_FLAG
ORDER BY flag_count DESC;


-- QUERY 13: Top 10 countries by total energy supply
-- Quick sanity check: do the numbers make sense?
-- Germany, France, Italy should be near the top for EU countries.
SELECT
    geo,
    ROUND(SUM(OBS_VALUE), 0) AS total_value,
    COUNT(*) AS observation_count
FROM raw_energy
WHERE nrg_bal = 'NRGSUP'
    AND unit = 'TJ'
    AND OBS_VALUE IS NOT NULL
    AND LENGTH(geo) = 2  -- filter to country codes only (exclude aggregates)
GROUP BY geo
ORDER BY total_value DESC
LIMIT 10;


-- QUERY 14: Data completeness by country
-- Which countries have the most missing observations (NULL OBS_VALUE)?
-- A country with 40% NULLs needs different treatment than one with 2%.
SELECT
    geo,
    COUNT(*) AS total_rows,
    COUNT(OBS_VALUE) AS rows_with_value,
    COUNT(*) - COUNT(OBS_VALUE) AS rows_without_value,
    ROUND(100.0 * (COUNT(*) - COUNT(OBS_VALUE)) / COUNT(*), 2) AS pct_missing
FROM raw_energy
WHERE LENGTH(geo) = 2  -- country codes only
GROUP BY geo
ORDER BY pct_missing DESC
LIMIT 15;


-- QUERY 15: Year-over-year completeness for a specific country
-- Pick Germany (DE) as a reference — one of the most complete datasets.
-- Missing year-product combinations = holes in the time series.
SELECT
    TIME_PERIOD AS year,
    COUNT(*) AS total_observations,
    COUNT(OBS_VALUE) AS with_value,
    COUNT(*) - COUNT(OBS_VALUE) AS missing_value,
    ROUND(100.0 * COUNT(OBS_VALUE) / COUNT(*), 2) AS completeness_pct
FROM raw_energy
WHERE geo = 'DE'
GROUP BY TIME_PERIOD
ORDER BY TIME_PERIOD;


-- QUERY 16: DATAFLOW and LAST UPDATE columns — metadata check
-- SDMX-CSV includes metadata columns that are not part of the data model.
-- These should be documented but not loaded into the star schema.
SELECT
    DISTINCT DATAFLOW,
    "LAST UPDATE" AS last_update
FROM raw_energy
LIMIT 5;


-- QUERY 17: freq column — what frequency is this data?
-- Should be 'A' (annual) for this dataset. If mixed, we have a problem.
SELECT
    freq,
    COUNT(*) AS row_count
FROM raw_energy
GROUP BY freq;


-- =============================================================================
-- EXPLORATION COMPLETE
-- =============================================================================
-- Next step: Use these findings to write the data contract
-- (contracts/energy_balance_raw.yaml)
--
-- Key findings to document in quality-report-week1.md:
-- 1. Total row count and date range
-- 2. NULL percentages per column (especially OBS_VALUE)
-- 3. Duplicate key count
-- 4. Negative values in unexpected balance items
-- 5. Countries with high missing-value percentages
-- 6. Observation flag distribution
-- =============================================================================
