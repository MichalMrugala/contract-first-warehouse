# Contract First

[![License: MIT](https://img.shields.io/badge/License-MIT-0D5C55.svg)](https://opensource.org/licenses/MIT)
[![Release](https://img.shields.io/github/v/tag/MichalMrugala/contract-first-warehouse?label=release&color=0D5C55)](https://github.com/MichalMrugala/contract-first-warehouse/releases)
[![EU AI Act](https://img.shields.io/badge/EU%20AI%20Act-Article%2010-0D5C55.svg)](docs/article-10-mapping.md)
[![Multi-Entity](https://img.shields.io/badge/Pattern-Multi--Entity-D96846.svg)](docs/multi-entity-pattern.md)
[![Newsletter](https://img.shields.io/badge/Newsletter-Architecture%20First-0D5C55.svg)](https://architecture-first.beehiiv.com)

> **The reference implementation for EU AI Act Article 10 data governance — including the joint-deployer pattern for multi-entity organisations.**
> A governed star schema data warehouse built from 39.5M rows of EU energy data in 8 weekends. YAML data contracts written before a single SQL query. Now extended with the multi-entity reference for joint deployer arrangements under Article 3(8) and Article 26.

![Architecture Diagram](docs/architecture-sketch.png)

A public build-in-public project by [Michał Mrugała](https://www.linkedin.com/in/michal-mrugala02/) and the [Architecture First](https://architecture-first.beehiiv.com) newsletter.

---

## Why this exists

EU AI Act enforcement is staged. Annex I high-risk systems begin **2 August 2028**. Annex III high-risk systems begin **2 December 2027** (extended from August 2026 via the Digital Omnibus process). Penalties remain: up to **€35M or 7% of global turnover** for the most serious violations.

Article 10 requires documented data governance for every high-risk AI system: documented bias assessment, documented data gaps, documented provenance, documented legal basis. Most data teams have none of these in a regulator-defensible format. Most published guidance assumes a single deployer.

Real organisations are not built that way. A parent group sets policy. A subsidiary runs the pipeline. A retail arm uses the same platform for non-regulated purposes. Three entities. One AI system. Article 10 applies — but to whom, and for what?

This repository is the working reference for both cases. Single-deployer Article 10 mapping is in v0.4. Joint-deployer multi-entity pattern is in v0.5.

---

## What you will find here

- **Working YAML data contracts** mapped to all 8 Article 10 sub-clauses ([single deployer](contracts/energy_balance_v0.4.yaml) | [multi-entity joint deployer](contracts/energy_balance_v0.5_multi_entity.yaml))
- **The multi-entity pattern document** — when single-deployer YAML breaks and what replaces it ([read it](docs/multi-entity-pattern.md))
- **A 39.5M row data warehouse** built from real Eurostat data with 24 automated quality tests
- **A complete Power BI implementation** with 9 DAX measures across 7 pages — not 50
- **Every architecture decision documented** with the reasoning behind it
- **Eight weekly write-ups** showing what broke, what was fixed, and what the principle was

---

## Quick stats

| Metric | Value |
|---|---|
| Source rows ingested | 39,486,867 |
| Fact table rows | 20,709,414 |
| Dimensions | 6 (with 0 orphan keys) |
| Quality tests | 24 (all passing) |
| DAX measures | 9 (across 7 Power BI pages) |
| Weekends to build | 8 |
| Article 10 sub-clauses mapped | 8 of 8 |
| Multi-entity reference | v0.5 — joint deployer pattern |
| Public from day | 1 |

---

## The Philosophy

**SQL First. Model Second. DAX Last.**

Problems solved in SQL stay solved. Problems deferred to Power BI multiply.

---

## The Stack

- **Database:** DuckDB v1.5.0 (local, serverless, columnar)
- **Data Source:** Eurostat nrg_bal_c — Complete Energy Balances (EU-27, 1990–2024)
- **Contracts:** ODCS v3.1.0 (YAML) with custom `x_ai_act_article_10`, `x_ai_act_article_3_8`, and `x_ai_act_article_26` extensions
- **Visualization:** Power BI Desktop
- **Version Control:** Git + GitHub

---

## EU AI Act Article 10 Compliance

Each of the 8 Article 10 sub-clauses maps to specific YAML fields in the data contract. The contract is validated on every pipeline run via SQL tests — not signed off once and forgotten.

**Read the full mapping:** [docs/article-10-mapping.md](docs/article-10-mapping.md)

The mapping covers:
- Sub-clause 2(a) — Data governance practices
- Sub-clause 2(b) — Data collection procedures
- Sub-clause 2(c) — Data preparation operations
- Sub-clause 2(d) — Bias examination
- Sub-clause 2(e) — Data gaps identification
- Sub-clause 2(f) — Relevance assessment
- Sub-clause 3 — Representativeness
- Sub-clause 5 — Special categories handling

---

## Multi-Entity Implementation

Single-deployer Article 10 mapping breaks the moment a subsidiary runs a platform the parent procured. When two or more legal entities share authority over the same AI system, both are deployers under Article 3(8). Article 26 obligations apply to each. Documentation that names a single owner ceases to function the moment a regulator asks which entity is responsible for what.

The multi-entity pattern adds three blocks to the YAML structure:

- **`deployer_arrangement`** — composable joint-deployer pattern with one row per entity, one row per joint responsibility, one explicit boundary for hybrid (regulated + non-regulated) usage
- **`x_ai_act_article_3_8`** — per-entity authority analysis covering procurement, policy, operational, and end-use decision dimensions
- **`x_ai_act_article_26`** — joint deployer obligation matrix with GDPR Article 26 written-agreement test by analogy

The legal grounding rests on three CJEU cases that established joint controllership doctrine under GDPR — translated to deployer status under the AI Act:

- **C-210/16** (*Wirtschaftsakademie Schleswig-Holstein*, 2018) — decisive influence as the controlling test, joint status without direct technical access
- **C-25/17** (*Jehovah's Witnesses*, 2018) — joint determination of purposes and means even when one party never touches the data
- **C-40/17** (*Fashion ID*, 2019) — doctrine extends to embedded-component scenarios on shared platforms

**Read the full pattern:** [docs/multi-entity-pattern.md](docs/multi-entity-pattern.md)
**Reference YAML:** [contracts/energy_balance_v0.5_multi_entity.yaml](contracts/energy_balance_v0.5_multi_entity.yaml)

---

## 8-Week Build Log

| Week | Layer | Status | Notes |
|---|---|---|---|
| 1 | Contract + Raw + Exploration | Complete | [Quality Report](docs/quality-report-week1.md) |
| 2 | Quality Gates + 3-tier Staging | Complete | [Quality Report](docs/quality-report-week2.md) |
| 3 | Star Schema (6 dims + fact) | Complete | 20.7M row fact table |
| 4 | Power BI Connection + DAX | Complete | See DAX catalog below |
| 5 | DAX Refinement + KPI Logic | Complete | Renewable share fix, CAGR, balance filters |
| 6 | Final Dashboard (7 pages) | Complete | Executive Pulse, Geographic, Energy Mix, Balance Flow, Transition Story, Country Profile, Product Detail |
| 7 | Governance Layer (YAML v0.4) | Complete | Article 10 + GDPR Art 30 + lineage |
| 8 | Documentation + v1.0.0 Release | Complete | [v1.0.0 shipped](https://github.com/MichalMrugala/contract-first-warehouse/releases/tag/v1.0.0) |
| Post-launch | Multi-Entity v0.5 + v1.1.0 Release | Complete | Joint deployer pattern, Article 3(8) + 26 mapping |

---

## Key Findings

- **46% of source data is structurally missing** (Eurostat flag `m`). Treating NULLs as zeros overestimates totals by 88%.
- **Germany renewable energy** grew **10.8x** from 1990 to 2024 (285,924 TJ → 3,100,935 TJ).
- **Norway leads** total energy production across the EU-27 dataset.
- **9 DAX measures replaced an estimated 40+** that a flat data model would require. Star schema did the work.
- **Single-deployer YAML breaks at the first subsidiary boundary.** Multi-entity pattern is not optional for group structures.

---

## DAX Measure Catalog

| Measure | DAX Pattern | Purpose |
|---|---|---|
| Total Energy | SUM(obs_value) | Base aggregation |
| YoY Change % | CALCULATE + FILTER(ALL) | Year-over-year comparison |
| CAGR | POWER(DIVIDE, 1/N) - 1 | Compound annual growth rate |
| Share of Total % | DIVIDE + ALL(Dim_EnergyProduct) | Product share of total |
| Moving Avg 3Y | AVERAGEX + FILTER(ALL) | 3-year smoothing |
| Latest Energy | CALCULATE + MAX(year) | Dynamic KPI for slicer |
| Latest YoY | CALCULATE + MAX(year) | Dynamic YoY KPI |
| Latest Renewable Share | CALCULATE + MAX(year) + filter | Dynamic renewables KPI |
| Latest Germany Renewables | CALCULATE + MAX(year) + filters | Country-specific KPI |

---

## Project Structure

Top-level files:

- **README.md** — this document
- **LICENSE** — MIT for code, Eurostat CC BY 4.0 for data
- **CITATION.cff** — formal citation metadata
- **CHANGELOG.md** — version history per weekend and post-launch
- **CONTRIBUTING.md** — contribution guidelines
- **CODE_OF_CONDUCT.md** — community standards
- **.gitignore** — excludes raw data and binary files

Folders:

- **raw/** — source Eurostat data (gitignored)
- **contracts/** — YAML data contracts: `v0.4` (single deployer, full Article 10) and `v0.5` (multi-entity joint deployer)
- **sql/explore/** — 17 exploration queries (Week 1)
- **sql/quality/** — 24 automated tests (Weeks 1, 2, 5)
- **sql/staging/** — 3-tier staging views: clean, missing, rejected (Week 2)
- **sql/model/** — 6 dimension tables + fact table (Week 3)
- **export/parquet/** — star schema exported for Power BI (Week 4)
- **powerbi/themes/** — custom teal theme `eu_energy_architecture.json`
- **docs/** — `article-10-mapping.md`, `multi-entity-pattern.md`, quality reports, architecture sketch

---

## Quick Start (5 minutes)

Step 1 — Clone the repository:

    git clone https://github.com/MichalMrugala/contract-first-warehouse.git
    cd contract-first-warehouse

Step 2 — Download Eurostat data (SDMX-CSV format) from:
https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table?lang=en

Place it in: `raw/nrg_bal_c.csv`

Step 3 — Build the warehouse (DuckDB v1.5.0+ required):

    duckdb warehouse.duckdb
    .read sql/explore/01_exploration.sql
    .read sql/quality/02_quality_checks.sql
    .read sql/staging/06_staging_v2.sql
    .read sql/model/07_dim_country.sql
    .read sql/model/08_dim_energy_product.sql
    .read sql/model/09_dim_balance_item.sql
    .read sql/model/10_dim_unit.sql
    .read sql/model/11_dim_year.sql
    .read sql/model/12_dim_obs_status.sql
    .read sql/model/13_fact_energy_balance.sql
    .read sql/quality/04_quality_gates.sql

Step 4 — Export to Parquet for Power BI:

    COPY Fact_EnergyBalance TO 'export/parquet/fact_energy_balance.parquet'
      (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000);

Step 5 — Open the Power BI file at `powerbi/contract_first.pbix`

---

## Who is this for?

You will get the most out of this repository if you are:

- **A data engineering lead** preparing your team for EU AI Act compliance
- **A privacy or compliance officer** who needs technical artifacts, not policy PDFs
- **A consultant** building governance practices for SME and mid-market clients
- **A senior architect at a group structure** preparing the multi-entity case
- **A senior analyst** transitioning into data engineering and learning what "good" looks like
- **A student or researcher** studying data contracts as compliance artifacts

---

## What I learned

Eight weekends. 39.5 million rows. The biggest finding was not technical.

Data quality and data governance are the same problem viewed from different angles. Quality engineers ask "is this row correct?" Governance officers ask "could you prove that to a regulator in court?" The YAML data contract answers both questions with the same artifact.

If your data contract cannot serve as legal evidence, it is documentation. If it can, it is governance.

The multi-entity extension added a second insight: structure forces conversations that prose deflects. Single-deployer YAML lets ambiguity hide in free text. Multi-entity YAML forces every joint responsibility to name a lead and a reviewer. The conversation that produces those names is the same conversation a regulator will run later — except now it happens up front, when there is time to think.

---

## Follow the build

- **Newsletter:** [Architecture First](https://architecture-first.beehiiv.com) — one architecture rule every Friday at 8:00 CET
- **LinkedIn:** [Michał Mrugała](https://www.linkedin.com/in/michal-mrugala02/) — weekly posts on the build, the breaks, and the principle behind each fix

---

## Star this repository

If this repository saved you research time on Article 10 implementation — please star it. Visibility helps other data engineers find this work before the December 2027 enforcement window closes.

---

## How to cite

See [CITATION.cff](CITATION.cff) for formal citation, or use:

> Mrugała, M. (2026). *Contract First: A reference implementation for EU AI Act Article 10 data governance, including the multi-entity joint deployer pattern*. GitHub. https://github.com/MichalMrugala/contract-first-warehouse

---

## License

- **Code:** MIT — see [LICENSE](LICENSE)
- **Data:** Eurostat open data (CC BY 4.0)
- **Documentation:** CC BY 4.0
