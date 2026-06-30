SELECT
    "ServiceProviderName",
    "ServiceCategory",
    "ServiceName",
    "ConsumedUnit",
    round(sum("ConsumedQuantity"), 6) AS consumed_quantity,
    round(sum("EffectiveCost"), 2) AS effective_cost
FROM focus.cost_usage
WHERE "ConsumedQuantity" IS NOT NULL
GROUP BY 1, 2, 3, 4
ORDER BY consumed_quantity DESC
LIMIT 10;
