WITH latest_day AS (
    SELECT max(charge_day) AS max_charge_day
    FROM business.mv_daily_business_cost_moving_average
),
recent_month AS (
    SELECT
        ma.business_name,
        ma.billing_currency,
        avg(ma.m30_effective_cost) AS average_m30_daily_cost,
        avg(ma.m90_effective_cost) AS average_m90_daily_cost,
        count(*) AS compared_days
    FROM business.mv_daily_business_cost_moving_average ma
    CROSS JOIN latest_day ld
    WHERE ma.charge_day > ld.max_charge_day - interval '1 month'
    GROUP BY 1, 2
)
SELECT
    business_name,
    billing_currency,
    compared_days,
    round(average_m30_daily_cost, 2) AS average_m30_daily_cost,
    round(average_m90_daily_cost, 2) AS average_m90_daily_cost,
    round(average_m30_daily_cost - average_m90_daily_cost, 2) AS daily_cost_gap,
    round(
        ((average_m30_daily_cost - average_m90_daily_cost) / NULLIF(average_m90_daily_cost, 0)) * 100,
        2
    ) AS gap_percent
FROM recent_month
WHERE average_m30_daily_cost > average_m90_daily_cost
ORDER BY gap_percent DESC, daily_cost_gap DESC;
