# Quality Report — Week 1

## Dataset: nrg_bal_c (Eurostat Complete Energy Balances)
## Date: March 2026
## Contract: contracts/energy_balance_raw.yaml v0.1.0

---

## Summary

| Metric | Value |
|--------|-------|
| Total rows | _[update after Query 2]_ |
| Date range | _[year]_ to _[year]_ |
| Countries/geo codes | _[X]_ |
| Energy products (siec) | _[X]_ |
| Balance items (nrg_bal) | _[X]_ |
| Units | _[X]_ |
| Rows with OBS_VALUE | _[X]_ (_[X]_%_) |
| Rows with NULL OBS_VALUE | _[X]_ (_[X]_%_) |

## Quality Check Results

| Rule | Severity | Rows Passing | Rows Failing | Pass Rate |
|------|----------|-------------|-------------|-----------|
| no_null_geo | critical | _[X]_ | _[X]_ | _[X]%_ |
| valid_year_range | critical | _[X]_ | _[X]_ | _[X]%_ |
| no_null_nrg_bal | critical | _[X]_ | _[X]_ | _[X]%_ |
| no_null_unit | critical | _[X]_ | _[X]_ | _[X]%_ |
| valid_units_only | warning | _[X]_ | _[X]_ | _[X]%_ |
| annual_frequency | warning | _[X]_ | _[X]_ | _[X]%_ |
| no_duplicate_keys | critical | _[X]_ | _[X]_ | _[X]%_ |
| row_count_minimum | critical | _[X]_ | — | PASS/FAIL |
| geo_code_length | warning | _[X]_ | _[X]_ | _[X]%_ |

**Overall quality score:** _[X]%_ of rows pass all critical rules.

---

## Issues Found

### Issue 1: _[name — e.g., "High NULL rate in OBS_VALUE"]_

- **Description:** _[what it is]_
- **Rows affected:** _[X]_ (_[X]%_ of total)
- **SQL that found it:** Query 3 in 01_exploration.sql
- **Impact:** _[why it matters for the star schema and dashboard]_
- **Contract rule:** _[which rule catches this, or "new rule needed"]_

### Issue 2: _[name — e.g., "Aggregate geo codes mixed with countries"]_

- **Description:** _[what it is]_
- **Rows affected:** _[X]_
- **SQL that found it:** Query 4 in 01_exploration.sql
- **Impact:** _[why it matters]_
- **Contract rule:** _[which rule]_

### Issue 3: _[name — e.g., "Duplicate key combinations"]_

- **Description:** _[what it is]_
- **Rows affected:** _[X]_
- **SQL that found it:** Query 5/6 in 01_exploration.sql
- **Impact:** _[why it matters]_
- **Contract rule:** no_duplicate_keys (handled by staging deduplication)

---

## Decision Log

| # | Decision | Reasoning |
|---|----------|-----------|
| 1 | Drop DATAFLOW and LAST UPDATE columns in staging | SDMX metadata, not analytical data. Not needed in star schema. |
| 2 | UPPER + TRIM all string columns | Standardize for consistent joins. Prevents "DE" != "de " bugs. |
| 3 | Filter rows where geo IS NULL | Contract rule: no_null_geo. Can't attribute to any country. |
| 4 | Deduplicate by natural key, prefer non-NULL OBS_VALUE | Contract rule: no_duplicate_keys. Keep the most informative row. |
| 5 | Keep rejected rows in a separate view | Auditability. We must know what we dropped and why. |
| 6 | Classify geo codes as 'country' vs 'aggregate' by length | 2-char = ISO country code. Longer = Eurostat aggregate (EU27_2020, EA20). |
| 7 | _[add more as they come up during the build]_ | |

---

## Staging Results

| View | Row Count |
|------|-----------|
| raw_energy (source) | _[X]_ |
| stg_energy_balance (passed) | _[X]_ |
| stg_energy_balance_quality_rejected | _[X]_ |
| Difference (deduplicated rows) | _[X]_ |

---

## What This Means for Week 2

The staging layer is built. The contract caught _[X]_ issues that would have surfaced as broken dashboards in Week 6 if we hadn't checked. Next weekend: complete the staging layer with automated quality gates that run before every load.

---

_Contract First. SQL First. Model Second. DAX Last._
