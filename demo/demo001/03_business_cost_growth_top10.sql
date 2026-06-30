WITH business_cost_rows AS (
    SELECT
        COALESCE(
            p.business_unit,
            cu."Tags" ->> 'cost_center',
            cu."Tags" ->> 'owner',
            cu."SubAccountName",
            'Unmapped'
        ) AS business_name,
        cu."BillingCurrency",
        date_trunc('month', cu."ChargePeriodStart")::date AS charge_month,
        cu."EffectiveCost" * COALESCE(pca.allocation_weight, 1.000000) AS allocated_effective_cost
    FROM focus.cost_usage cu
    LEFT JOIN business.cloud_accounts ca
        ON ca.service_provider_name = cu."ServiceProviderName"
        AND ca.billing_account_id = cu."BillingAccountId"
        AND ca.sub_account_id = cu."SubAccountId"
    LEFT JOIN business.project_cloud_accounts pca
        ON pca.cloud_account_key = ca.cloud_account_key
    LEFT JOIN business.company_projects p
        ON p.project_id = pca.project_id
),
monthly_business_costs AS (
    SELECT
        business_name,
        "BillingCurrency",
        charge_month,
        sum(allocated_effective_cost) AS effective_cost
    FROM business_cost_rows
    GROUP BY 1, 2, 3
),
latest_month AS (
    SELECT max(charge_month) AS current_month
    FROM monthly_business_costs
),
period_costs AS (
    SELECT
        mbc.business_name,
        mbc."BillingCurrency",
        lm.current_month,
        lm.current_month - interval '1 month' AS previous_month,
        sum(mbc.effective_cost) FILTER (
            WHERE mbc.charge_month = lm.current_month
        ) AS current_month_cost,
        sum(mbc.effective_cost) FILTER (
            WHERE mbc.charge_month = (lm.current_month - interval '1 month')::date
        ) AS previous_month_cost
    FROM monthly_business_costs mbc
    CROSS JOIN latest_month lm
    WHERE mbc.charge_month IN (
        lm.current_month,
        (lm.current_month - interval '1 month')::date
    )
    GROUP BY 1, 2, 3, 4
)
SELECT
    business_name,
    "BillingCurrency",
    current_month,
    previous_month::date AS previous_month,
    round(current_month_cost, 2) AS current_month_cost,
    round(previous_month_cost, 2) AS previous_month_cost,
    round(current_month_cost - previous_month_cost, 2) AS cost_increase,
    round(
        ((current_month_cost - previous_month_cost) / NULLIF(previous_month_cost, 0)) * 100,
        2
    ) AS increase_rate_percent
FROM period_costs
WHERE current_month_cost > previous_month_cost
    AND previous_month_cost > 0
ORDER BY increase_rate_percent DESC, cost_increase DESC
LIMIT 10;
