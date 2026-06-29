---
name: focus-postgresql-demo
description: Maintain this repository's FOCUS PostgreSQL demonstration project. Use when changing the PostgreSQL schema, sample FOCUS cost and usage data, Python local tooling, requirements.txt, sample FinOps queries, or project documentation for this FOCUS showcase.
---

# FOCUS PostgreSQL Demo

## Workflow

1. Keep local executable tooling in Python.
2. Update `requirements.txt` whenever Python imports need a third-party package.
3. Update `.gitignore` whenever new local-only files, generated outputs, caches, credentials, or tool artifacts are introduced.
4. Keep PostgreSQL connection details out of git; edit `config/postgres.example.ini` for the template and rely on ignored `config/postgres.ini` for local credentials.
5. Preserve FOCUS standard column names in SQL with quoted PascalCase identifiers, such as `"EffectiveCost"` and `"ChargePeriodStart"`.
6. Prefer small, explainable FOCUS Cost and Usage subsets for demos instead of adding every standard column by default.
7. Add or update `sql/query_*.sql` files when introducing new FinOps examples.
8. Validate Python syntax with `python -m compileall scripts` after code changes.

## Project Map

- `scripts/focus_demo.py`: Python CLI for config validation, schema creation, seed loading, and query execution.
- `config/postgres.example.ini`: PostgreSQL connection template.
- `sql/01_schema.sql`: FOCUS-shaped PostgreSQL schema.
- `sql/02_seed_data.sql`: demo rows for multiple providers and services.
- `sql/query_*.sql`: sample analytical queries.
- `docs/focus_overview.md`: short explainer for presentation context.

## References

Read `references/focus-v14-notes.md` when changing schema columns, seed data semantics, or documentation that describes the FOCUS standard.
