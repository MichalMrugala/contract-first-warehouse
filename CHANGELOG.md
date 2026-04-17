# Changelog

All notable changes to Contract First are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] — 2026-04-13

### Released
- Full v1.0.0 release. Eight weekends of build-in-public completed.

### Added
- Complete EU AI Act Article 10 mapping in `docs/article-10-mapping.md`
- All 6 dimension tables and fact table (20.7M rows)
- 24 automated quality tests (all passing)
- 9 DAX measures across 7 Power BI pages
- Custom Power BI theme with teal #00827A palette
- YAML data contract v0.4 with Article 10 + GDPR Art 30 + lineage
- LICENSE file (MIT for code, CC BY 4.0 reference for Eurostat data)
- CITATION.cff for formal citation

### Changed
- README rewritten to reflect full 8-week completion
- Hero image renamed: `IMG_0357.png` → `architecture-sketch.png`

## [0.4.0] — 2026-04-06 (Week 7)

### Added
- YAML data contract v0.4
- GDPR Article 30 record-of-processing fields
- Data lineage documentation
- `x_ai_act_article_10` extension fields

## [0.3.0] — 2026-03-30 (Week 4)

### Added
- Power BI connection via Parquet export (ZSTD compression)
- 9 DAX measures: 5 core + 4 dynamic KPI
- 5 dashboard pages (later expanded to 7 in Week 6)
- Custom theme: `eu_energy_architecture.json`
- Bookmark navigation across 5 historical states

### Changed
- Auto Date/Time disabled (saves ~76% memory)
- Single-direction relationships enforced

## [0.2.0] — 2026-03-23 (Week 3)

### Added
- Star schema: 6 dimension tables + Fact_EnergyBalance (20.7M rows)
- 3-level energy product hierarchy (49 mapped, 23 "Other")
- 35-year time dimension with decade grouping
- Surrogate keys with zero orphan keys verified

## [0.1.0] — 2026-03-16 (Week 2)

### Added
- 12 automated quality gates (executes in 2s on 39.5M rows)
- 3-tier staging: clean (21.3M) + missing (18.2M) + rejected (0)
- Completeness analysis showing structural missing pattern
- Quality report (`docs/quality-report-week2.md`)

## [0.0.1] — 2026-03-09 (Week 1)

### Added
- Initial repository structure
- Data contract v0.1 (9 rules)
- 17 SQL exploration queries
- Manual quality checks (100% structural pass)
- 3 staging views
- Quality report (`docs/quality-report-week1.md`)
- README with project framing
