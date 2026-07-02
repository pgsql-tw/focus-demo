DROP MATERIALIZED VIEW IF EXISTS business.mv_ai_financial_control_score;
DROP TABLE IF EXISTS business.ai_workflow_daily_usage;
DROP TABLE IF EXISTS business.ai_workflow_controls;

CREATE TABLE business.ai_workflow_controls (
    project_id text NOT NULL,
    workflow_id text NOT NULL,
    workflow_name text NOT NULL,
    workflow_type text NOT NULL,
    business_owner text,
    monthly_token_budget numeric(20, 0) NOT NULL,
    value_evidence_status text NOT NULL,
    value_evidence_score numeric(5, 4) NOT NULL,
    max_agent_steps integer NOT NULL,
    guardrail_status text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (project_id, workflow_id),
    CHECK (monthly_token_budget > 0),
    CHECK (value_evidence_score >= 0.0000 AND value_evidence_score <= 1.0000),
    CHECK (max_agent_steps > 0)
);

CREATE TABLE business.ai_workflow_daily_usage (
    project_id text NOT NULL,
    workflow_id text NOT NULL,
    usage_date date NOT NULL,
    input_tokens numeric(20, 0) NOT NULL,
    output_tokens numeric(20, 0) NOT NULL,
    agent_runs integer NOT NULL,
    tool_calls integer NOT NULL,
    failed_runs integer NOT NULL,
    estimated_business_value_usd numeric(20, 6) NOT NULL,
    PRIMARY KEY (project_id, workflow_id, usage_date),
    FOREIGN KEY (project_id, workflow_id)
        REFERENCES business.ai_workflow_controls (project_id, workflow_id),
    CHECK (input_tokens >= 0),
    CHECK (output_tokens >= 0),
    CHECK (agent_runs >= 0),
    CHECK (tool_calls >= 0),
    CHECK (failed_runs >= 0),
    CHECK (estimated_business_value_usd >= 0)
);

WITH candidate_projects AS (
    SELECT
        cu."Tags" ->> 'project' AS project_id,
        max(cu."SubAccountName") AS project_name,
        max(cu."Tags" ->> 'cost_center') AS business_unit,
        max(cu."Tags" ->> 'app') AS app_name,
        max(cu."Tags" ->> 'workload_pattern') AS workload_pattern
    FROM focus.cost_usage cu
    WHERE cu."Tags" ->> 'app' IN ('ml-training', 'checkout')
    GROUP BY 1
),
ranked_projects AS (
    SELECT
        cp.*,
        row_number() OVER (ORDER BY cp.business_unit, cp.project_id) AS project_rank
    FROM candidate_projects cp
)
INSERT INTO business.ai_workflow_controls (
    project_id,
    workflow_id,
    workflow_name,
    workflow_type,
    business_owner,
    monthly_token_budget,
    value_evidence_status,
    value_evidence_score,
    max_agent_steps,
    guardrail_status
)
SELECT
    project_id,
    'aiwf-' || lower(regexp_replace(project_id, '[^a-zA-Z0-9]+', '-', 'g')) AS workflow_id,
    CASE app_name
        WHEN 'ml-training' THEN project_name || ' model training assistant'
        ELSE project_name || ' customer automation agent'
    END AS workflow_name,
    CASE app_name
        WHEN 'ml-training' THEN 'ModelTraining'
        ELSE 'AgenticCustomerWorkflow'
    END AS workflow_type,
    CASE
        WHEN project_rank % 7 = 0 THEN NULL
        WHEN business_unit = 'research' THEN 'research-ai-owner'
        WHEN business_unit = 'product' THEN 'product-ai-owner'
        ELSE lower(business_unit) || '-ai-owner'
    END AS business_owner,
    CASE app_name
        WHEN 'ml-training' THEN (42000000 + (project_rank % 6) * 5500000)::numeric
        ELSE (26000000 + (project_rank % 5) * 4200000)::numeric
    END AS monthly_token_budget,
    CASE
        WHEN project_rank % 6 = 0 THEN 'Missing'
        WHEN project_rank % 4 = 0 THEN 'Weak'
        ELSE 'Validated'
    END AS value_evidence_status,
    CASE
        WHEN project_rank % 6 = 0 THEN 0.1500
        WHEN project_rank % 4 = 0 THEN 0.4200
        WHEN app_name = 'ml-training' THEN 0.7200
        ELSE 0.6500
    END AS value_evidence_score,
    CASE app_name
        WHEN 'ml-training' THEN 8 + (project_rank % 5)
        ELSE 14 + (project_rank % 9)
    END AS max_agent_steps,
    CASE
        WHEN project_rank % 8 = 0 THEN 'Missing'
        WHEN project_rank % 5 = 0 THEN 'Draft'
        ELSE 'Enforced'
    END AS guardrail_status
FROM ranked_projects
ORDER BY business_unit, project_id;

WITH latest_day AS (
    SELECT max("ChargePeriodStart")::date AS max_charge_day
    FROM focus.cost_usage
),
days AS (
    SELECT generate_series(
        (SELECT max_charge_day - interval '179 days' FROM latest_day),
        (SELECT max_charge_day FROM latest_day),
        '1 day'::interval
    )::date AS usage_date
),
workflow_seed AS (
    SELECT
        awc.*,
        row_number() OVER (ORDER BY awc.project_id) AS workflow_rank
    FROM business.ai_workflow_controls awc
),
daily_usage AS (
    SELECT
        ws.project_id,
        ws.workflow_id,
        d.usage_date,
        ws.workflow_type,
        ws.monthly_token_budget,
        ws.value_evidence_score,
        ws.max_agent_steps,
        ws.guardrail_status,
        ws.workflow_rank,
        (
            0.650000
            + (extract(doy FROM d.usage_date)::int % 23) * 0.018000
            + CASE ws.workflow_type
                WHEN 'AgenticCustomerWorkflow' THEN 0.280000
                ELSE 0.000000
              END
            + CASE WHEN d.usage_date > (SELECT max_charge_day - interval '45 days' FROM latest_day)
                THEN (ws.workflow_rank % 5) * 0.120000
                ELSE 0.000000
              END
            + CASE WHEN ws.value_evidence_score < 0.5000 THEN 0.250000 ELSE 0.000000 END
            + CASE WHEN ws.guardrail_status <> 'Enforced' THEN 0.180000 ELSE 0.000000 END
        ) AS usage_multiplier
    FROM workflow_seed ws
    CROSS JOIN days d
)
INSERT INTO business.ai_workflow_daily_usage (
    project_id,
    workflow_id,
    usage_date,
    input_tokens,
    output_tokens,
    agent_runs,
    tool_calls,
    failed_runs,
    estimated_business_value_usd
)
SELECT
    project_id,
    workflow_id,
    usage_date,
    round(monthly_token_budget / 30.000000 * usage_multiplier * 0.620000, 0) AS input_tokens,
    round(monthly_token_budget / 30.000000 * usage_multiplier * 0.380000, 0) AS output_tokens,
    greatest(1, round(18.000000 * usage_multiplier + (workflow_rank % 7), 0)::integer) AS agent_runs,
    greatest(1, round((18.000000 * usage_multiplier + (workflow_rank % 7)) * max_agent_steps * 0.680000, 0)::integer) AS tool_calls,
    greatest(0, round((18.000000 * usage_multiplier + (workflow_rank % 7)) * CASE
        WHEN guardrail_status = 'Missing' THEN 0.180000
        WHEN guardrail_status = 'Draft' THEN 0.090000
        ELSE 0.035000
    END, 0)::integer) AS failed_runs,
    round((monthly_token_budget / 30.000000 * usage_multiplier / 1000000.000000 * value_evidence_score * 18.000000)::numeric, 6) AS estimated_business_value_usd
FROM daily_usage
ORDER BY project_id, workflow_id, usage_date;

CREATE MATERIALIZED VIEW business.mv_ai_financial_control_score AS
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
        cu."BillingCurrency" AS billing_currency,
        date_trunc('day', cu."ChargePeriodStart")::date AS charge_day,
        cu."ServiceCategory" AS service_category,
        cu."ServiceName" AS service_name,
        cu."ResourceType" AS resource_type,
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
latest_cost_day AS (
    SELECT max(charge_day) AS max_charge_day
    FROM project_cost_rows
),
ai_enabled_projects AS (
    SELECT DISTINCT project_id
    FROM business.ai_workflow_controls
),
ai_cost_metrics AS (
    SELECT
        pcr.project_id,
        max(pcr.project_name) AS project_name,
        max(pcr.business_unit) AS business_unit,
        pcr.billing_currency,
        sum(pcr.allocated_effective_cost) FILTER (
            WHERE pcr.charge_day > lcd.max_charge_day - interval '30 days'
                AND pcr.service_category IN ('Compute', 'Analytics')
        ) AS m30_direct_ai_cost,
        sum(pcr.allocated_effective_cost) FILTER (
            WHERE pcr.charge_day > lcd.max_charge_day - interval '30 days'
                AND pcr.service_category IN ('Database', 'Storage')
        ) AS m30_secondary_cloud_cost,
        sum(pcr.allocated_effective_cost) FILTER (
            WHERE pcr.charge_day > lcd.max_charge_day - interval '90 days'
                AND pcr.service_category IN ('Compute', 'Analytics')
        ) AS m90_direct_ai_cost,
        sum(pcr.allocated_effective_cost) FILTER (
            WHERE pcr.charge_day > lcd.max_charge_day - interval '90 days'
                AND pcr.service_category IN ('Database', 'Storage')
        ) AS m90_secondary_cloud_cost
    FROM project_cost_rows pcr
    JOIN ai_enabled_projects aep
        ON aep.project_id = pcr.project_id
    CROSS JOIN latest_cost_day lcd
    GROUP BY 1, 4
),
workflow_daily AS (
    SELECT
        awc.project_id,
        awc.workflow_id,
        awdu.usage_date,
        awc.workflow_name,
        awc.workflow_type,
        awc.business_owner,
        awc.monthly_token_budget,
        awc.value_evidence_status,
        awc.value_evidence_score,
        awc.max_agent_steps,
        awc.guardrail_status,
        awdu.input_tokens + awdu.output_tokens AS total_tokens,
        awdu.agent_runs,
        awdu.tool_calls,
        awdu.failed_runs,
        awdu.estimated_business_value_usd
    FROM business.ai_workflow_controls awc
    JOIN business.ai_workflow_daily_usage awdu
        ON awdu.project_id = awc.project_id
        AND awdu.workflow_id = awc.workflow_id
),
latest_usage_day AS (
    SELECT max(usage_date) AS max_usage_date
    FROM workflow_daily
),
workflow_metrics AS (
    SELECT
        wd.project_id,
        wd.workflow_id,
        max(wd.workflow_name) AS workflow_name,
        max(wd.workflow_type) AS workflow_type,
        max(wd.business_owner) AS business_owner,
        max(wd.monthly_token_budget) AS monthly_token_budget,
        max(wd.value_evidence_status) AS value_evidence_status,
        max(wd.value_evidence_score) AS value_evidence_score,
        max(wd.max_agent_steps) AS max_agent_steps,
        max(wd.guardrail_status) AS guardrail_status,
        lud.max_usage_date AS score_as_of_date,
        sum(wd.total_tokens) FILTER (
            WHERE wd.usage_date >= date_trunc('month', lud.max_usage_date)::date
                AND wd.usage_date <= lud.max_usage_date
        ) AS month_to_date_tokens,
        sum(wd.total_tokens) FILTER (
            WHERE wd.usage_date > lud.max_usage_date - interval '30 days'
        ) AS m30_tokens,
        sum(wd.total_tokens) FILTER (
            WHERE wd.usage_date > lud.max_usage_date - interval '90 days'
        ) AS m90_tokens,
        avg(wd.total_tokens / NULLIF(wd.agent_runs, 0)) FILTER (
            WHERE wd.usage_date > lud.max_usage_date - interval '90 days'
        ) AS m90_tokens_per_agent_run,
        stddev_samp(wd.total_tokens / NULLIF(wd.agent_runs, 0)) FILTER (
            WHERE wd.usage_date > lud.max_usage_date - interval '90 days'
        ) AS m90_tokens_per_agent_run_stddev,
        sum(wd.agent_runs) FILTER (
            WHERE wd.usage_date > lud.max_usage_date - interval '30 days'
        ) AS m30_agent_runs,
        sum(wd.tool_calls) FILTER (
            WHERE wd.usage_date > lud.max_usage_date - interval '30 days'
        ) AS m30_tool_calls,
        sum(wd.failed_runs) FILTER (
            WHERE wd.usage_date > lud.max_usage_date - interval '30 days'
        ) AS m30_failed_runs,
        sum(wd.estimated_business_value_usd) FILTER (
            WHERE wd.usage_date > lud.max_usage_date - interval '30 days'
        ) AS m30_estimated_business_value_usd
    FROM workflow_daily wd
    CROSS JOIN latest_usage_day lud
    GROUP BY 1, 2, lud.max_usage_date
),
score_inputs AS (
    SELECT
        wm.project_id,
        COALESCE(acm.project_name, wm.project_id) AS project_name,
        COALESCE(acm.business_unit, 'Unmapped') AS business_unit,
        COALESCE(acm.billing_currency, 'USD') AS billing_currency,
        wm.workflow_id,
        wm.workflow_name,
        wm.workflow_type,
        wm.business_owner,
        wm.score_as_of_date,
        wm.monthly_token_budget,
        COALESCE(wm.month_to_date_tokens, 0) AS month_to_date_tokens,
        COALESCE(wm.m30_tokens, 0) AS m30_tokens,
        COALESCE(wm.m90_tokens, 0) AS m90_tokens,
        COALESCE(wm.m90_tokens_per_agent_run, 0) AS m90_tokens_per_agent_run,
        COALESCE(wm.m90_tokens_per_agent_run_stddev, 0) AS m90_tokens_per_agent_run_stddev,
        COALESCE(wm.m30_agent_runs, 0) AS m30_agent_runs,
        COALESCE(wm.m30_tool_calls, 0) AS m30_tool_calls,
        COALESCE(wm.m30_failed_runs, 0) AS m30_failed_runs,
        wm.value_evidence_status,
        wm.value_evidence_score,
        wm.max_agent_steps,
        wm.guardrail_status,
        COALESCE(acm.m30_direct_ai_cost, 0.000000) AS m30_direct_ai_cost,
        COALESCE(acm.m30_secondary_cloud_cost, 0.000000) AS m30_secondary_cloud_cost,
        COALESCE(acm.m90_direct_ai_cost, 0.000000) AS m90_direct_ai_cost,
        COALESCE(acm.m90_secondary_cloud_cost, 0.000000) AS m90_secondary_cloud_cost,
        COALESCE(wm.m30_estimated_business_value_usd, 0.000000) AS m30_estimated_business_value_usd
    FROM workflow_metrics wm
    LEFT JOIN ai_cost_metrics acm
        ON acm.project_id = wm.project_id
),
normalized_risks AS (
    SELECT
        si.*,
        least(greatest((si.m30_tokens / NULLIF(si.monthly_token_budget, 0) - 0.850000) / 0.550000, 0.000000), 1.000000) AS token_consumption_risk,
        least(greatest(((si.m90_tokens_per_agent_run_stddev / NULLIF(si.m90_tokens_per_agent_run, 0)) - 0.120000) / 0.550000, 0.000000), 1.000000) AS agentic_workflow_volatility_risk,
        least(greatest(((si.m30_secondary_cloud_cost / NULLIF(si.m30_direct_ai_cost + si.m30_secondary_cloud_cost, 0.000000)) - 0.350000) / 0.400000, 0.000000), 1.000000) AS secondary_cloud_cost_risk,
        least(greatest(1.000000 - si.value_evidence_score, 0.000000), 1.000000) AS ai_value_evidence_risk,
        CASE
            WHEN si.business_owner IS NULL AND si.guardrail_status = 'Missing' THEN 1.000000
            WHEN si.business_owner IS NULL THEN 0.850000
            WHEN si.guardrail_status = 'Missing' THEN 0.750000
            WHEN si.guardrail_status = 'Draft' THEN 0.450000
            ELSE 0.000000
        END AS unowned_ai_usage_risk
    FROM score_inputs si
),
scored_workflows AS (
    SELECT
        nr.*,
        100.000000 * (
            0.300000 * COALESCE(nr.token_consumption_risk, 0.000000)
            + 0.250000 * COALESCE(nr.agentic_workflow_volatility_risk, 0.000000)
            + 0.200000 * COALESCE(nr.secondary_cloud_cost_risk, 0.000000)
            + 0.150000 * COALESCE(nr.ai_value_evidence_risk, 0.000000)
            + 0.100000 * COALESCE(nr.unowned_ai_usage_risk, 0.000000)
        ) AS ai_financial_control_score
    FROM normalized_risks nr
)
SELECT
    project_id,
    project_name,
    business_unit,
    billing_currency,
    workflow_id,
    workflow_name,
    workflow_type,
    business_owner,
    score_as_of_date,
    monthly_token_budget,
    round(month_to_date_tokens, 0) AS month_to_date_tokens,
    round(m30_tokens, 0) AS m30_tokens,
    round(m90_tokens, 0) AS m90_tokens,
    round(m90_tokens_per_agent_run, 2) AS m90_tokens_per_agent_run,
    round(m90_tokens_per_agent_run_stddev, 2) AS m90_tokens_per_agent_run_stddev,
    m30_agent_runs,
    m30_tool_calls,
    m30_failed_runs,
    value_evidence_status,
    round(value_evidence_score, 4) AS value_evidence_score,
    max_agent_steps,
    guardrail_status,
    round(m30_direct_ai_cost, 2) AS m30_direct_ai_cost,
    round(m30_secondary_cloud_cost, 2) AS m30_secondary_cloud_cost,
    round(m30_estimated_business_value_usd, 2) AS m30_estimated_business_value_usd,
    round(token_consumption_risk, 4) AS token_consumption_risk,
    round(agentic_workflow_volatility_risk, 4) AS agentic_workflow_volatility_risk,
    round(secondary_cloud_cost_risk, 4) AS secondary_cloud_cost_risk,
    round(ai_value_evidence_risk, 4) AS ai_value_evidence_risk,
    round(unowned_ai_usage_risk, 4) AS unowned_ai_usage_risk,
    round(ai_financial_control_score, 2) AS ai_financial_control_score,
    CASE
        WHEN ai_financial_control_score >= 75.000000 THEN 'Critical'
        WHEN ai_financial_control_score >= 50.000000 THEN 'High'
        WHEN ai_financial_control_score >= 25.000000 THEN 'Watch'
        ELSE 'Low'
    END AS control_level,
    CASE greatest(
        0.300000 * COALESCE(token_consumption_risk, 0.000000),
        0.250000 * COALESCE(agentic_workflow_volatility_risk, 0.000000),
        0.200000 * COALESCE(secondary_cloud_cost_risk, 0.000000),
        0.150000 * COALESCE(ai_value_evidence_risk, 0.000000),
        0.100000 * COALESCE(unowned_ai_usage_risk, 0.000000)
    )
        WHEN 0.300000 * COALESCE(token_consumption_risk, 0.000000) THEN 'TokenConsumptionRisk'
        WHEN 0.250000 * COALESCE(agentic_workflow_volatility_risk, 0.000000) THEN 'AgenticWorkflowVolatilityRisk'
        WHEN 0.200000 * COALESCE(secondary_cloud_cost_risk, 0.000000) THEN 'SecondaryCloudCostRisk'
        WHEN 0.150000 * COALESCE(ai_value_evidence_risk, 0.000000) THEN 'AIValueEvidenceRisk'
        ELSE 'UnownedAIUsageRisk'
    END AS primary_control_gap,
    CASE
        WHEN ai_financial_control_score >= 75.000000 THEN 'Freeze expansion until owner, guardrail, and value evidence are approved'
        WHEN ai_financial_control_score >= 50.000000 THEN 'Require CFO review, token cap, and value evidence update this month'
        WHEN ai_financial_control_score >= 25.000000 THEN 'Ask owner to explain token trend and secondary cloud cost'
        ELSE 'Monitor in normal AI FinOps cadence'
    END AS recommended_cfo_action
FROM scored_workflows
ORDER BY ai_financial_control_score DESC, m30_tokens DESC;

CREATE UNIQUE INDEX idx_mv_ai_financial_control_score_key
    ON business.mv_ai_financial_control_score (project_id, workflow_id, billing_currency);

CREATE INDEX idx_mv_ai_financial_control_score_level
    ON business.mv_ai_financial_control_score (control_level, ai_financial_control_score DESC);

CREATE INDEX idx_ai_workflow_controls_owner
    ON business.ai_workflow_controls (business_owner, guardrail_status);

CREATE INDEX idx_ai_workflow_daily_usage_date
    ON business.ai_workflow_daily_usage (usage_date, project_id);

COMMENT ON TABLE business.ai_workflow_controls IS
    'AI 財務治理 demo 使用的 workflow 控制表，保存每個 AI workflow 的 owner、token 預算、價值證據與 guardrail 狀態。';

COMMENT ON COLUMN business.ai_workflow_controls.project_id IS
    'AI workflow 所屬專案代碼，用來連結 FOCUS 成本、token 使用與公司治理責任。';

COMMENT ON COLUMN business.ai_workflow_controls.workflow_id IS
    'AI workflow 的穩定識別碼，用來追蹤單一模型訓練、agent 或自動化流程。';

COMMENT ON COLUMN business.ai_workflow_controls.workflow_name IS
    'AI workflow 顯示名稱，協助 CFO 與業務 owner 辨識治理對象。';

COMMENT ON COLUMN business.ai_workflow_controls.workflow_type IS
    'AI workflow 類型，例如模型訓練或 agentic customer workflow，用來區分成本行為。';

COMMENT ON COLUMN business.ai_workflow_controls.business_owner IS
    '負責 AI workflow 財務結果與治理回應的業務 owner；NULL 代表責任歸屬缺口。';

COMMENT ON COLUMN business.ai_workflow_controls.monthly_token_budget IS
    'CFO 核定或暫定的月度 token 預算，用來評估 token 消費是否超出財務假設。';

COMMENT ON COLUMN business.ai_workflow_controls.value_evidence_status IS
    'AI workflow 的業務價值證據狀態，例如 Validated、Weak 或 Missing。';

COMMENT ON COLUMN business.ai_workflow_controls.value_evidence_score IS
    '0 到 1 的業務價值證據分數，分數越低代表 AI 支出越缺乏可驗證回報。';

COMMENT ON COLUMN business.ai_workflow_controls.max_agent_steps IS
    '單次 agent workflow 允許的最大步驟數，用來估計 agentic AI 成本擴張風險。';

COMMENT ON COLUMN business.ai_workflow_controls.guardrail_status IS
    'AI workflow 成本與行為 guardrail 狀態，例如 Enforced、Draft 或 Missing。';

COMMENT ON COLUMN business.ai_workflow_controls.created_at IS
    'AI workflow 控制資料列建立時間，用於追蹤治理資料產生或更新時間。';

COMMENT ON TABLE business.ai_workflow_daily_usage IS
    'AI workflow 每日 token 與 agent 使用量表，提供 FOCUS 成本以外的 AI 消費行為證據。';

COMMENT ON COLUMN business.ai_workflow_daily_usage.project_id IS
    '每日 AI 使用量所屬專案代碼，用來連回 workflow 控制表與 FOCUS 成本。';

COMMENT ON COLUMN business.ai_workflow_daily_usage.workflow_id IS
    '每日 AI 使用量所屬 workflow 識別碼。';

COMMENT ON COLUMN business.ai_workflow_daily_usage.usage_date IS
    'AI workflow 發生 token 與 agent 使用量的日期。';

COMMENT ON COLUMN business.ai_workflow_daily_usage.input_tokens IS
    '當日輸入 token 數量，用來衡量 prompt、context 與資料擷取帶來的 AI 消費。';

COMMENT ON COLUMN business.ai_workflow_daily_usage.output_tokens IS
    '當日輸出 token 數量，用來衡量模型生成內容帶來的 AI 消費。';

COMMENT ON COLUMN business.ai_workflow_daily_usage.agent_runs IS
    '當日 agent workflow 執行次數，用來衡量自動化任務需求。';

COMMENT ON COLUMN business.ai_workflow_daily_usage.tool_calls IS
    '當日 agent workflow 工具呼叫次數，用來衡量任務複雜度與次級系統負載。';

COMMENT ON COLUMN business.ai_workflow_daily_usage.failed_runs IS
    '當日失敗或重試的 agent run 次數，用來衡量浪費與治理風險。';

COMMENT ON COLUMN business.ai_workflow_daily_usage.estimated_business_value_usd IS
    'AI workflow 當日估計業務價值金額，用來與 token 與雲端成本比較。';

COMMENT ON MATERIALIZED VIEW business.mv_ai_financial_control_score IS
    'CFO AI 財務治理 demo 的 workflow 級物化視圖，整合 FOCUS 成本、token 使用、agent 波動、次級雲成本、owner 與價值證據，產生 AI Financial Control Score。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.project_id IS
    'AI workflow 所屬專案代碼，優先取 business mapping，否則使用 FOCUS Tags project。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.project_name IS
    'AI workflow 所屬專案名稱，用來讓 CFO 辨識治理對象。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.business_unit IS
    'AI workflow 所屬業務單位，用來建立財務治理責任。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.billing_currency IS
    '成本計算使用的幣別，對應 FOCUS BillingCurrency。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.workflow_id IS
    'AI workflow 的穩定識別碼。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.workflow_name IS
    'AI workflow 顯示名稱。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.workflow_type IS
    'AI workflow 類型，用來區分模型訓練與 agentic workflow 的財務行為。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.business_owner IS
    '負責此 AI workflow 的業務 owner；缺值表示治理責任不完整。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.score_as_of_date IS
    'AI 財務治理分數使用的最新使用量日期。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.monthly_token_budget IS
    '用來比較實際 token 消費的月度 token 預算。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.month_to_date_tokens IS
    '本月至評分日期為止累計的輸入與輸出 token 數。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.m30_tokens IS
    '最近 30 天輸入與輸出 token 總數。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.m90_tokens IS
    '最近 90 天輸入與輸出 token 總數。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.m90_tokens_per_agent_run IS
    '最近 90 天每次 agent run 平均 token 數，用來衡量任務成本強度。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.m90_tokens_per_agent_run_stddev IS
    '最近 90 天每次 agent run token 數標準差，用來衡量 agentic workflow 成本波動。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.m30_agent_runs IS
    '最近 30 天 agent workflow 執行次數。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.m30_tool_calls IS
    '最近 30 天 agent 工具呼叫次數，用來觀察次級雲服務可能承受的負載。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.m30_failed_runs IS
    '最近 30 天失敗或重試的 agent run 次數，用來衡量浪費與治理缺口。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.value_evidence_status IS
    'AI workflow 的業務價值證據狀態。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.value_evidence_score IS
    '0 到 1 的業務價值證據分數，分數越低代表治理風險越高。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.max_agent_steps IS
    '單次 agent workflow 允許的最大步驟數。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.guardrail_status IS
    'AI workflow 成本與行為 guardrail 狀態。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.m30_direct_ai_cost IS
    '最近 30 天與 AI workflow 直接相關的 Compute 或 Analytics EffectiveCost。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.m30_secondary_cloud_cost IS
    '最近 30 天支援 AI workflow 的 Database 或 Storage EffectiveCost。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.m30_estimated_business_value_usd IS
    '最近 30 天估計業務價值金額，用來檢查 AI 支出是否有回報證據。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.token_consumption_risk IS
    'token 消費風險，衡量最近 30 天 token 使用量相對月度 token 預算是否過高。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.agentic_workflow_volatility_risk IS
    'agentic workflow 波動風險，衡量每次 agent run token 消耗是否難以預測。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.secondary_cloud_cost_risk IS
    '次級雲成本風險，衡量支援 AI workflow 的資料庫與儲存成本占比是否過高。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.ai_value_evidence_risk IS
    'AI 價值證據風險，衡量 AI 支出是否缺乏可驗證業務價值。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.unowned_ai_usage_risk IS
    '未歸屬 AI 使用風險，衡量 owner 或 guardrail 缺口。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.ai_financial_control_score IS
    '0 到 100 的 AI Financial Control Score，分數越高代表 CFO 越需要治理介入。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.control_level IS
    '依 AI Financial Control Score 分級的 Low、Watch、High 或 Critical。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.primary_control_gap IS
    '對 AI Financial Control Score 貢獻最大的治理缺口。';

COMMENT ON COLUMN business.mv_ai_financial_control_score.recommended_cfo_action IS
    '依 AI 財務治理分級建議 CFO 採取的行動。';

COMMENT ON INDEX business.ai_workflow_controls_pkey IS
    '確保同一專案底下每個 AI workflow 只有一筆控制資料。';

COMMENT ON INDEX business.ai_workflow_daily_usage_pkey IS
    '確保同一 AI workflow 每日只有一筆 token 與 agent 使用量資料。';

COMMENT ON INDEX business.idx_mv_ai_financial_control_score_key IS
    '確保每個 AI workflow 與幣別只有一筆 AI Financial Control Score。';

COMMENT ON INDEX business.idx_mv_ai_financial_control_score_level IS
    '加速 CFO 依治理等級與分數排序檢視 AI workflow。';

COMMENT ON INDEX business.idx_ai_workflow_controls_owner IS
    '加速依 owner 與 guardrail 狀態檢視 AI workflow 治理缺口。';

COMMENT ON INDEX business.idx_ai_workflow_daily_usage_date IS
    '加速依日期與專案彙總 AI workflow token 與 agent 使用量。';
