# Project Codex Instructions

## Changelog

- Update `CHANGELOG.md` in the same change whenever project behavior, schema, seed data, queries, tooling, documentation, or Codex project instructions change.
- Keep changelog entries dated, concise, and human-readable.
- Use Chinese for user-facing project notes unless the surrounding section is already in English.

## FOCUS PostgreSQL Demo

- Preserve `focus.cost_usage` as the canonical complete FOCUS v1.4 Cost and Usage table with 107 standard columns.
- Keep non-standard business mapping data outside `focus.cost_usage`; use the `business` schema for company project and cloud account mapping tables.
- Add Chinese PostgreSQL metadata comments for every table, index, and column introduced or changed. Column comments must describe data content and business meaning, not merely repeat the column name.
- Preserve FOCUS standard column names in SQL with quoted PascalCase identifiers, such as `"EffectiveCost"` and `"ChargePeriodStart"`.

## Validation

- Validate Python syntax with `python -m compileall scripts` after Python changes.
- When schema or seed files change, verify `focus.cost_usage` still has 107 columns and sample seed/query files still execute.
