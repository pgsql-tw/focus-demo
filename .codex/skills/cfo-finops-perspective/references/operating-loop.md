# CFO FinOps Operating Loop

Use this reference when updating CFO-facing docs or interpreting demo evidence.

## Operating Loop

1. Define the CFO decision: budget intervention, forecast adjustment, commitment purchase, ownership escalation, or normal monitoring.
2. Map the decision to measurable FOCUS data: time, cost, provider, service, account, resource, tags, discount fields, and business mapping.
3. Implement the smallest useful SQL demo that produces an ordered management view.
4. Run the demo against PostgreSQL and preserve result logs under ignored `outputs/`.
5. Reflect on the result:
   - Did the top risks match the intended CFO story?
   - Did one submetric dominate too much?
   - Did generated assumptions create artificial risk?
   - Is the recommended action credible for finance and engineering?
6. Write the lesson back into `docs/` so the next demo starts from evidence, not memory.

## Demo README Style Principles

Use these rules when preparing or revising CFO-facing demo README files, especially `demo/demo004/`:

- Start with the CFO-facing answer. Recommended order: CFO narrative or question, actual observed results, result charts, output field meaning, then implementation process, formula, and SQL details.
- Do not turn the README into one long SQL wall. If SQL must be embedded, split it into small labeled sections by intent, such as object setup, source mapping, time-window filtering, metric calculation, scoring, output shaping, indexes, and metadata comments.
- Make the execution model clear. The `.sql` file can remain the runnable unit, while README snippets can be marked as reading fragments that explain the logic in smaller steps.
- Keep instructions portable. Avoid local filesystem paths, fixed PostgreSQL binary paths, and local-only `psql` command examples unless the user explicitly asks for setup or troubleshooting notes.
- Preserve the CFO narrative around the code. Each SQL section should answer why the metric matters for budget confidence, ownership, commitment coverage, volatility, concentration, or governance action.
- Results should include the actual observed output when available. Use compact tables for evidence and add Mermaid charts when a ranking, gap, mix, or distribution helps a CFO understand the decision.
- Charts must be management artifacts, not decoration. Prefer visuals such as Top N risk scores, run rate versus budget, risk-level distribution, or primary-driver distribution when the data supports them.
- Keep chart labels concise and tied to the question being answered. If a chart would repeat a nearby table without improving interpretation, skip it.

## CFO Biases To Keep Explicit

- Favor predictability over pure cost minimization.
- Treat unowned spend as a governance risk even when the amount is not large.
- Treat volatility as a finance problem because it weakens forecast credibility.
- Treat concentration as a resilience and negotiation risk, not only a technical architecture issue.
- Treat discounts and commitments as portfolio instruments; undercoverage and overcommitment are both risks.

## Demo004 Lessons To Carry Forward

The first CFRS implementation validated that FOCUS data can support project-level CFO scoring, but it also showed that calibration matters. In the verified run, `BudgetRunRateRisk` dominated Critical and High results. That is useful for a CFO escalation demo, but future demos should test whether weights and thresholds still behave well when volatility, concentration, or commitment leakage are intentionally stronger.
