# Quality Report — Week 3

## Weekend 3: Star Schema
## Date: March 2026
## Contract: contracts/energy_balance_raw.yaml v0.3

---

## What Was Built

1. **Dim_Country** (`sql/model/07_dim_country.sql`) — 40 individual countries with names, regions, observation counts. EU27_2020 aggregate excluded.
2. **Dim_EnergyProduct** (`sql/model/08_dim_energy_product.sql`) — 72 energy products with 3-level hierarchy reconstructed manually from Eurostat SIEC codes.
3. **Dim_BalanceItem** (`sql/model/09_dim_balance_item.sql`) — 142 balance item codes grouped into 5 categories (Supply, Transformation, Energy sector, Consumption, Other).
4. **Dim_Unit** (`sql/model/10_dim_unit.sql`) — 3 units (TJ, KTOE, GWH) with conversion factors.
5. **Dim_Year** (`sql/model/11_dim_year.sql`) — 35 years (1990–2024) with decade grouping and boolean filters.
6. **Dim_ObsStatus** (`sql/model/12_dim_obs_status.sql`) — 2 statuses (measured/missing) for audit trail.
7. **Fact_EnergyBalance** (`sql/model/13_fact_energy_balance.sql`) — 20,709,414 rows. Grain: one measured observation per country/product/balance item/unit/year.

---

## Schema Diagram

```
┌──────────────────┐
│   Dim_Country    │──┐
│   (40 rows)      │  │
└──────────────────┘  │
┌──────────────────┐  │  ┌──────────────────────────┐
│Dim_EnergyProduct │──┤  │  Fact_EnergyBalance      │
│   (72 rows)      │  │  │  (20,709,414 rows)       │
└──────────────────┘  │  │                          │
┌──────────────────┐  ├──│  country_key (FK)        │
│   Dim_Unit       │──┤  │  product_key (FK)        │
│   (3 rows)       │  │  │  balance_key (FK)        │
└──────────────────┘  │  │  unit_key (FK)           │
┌──────────────────┐  │  │  year_key (FK)           │
│   Dim_Year       │──┤  │  obs_status_key (FK)     │
│   (35 rows)      │  │  │  obs_value (DOUBLE)      │
└──────────────────┘  │  └──────────────────────────┘
┌──────────────────┐  │
│Dim_BalanceItem   │──┤
│  (142 rows)      │  │
└──────────────────┘  │
┌──────────────────┐  │
│ Dim_ObsStatus    │──┘
│   (2 rows)       │
└──────────────────┘
```

---

## Dimension Tables

| Dimension | Rows | Key Attributes |
|-----------|------|----------------|
| Dim_Country | 40 | geo_code, country_name, region (4 regions: Western/Eastern/Northern/Southern Europe) |
| Dim_EnergyProduct | 72 | product_code, product_name, level1_category (10 categories), level2_group, level3_detail |
| Dim_BalanceItem | 142 | balance_code, balance_name, balance_category (5 categories: Supply, Transformation, Energy sector, Consumption, Other) |
| Dim_Unit | 3 | unit_code, unit_name, conversion_to_tj |
| Dim_Year | 35 | year, decade, is_post_2000, is_post_2010, is_post_2020 |
| Dim_ObsStatus | 2 | status_code (measured/missing), status_description, is_measured |

---

## Fact Table

| Metric | Value |
|--------|-------|
| Table name | Fact_EnergyBalance |
| Total rows | 20,709,414 |
| Grain | One measured observation per country + product + balance item + unit + year |
| Measure | obs_value (DOUBLE) — energy value in specified unit |
| NULL obs_values | 0 (verified) |
| Grain uniqueness | Verified — 20,709,414 total = 20,709,414 unique keys |
| Orphan foreign keys | 0 across all 5 dimensions (verified) |
| Build time | ~16 seconds |

---

## Architectural Decisions

### Decision 1: Exclude geographic aggregates

EU27_2020 excluded from Dim_Country. Fact table contains only 40 individual countries. If users need EU totals, they SUM individual countries — more accurate than pre-aggregated Eurostat values. Prevents accidental double-counting.

### Decision 2: Missing rows excluded from fact table

18.2M rows with NULL OBS_VALUE (flag 'm') are not in the fact table. Every row in Fact_EnergyBalance has a real numeric value. Missing patterns documented in stg_energy_missing (Week 2).

### Decision 3: Energy product hierarchy — 3 levels, pragmatic scope

72 products mapped to 3-level hierarchy. 49 products mapped accurately to 10 Level 1 categories (Oil and petroleum, Renewables, Solid fossil fuels, Natural gas, Nuclear, Electricity, Heat, Waste, Total, Other). 23 products classified as "Other" — codes not in initial Eurostat SIEC reference. To be refined in future weekends.

### Decision 4: Unit as dimension, all 3 units kept

TJ, KTOE, GWH all in fact table. Dim_Unit has 3 rows with conversion factors. Default dashboard filter: TJ. Users switch units via slicer — no DAX conversion needed. SQL First: solve it in the warehouse.

### Decision 5: OBS_FLAG not promoted to full dimension

Only two values in the dataset: NULL (validated) and 'm' (missing). All 'm' rows excluded from fact table. Every row in fact table has OBS_FLAG = NULL. Dim_ObsStatus exists for audit trail with 2 rows but has 1 effective value in fact table context.

---

## Energy Product Hierarchy

| Level 1 Category | Products Mapped | Example Codes |
|-------------------|----------------|---------------|
| Oil and petroleum | 23 | O4000XBIO, O4630, O4680 |
| Renewables | 13 | RA000, RA110, RA130, RA200 |
| Total | 3 | TOTAL, FE, BIOE |
| Solid fossil fuels | 3 | C0000X0350-0370, C0350-0370, P1000 |
| Waste | 3 | W6100, W6210, W6220 |
| Nuclear | 2 | N9000, N900H |
| Electricity | 1 | E7000 |
| Heat | 1 | H8000 |
| Natural gas | 1 | G3000 |
| Other (unmapped) | 23 | C0110, C0121, S2000, R5290 |

---

## Validation Queries

### Top 5 countries by primary production (TJ, all years)

| Country | Total Energy (TJ) |
|---------|-------------------|
| Norway | 1,059,228,378 |
| United Kingdom | 846,013,295 |
| Germany | 638,963,934 |
| France | 444,022,090 |
| Poland | 441,346,427 |

### Germany renewable energy production trend (TJ)

| Year | Renewable TJ | Note |
|------|-------------|------|
| 1990 | 285,924 | Baseline |
| 2000 | 492,875 | 1.7x vs 1990 |
| 2010 | 1,594,247 | 5.6x vs 1990 |
| 2020 | 2,777,385 | 9.7x vs 1990 |
| 2024 | 3,100,935 | 10.8x vs 1990 |

**10.8x growth in 35 years — from a 5-line SQL query joining fact table with 4 dimensions. No DAX.**

---

## Numbers for Content

| Metric | Value |
|--------|-------|
| Dimension tables built | 6 |
| Fact table rows | 20,709,414 |
| Fact table rows (single unit, TJ) | ~6,903,138 |
| Individual countries | 40 |
| Energy products | 72 |
| Product hierarchy levels | 3 |
| Products with clear hierarchy | 49 (68%) |
| Products classified as "Other" | 23 (32%) |
| Balance items | 142 |
| Balance categories | 5 |
| Units | 3 |
| Years | 35 |
| NULL obs_values in fact table | 0 |
| Orphan foreign keys | 0 |
| Grain uniqueness | Verified |
| Fact table build time | ~16 seconds |
| Germany renewables growth 1990-2024 | 10.8x |

---

## Week 4 Preview: Power BI Connection

The star schema is built. Next weekend: connect Power BI Desktop to DuckDB, build the data model, and test the philosophy — if SQL First and Model Second worked correctly, DAX should have almost nothing left to do. Target: fewer than 5 DAX measures for a 12-visual dashboard.

---

_Contract First. SQL First. Model Second. DAX Last._
