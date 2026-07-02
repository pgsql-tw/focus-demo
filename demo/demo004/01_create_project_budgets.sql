DROP MATERIALIZED VIEW IF EXISTS business.mv_project_financial_risk_score;
DROP TABLE IF EXISTS business.project_budgets;

CREATE TABLE business.project_budgets (
    project_id text NOT NULL,
    project_name text NOT NULL,
    business_unit text NOT NULL,
    billing_currency char(3) NOT NULL,
    budget_period_start date NOT NULL,
    monthly_budget numeric(20, 6) NOT NULL,
    annual_budget numeric(20, 6) NOT NULL,
    budget_owner text NOT NULL DEFAULT 'CFO Office',
    budget_status text NOT NULL DEFAULT 'Active',
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (project_id, billing_currency, budget_period_start),
    CHECK (monthly_budget > 0),
    CHECK (annual_budget >= monthly_budget)
);

WITH project_cost_rows AS (
    SELECT
        COALESCE(
            p.project_id,
            cu."Tags" ->> 'project',
            lower(regexp_replace(COALESCE(cu."SubAccountId", cu."Tags" ->> 'app', 'unmapped'), '[^a-zA-Z0-9]+', '-', 'g'))
        ) AS project_id,
        COALESCE(
            p.project_name,
            cu."SubAccountName",
            cu."Tags" ->> 'app',
            'Unmapped project'
        ) AS project_name,
        COALESCE(
            p.business_unit,
            cu."Tags" ->> 'cost_center',
            cu."Tags" ->> 'owner',
            'Unmapped'
        ) AS business_unit,
        COALESCE(cu."Tags" ->> 'workload_pattern', 'mapped') AS workload_pattern,
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
daily_project_costs AS (
    SELECT
        project_id,
        project_name,
        business_unit,
        billing_currency,
        workload_pattern,
        charge_day,
        sum(allocated_effective_cost) AS daily_effective_cost
    FROM project_cost_rows
    GROUP BY 1, 2, 3, 4, 5, 6
),
latest_day AS (
    SELECT max(charge_day) AS max_charge_day
    FROM daily_project_costs
),
recent_project_costs AS (
    SELECT
        d.project_id,
        max(d.project_name) AS project_name,
        max(d.business_unit) AS business_unit,
        d.billing_currency,
        max(d.workload_pattern) AS workload_pattern,
        avg(d.daily_effective_cost) AS average_recent_daily_cost,
        count(*) AS observed_days
    FROM daily_project_costs d
    CROSS JOIN latest_day ld
    WHERE d.charge_day > ld.max_charge_day - interval '90 days'
    GROUP BY 1, 4
),
budget_assumptions AS (
    SELECT
        project_id,
        project_name,
        business_unit,
        billing_currency,
        CASE
            WHEN workload_pattern = 'growth-spiky' THEN 0.780000
            WHEN workload_pattern = 'seasonal-training' THEN 0.820000
            WHEN lower(business_unit) = 'product' THEN 0.880000
            WHEN lower(business_unit) = 'research' THEN 0.900000
            WHEN lower(business_unit) = 'finance' THEN 1.030000
            WHEN lower(business_unit) = 'finops' THEN 1.120000
            ELSE 1.000000
        END AS budget_factor,
        average_recent_daily_cost,
        observed_days
    FROM recent_project_costs
)
INSERT INTO business.project_budgets (
    project_id,
    project_name,
    business_unit,
    billing_currency,
    budget_period_start,
    monthly_budget,
    annual_budget
)
SELECT
    b.project_id,
    b.project_name,
    b.business_unit,
    b.billing_currency,
    date_trunc('month', ld.max_charge_day)::date AS budget_period_start,
    round(greatest(b.average_recent_daily_cost * 30.000000 * b.budget_factor, 250.000000)::numeric, 6) AS monthly_budget,
    round(greatest(b.average_recent_daily_cost * 30.000000 * b.budget_factor, 250.000000)::numeric * 12.000000, 6) AS annual_budget
FROM budget_assumptions b
CROSS JOIN latest_day ld
WHERE b.observed_days > 0
ORDER BY b.business_unit, b.project_id;

CREATE INDEX idx_project_budgets_business_unit
    ON business.project_budgets (business_unit, billing_currency, budget_period_start);

COMMENT ON TABLE business.project_budgets IS
    'CFO 財務風險 demo 使用的專案預算表，保存每個專案在指定期間的月度與年度預算，用來評估雲端成本是否偏離財務承諾。';

COMMENT ON COLUMN business.project_budgets.project_id IS
    '公司內部或由 FOCUS 帳號資料推導出的專案代碼，用來連結成本、預算與財務風險分數。';

COMMENT ON COLUMN business.project_budgets.project_name IS
    '專案顯示名稱，協助 CFO 與業務主管辨識成本風險所屬的工作負載或產品。';

COMMENT ON COLUMN business.project_budgets.business_unit IS
    '承擔預算責任的業務單位，用來彙總財務風險並安排治理 owner。';

COMMENT ON COLUMN business.project_budgets.billing_currency IS
    '預算與成本比較時使用的 ISO 三碼幣別，對應 FOCUS BillingCurrency。';

COMMENT ON COLUMN business.project_budgets.budget_period_start IS
    '預算期間的起始日期，本 demo 以最新成本日期所在月份作為月度預算期間。';

COMMENT ON COLUMN business.project_budgets.monthly_budget IS
    '專案月度核定預算，用來計算本月至今成本 run rate 是否超出 CFO 可接受範圍。';

COMMENT ON COLUMN business.project_budgets.annual_budget IS
    '專案年度核定預算，用來延伸月度風險到年度財務承諾與現金流觀點。';

COMMENT ON COLUMN business.project_budgets.budget_owner IS
    '負責核定與追蹤預算風險的財務 owner，本 demo 預設為 CFO Office。';

COMMENT ON COLUMN business.project_budgets.budget_status IS
    '預算狀態，例如 Active 或 Retired，用來排除不應再納入治理的舊預算。';

COMMENT ON COLUMN business.project_budgets.created_at IS
    '預算資料列建立時間，協助追蹤 demo 產生或更新預算基準的時間點。';

COMMENT ON INDEX business.project_budgets_pkey IS
    '確保同一專案、幣別與預算期間只有一筆 CFO 預算基準。';

COMMENT ON INDEX business.idx_project_budgets_business_unit IS
    '加速 CFO 依業務單位、幣別與期間檢視專案預算與風險排序。';
