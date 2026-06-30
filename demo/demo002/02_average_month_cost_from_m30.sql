WITH latest_month AS (
    SELECT date_trunc('month', max(charge_day))::date AS month_start
    FROM business.mv_daily_business_cost_moving_average
)
SELECT
    ma.business_name,
    ma.billing_currency,
    lm.month_start,
    (lm.month_start + interval '1 month - 1 day')::date AS month_end,
    round(avg(ma.m30_effective_cost), 2) AS average_m30_daily_cost,
    round(avg(ma.m30_effective_cost) * 30, 2) AS average_month_cost_from_m30
FROM business.mv_daily_business_cost_moving_average ma
CROSS JOIN latest_month lm
WHERE ma.charge_day >= lm.month_start
    AND ma.charge_day < lm.month_start + interval '1 month'
GROUP BY 1, 2, 3, 4
ORDER BY average_month_cost_from_m30 DESC;
