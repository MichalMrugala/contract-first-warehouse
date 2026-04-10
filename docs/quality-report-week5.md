# Contract First — Weekend 5: Star Schema Quality Report

## Test Execution

- **Date:** 2026-04-10
- **Database:** warehouse.duckdb
- **Command:** `.read sql/quality/15_star_schema_tests.sql`
- **Execution time:** <1 second

## Results

| Test | Expected | Actual | Status |
|------|----------|--------|--------|
| T01: Fact row count | 20,709,414 | 20,709,414 | PASS |
| T02a: NULL country_key | 0 | 0 | PASS |
| T02b: NULL product_key | 0 | 0 | PASS |
| T02c: NULL balance_key | 0 | 0 | PASS |
| T02d: NULL unit_key | 0 | 0 | PASS |
| T02e: NULL year_key | 0 | 0 | PASS |
| T03a: Orphan country | 0 | 0 | PASS |
| T03b: Orphan product | 0 | 0 | PASS |
| T03c: Orphan balance | 0 | 0 | PASS |
| T03d: Orphan unit | 0 | 0 | PASS |
| T04: Grain unique | 20,709,414 | 20,709,414 | PASS |
| T05: No negative PPRD | 0 | 0 | PASS |
| T06a: Year min | 1990 | 1990 | PASS |
| T06b: Year max | 2024 | 2024 | PASS |
| T06c: Year count | 35 | 35 | PASS |
| T07a: Dim_Country | 40 | 40 | PASS |
| T07b: Dim_Product | >65 | 72 | PASS |
| T07c: Dim_Balance | >130 | 142 | PASS |
| T07d: Dim_Unit | 3 | 3 | PASS |
| T07e: Dim_Year | 35 | 35 | PASS |
| T07f: Dim_ObsStatus | 2 | 2 | PASS |
| T08: Cross-unit consistency | 0 inconsistent | 0 | PASS |
| T09: Germany renewables 2024 | ~3.1M TJ | 3,100,935 | PASS |
| T10: No NULL obs_value | 0 | 0 | PASS |

## Summary

- **Total tests:** 24
- **Passed:** 24
- **Failed:** 0
- **Warnings:** 0
- **Verdict:** ALL TESTS PASSED

## Cumulative Quality Rules

| Week | Tests Added | Running Total |
|------|------------|---------------|
| 1 | 9 structural checks | 9 |
| 2 | 12 automated gates | 21 |
| 5 | 24 star schema tests | 45 |

Every rule traces to a field in `contracts/energy_balance_v0.4.yaml`.
