# Contract First

![Architecture Diagram](docs/IMG_0357.png)

**A governed star schema data warehouse built from 39.5 million rows of EU energy data in 8 weekends. Data contracts first. SQL first. Model second. DAX last.**

A build-in-public project by [Michał Mrugała](https://www.linkedin.com/in/michal-mrugala02/) — law student, data engineering intern at ArcelorMittal, and creator of the [Architecture First](https://architecture-first.beehiiv.com) newsletter.

## What is this?

A complete data warehouse built from scratch using real EU energy consumption data from Eurostat. The twist: the data contract is written *before* a single line of transformation SQL. Every quality rule, every staging decision, every dimension traces back to a YAML contract.

The result: **20.7 million rows, 6 dimensions, 9 DAX measures, 7 dashboard pages** — and a full EU AI Act Article 10 compliance mapping that proves a YAML data contract is 70% of what the regulation requires.

## The Philosophy

**SQL First. Model Second. DAX Last.**

Problems solved in SQL stay solved. Problems deferred to Power BI multiply.

## The Stack

- **Database:** DuckDB v1.5.0 (local, serverless, columnar)
- **Data Source:** Eurostat nrg_bal_c — Complete Energy Balances (40 countries, 1990–2024)
- **Contracts:** YAML aligned with ODCS v3.1.0 (Bitol / Linux Foundation)
- **Visualization:** Power BI Desktop
- **Version Control:** Git + GitHub

## 8-Week Build Plan

| Week | Layer | What I Built | Status |
|------|-------|-------------|--------|
| 1 | Contract + Raw | Data contract, exploration, 9 quality checks, staging views | ✅ |
| 2 | Quality Gates | 12 automated quality gates, completeness analysis, 3-tier staging | ✅ |
| 3 | Star Schema | 6 dimension tables, fact table, energy product hierarchy | ✅ |
| 4 | Power BI | 7 dashboard pages, 9 DAX measures, custom teal theme | ✅ |
| 5 | Quality Tests | 24 automated star schema tests — all PASS | ✅ |
| 6 | Dashboard Polish | Conditional formatting, tooltips, balance filters, text boxes | ✅ |
| 7 | Governance | EU AI Act Article 10 mapping, GDPR Art 30, data lineage | ✅ |
| 8 | Showdown | SQL-first vs DAX-first — quantified comparison | ✅ |

## The Numbers

| Metric | Value |
|--------|-------|
| Raw rows loaded | 39,486,867 |
| Fact table rows | 20,709,414 |
| Dimension tables | 6 |
| DAX measures | 9 |
| Calculated columns | 0 |
| Calculated tables | 0 |
| SQL files | 15 |
| Quality rules (cumulative) | 45 |
| Dashboard pages | 7 (5 main + 2 drillthrough) |
| Countries covered | 40 |
| Years covered | 35 (1990–2024) |
| Energy products | 72 (3-level hierarchy) |

## The Hypothesis — Confirmed

> "If the star schema is right, Power BI needs fewer than 10 DAX measures."

**Result: 9 measures for 7 pages.** The star schema eliminated ~40 DAX measures that a flat model would require. Zero calculated columns. Zero calculated tables. Architecture did the work.

## Week-by-Week Results

### Week 1 — Contract + Raw

- **39,486,867 rows** loaded from Eurostat SDMX-CSV
- 9 quality rules — 100% structural pass rate
- **Key finding:** 46.14% of observations have NULL values — missing by design, not data error
- Report: [`docs/quality-report-week1.md`](docs/quality-report-week1.md)

### Week 2 — Quality Gates

- **12 automated gates** running in 2 seconds on 39.5M rows
- 3-tier staging: 21.3M clean + 18.2M missing + 0 rejected
- **Key finding:** Every country has identical 53.2% completeness — structural, not random
- **The 88% trap:** Counting rows without filtering NULLs overestimates observations by 88%
- Report: [`docs/quality-report-week2.md`](docs/quality-report-week2.md)

### Week 3 — Star Schema

- **20,709,414 fact rows** with verified unique grain
- 6 dimensions: Country (40), Product (72), Balance (142), Unit (3), Year (35), ObsStatus (2)
- Zero NULL obs_values, zero orphan keys
- **Key finding:** Germany renewable energy — 10.8× growth from 285,924 TJ (1990) to 3,100,935 TJ (2024)
- Report: [`docs/quality-report-week3.md`](docs/quality-report-week3.md)

### Week 4 — Power BI

- 7 pages: Executive Pulse, Geographic, Energy Mix, Balance Flow, Transition Story + 2 drillthrough
- 9 DAX measures (5 core + 4 dynamic KPI)
- Custom teal theme (#00827A), bookmark navigation, conditional formatting
- **Key finding:** The star schema made Power BI a thin presentation layer — not a calculation engine

### Week 5 — Quality Tests

- **24 automated tests** — all PASS
- Tests cover: row count stability, NULL keys, referential integrity, grain uniqueness, dimension completeness, cross-unit consistency, measure accuracy
- **Cumulative quality rules: 45** (9 week 1 + 12 week 2 + 24 week 5)
- Report: [`docs/quality-report-week5.md`](docs/quality-report-week5.md)

### Week 6 — Dashboard Polish

- Conditional formatting on YoY cards (teal positive, coral negative)
- Balance name filters on KPI cards (Total energy supply, Primary production)
- Primary production filter on Energy Mix chart (removes negative electricity artifact)
- Renewable Share (FEC) measure — correct denominator for renewable primary sources
- CAGR null-guard for countries with incomplete data (UK, Ukraine, Turkey)

### Week 7 — Governance

- **EU AI Act Article 10 full mapping** — all 8 sub-clauses (10.2a through 10.2h) mapped to YAML fields and SQL files
- GDPR Article 30 record of processing activities
- Complete data lineage: Eurostat API → DuckDB → staging → star schema → Parquet → Power BI
- **Key finding:** A YAML data contract already covers ~70% of what Article 10 requires. The gap is 3 lines of YAML per sub-clause.
- Contract: [`contracts/energy_balance_v0.4.yaml`](contracts/energy_balance_v0.4.yaml)
- Report: [`docs/governance-report-week7.md`](docs/governance-report-week7.md)

### Week 8 — The Showdown

| Metric | SQL-First (actual) | DAX-First (estimated) |
|--------|-------------------|----------------------|
| DAX measures | 9 | 50+ |
| Calculated columns | 0 | 6+ |
| Calculated tables | 0 | 2+ |
| Model relationships | 6 (star) | 0 (flat) |
| SQL files | 15 | 0 |
| Quality rules | 45 | 0 |
| Governance docs | YAML + 5 reports | none |
| Fact table rows | 20.7M (staged) | 39.5M (raw) |
| Debug time | minutes (SQL) | hours (DAX) |

Report: [`docs/showdown-week8.md`](docs/showdown-week8.md)

### DAX Measure Catalog

| Measure | DAX Pattern | Purpose |
|---------|------------|---------|
| Total Energy | `SUM(obs_value)` | Base aggregation |
| YoY Change % | `CALCULATE + FILTER(ALL)` | Year-over-year comparison |
| CAGR | `MAXX + FILTER + POWER` | Compound annual growth rate with null-guard |
| Share of Total % | `DIVIDE + ALL(Dim_EnergyProduct)` | Product share of total energy |
| Moving Avg 3Y | `AVERAGEX + FILTER(ALL)` | 3-year smoothing |
| Renewable Share (FEC) | `CALCULATE + FILTER(SEARCH)` | Renewable primary sources / final consumption |
| Latest Energy | `CALCULATE + MAX(year)` | Dynamic KPI — last year in slicer |
| Latest YoY | `CALCULATE + MAX(year)` | Dynamic KPI — last year YoY |
| Latest Renewable Share (FEC) | `CALCULATE + MAX(year)` | Dynamic KPI — last year renewables |

### Design Decisions

| Decision | Reasoning |
|----------|-----------|
| Parquet export with ZSTD | Compressed for Power BI. Fact table excluded from git (70MB). |
| Auto Date/Time disabled | Saves ~76% memory. Dim_Year handles all time intelligence. |
| Integer surrogate keys | Faster joins than string keys on 20.7M rows. |
| Single-direction relationships | Prevents ambiguous filter propagation in star schema. |
| "Total" excluded via report filter | level1_category = "Total" caused double-counting. |
| Balance filters on KPI cards | Total Energy Supply filtered to "Total energy supply" balance item. |
| Primary production on Energy Mix | Prevents negative electricity values in stacked area chart. |
| Renewable Share uses SEARCH filter | Bypasses en-dash encoding mismatch in balance_name. |
| Latest-year measures for KPIs | Visual-level filters broke slicer interaction. DAX with MAX(year) solves dynamically. |
| 2024 data flagged as preliminary | Incomplete Eurostat reporting causes artificial YoY drops. Default slicer: 1990–2023. |

## What I Learned

1. **The star schema eliminated 80% of DAX complexity.** 9 measures instead of 50+. The model does the filtering, not the formula.
2. **Data contracts catch bugs before they reach the dashboard.** The renewable share error (6% vs 24%) was a measure problem, not a data problem. The contract was correct — the query asked the wrong question.
3. **Governance documentation is architecture, not paperwork.** Mapping Article 10 to YAML took 3 lines per sub-clause because the contract already had the structure.
4. **SQL First is not a philosophy. It's a decision framework.** Every decision point asks: "Can this be solved in SQL?" If yes, solve it there. If not, then and only then, write DAX.
5. **46% of data being NULL is not a problem. Not knowing why is.** The completeness analysis turned a scary number into a documented design decision.

## Project Structure

```
contract-first-warehouse/
├── README.md
├── .gitignore
├── /contracts
│   ├── energy_balance_raw.yaml        # Data contract v0.3
│   └── energy_balance_v0.4.yaml       # Full Article 10 + GDPR Art 30 + lineage
├── /sql
│   ├── /explore
│   │   └── 01_exploration.sql         # 17 exploration queries (Week 1)
│   ├── /quality
│   │   ├── 02_quality_checks.sql      # Manual quality checks (Week 1)
│   │   ├── 04_quality_gates.sql       # 12 automated gates (Week 2)
│   │   ├── 05_completeness_analysis.sql  # Completeness deep dive (Week 2)
│   │   └── 15_star_schema_tests.sql   # 24 automated tests (Week 5)
│   ├── /staging
│   │   ├── 03_staging_views.sql       # Original staging views (Week 1)
│   │   └── 06_staging_v2.sql          # 3-tier staging (Week 2)
│   ├── /model
│   │   ├── 07_dim_country.sql
│   │   ├── 08_dim_energy_product.sql
│   │   ├── 09_dim_balance_item.sql
│   │   ├── 10_dim_unit.sql
│   │   ├── 11_dim_year.sql
│   │   ├── 12_dim_obs_status.sql
│   │   └── 13_fact_energy_balance.sql
│   └── /export
│       └── 14_parquet_export.sql
├── /export/parquet                     # Star schema for Power BI
├── /powerbi
│   ├── /themes
│   │   └── eu_energy_architecture.json
│   └── contract_first.pbix            # Not tracked (binary)
├── /docs
│   ├── quality-report-week1.md
│   ├── quality-report-week2.md
│   ├── quality-report-week3.md
│   ├── quality-report-week5.md
│   ├── governance-report-week7.md     # Article 10 mapping + GDPR + lineage
│   └── showdown-week8.md              # SQL-first vs DAX-first benchmark
└── /raw                                # Source data (not tracked)
    └── nrg_bal_c.csv
```

## How to Reproduce

1. Download `nrg_bal_c` from [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table?lang=en) (SDMX-CSV format)
2. Place in `raw/nrg_bal_c.csv`
3. Run SQL files in order:
   ```
   duckdb warehouse.duckdb
   .read sql/explore/01_exploration.sql
   .read sql/staging/06_staging_v2.sql
   .read sql/model/07_dim_country.sql
   -- ... through 13_fact_energy_balance.sql
   .read sql/quality/15_star_schema_tests.sql
   .read sql/export/14_parquet_export.sql
   ```
4. Open `powerbi/contract_first.pbix` in Power BI Desktop
5. If fact table parquet is missing, regenerate from DuckDB:
   ```sql
   COPY Fact_EnergyBalance TO 'export/parquet/fact_energy_balance.parquet'
     (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000);
   ```

## EU AI Act Article 10 — Why This Matters

Article 10 of the EU AI Act requires documented data governance for high-risk AI systems. Enforcement begins **August 2, 2026**. Penalty: up to €20M or 4% of global annual turnover.

This project demonstrates that a well-structured YAML data contract already contains ~70% of what Article 10 requires. The full mapping is in [`contracts/energy_balance_v0.4.yaml`](contracts/energy_balance_v0.4.yaml).

## Follow the Build

- **LinkedIn:** [Michał Mrugała](https://www.linkedin.com/in/michal-mrugala02/) — weekly posts on data architecture
- **Newsletter:** [Architecture First](https://architecture-first.beehiiv.com) — deeper technical reasoning every Friday
- **Template Pack:** [EU AI Act Article 10 Templates](https://michalmrugala.gumroad.com/l/article10) — YAML, SQL, and compliance docs

## License

Code: MIT. Data: Eurostat open data (CC BY 4.0). Attribution: "Source: Eurostat."
