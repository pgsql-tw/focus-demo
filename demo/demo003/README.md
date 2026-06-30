# demo003：年度預算超支機率

本 demo 示範三個常見 FinOps 預測問題：

1. 建立一個和 Excel `NORM.DIST` function 類似的 PostgreSQL function，用來計算常態分布累積機率。
2. 利用 demo002 的 M30 平均數與標準差，套入機率 function，計算 30 天後超過年度預算的機率。
3. 用同樣年度預算，計算 90 天後與 360 天後超過年度預算的機率。

本範例使用年度預算 `493900.00 USD`。這個值是依五年每日範例資料試算後選定，讓 360 天期最高超預算機率仍低於 10%。

## 查詢檔案

### 01_create_normdist_function.sql

建立 `business.normdist`，行為比照 Excel `NORM.DIST(x, mean, standard_dev, cumulative)`：`cumulative = true` 時回傳累積機率，`false` 時回傳機率密度。

```sql
CREATE OR REPLACE FUNCTION business.normdist(
    x double precision,
    mean double precision,
    standard_dev double precision,
    cumulative boolean DEFAULT true
)
RETURNS double precision
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
AS $function$
WITH normalized AS (
    SELECT
        (x - mean) / NULLIF(standard_dev, 0.0) AS z,
        standard_dev AS standard_dev
),
normal_terms AS (
    SELECT
        z,
        standard_dev,
        abs(z) AS abs_z,
        1.0 / (1.0 + 0.2316419 * abs(z)) AS t,
        CASE
            WHEN abs(z) > 37.0 THEN 0.0
            ELSE exp(-0.5 * abs(z) * abs(z)) / sqrt(2.0 * pi())
        END AS standard_density
    FROM normalized
    WHERE standard_dev > 0.0
),
distribution AS (
    SELECT
        standard_density / standard_dev AS probability_density,
        CASE
            WHEN z > 37.0 THEN 1.0
            WHEN z < -37.0 THEN 0.0
            WHEN z >= 0.0 THEN
                1.0 - (
                    standard_density
                    * (
                        0.319381530 * t
                        - 0.356563782 * t ^ 2
                        + 1.781477937 * t ^ 3
                        - 1.821255978 * t ^ 4
                        + 1.330274429 * t ^ 5
                    )
                )
            ELSE
                standard_density
                * (
                    0.319381530 * t
                    - 0.356563782 * t ^ 2
                    + 1.781477937 * t ^ 3
                    - 1.821255978 * t ^ 4
                    + 1.330274429 * t ^ 5
                )
        END AS cumulative_probability
    FROM normal_terms
)
SELECT
    CASE
        WHEN cumulative THEN cumulative_probability
        ELSE probability_density
    END
FROM distribution;
$function$;

COMMENT ON FUNCTION business.normdist(double precision, double precision, double precision, boolean) IS
    '模擬 Excel NORM.DIST 函數：輸入 x、平均數、標準差與 cumulative 旗標，回傳常態分布的累積機率或機率密度。';
```

範例結果：

| 動作 | 結果 |
|---|---|
| 建立 `business.normdist` function | completed |
| 加入 function comment | completed |

### 02_annual_budget_probability_after_30_days.sql

使用 demo002 materialized view 中近一個月的 M30 平均數與標準差，估算 30 天後超過年度預算的機率。

```sql
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
```

範例結果：

| business_name | billing_currency | horizon_days | annual_budget | observed_days | average_m30_daily_cost | stddev_m30_daily_cost | expected_cost_after_30_days | stddev_cost_after_30_days | probability_over_budget_percent |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| product | USD | 30 | 493900.00 | 31 | 1371.11 | 9.95 | 41133.43 | 54.51 | 0.0000 |
| finance | USD | 30 | 493900.00 | 31 | 1222.22 | 16.57 | 36666.57 | 90.74 | 0.0000 |
| research | USD | 30 | 493900.00 | 31 | 959.46 | 227.78 | 28783.94 | 1247.62 | 0.0000 |
| finops | USD | 30 | 493900.00 | 31 | 603.35 | 0.89 | 18100.47 | 4.88 | 0.0000 |

### 03_annual_budget_probability_after_90_360_days.sql

使用同一個年度預算 `493900.00 USD`，估算 90 天後與 360 天後超過年度預算的機率。

```sql
WITH parameters AS (
    SELECT
        493900.00::numeric AS annual_budget,
        horizon_days
    FROM (VALUES
        (90),
        (360)
    ) AS horizons(horizon_days)
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
    round((s.average_m30_daily_cost * p.horizon_days)::numeric, 2) AS expected_cost_after_horizon,
    round((s.stddev_m30_daily_cost * sqrt(p.horizon_days))::numeric, 2) AS stddev_cost_after_horizon,
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
ORDER BY p.horizon_days, probability_over_budget_percent DESC, expected_cost_after_horizon DESC;
```

範例結果：

| business_name | billing_currency | horizon_days | annual_budget | observed_days | average_m30_daily_cost | stddev_m30_daily_cost | expected_cost_after_horizon | stddev_cost_after_horizon | probability_over_budget_percent |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| product | USD | 90 | 493900.00 | 31 | 1371.11 | 9.95 | 123400.28 | 94.42 | 0.0000 |
| finance | USD | 90 | 493900.00 | 31 | 1222.22 | 16.57 | 109999.71 | 157.17 | 0.0000 |
| research | USD | 90 | 493900.00 | 31 | 959.46 | 227.78 | 86351.82 | 2160.93 | 0.0000 |
| finops | USD | 90 | 493900.00 | 31 | 603.35 | 0.89 | 54301.41 | 8.45 | 0.0000 |
| product | USD | 360 | 493900.00 | 31 | 1371.11 | 9.95 | 493601.14 | 188.84 | 5.6753 |
| finance | USD | 360 | 493900.00 | 31 | 1222.22 | 16.57 | 439998.82 | 314.34 | 0.0000 |
| research | USD | 360 | 493900.00 | 31 | 959.46 | 227.78 | 345407.28 | 4321.87 | 0.0000 |
| finops | USD | 360 | 493900.00 | 31 | 603.35 | 0.89 | 217205.63 | 16.90 | 0.0000 |
