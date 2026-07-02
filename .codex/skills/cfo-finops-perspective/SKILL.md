---
name: cfo-finops-perspective
description: Apply a CFO perspective to this FOCUS PostgreSQL FinOps project. Use when designing, reviewing, or extending FinOps demos, financial risk metrics, governance narratives, budget/forecast queries, CFO-facing Markdown documentation under docs/, or when reflecting on demo results and feeding those lessons back into the project skill and documentation.
---

# CFO FinOps Perspective

## Purpose

Use this skill to think like a CFO who values FinOps maturity: cost visibility matters, but the higher goal is financial predictability, accountable ownership, and earlier governance action.

## Workflow

1. Read the current CFO viewpoint:
   - `docs/cfo_finops_operating_view.md`
   - `docs/cfo_financial_risk_metric.md`
2. Inspect the relevant demo implementation before changing it:
   - Start with `demo/demo004/` for Cloud Financial Risk Score work.
   - Read SQL and README files directly; do not infer behavior only from docs.
3. If demo results already exist, read local logs under `outputs/<demo-name>/`.
   - Treat outputs as feedback evidence, not just proof that SQL ran.
   - Ask what the result teaches about the CFO metric, thresholds, weights, governance action, or data model.
4. When adding or changing CFO/FinOps ideas, update a Markdown note under `docs/`.
   - Use Chinese for user-facing project notes.
   - Preserve explicit links between CFO judgment, FOCUS fields, SQL implementation, and observed demo results.
5. When changing demo SQL or schema objects, also use the `focus-postgresql-demo` project skill.
   - Keep quoted PascalCase FOCUS column names.
   - Add Chinese PostgreSQL comments for new or changed schema objects.
   - Verify `focus.cost_usage` remains the canonical 107-column table.
6. Update `CHANGELOG.md` for any skill, docs, demo, query, schema, or validation change.

## CFO Review Lens

Prefer questions that change management action:

- Which business unit, project, or cloud account is making forecast confidence worse?
- Is the variance caused by growth, volatility, discount leakage, concentration, or missing ownership?
- Does the metric explain its own score well enough for a CFO, CTO, and product owner to agree on the next action?
- Are thresholds calibrated from evidence, or are they arbitrary policy choices?
- Does the demo separate financial assumptions from measured cost facts?

## Expected Output Style

When using this skill, produce artifacts that are decision-ready:

- State the CFO question first.
- Tie each risk signal to FOCUS data and business ownership.
- Put CFO narrative and observed results before implementation details in demo README files, so finance readers can validate the management answer before reading SQL.
- Include demo evidence when available, such as row counts, top risk projects, and risk-driver distribution.
- Keep demo README SQL readable: split long SQL into labeled subsections by purpose, and state when snippets are reading fragments rather than standalone execution units.
- Add Mermaid charts when demo results contain useful rankings, comparisons, distributions, or trend-like summaries; charts should clarify CFO decisions, not decorate the page.
- Avoid local machine paths, fixed PostgreSQL binary paths, or local-only `psql` command examples in demo README files unless the user explicitly asks for local setup notes.
- Record reflection in docs: what worked, what distorted the view, and what should be improved in the next demo.

## Reference

Read `references/operating-loop.md` when the task asks for strategy, reflection, governance language, or evolution of the CFO/FinOps point of view.
