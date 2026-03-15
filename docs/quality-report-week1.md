# Quality Report — Week 1

## Dataset: nrg_bal_c (Eurostat Complete Energy Balances)
## Date: March 15, 2026
## Contract: contracts/energy_balance_raw.yaml v0.1.0

---

## Summary

| Metric | Value |
|--------|-------|
| Total rows | 39,486,867 |
| Date range | 1990 to 2024 |
| Countries/geo codes | 41 (40 countries + 1 aggregate) |
| Energy products (siec) | 72 |
| Balance items (nrg_bal) | 142 |
| Units | 3 (TJ, KTOE, GWH) |
| Rows with OBS_VALUE | 21,268,329 (53.86%) |
| Rows with NULL OBS_VALUE | 18,218,538 (46.14%) |

## Quality Check Results

| Rule | Severity | Rows Passing | Rows Failing | Pass Rate |
|------|----------|-------------|-------------|-----------|
| no_null_geo | critical | 39,486,867 | 0 | 100% |
| valid_year_range | critical | 39,486,867 | 0 | 100% |
| no_null_nrg_bal | critical | 39,486,867 | 0 | 100% |
| no_null_unit | critical | 39,486,867 | 0 | 100% |
| valid_units_only | warning | 39,486,867 | 0 | 100% |
| annual_frequency | warning | 39,486,867 | 0 | 100% |
| no_duplicate_keys | critical | 39,486,867 | 0 | 100% |
| row_count_minimum | critical | 39,486,867 | — | PASS |
| geo_code_length | warning | 39,486,867 | 0 | 100% |

**Overall quality score:** 100% of rows pass all critical structural rules.

**However:** 46.14% of rows have NULL OBS_VALUE — this is not a structural quality issue but a data completeness issue by design. See Issue 1 below.

---

## Issues Found

### Issue 1: 46% of observations have no measured value

- **Description:** 18,218,538 rows (46.14%) have NULL in OBS_VALUE, all flagged with OBS_FLAG = 'm' (missing). This is not a data loading error — Eurostat uses 'm' to mark observations that are unavailable, confidential, or not applicable for a given country-product-year combination.
- **Rows affected:** 18,218,538 (46.14% of total)
- **SQL that found it:** Query 3 and Query 12 in 01_exploration.sql
- **Impact:** Any dashboard that counts rows instead of filtering for non-NULL values will overcount by nearly 2x. Aggregations (SUM, AVG) must explicitly exclude NULL values or results will be misleading. The star schema in Week 3 needs a design decision: include NULLs as "no data" rows or filter them out entirely.
- **Contract rule:** New rule added — obs_value_coverage (informational). The contract documents this as expected behavior, not an error.

### Issue 2: Aggregate geo codes mixed with individual countries

- **Description:** The dataset contains 40 individual country codes (2-character ISO codes like DE, FR, PL) and 1 aggregate code: EU27_2020 (558,915 rows). Aggregates represent pre-calculated totals for the EU as a whole. If included in analysis alongside individual countries, every metric gets double-counted.
- **Rows affected:** 558,915 (1.42% of total)
- **SQL that found it:** Query 4 in 01_exploration.sql, stg_country_reference view
- **Impact:** The star schema Dim_Country table in Week 3 must classify each geo code as 'country' or 'aggregate' and provide a filter. Dashboard filters must default to individual countries only.
- **Contract rule:** geo_code_length (warning) — catches codes longer than 2 characters. The staging view stg_country_reference classifies each code by type.

### Issue 3: Undocumented CONF_STATUS column and legitimate negative values

- **Description:** Two surprises. First: the dataset contains a CONF_STATUS column not present in the original data contract specification — this is a confidentiality status field from the SDMX format. Second: 15 balance item types contain negative values (e.g., STK_CHG with 42,247 negative rows, STATDIFF with 32,862, NRGSUP with 23,613). These are legitimate — stock changes, statistical differences, and net supply calculations can be negative in energy balances.
- **Rows affected:** CONF_STATUS present in all 39,486,867 rows. Negative values in ~145,000+ rows across 15 balance items.
- **SQL that found it:** Query 1 (DESCRIBE) and Query 11 in 01_exploration.sql
- **Impact:** The data contract was updated to include CONF_STATUS. Negative values must NOT be filtered out — they are valid accounting entries. Any quality rule that rejects negative OBS_VALUE would destroy legitimate data. The contract explicitly documents that negative values are expected for specific nrg_bal codes.
- **Contract rule:** Contract updated to include CONF_STATUS field. No negative-value filter rule — documented as valid.

---

## Decision Log

| # | Decision | Reasoning |
|---|----------|-----------|
| 1 | Drop DATAFLOW and LAST UPDATE columns in staging | SDMX metadata, not analytical data. Not needed in star schema. |
| 2 | UPPER + TRIM all string columns | Standardize for consistent joins. Prevents "DE" != "de " bugs. |
| 3 | Filter rows where geo IS NULL | Contract rule: no_null_geo. Can't attribute to any country. |
| 4 | Deduplicate by natural key, prefer non-NULL OBS_VALUE | Contract rule: no_duplicate_keys. Keep the most informative row. |
| 5 | Keep rejected rows in a separate view | Auditability. We must know what we dropped and why. |
| 6 | Classify geo codes as 'country' vs 'aggregate' by length | 2-char = ISO country code. Longer = Eurostat aggregate (EU27_2020). |
| 7 | Do NOT filter negative OBS_VALUE | Negative values are valid for stock changes, exports, statistical differences. Filtering them would destroy legitimate data. |
| 8 | Document CONF_STATUS as unexpected column | Column not in original spec. Added to contract. Does not affect current analysis but must be tracked. |
| 9 | Keep NULL OBS_VALUE rows in staging | These are "no data" observations, not errors. Filtering decision deferred to star schema design (Week 3). |

---

## Staging Results

| View | Row Count |
|------|-----------|
| raw_energy (source) | 39,486,867 |
| stg_energy_balance (passed) | 39,486,867 |
| stg_energy_balance_quality_rejected | 0 |
| Difference (deduplicated rows) | 0 |

All rows passed structural quality checks. Zero rejected. Zero duplicates.

---

## What This Means for Week 2

The staging layer is built. All 9 contract rules pass at 100%. But the contract revealed something the quality checks alone could not: 46% of observations have no measured value. This is not dirty data — it is incomplete data by design. The automated quality gates in Week 2 must distinguish between "structurally invalid" (reject) and "missing by design" (document and pass through). The star schema in Week 3 needs a strategy for 18.2 million NULL values.

---

_Contract First. SQL First. Model Second. DAX Last._
