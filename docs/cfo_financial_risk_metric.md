# CFO 財務風險量化指標設計：Cloud Financial Risk Score

這份文件定義下一個 demo 的標的：以 CFO 視角，把雲端成本資料轉成可排序、可追蹤、可治理的財務風險量化指標。

## 指標目的

Cloud Financial Risk Score, 簡稱 CFRS，用來回答一個 CFO 每週都會問的問題：

> 哪些業務、專案或雲端帳號，正在把公司的財務預測推向不可控？

CFRS 不是用來取代預算差異分析，而是把多個風險訊號合併成 0 到 100 分的風險分數，讓財務、FinOps、工程主管能優先處理真正會影響現金流、毛利率與預測可信度的成本異常。

## 管理假設

- 風險不是「花很多錢」本身，而是花費偏離預期、成長速度失控、承諾折扣未被有效使用、或成本集中在少數不可替代服務上。
- CFO 需要的是可比較的風險排序，而不是單一報表上的金額排名。
- 指標必須能從 FOCUS Cost and Usage 資料與內部 business mapping 推導，避免靠人工標記才能運作。
- 分數要能下鑽到 business unit、project、cloud account、provider、service 與 resource 層級。

## 指標定義

CFRS 是 0 到 100 的加權分數：

```text
CFRS = 100 * (
    0.30 * BudgetRunRateRisk
  + 0.25 * CostAccelerationRisk
  + 0.20 * ForecastVolatilityRisk
  + 0.15 * CommitmentCoverageRisk
  + 0.10 * ConcentrationRisk
)
```

每個子指標都正規化為 0 到 1。0 代表低風險，1 代表高風險。

## 子指標

| 子指標 | CFO 解讀 | 建議計算方式 |
|---|---|---|
| BudgetRunRateRisk | 依目前消耗速度，年底是否會超支 | 本期累計成本除以時間進度後，與年度或月度預算比較 |
| CostAccelerationRisk | 成本是否正在加速惡化 | 最近 30 天平均成本相對最近 90 天平均成本的增幅 |
| ForecastVolatilityRisk | 成本預測是否不穩定 | 最近 90 天每日成本的變異係數，或移動平均殘差 |
| CommitmentCoverageRisk | 承諾折扣與保留資源是否沒有覆蓋主要支出 | 可折扣服務支出中，未被承諾或合約折扣覆蓋的比例 |
| ConcentrationRisk | 財務風險是否集中在少數服務或帳號 | Top 3 service 或 account 成本占比 |

## 風險分級

| CFRS 分數 | 等級 | CFO 行動 |
|---:|---|---|
| 0-24 | Low | 維持監控，不需要進入財務例外流程 |
| 25-49 | Watch | 要求業務或平台團隊說明主要成本驅動因子 |
| 50-74 | High | 納入月度財務風險會議，建立改善 owner 與期限 |
| 75-100 | Critical | 觸發 CFO/CTO 聯合審查，暫停非必要擴容或要求預算重估 |

## FOCUS 資料對應

| 需求 | FOCUS / business 欄位 |
|---|---|
| 成本金額 | `"EffectiveCost"`, `"ContractedCost"`, `"ListCost"`, `"BillingCurrency"` |
| 時間序列 | `"ChargePeriodStart"`, `"ChargePeriodEnd"`, `"BillingPeriodStart"` |
| 雲端與服務 | `"ServiceProviderName"`, `"ProviderName"`, `"ServiceName"`, `"ServiceCategory"` |
| 帳號與專案歸屬 | `"BillingAccountId"`, `"SubAccountId"`, `business.cloud_accounts`, `business.company_projects`, `business.project_cloud_accounts` |
| 承諾與折扣訊號 | `"PricingCategory"`, `"ChargeCategory"`, `"ChargeClass"`, `"CommitmentDiscountId"`, `"CommitmentDiscountName"` |
| 資源集中度 | `"ResourceId"`, `"ResourceName"`, `"ResourceType"`, `"Tags"` |

## Demo004 建議範圍

下一個 demo 可以命名為：

```text
demo004_cfo_financial_risk_score
```

建議產出：

- 建立 `business.project_budgets`，保存 project 的月度或年度預算。
- 建立 materialized view，彙總 project 每日有效成本與移動平均。
- 建立 SQL query，計算五個子指標與總分 CFRS。
- 輸出 Top 10 高風險 project，包含風險分數、最大風險來源與建議 CFO 行動。
- 用 demo003 的常態分布預算超支機率，補強 `ForecastVolatilityRisk` 或作為附加欄位。

## 範例輸出欄位

| 欄位 | 說明 |
|---|---|
| `project_id` | 公司內部專案代碼 |
| `project_name` | 專案名稱 |
| `business_unit` | 業務單位 |
| `monthly_budget` | 本月核定預算 |
| `month_to_date_effective_cost` | 本月至今有效成本 |
| `budget_run_rate_risk` | 預算燃燒速度風險 |
| `cost_acceleration_risk` | 成本加速風險 |
| `forecast_volatility_risk` | 預測波動風險 |
| `commitment_coverage_risk` | 承諾折扣覆蓋風險 |
| `concentration_risk` | 成本集中風險 |
| `cloud_financial_risk_score` | 0 到 100 的整體財務風險分數 |
| `risk_level` | Low、Watch、High 或 Critical |
| `primary_risk_driver` | 對分數貢獻最高的子指標 |
| `recommended_cfo_action` | 建議 CFO 採取的治理動作 |

## 設計原則

- 分數必須可解釋：每個 project 的高分原因要能追溯到子指標與原始成本資料。
- 分數必須可比較：不同 business unit 和 cloud provider 之間使用同一個 0 到 100 尺度。
- 分數必須可行動：每個風險等級都對應清楚的治理動作。
- 分數必須可重算：每日或每月重算後，可以形成趨勢線與治理成效追蹤。

## CFO 敘事

這個 demo 的核心故事是：FinOps 不只是節省雲端成本，而是提高財務預測的可信度。

當 CFRS 上升時，CFO 可以快速知道風險來自預算燃燒、成本加速、預測波動、承諾折扣不足，還是服務集中度過高。這讓財務團隊不只是在月底解釋超支，而是在風險形成的早期就介入治理。
