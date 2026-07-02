SELECT
    project_id,
    project_name,
    business_unit,
    billing_currency,
    score_as_of_date,
    monthly_budget,
    month_to_date_effective_cost,
    current_month_run_rate,
    cloud_financial_risk_score,
    risk_level,
    primary_risk_driver,
    recommended_cfo_action
FROM business.mv_project_financial_risk_score
ORDER BY cloud_financial_risk_score DESC, month_to_date_effective_cost DESC
LIMIT 10;
