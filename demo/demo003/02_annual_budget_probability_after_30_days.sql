WITH parameters AS (
    SELECT
        493900.00::numeric AS annual_budget,
        30::integer AS horizon_days
),
latest_day AS (
    SELECT max(charge_day) AS max_charge_day
    FROM business.mv_daily_business_cost_moving_average
),
recent_m30_stats AS (
    SELECT
        ma.business_name,
        ma.billing_currency,
        avg(ma.m30_effective_cost) AS average_m30_daily_cost,
        stddev_samp(ma.m30_effective_cost) AS stddev_m30_daily_cost,
        count(*) AS observed_days
    FROM business.mv_daily_business_cost_moving_average ma
    CROSS JOIN latest_day ld
    WHERE ma.charge_day > ld.max_charge_day - interval '1 month'
    GROUP BY 1, 2
)
SELECT
    s.business_name,
    s.billing_currency,
    p.horizon_days,
    p.annual_budget,
    s.observed_days,
    round(s.average_m30_daily_cost, 2) AS average_m30_daily_cost,
    round(s.stddev_m30_daily_cost, 2) AS stddev_m30_daily_cost,
    round((s.average_m30_daily_cost * p.horizon_days)::numeric, 2) AS expected_cost_after_30_days,
    round((s.stddev_m30_daily_cost * sqrt(p.horizon_days))::numeric, 2) AS stddev_cost_after_30_days,
    round(
        (
            1.0 - business.normdist(
                p.annual_budget::double precision,
                (s.average_m30_daily_cost * p.horizon_days)::double precision,
                (s.stddev_m30_daily_cost * sqrt(p.horizon_days))::double precision,
                true
            )
        )::numeric * 100,
        4
    ) AS probability_over_budget_percent
FROM recent_m30_stats s
CROSS JOIN parameters p
ORDER BY probability_over_budget_percent DESC, expected_cost_after_30_days DESC;
