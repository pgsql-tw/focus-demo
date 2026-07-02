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

## CFO Biases To Keep Explicit

- Favor predictability over pure cost minimization.
- Treat unowned spend as a governance risk even when the amount is not large.
- Treat volatility as a finance problem because it weakens forecast credibility.
- Treat concentration as a resilience and negotiation risk, not only a technical architecture issue.
- Treat discounts and commitments as portfolio instruments; undercoverage and overcommitment are both risks.

## Demo004 Lessons To Carry Forward

The first CFRS implementation validated that FOCUS data can support project-level CFO scoring, but it also showed that calibration matters. In the verified run, `BudgetRunRateRisk` dominated Critical and High results. That is useful for a CFO escalation demo, but future demos should test whether weights and thresholds still behave well when volatility, concentration, or commitment leakage are intentionally stronger.
