WITH latest_day AS (
    SELECT max(charge_day) AS max_charge_day
    FROM business.mv_daily_business_cost_moving_average
)
SELECT
    ma.business_name,
    ma.billing_currency,
    (ld.max_charge_day - interval '1 month' + interval '1 day')::date AS period_start,
    ld.max_charge_day AS period_end,
    count(*) AS observed_days,
    round(avg(ma.daily_effective_cost), 2) AS average_daily_effective_cost,
    round(avg(ma.m30_effective_cost), 2) AS average_m30_daily_cost,
    round(avg(ma.m90_effective_cost), 2) AS average_m90_daily_cost,
    round(avg(ma.m360_effective_cost), 2) AS average_m360_daily_cost
FROM business.mv_daily_business_cost_moving_average ma
CROSS JOIN latest_day ld
WHERE ma.charge_day > ld.max_charge_day - interval '1 month'
GROUP BY 1, 2, 3, 4
ORDER BY average_m30_daily_cost DESC;
