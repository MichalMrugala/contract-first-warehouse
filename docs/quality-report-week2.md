# Quality Report — Week 2

## Weekend 2: Automated Quality Gates + Completeness Analysis
## Date: March 2026
## Contract: contracts/energy_balance_raw.yaml v0.2

---

## What Was Built

1. **Automated Quality Gate Framework** (`sql/quality/04_quality_gates.sql`) — 12 rules running in 2 seconds across 39.5M rows. Produces a timestamped results table with pass/fail verdicts.
2. **Completeness Analysis** (`sql/quality/05_completeness_analysis.sql`) — 10 queries investigating the 46% missing data. Found the root cause and quantified the impact.
3. **Enhanced Staging v2** (`sql/staging/06_staging_v2.sql`) — 3-tier row separation (clean/missing/rejected) plus completeness summary view.

---

## Quality Gate Results

| Rule | Type | Severity | Pass Rate | Result |
|------|------|----------|-----------|--------|
| no_null_geo | structural | critical | 100% | PASS |
| no_null_nrg_bal | structural | critical | 100% | PASS |
| no_null_unit | structural | critical | 100% | PASS |
| no_null_siec | structural | critical | 100% | PASS |
| valid_year_range | structural | critical | 100% | PASS |
| valid_units_only | structural | warning | 100% | PASS |
| annual_frequency_only | structural | warning | 100% | PASS |
| geo_code_length | structural | warning | 100% | PASS |
| missing_has_flag | consistency | warning | 100% | PASS |
| obs_value_not_null | completeness | info | 53.86% | FAIL |
| obs_flag_documented | completeness | info | 100% | PASS |
| conf_status_present | completeness | info | 0% | FAIL |

**Overall Verdict:** GATE PASSED — all structural and consistency checks clear.

**Runtime:** 2 seconds for 12 rules on 39,486,867 rows.

---

## Completeness Analysis Findings

### Finding 1: Missing data is structural, not random

Every country has identical 53.2% completeness. The missing 46% is not caused by countries failing to report — it is caused by energy products that Eurostat tracks but most countries do not produce. Example: RA100 (specific renewable subcategories) has only 9.36% completeness. TOTAL has 100%.

### Finding 2: The 88% overcount error

If you count rows to estimate how many observations a country has, you get 1,050,840 for Germany. But only 558,915 have measured values. Your estimate is off by 88%. Any COUNT-based metric in a dashboard built on this data without filtering NULLs will be wrong by nearly 2x.

### Finding 3: The unit trap — dataset is 3x larger than it needs to be

Every observation exists in 3 identical copies: TJ, KTOE, and GWH. Exactly 33.33% of the dataset per unit. The same fact measured in different units. For the star schema, unit becomes a dimension — not a row multiplier.

### Finding 4: CONF_STATUS is empty

The entire CONF_STATUS column contains NULL values. Eurostat included it in the SDMX format but did not populate it.

### Finding 5: OBS_FLAG is binary

Only two values exist: NULL (validated observation, 53.86%) and 'm' (missing, 46.14%). No provisional, estimated, or confidential flags. This simplifies the star schema — no Dim_ObservationStatus needed.

---

## The 3 Design Decisions

### Decision 1: Missing rows do NOT go into the fact table

Only rows with non-NULL OBS_VALUE enter the fact table. Missing rows are documented in stg_energy_missing for auditability but excluded from analysis. Including 18.2M NULL rows would bloat storage, complicate every DAX measure, and create misleading row counts.

### Decision 2: OBS_FLAG does NOT become a dimension

With only two values (NULL and 'm'), and all 'm' rows excluded from the fact table, every row in the fact table has OBS_FLAG = NULL. A dimension with one value is not a dimension.

### Decision 3: Unit becomes a dimension, all 3 units kept

Keep all 3 units in the fact table. Dim_Unit has 3 rows. Default dashboard filter: TJ. Users can switch between TJ, KTOE, and GWH without runtime conversion.

---

## Staging v2 Results

| View | Row Count | Description |
|------|-----------|-------------|
| raw_energy | 39,486,867 | Source data (unchanged) |
| stg_energy_clean | 21,268,329 | Rows with values, pass all gates |
| stg_energy_missing | 18,218,538 | Structurally valid, no value (flag 'm') |
| stg_energy_rejected | 0 | Failed structural gates |
| **Sum of tiers** | **39,486,867** | **Matches raw — zero rows lost** |

Fact table preview (countries only, TJ): **6,903,138 rows**

From 39.5M raw to 6.9M fact table = **82% reduction** through documented, traceable filtering.

---

_Contract First. SQL First. Model Second. DAX Last._
