WITH usage_by_business AS (
    SELECT
        COALESCE(
            p.business_unit,
            cu."Tags" ->> 'cost_center',
            cu."Tags" ->> 'owner',
            cu."SubAccountName",
            'Unmapped'
        ) AS business_name,
        cu."ConsumedUnit",
        cu."ConsumedQuantity" * COALESCE(pca.allocation_weight, 1.000000) AS allocated_consumed_quantity,
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
    WHERE cu."ConsumedQuantity" IS NOT NULL
)
SELECT
    business_name,
    "ConsumedUnit",
    round(sum(allocated_consumed_quantity), 6) AS consumed_quantity,
    round(sum(allocated_effective_cost), 2) AS effective_cost
FROM usage_by_business
GROUP BY 1, 2
ORDER BY consumed_quantity DESC
LIMIT 10;
