SELECT
    "Tags" ->> 'owner' AS owner,
    "ServiceCategory",
    "ServiceName",
    round(sum("EffectiveCost"), 2) AS effective_cost
FROM focus.cost_usage
GROUP BY 1, 2, 3
ORDER BY effective_cost DESC;
