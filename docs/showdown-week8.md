# Contract First — Weekend 8: The Showdown

## SQL-First vs DAX-First — A Quantified Comparison

### The Question

If you have 39.5 million rows of energy data and need a 7-page Power BI dashboard, which approach produces better results?

**SQL-First:** Build a star schema in SQL. Clean data before it reaches Power BI. Let the model do the heavy lifting. Write minimal DAX.

**DAX-First:** Load raw data directly into Power BI. Build everything in DAX — calculations, filtering, hierarchies, data quality.

### The Numbers

| Metric | SQL-First (actual) | DAX-First (estimated) |
|--------|-------------------|----------------------|
| DAX measures | 9 | 50+ |
| Calculated columns | 0 | 6+ |
| Calculated tables | 0 | 2+ |
| Model relationships | 6 (star) | 0 (flat) |
| SQL files | 15 | 0 |
| Quality rules | 22+ | 0 |
| Governance docs | YAML + 4 reports | none |
| Data contract | v0.4 with Article 10 | none |
| Fact table rows | 20.7M (clean) | 39.5M (raw, with NULLs) |
| Dimensions | 6 tables | embedded in measures |
| Refresh time | <5 sec (Parquet) | 30+ sec (CSV) |
| Debug time | minutes (SQL) | hours (DAX) |
| Reproducible | yes (git + SQL) | no (PBIX binary) |

### What SQL-First Eliminated

1. **~40 DAX measures** that would handle filtering, hierarchies, and cross-unit logic
2. **6+ calculated columns** for product hierarchies and country regions
3. **18.2 million NULL rows** that would slow every calculation
4. **The double-counting bug** — caught by a quality rule, not visual inspection
5. **The aggregation trap** — "Total" category excluded before Power BI sees it

### What DAX-First Would Require

Without the star schema, the dashboard would need:
- `CALCULATE` with hardcoded country filters (10+ measures per country KPI)
- `SWITCH` or `IF` for product hierarchies (no dimension to slice by)
- Manual date table (no Dim_Year with decades and flags)
- Duplicate measures per page (no shared model)
- `REMOVEFILTERS` patterns to work around flat-table ambiguity
- Total estimate: **50-60 DAX measures** for the same 7 pages

### The Verdict

SQL-First is not about preferring SQL over DAX. It's about solving problems in the layer where they're cheapest to solve.

- **Data quality** is cheapest in SQL (automated, testable, version-controlled)
- **Data modeling** is cheapest in the database (star schema, relationships)
- **Visual calculations** are cheapest in DAX (aggregations, dynamic measures)

The 9 remaining DAX measures are the ones that SHOULD be in DAX — they depend on user interaction (slicers, filters, drill-through).

**SQL First. Model Second. DAX Last.**


