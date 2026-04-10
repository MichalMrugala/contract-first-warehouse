# Contract First — Weekend 7: Governance Report

## EU AI Act Article 10 Compliance Mapping

This project maps every sub-clause of Article 10 (Data and Data Governance) of the EU AI Act (Regulation 2024/1689) to specific fields in a YAML data contract.

**Why this matters:** Article 10 requires documented data governance practices for high-risk AI systems. Enforcement begins August 2, 2026. Penalties: up to €20M or 4% of global annual turnover.

**Our approach:** A well-structured YAML data contract already contains most of the information Article 10 requires. The mapping adds 3 lines of YAML per sub-clause — not a new system, but a new lens on existing documentation.

### Article 10(2) Sub-clause Mapping

| Sub-clause | Requirement | Contract Field | Evidence File |
|------------|------------|----------------|---------------|
| 10(2)(a) | Design choices | `quality.specification` + `star_schema.design_decisions` | contracts/energy_balance_v0.4.yaml |
| 10(2)(b) | Data collection | `links.source_api` + `x_legal_basis` | contracts/energy_balance_v0.4.yaml |
| 10(2)(c) | Data preparation | `quality.staging` | sql/staging/06_staging_v2.sql |
| 10(2)(d) | Labelling/annotation | `x_ai_act_article_10.article_10_2_d` | N/A (statistical data) |
| 10(2)(e) | Data gaps | `quality.completeness` | docs/quality-report-week2.md |
| 10(2)(f) | Bias examination | `x_ai_act_article_10.article_10_2_f` | sql/quality/05_completeness_analysis.sql |
| 10(2)(g) | Bias identification | `x_ai_act_article_10.article_10_2_g` | docs/quality-report-week2.md |
| 10(2)(h) | Gap remediation | `x_ai_act_article_10.article_10_2_h` | sql/quality/15_star_schema_tests.sql |

### Key Finding

The gap between existing data engineering best practices and Article 10 requirements is approximately 70%. Most data teams already have quality checks and staging pipelines. What they lack is:
1. **Explicit documentation** linking technical artifacts to legal requirements
2. **Bias examination** as a formal step in the pipeline
3. **Traceability** from contract rule to SQL file to test result

A YAML data contract bridges this gap with minimal overhead.

## GDPR Article 30 Record

| Field | Value |
|-------|-------|
| Controller | Michał Mrugała (educational project) |
| Purpose | Analytics and reporting on EU energy consumption |
| Legal basis | Legitimate interest — public statistical data |
| Data categories | National-level energy statistics (non-personal) |
| Data subjects | None |
| Recipients | GitHub (public), Power BI (local), Beehiiv newsletter |
| Retention | Project duration |
| DPO required | No |
| DPIA required | No |

## Data Lineage

```
Eurostat SDMX API
        │
        ▼
  raw/nrg_bal_c.csv (39.5M rows)
        │
        ▼
  ┌─────────────────────────┐
  │  DuckDB: raw_energy     │ ← sql/explore/01_exploration.sql
  │  39,486,867 rows        │
  └─────────────────────────┘
        │
        ▼
  ┌─────────────────────────┐
  │  Quality Gates           │ ← sql/quality/04_quality_gates.sql
  │  12 rules, all PASS     │
  └─────────────────────────┘
        │
        ├──► stg_energy_clean    (21.3M) ──► Fact table
        ├──► stg_energy_missing  (18.2M) ──► Documented
        └──► stg_energy_rejected (0)     ──► None
                    │
                    ▼
  ┌─────────────────────────┐
  │  Star Schema             │ ← sql/model/07-13*.sql
  │  6 dims + 1 fact         │
  │  20,709,414 rows         │
  └─────────────────────────┘
        │
        ▼
  ┌─────────────────────────┐
  │  Schema Tests            │ ← sql/quality/15_star_schema_tests.sql
  │  24 tests, all PASS      │
  └─────────────────────────┘
        │
        ▼
  ┌─────────────────────────┐
  │  Parquet Export (ZSTD)   │ ← sql/export/14_parquet_export.sql
  └─────────────────────────┘
        │
        ▼
  ┌─────────────────────────┐
  │  Power BI Dashboard      │
  │  7 pages, 9 DAX measures │
  └─────────────────────────┘
```

Every arrow traces to a SQL file. Every SQL file traces to a contract rule.

## Design Decisions Log

| # | Decision | Reasoning | Week |
|---|----------|-----------|------|
| 1 | Exclude geographic aggregates | Prevents double-counting when users SUM countries | 3 |
| 2 | Missing rows excluded, not imputed | Preserves data integrity; documented in stg_energy_missing | 2 |
| 3 | Unit as dimension (all 3 kept) | SQL First — solve unit selection in warehouse, not DAX | 3 |
| 4 | 3-tier staging (clean/missing/rejected) | Complete audit trail — every row accounted for | 2 |
| 5 | Integer surrogate keys | Faster joins than string keys on 20.7M rows | 3 |
| 6 | YAML contract before SQL | Contract defines rules; SQL implements them | 1 |
| 7 | "Total" excluded via report filter | Aggregate category caused silent double-counting | 4 |
| 8 | Latest-year DAX measures | Visual-level filters broke slicer interaction | 4 |
| 9 | Parquet export (ZSTD) | Compressed, portable, Power BI native support | 4 |
| 10 | Auto Date/Time disabled | Saves ~76% memory; Dim_Year handles time intelligence | 4 |


