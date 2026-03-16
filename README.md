# Contract First

**Building a governed star schema data warehouse from EU energy data in 8 weekends. Data contracts first. SQL first. Model second. DAX last.**
![Architecture Diagram](docs/IMG_0357.jpg)
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
| 2 | Staging | Complete staging layer + automated quality gates |
| 3 | Model | Star schema design + dimension tables |
| 4 | DAX Trap | Connect Power BI, kill unnecessary DAX measures |
| 5 | Quality | SQL-based quality tests before data touches Power BI |
| 6 | Dashboard | Minimal DAX, maximum model — the full report |
| 7 | Governance | GDPR Article 30 records, data lineage, retention policies |
| 8 | Showdown | SQL-first vs DAX-first — full performance benchmark |

## Week 1 Results

- **Dataset:** nrg_bal_c (Eurostat Complete Energy Balances)
- **Total rows:** 39,486,867
- **Countries:** 41 (40 individual + 1 EU aggregate)
- **Energy products:** 72
- **Balance items:** 142
- **Time range:** 1990–2024 (35 years)
- **Quality checks:** 9 rules tested — 100% structural pass rate
- **Key finding:** 46.14% of observations have NULL values (flagged as 'm' by Eurostat — missing by design, not by error)
- **Data contract:** [`contracts/energy_balance_raw.yaml`](contracts/energy_balance_raw.yaml)
- **Quality report:** [`docs/quality-report-week1.md`](docs/quality-report-week1.md)

## Project Structure

```
contract-first-warehouse/
├── README.md
├── .gitignore
├── /raw                  # Source data (not tracked in git)
│   └── nrg_bal_c.csv
├── /contracts            # Data contracts (YAML)
│   └── energy_balance_raw.yaml
├── /sql
│   ├── /explore          # Exploration queries
│   │   └── 01_exploration.sql
│   ├── /quality          # Quality check queries
│   │   └── 02_quality_checks.sql
│   └── /staging          # Staging views
│       └── 03_staging_views.sql
├── /docs                 # Documentation
│   └── quality-report-week1.md
└── /powerbi              # Power BI files (Week 4+)
```

## Follow the Build

- **LinkedIn:** Weekly posts every Tuesday - the mistake, the fix, the principle
- **Newsletter:** [Architecture First](https://architecture-first.beehiiv.com) -
-  deeper architecture reasoning every Friday

## License

Code: MIT. Data: Eurostat open data license (CC BY 4.0).
