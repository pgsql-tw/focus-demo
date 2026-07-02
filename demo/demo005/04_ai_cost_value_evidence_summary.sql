SELECT
    business_unit,
    workflow_type,
    value_evidence_status,
    count(*) AS workflow_count,
    round(sum(m30_tokens), 0) AS m30_tokens,
    round(sum(m30_direct_ai_cost + m30_secondary_cloud_cost), 2) AS m30_ai_related_cost,
    round(sum(m30_estimated_business_value_usd), 2) AS m30_estimated_business_value_usd,
    round(avg(ai_financial_control_score), 2) AS average_control_score
FROM business.mv_ai_financial_control_score
GROUP BY 1, 2, 3
ORDER BY average_control_score DESC, m30_ai_related_cost DESC;
