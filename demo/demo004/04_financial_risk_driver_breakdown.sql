SELECT
    risk_level,
    primary_risk_driver,
    count(*) AS project_count,
    round(avg(cloud_financial_risk_score), 2) AS average_risk_score,
    round(sum(month_to_date_effective_cost), 2) AS month_to_date_effective_cost,
    round(sum(current_month_run_rate), 2) AS current_month_run_rate,
    round(sum(monthly_budget), 2) AS monthly_budget
FROM business.mv_project_financial_risk_score
GROUP BY 1, 2
ORDER BY
    CASE risk_level
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Watch' THEN 3
        ELSE 4
    END,
    average_risk_score DESC;
