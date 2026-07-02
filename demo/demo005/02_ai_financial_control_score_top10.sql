SELECT
    project_id,
    project_name,
    business_unit,
    workflow_type,
    business_owner,
    score_as_of_date,
    monthly_token_budget,
    m30_tokens,
    m30_direct_ai_cost,
    m30_secondary_cloud_cost,
    ai_financial_control_score,
    control_level,
    primary_control_gap,
    recommended_cfo_action
FROM business.mv_ai_financial_control_score
ORDER BY ai_financial_control_score DESC, m30_tokens DESC
LIMIT 10;
