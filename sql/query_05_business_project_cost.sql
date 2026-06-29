SELECT
    p.project_id,
    p.project_name,
    p.business_unit,
    count(DISTINCT a.service_provider_name) AS cloud_count,
    string_agg(DISTINCT a.service_provider_name, ', ' ORDER BY a.service_provider_name) AS clouds,
    count(DISTINCT a.cloud_account_key) AS cloud_account_count,
    round(sum(cu."EffectiveCost" * pca.allocation_weight), 2) AS allocated_effective_cost
FROM business.company_projects p
JOIN business.project_cloud_accounts pca
    ON pca.project_id = p.project_id
JOIN business.cloud_accounts a
    ON a.cloud_account_key = pca.cloud_account_key
JOIN focus.cost_usage cu
    ON cu."ServiceProviderName" = a.service_provider_name
    AND cu."BillingAccountId" = a.billing_account_id
    AND cu."SubAccountId" = a.sub_account_id
GROUP BY 1, 2, 3
ORDER BY allocated_effective_cost DESC;
