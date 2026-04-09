# Contract First
![Architecture Diagram](docs/IMG_0357.png)
**Building a governed star schema data warehouse from EU energy data in 8 weekends. Data contracts first. SQL first. Model second. DAX last.**

A public build-in-public project by [Michał Mrugała](https://www.linkedin.com/in/michal-mrugala02/) — law student, data engineering intern at ArcelorMittal, and creator of the [Architecture First](https://architecture-first.beehiiv.com) newsletter.

## What is this?

I'm building a complete data warehouse from scratch using real EU energy consumption data from Eurostat. The twist: I write the data contract *before* a single line of transformation SQL. Every weekend I build one layer. Every Tuesday I share what broke on LinkedIn.

## The Philosophy

**SQL First. Model Second. DAX Last.**

Problems solved in SQL stay solved. Problems deferred to Power BI multiply.

## The Stack

- **Database:** DuckDB (local, serverless, columnar)
- **Data Source:** Eurostat nrg_bal_c — Complete Energy Balances (EU-27, 1990–2024)
- **Contracts:** datacontract-specification (YAML)
- **Visualization:** Power BI Desktop
- **Version Control:** Git + GitHub

## 8-Week Build Plan

| Week | Layer | What I'm Building |
|------|-------|-------------------|
| 1 ✅ | Contract + Raw | Data contract, exploration, quality checks, staging views |
| 2 ✅ | Quality Gates | Automated quality gates, completeness analysis, 3-tier staging |
| 3 ✅ | Star Schema | 6 dimension tables, fact table, energy product hierarchy |
| 4 ✅ | Power BI | 5 dashboard pages, 9 DAX measures, custom theme |
| 5 | Quality | SQL-based quality tests before data touches Power BI |
| 6 | Dashboard | Minimal DAX, maximum model — the full report |
| 7 | Governance | GDPR Article 30 records, data lineage, retention policies |
| 8 | Showdown | SQL-first vs DAX-first — full performance benchmark |

## Week 1 Results

- **Total rows loaded:** 39,486,867
- **Countries:** 41 (40 individual + 1 EU aggregate)
- **Quality checks:** 9 rules — 100% structural pass rate
- **Key finding:** 46.14% of observations have NULL values (Eurostat flag 'm' = missing by design)
- **Reports:** [`docs/quality-report-week1.md`](docs/quality-report-week1.md)

## Week 2 Results

- **Automated quality gates:** 12 rules running in 2 seconds on 39.5M rows
- **Structural checks:** 8/8 PASS | Consistency: 1/1 PASS
- **Key finding:** Missing data is structural, not random — every country has identical 53.2% completeness
- **The 88% trap:** Counting rows without filtering NULLs overestimates observations by 88%
- **3-tier staging:** 21.3M clean + 18.2M missing + 0 rejected = 39.5M (every row accounted for)
- **Fact table preview:** 6,903,138 rows (countries only, single unit) — 82% reduction from raw
- **Reports:** [`docs/quality-report-week2.md`](docs/quality-report-week2.md)

## Week 3 Results

- **Star schema:** 6 dimension tables + 1 fact table
- **Fact table:** 20,709,414 rows (40 countries × 3 units × 72 products × 142 balance items × 35 years)
- **Grain:** one row = one measured observation (country + product + balance item + unit + year) — verified unique
- **Dim_Country:** 40 individual countries, EU27 aggregate excluded
- **Dim_EnergyProduct:** 72 products with 3-level hierarchy (49 mapped, 23 "Other")
- **Dim_BalanceItem:** 142 balance categories
- **Dim_Unit:** 3 units (TJ, KTOE, GWH) with conversion factors
- **Dim_Year:** 35 years (1990–2024) with decade grouping
- **Dim_ObsStatus:** 2 statuses (measured/missing) for audit trail
- **Validation:** Zero NULL obs_values, zero orphan keys, grain unique
- **Key finding:** Germany renewable energy — 10.8x growth from 285,924 TJ (1990) to 3,100,935 TJ (2024) from a 5-line SQL query with no DAX

## Week 4 Results

- **Power BI connected** to star schema via Parquet export (ZSTD compression)
- **9 DAX measures total:**
  - 5 core: Total Energy, YoY Change %, CAGR, Share of Total %, Moving Avg 3Y
  - 4 dynamic KPI: Latest Energy, Latest YoY, Latest Renewable Share, Latest Germany Renewables
- **5 dashboard pages:** Executive Pulse, Geographic, Energy Mix, Balance Flow, Transition Story
- **2 drillthrough pages:** Country Profile, Product Detail
- **Custom theme:** `eu_energy_architecture.json` — teal #00827A palette, colorblind-safe
- **EU 2030 target line:** 42.5% renewable share reference on Energy Mix and Transition Story
- **Bookmark navigation:** 5 states (1990, 2004, 2020, 2022, 2024) with teal buttons
- **Hypothesis tested:** "If the star schema is right, Power BI needs fewer than 10 DAX measures" — **confirmed (9 measures for 7 pages)**
- **Key finding:** The star schema eliminated the need for ~40 DAX measures that a flat model would require. Zero calculated columns. Zero calculated tables. Architecture did the work.

### DAX Measure Catalog

| Measure | DAX Pattern | Purpose |
|---------|------------|---------|
| Total Energy | `SUM(obs_value)` | Base aggregation |
| YoY Change % | `CALCULATE + FILTER(ALL)` | Year-over-year comparison |
| CAGR | `POWER(DIVIDE, 1/N) - 1` | Compound annual growth rate |
| Share of Total % | `DIVIDE + ALL(Dim_EnergyProduct)` | Product share of total energy |
| Moving Avg 3Y | `AVERAGEX + FILTER(ALL)` | 3-year smoothing |
| Latest Energy | `CALCULATE + MAX(year)` | Dynamic KPI — last year in slicer |
| Latest YoY | `CALCULATE + MAX(year)` | Dynamic KPI — last year YoY |
| Latest Renewable Share | `CALCULATE + MAX(year) + filter` | Dynamic KPI — last year renewables |
| Latest Germany Renewables | `CALCULATE + MAX(year) + filters` | Dynamic KPI — Germany focus |

### Design Decisions (Week 4)

| Decision | Reasoning |
|----------|-----------|
| Parquet export with ZSTD | Compressed from ~2GB DuckDB to manageable files. Fact table excluded from git (70MB). |
| Auto Date/Time disabled | Saves ~76% memory. Dim_Year handles all time intelligence. |
| Integer surrogate keys | Faster joins than string keys on 20.7M rows. |
| Single-direction relationships | Prevents ambiguous filter propagation in star schema. |
| "Total" excluded via report filter | level1_category = "Total" caused double-counting. Filtered at report level, not data level. |
| Latest-year measures for KPIs | Visual-level filters broke slicer interaction. DAX measures with MAX(year) solve dynamically. |

## Project Structure
```
contract-first-warehouse/
├── README.md
├── .gitignore
├── /raw                          # Source data (not tracked in git)
│   └── nrg_bal_c.csv
├── /contracts
│   └── energy_balance_raw.yaml   # Data contract v0.3 + AI Act Article 10 mapping
├── /sql
│   ├── /explore
│   │   └── 01_exploration.sql    # 17 exploration queries (Week 1)
│   ├── /quality
│   │   ├── 02_quality_checks.sql # Manual quality checks (Week 1)
│   │   ├── 04_quality_gates.sql  # Automated quality gates (Week 2)
│   │   └── 05_completeness_analysis.sql  # Completeness deep dive (Week 2)
│   ├── /staging
│   │   ├── 03_staging_views.sql  # Original staging views (Week 1)
│   │   └── 06_staging_v2.sql     # 3-tier staging (Week 2)
│   └── /model
│       ├── 07_dim_country.sql         # Dim_Country (Week 3)
│       ├── 08_dim_energy_product.sql  # Dim_EnergyProduct with hierarchy (Week 3)
│       ├── 09_dim_balance_item.sql    # Dim_BalanceItem (Week 3)
│       ├── 10_dim_unit.sql            # Dim_Unit (Week 3)
│       ├── 11_dim_year.sql            # Dim_Year (Week 3)
│       ├── 12_dim_obs_status.sql      # Dim_ObsStatus (Week 3)
│       └── 13_fact_energy_balance.sql # Fact_EnergyBalance (Week 3)
├── /export
│   └── /parquet                  # Star schema exported for Power BI (Week 4)
│       ├── dim_balance_item.parquet
│       ├── dim_country.parquet
│       ├── dim_energy_product.parquet
│       ├── dim_obs_status.parquet
│       ├── dim_unit.parquet
│       └── dim_year.parquet
│       # fact_energy_balance.parquet excluded (70MB) — regenerate with:
│       # COPY Fact_EnergyBalance TO 'export/parquet/fact_energy_balance.parquet'
│       #   (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000);
├── /powerbi
│   ├── /themes
│   │   └── eu_energy_architecture.json  # Custom teal theme (Week 4)
│   └── contract_first.pbix       # Power BI report (not tracked — binary)
├── /docs
│   ├── quality-report-week1.md
│   └── quality-report-week2.md
```

## How to Reproduce

1. Download data: `nrg_bal_c` from [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table?lang=en) (SDMX-CSV format)
2. Place in `raw/nrg_bal_c.csv`
3. Run SQL files in order: `duckdb warehouse.duckdb` → `.read sql/explore/01_exploration.sql` → etc.
4. Export to Parquet: run COPY TO commands for each table
5. Open `powerbi/contract_first.pbix` in Power BI Desktop
6. If fact table parquet is missing, regenerate from DuckDB (see project structure above)

## Follow the Build

- **LinkedIn:** Weekly posts every Tuesday — the mistake, the fix, the principle
- **Newsletter:** [Architecture First](https://architecture-first.beehiiv.com) — deeper architecture reasoning every Friday

## License

Code: MIT. Data: Eurostat open data license (CC BY 4.0).
