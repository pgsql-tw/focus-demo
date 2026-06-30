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
