# Contributing to Contract First

Thank you for considering a contribution.

This is a build-in-public solo project, but contributions are welcome — particularly:

- **Article 10 mapping corrections** if you find a YAML field that does not actually satisfy the sub-clause it claims to map to
- **Quality test additions** for edge cases in Eurostat data not currently covered
- **Translations** of `docs/article-10-mapping.md` into other EU languages (German, French, Spanish, Polish, Italian)
- **Implementation experience reports** in other regulated sectors (healthcare, financial services, recruitment)

## What I am NOT looking for

- Generic dependency updates (handled automatically)
- Style refactors of working SQL
- Conversion to other dialects (BigQuery, Snowflake) — DuckDB is a deliberate choice
- New dimensions or fact tables — the schema is final at v1.0.0

## How to contribute

1. Open an issue first to discuss the change
2. Fork the repository
3. Create a branch named for the change: `article-10-mapping-fix-2d`
4. Make your change with a clear commit message
5. Open a pull request referencing the issue

## Code of conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). The short version: be useful, be specific, do not be cruel.

## Author response time

Solo project. Author response within 7 days for issues, 14 days for pull requests. If a contribution is time-sensitive (e.g., regulatory update), tag the issue with `urgent` and the response window drops to 24 hours.

## Recognition

All contributors will be acknowledged in the relevant release notes and in `docs/contributors.md` (created upon first external contribution).
