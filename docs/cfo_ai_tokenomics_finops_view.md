# CFO AI Tokenomics FinOps 觀點：把 AI 消費納入財務治理

這份文件記錄 2026 年近期雲端與 AI 成本討論帶來的新想法。核心判斷是：AI 成本不只是新的雲端帳單項目，而是一種會改變預算可信度、毛利、資本配置與治理節奏的變動成本。

## CFO 問題

> 哪些 business unit、project 或 AI workflow，正在把公司的雲端與 AI 消費推向不可預測？

CFO 不應只問 AI 花了多少錢，而要問 AI 支出是否能被預測、歸屬、解釋與治理。如果 token、inference、GPU、資料搬移與 agentic workflow 的成本無法連回 business owner 與業務價值，AI 就會把 P&L 變成黑盒。

## 新觀察

### 1. Token 是新的財務消費單位

傳統 SaaS 成本常用使用者席次、合約金額或固定訂閱費管理，但生成式 AI 逐漸改成依 token、請求量、模型選擇、context 長度、推理深度與 agent workflow 收費。這代表成本會隨使用行為非線性擴張。

CFO 的風險不是 token 單價高，而是 token demand 難預測。即使單價下降，更多使用者、更長 context、更多 agent 自動執行與更複雜模型，仍可能讓總支出快速上升。

### 2. Agentic AI 讓 forecast volatility 升高

一般 chatbot 的成本仍可用人數、互動次數與平均 token 估算，但 agentic workflow 會自己拆解任務、查資料、產生中間步驟、重試與驗證。這讓同一個業務任務可能出現高度不同的 token 消耗。

對 CFO 來說，agentic AI 應被視為高波動變動成本。它不只影響雲端帳單，也會影響產品毛利、工程生產力 ROI、以及是否需要額外 GPU 或私有部署投資。

### 3. AI 成本常藏在次級費用裡

AI bill shock 不一定只來自模型 API 或 GPU compute。更常見的隱性來源包括 data egress、跨區 replication、向量資料庫、長期儲存、重複環境、idle GPU、以及與實際用量錯配的 commitment discount。

因此 FinOps 不能只做月底帳單解釋。成本治理要前移到架構設計與採購決策：哪些 workflow 允許使用高階模型？哪些資料可以跨區？哪些 agent 需要 spending cap？哪些 SaaS 合約必須揭露 token 或 metered usage？

## 建議新增風險構面

下一版 CFO 風險指標可以在 Cloud Financial Risk Score 之外，延伸成 AI Financial Control Score。建議子指標如下：

| 子指標 | CFO 解讀 | 可用資料或實作方向 |
|---|---|---|
| `TokenConsumptionRisk` | token 使用量是否快速成長或超過預算假設 | AI gateway logs、SaaS metered usage、FOCUS 成本資料中的 AI service spend |
| `AgenticWorkflowVolatilityRisk` | agent 任務成本是否高度不可預測 | workflow run logs、每次任務 token 分布、重試次數與工具呼叫次數 |
| `SecondaryCloudCostRisk` | AI 周邊雲成本是否正在累積 | `"ServiceName"`、`"ServiceCategory"`、data transfer、storage、database、GPU instance 成本 |
| `AIValueEvidenceRisk` | AI 支出是否缺乏可驗證業務價值 | project owner、use case、收入提升、成本節省或生產力指標 |
| `UnownedAIUsageRisk` | AI 使用是否沒有 owner 或 chargeback/showback | business mapping、tags、帳號歸屬、內部 chargeback 規則 |

## Demo005 想法

建議下一個 demo 命名為：

```text
demo005_ai_financial_control_score
```

它要回答的 CFO 問題是：

> 哪些 AI 與雲端消費正在破壞預算可預測性、毛利可信度與治理責任？

建議輸出：

- 依 business unit、project、cloud account 彙總 AI 相關有效成本。
- 區分直接 AI 成本與次級雲成本，例如 inference、GPU、資料庫、storage、data transfer。
- 產出 AI financial control score，並標示主要風險來源。
- 對沒有 owner、沒有 value evidence、或 token 成長異常的 project 給予較高治理風險。
- 讓 CFO 可以排序 Top 10 高風險 AI project，而不是只看最高成本 project。

## 與 FOCUS 資料的連結

FOCUS 目前能支援 AI FinOps 的基礎是標準化成本與用量欄位，但 token、agent run、business value evidence 仍可能需要外部操作資料補充。

| 需求 | FOCUS / business 欄位或補充資料 |
|---|---|
| AI 服務成本 | `"ServiceName"`, `"ServiceCategory"`, `"ProviderName"`, `"EffectiveCost"` |
| GPU 或 inference 支出 | `"ResourceType"`, `"ResourceName"`, `"SKUId"`, `"SKUPurchaseOption"`, `"PricingCategory"` |
| 時間趨勢 | `"ChargePeriodStart"`, `"ChargePeriodEnd"`, `"BillingPeriodStart"` |
| 專案與 owner | `business.company_projects`, `business.cloud_accounts`, `business.project_cloud_accounts` |
| 承諾與折扣 | `"CommitmentDiscountId"`, `"CommitmentDiscountName"`, `"ContractedCost"`, `"ListCost"` |
| token 與 agent 成本 | AI gateway logs、model provider usage export、SaaS metered usage 報表 |
| 業務價值證據 | use case registry、產品 KPI、節省工時、收入或成本改善估計 |

## CFO 治理原則

- 把 AI 當成經濟系統治理，不只當成技術工具採購。
- 把 token 與 agent run 納入 forecast model，避免月底才發現爆量。
- 要求高風險 AI project 同時提出 owner、成本上限、價值證據與停止條件。
- 對 agentic workflow 設定預算 guardrail，因為任務成本可能比人類直覺更不穩定。
- 在 SaaS 與模型供應商合約中要求 metered usage visibility，避免 token 成本藏在總價或附加費裡。
- 用 showback 或 chargeback 讓 business owner 看見 AI 消費，而不是只由平台團隊吸收。

## 對目前 CFRS 的影響

demo004 的 CFRS 目前以 budget run rate、cost acceleration、forecast volatility、commitment coverage 與 concentration 為主。這仍然是雲端財務風險的好起點。

但 AI 時代的下一步，是把「成本是否超出預算」升級成「消費行為是否可治理」。未來 CFRS 可以有兩種演進方式：

1. 在 CFRS 中加入 `AIUsageCostRisk`，讓 AI 成本成為雲端財務風險的一部分。
2. 另建 `AI Financial Control Score`，專門衡量 token、agent、AI 周邊雲成本與價值證據。

我的偏好是先做第二種。原因是 AI 成本的治理語言與傳統雲端成本不同，獨立 demo 可以更清楚地呈現 CFO 問題，再決定是否回併到 CFRS。
