SELECT
    count(*) AS row_count,
    count(*) FILTER (WHERE "BillingCurrency" !~ '^[A-Z]{3}$') AS invalid_currency_rows,
    count(*) FILTER (WHERE "ChargePeriodEnd" <= "ChargePeriodStart") AS invalid_charge_period_rows,
    count(*) FILTER (WHERE "EffectiveCost" IS NULL) AS missing_effective_cost_rows,
    count(*) FILTER (WHERE "ProviderName" IS NULL OR "ServiceName" IS NULL) AS missing_provider_or_service_rows
FROM focus.cost_usage;
