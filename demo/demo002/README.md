# demo002：每日成本移動平均

本 demo 示範四個常見 FinOps 趨勢分析問題：

1. 建立 materialized view，記錄每一日的 moving average，包含 M30、M90、M360。
2. 查詢 M30 的平均數，換算為平均一個月的花費。
3. 查詢近一個月的 M30、M90、M360。
4. 查詢近一個月平均 M30 大於 M90 的業務。

## 查詢檔案

### 01_create_daily_business_cost_moving_average.sql

建立每日業務成本 materialized view，並保存 M30、M90、M360 三個移動平均欄位。

```sql
DROP MATERIALIZED VIEW IF EXISTS business.mv_daily_business_cost_moving_average;

CREATE MATERIALIZED VIEW business.mv_daily_business_cost_moving_average AS
WITH business_cost_rows AS (
    SELECT
        COALESCE(
            p.business_unit,
            cu."Tags" ->> 'cost_center',
            cu."Tags" ->> 'owner',
            cu."SubAccountName",
            'Unmapped'
        ) AS business_name,
        cu."BillingCurrency" AS billing_currency,
        date_trunc('day', cu."ChargePeriodStart")::date AS charge_day,
        cu."EffectiveCost" * COALESCE(pca.allocation_weight, 1.000000) AS allocated_effective_cost
    FROM focus.cost_usage cu
    LEFT JOIN business.cloud_accounts ca
        ON ca.service_provider_name = cu."ServiceProviderName"
        AND ca.billing_account_id = cu."BillingAccountId"
        AND ca.sub_account_id = cu."SubAccountId"
    LEFT JOIN business.project_cloud_accounts pca
        ON pca.cloud_account_key = ca.cloud_account_key
    LEFT JOIN business.company_projects p
        ON p.project_id = pca.project_id
),
daily_business_costs AS (
    SELECT
        business_name,
        billing_currency,
        charge_day,
        sum(allocated_effective_cost) AS daily_effective_cost
    FROM business_cost_rows
    GROUP BY 1, 2, 3
)
SELECT
    business_name,
    billing_currency,
    charge_day,
    round(daily_effective_cost, 6) AS daily_effective_cost,
    round(
        avg(daily_effective_cost) OVER (
            PARTITION BY business_name, billing_currency
            ORDER BY charge_day
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ),
        6
    ) AS m30_effective_cost,
    round(
        avg(daily_effective_cost) OVER (
            PARTITION BY business_name, billing_currency
            ORDER BY charge_day
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ),
        6
    ) AS m90_effective_cost,
    round(
        avg(daily_effective_cost) OVER (
            PARTITION BY business_name, billing_currency
            ORDER BY charge_day
            ROWS BETWEEN 359 PRECEDING AND CURRENT ROW
        ),
        6
    ) AS m360_effective_cost
FROM daily_business_costs
ORDER BY business_name, billing_currency, charge_day;

COMMENT ON MATERIALIZED VIEW business.mv_daily_business_cost_moving_average IS
    '依業務、幣別與日期彙總每日 EffectiveCost，並保存 30 日、90 日、360 日移動平均成本，供趨勢與異常升溫分析使用。';

COMMENT ON COLUMN business.mv_daily_business_cost_moving_average.business_name IS
    '業務名稱，優先使用 business.company_projects.business_unit；無對應時改用 Tags 中的 cost_center、owner 或子帳戶名稱。';

COMMENT ON COLUMN business.mv_daily_business_cost_moving_average.billing_currency IS
    '成本金額使用的帳單幣別，來自 FOCUS BillingCurrency。';

COMMENT ON COLUMN business.mv_daily_business_cost_moving_average.charge_day IS
    '用量與成本發生日期，由 FOCUS ChargePeriodStart 轉為日粒度。';

COMMENT ON COLUMN business.mv_daily_business_cost_moving_average.daily_effective_cost IS
    '該業務在當日分攤後的 EffectiveCost 總額。';

COMMENT ON COLUMN business.mv_daily_business_cost_moving_average.m30_effective_cost IS
    '截至該日含當日的 30 日每日 EffectiveCost 移動平均，用於近一個月成本基準。';

COMMENT ON COLUMN business.mv_daily_business_cost_moving_average.m90_effective_cost IS
    '截至該日含當日的 90 日每日 EffectiveCost 移動平均，用於季度趨勢基準。';

COMMENT ON COLUMN business.mv_daily_business_cost_moving_average.m360_effective_cost IS
    '截至該日含當日的 360 日每日 EffectiveCost 移動平均，用於長期年度趨勢基準。';

CREATE UNIQUE INDEX idx_mv_daily_business_cost_ma_key
    ON business.mv_daily_business_cost_moving_average (business_name, billing_currency, charge_day);

CREATE INDEX idx_mv_daily_business_cost_ma_day
    ON business.mv_daily_business_cost_moving_average (charge_day);

COMMENT ON INDEX business.idx_mv_daily_business_cost_ma_key IS
    '確保每個業務、幣別與日期只有一筆移動平均成本資料，並支援精準查找與重新整理後比對。';

COMMENT ON INDEX business.idx_mv_daily_business_cost_ma_day IS
    '支援依日期區間查詢最近一個月或其他時間窗的移動平均成本資料。';
```

範例結果：

| 動作 | 結果 |
|---|---:|
| 建立 materialized view | 7304 rows |
| 建立唯一索引 `idx_mv_daily_business_cost_ma_key` | completed |
| 建立日期索引 `idx_mv_daily_business_cost_ma_day` | completed |

### 02_average_month_cost_from_m30.sql

查詢最新月份的平均 M30 每日成本，並乘以 30 換算為平均一個月花費。

```sql
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
```

範例結果：

| business_name | billing_currency | month_start | month_end | average_m30_daily_cost | average_month_cost_from_m30 |
|---|---|---|---|---:|---:|
| product | USD | 2026-12-01 | 2026-12-31 | 1371.11 | 41133.43 |
| finance | USD | 2026-12-01 | 2026-12-31 | 1222.22 | 36666.57 |
| research | USD | 2026-12-01 | 2026-12-31 | 959.46 | 28783.94 |
| finops | USD | 2026-12-01 | 2026-12-31 | 603.35 | 18100.47 |

### 03_recent_month_moving_averages.sql

查詢近一個月各業務的每日成本，以及 M30、M90、M360 平均值。

```sql
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
```

範例結果：

| business_name | billing_currency | period_start | period_end | observed_days | average_daily_effective_cost | average_m30_daily_cost | average_m90_daily_cost | average_m360_daily_cost |
|---|---|---|---|---:|---:|---:|---:|---:|
| product | USD | 2026-12-01 | 2026-12-31 | 31 | 1380.27 | 1371.11 | 1370.25 | 1365.81 |
| finance | USD | 2026-12-01 | 2026-12-31 | 31 | 1218.38 | 1222.22 | 1228.36 | 1227.35 |
| research | USD | 2026-12-01 | 2026-12-31 | 31 | 1313.09 | 959.46 | 801.49 | 802.33 |
| finops | USD | 2026-12-01 | 2026-12-31 | 31 | 602.90 | 603.35 | 603.25 | 602.47 |

### 04_recent_month_m30_gt_m90_businesses.sql

查詢近一個月平均 M30 大於 M90 的業務，用來找出近期成本高於季度基準的業務。

```sql
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
```

範例結果：

| business_name | billing_currency | compared_days | average_m30_daily_cost | average_m90_daily_cost | daily_cost_gap | gap_percent |
|---|---|---:|---:|---:|---:|---:|
| research | USD | 31 | 959.46 | 801.49 | 157.98 | 19.71 |
| product | USD | 31 | 1371.11 | 1370.25 | 0.87 | 0.06 |
| finops | USD | 31 | 603.35 | 603.25 | 0.10 | 0.02 |
