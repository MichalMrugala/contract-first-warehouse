-- =============================================================================
-- CONTRACT FIRST — Weekend 4: Export Star Schema to Parquet
-- =============================================================================
-- Purpose: Export all star schema tables to Parquet for Power BI consumption.
-- Run from DuckDB: duckdb warehouse.duckdb
-- Then: .read sql/export/14_parquet_export.sql
-- =============================================================================

COPY Dim_Country TO 'export/parquet/dim_country.parquet'
  (FORMAT PARQUET, COMPRESSION ZSTD);

COPY Dim_EnergyProduct TO 'export/parquet/dim_energy_product.parquet'
  (FORMAT PARQUET, COMPRESSION ZSTD);

COPY Dim_BalanceItem TO 'export/parquet/dim_balance_item.parquet'
  (FORMAT PARQUET, COMPRESSION ZSTD);

COPY Dim_Unit TO 'export/parquet/dim_unit.parquet'
  (FORMAT PARQUET, COMPRESSION ZSTD);

COPY Dim_Year TO 'export/parquet/dim_year.parquet'
  (FORMAT PARQUET, COMPRESSION ZSTD);

COPY Dim_ObsStatus TO 'export/parquet/dim_obs_status.parquet'
  (FORMAT PARQUET, COMPRESSION ZSTD);

COPY Fact_EnergyBalance TO 'export/parquet/fact_energy_balance.parquet'
  (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000);

-- Verify exports
SELECT 'dim_country' AS tbl, COUNT(*) AS rows FROM read_parquet('export/parquet/dim_country.parquet')
UNION ALL SELECT 'dim_energy_product', COUNT(*) FROM read_parquet('export/parquet/dim_energy_product.parquet')
UNION ALL SELECT 'dim_balance_item', COUNT(*) FROM read_parquet('export/parquet/dim_balance_item.parquet')
UNION ALL SELECT 'dim_unit', COUNT(*) FROM read_parquet('export/parquet/dim_unit.parquet')
UNION ALL SELECT 'dim_year', COUNT(*) FROM read_parquet('export/parquet/dim_year.parquet')
UNION ALL SELECT 'dim_obs_status', COUNT(*) FROM read_parquet('export/parquet/dim_obs_status.parquet')
UNION ALL SELECT 'fact_energy_balance', COUNT(*) FROM read_parquet('export/parquet/fact_energy_balance.parquet');
