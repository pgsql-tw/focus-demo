---
name: focus-postgresql-demo
description: Maintain this repository's complete FOCUS PostgreSQL standard data example. Use when changing the PostgreSQL schema, sample FOCUS cost and usage data, Python local tooling, requirements.txt, sample FinOps queries, validation checks, or project documentation for this FOCUS v1.4 showcase.
---

# FOCUS PostgreSQL Standard Example

## Workflow

1. Keep local executable tooling in Python.
2. Update `requirements.txt` whenever Python imports need a third-party package.
3. Update `.gitignore` whenever new local-only files, generated outputs, caches, credentials, or tool artifacts are introduced.
4. Keep PostgreSQL connection details out of git; edit `config/postgres.example.ini` for the template and rely on ignored `config/postgres.ini` for local credentials.
5. Preserve FOCUS standard column names in SQL with quoted PascalCase identifiers, such as `"EffectiveCost"` and `"ChargePeriodStart"`.
6. Treat complete FOCUS v1.4 Cost and Usage column coverage as the project goal. Keep `focus.cost_usage` aligned to the full 107 standard columns unless the user explicitly asks for a separate reduced teaching artifact.
7. Keep non-standard helper fields out of the canonical `focus.cost_usage` table. If extension fields are required, use an `x_` prefix and document why they are outside the standard.
8. Keep seed data readable while preserving the full standard schema. Populate representative columns for core FinOps demos and allow nullable standard columns to remain null when the example does not need them.
9. Add or update `sql/query_*.sql` files when introducing new FinOps examples.
10. Validate Python syntax with `python -m compileall scripts` after code changes.
11. When schema or seed files change, verify the local PostgreSQL table has 107 columns and that sample seed/query files still execute.

## Project Map

- `scripts/focus_demo.py`: Python CLI for config validation, schema creation, seed loading, and query execution.
- `config/postgres.example.ini`: PostgreSQL connection template.
- `sql/01_schema.sql`: Complete FOCUS v1.4 Cost and Usage PostgreSQL schema.
- `sql/02_seed_data.sql`: readable demo rows for multiple providers and services.
- `sql/03_seed_daily_5_years.sql`: generated five-year dataset for larger analytical demos.
- `sql/query_*.sql`: sample analytical queries.
- `docs/focus_overview.md`: short explainer for presentation context.

## References

Read `references/focus-v14-notes.md` when changing schema columns, seed data semantics, or documentation that describes the FOCUS standard.
