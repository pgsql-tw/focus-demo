SELECT
    "ResourceName",
    "ServiceName",
    "ConsumedUnit",
    sum("ConsumedQuantity") AS consumed_quantity,
    round(sum("EffectiveCost"), 2) AS effective_cost,
    round(sum("EffectiveCost") / NULLIF(sum("ConsumedQuantity"), 0), 6) AS effective_cost_per_unit
FROM focus.cost_usage
WHERE "ConsumedQuantity" IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY effective_cost DESC;
