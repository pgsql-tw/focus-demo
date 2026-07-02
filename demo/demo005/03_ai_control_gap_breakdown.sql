SELECT
    control_level,
    primary_control_gap,
    count(*) AS workflow_count,
    round(avg(ai_financial_control_score), 2) AS average_control_score,
    round(sum(m30_tokens), 0) AS m30_tokens,
    round(sum(m30_direct_ai_cost), 2) AS m30_direct_ai_cost,
    round(sum(m30_secondary_cloud_cost), 2) AS m30_secondary_cloud_cost,
    count(*) FILTER (WHERE business_owner IS NULL) AS unowned_workflows,
    count(*) FILTER (WHERE guardrail_status <> 'Enforced') AS weak_guardrail_workflows
FROM business.mv_ai_financial_control_score
GROUP BY 1, 2
ORDER BY
    CASE control_level
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Watch' THEN 3
        ELSE 4
    END,
    average_control_score DESC;
