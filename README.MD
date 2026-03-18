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
| 3 | Model | Star schema design + dimension tables |
| 4 | DAX Trap | Connect Power BI, kill unnecessary DAX measures |
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
- **Key finding:** Missing data is structural, not random — every country has identical 53.2% completeness. Root cause: sparse energy product categories (RA100 = 9.36% complete vs TOTAL = 100%)
- **The 88% trap:** Counting rows without filtering NULLs overestimates observations by 88%
- **Unit trap:** Every observation exists in 3 copies (TJ, KTOE, GWH) — dataset is 3x larger than necessary
- **3-tier staging:** 21.3M clean + 18.2M missing + 0 rejected = 39.5M (every row accounted for)
- **Fact table preview:** 6,903,138 rows (countries only, single unit) — 82% reduction from raw
- **3 design decisions locked:** NULLs excluded from fact table, OBS_FLAG not a dimension, Unit as dimension
- **Reports:** [`docs/quality-report-week2.md`](docs/quality-report-week2.md)

## Project Structure

```
contract-first-warehouse/
├── README.md
├── .gitignore
├── /raw                          # Source data (not tracked in git)
│   └── nrg_bal_c.csv
├── /contracts
│   └── energy_balance_raw.yaml   # Data contract v0.2
├── /sql
│   ├── /explore
│   │   └── 01_exploration.sql    # 17 exploration queries
│   ├── /quality
│   │   ├── 02_quality_checks.sql # Manual quality checks (Week 1)
│   │   ├── 04_quality_gates.sql  # Automated quality gates (Week 2)
│   │   └── 05_completeness_analysis.sql  # Completeness deep dive (Week 2)
│   └── /staging
│       ├── 03_staging_views.sql  # Original staging views (Week 1)
│       └── 06_staging_v2.sql     # 3-tier staging (Week 2)
├── /docs
│   ├── quality-report-week1.md
│   └── quality-report-week2.md
└── /powerbi                      # Power BI files (Week 4+)
```

## Follow the Build

- **LinkedIn:** Weekly posts every Tuesday — the mistake, the fix, the principle
- **Newsletter:** [Architecture First](https://architecture-first.beehiiv.com) — deeper architecture reasoning every Friday

## License

Code: MIT. Data: Eurostat open data license (CC BY 4.0).
