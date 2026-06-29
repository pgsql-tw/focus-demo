# FOCUS v1.4 Notes

Use FOCUS v1.4 as the target standard for this demo. Official FOCUS pages checked on 2026-06-29 indicated:

- FOCUS v1.4 was ratified on 2026-06-04.
- The FOCUS Column Library contained 107 columns for v1.4.
- The project goal is a complete FOCUS standard data example, so the canonical `focus.cost_usage` table should expose all 107 FOCUS v1.4 Cost and Usage columns.

Schema guidance:

- Keep standard FOCUS columns as quoted PascalCase PostgreSQL identifiers.
- Keep `focus.cost_usage` limited to the standard columns when demonstrating complete compliance.
- Use `numeric(20, 6)` for cost and quantity fields.
- Use `timestamptz` for billing and charge period boundaries.
- Use `jsonb` for `"Tags"` so PostgreSQL can index and query allocation labels.
- Prefix non-standard extension columns with `x_` only outside the canonical standard table or when the user explicitly asks for provider-specific extensions.
- Add Chinese PostgreSQL metadata comments for every table, index, and column in schema files. Use `COMMENT ON TABLE`, `COMMENT ON INDEX`, and `COMMENT ON COLUMN` so comments are visible from database metadata tools. Column comments should explain the data content and business meaning, not just restate the column name.

Validation guidance:

- Verify `information_schema.columns` reports 107 columns for `focus.cost_usage`.
- Verify table, index, and column comments are present in PostgreSQL metadata after applying `sql/01_schema.sql`.
- Run `sql/02_seed_data.sql` after schema changes to keep the readable demo viable.
- Run `sql/03_seed_daily_5_years.sql` when changes affect generated analytical data.
- Keep query examples on FOCUS v1.4 names such as `"ServiceProviderName"` and `"HostProviderName"`.

Useful demo query themes:

- cost by provider, service, and charge day
- allocation by tags such as owner, app, environment, and cost center
- unit economics using `EffectiveCost / ConsumedQuantity`
- data quality checks for required values, period validity, and currency format
