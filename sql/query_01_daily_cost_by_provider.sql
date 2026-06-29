SELECT
    date_trunc('day', "ChargePeriodStart")::date AS charge_day,
    "ServiceProviderName",
    "BillingCurrency",
    round(sum("EffectiveCost"), 2) AS effective_cost
FROM focus.cost_usage
GROUP BY 1, 2, 3
ORDER BY charge_day, effective_cost DESC;
