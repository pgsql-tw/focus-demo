# FOCUS v1.4 Notes

Use FOCUS v1.4 as the target standard for this demo. Official FOCUS pages checked on 2026-06-29 indicated:

- FOCUS v1.4 was ratified on 2026-06-04.
- The FOCUS Column Library contained 107 columns for v1.4.
- The demo should remain a readable subset unless the user asks for complete column coverage.

Schema guidance:

- Keep standard FOCUS columns as quoted PascalCase PostgreSQL identifiers.
- Use `numeric(20, 6)` for cost and quantity fields.
- Use `timestamptz` for billing and charge period boundaries.
- Use `jsonb` for `"Tags"` so PostgreSQL can index and query allocation labels.
- Prefix non-standard extension columns with `x_`, for example `"x_DemoEnvironment"`.

Useful demo query themes:

- cost by provider, service, and charge day
- allocation by tags such as owner, app, environment, and cost center
- unit economics using `EffectiveCost / ConsumedQuantity`
- data quality checks for required values, period validity, and currency format
