# CFO FinOps 經營觀點：從成本可視化走向財務可信度

這份文件記錄我作為 CFO 看待 FinOps demo 的思考方式。它不是會計科目說明，而是一套判斷框架：如何把雲端成本資料變成財務治理、預測可信度與經營決策。

## 我的 CFO 立場

我重視 FinOps 的發展，因為雲端支出已經不只是工程成本，而是產品毛利、現金流、預算紀律與組織治理的一部分。

我不會只問「哪裡最貴」，我會問：

- 哪些成本正在讓預測失去可信度？
- 哪些專案正在用比預算更快的速度消耗資源？
- 哪些支出沒有 owner，所以即使金額不大，也會變成治理漏洞？
- 哪些服務或帳號過度集中，讓議價、韌性與財務彈性變差？
- 哪些承諾折扣沒有被有效使用，或可能讓公司過度承諾？

FinOps 對 CFO 的價值，不只是省錢，而是讓公司更早知道財務風險在哪裡、誰要負責、何時要介入。

## 我期待的 FinOps 能力成熟度

| 成熟度 | 財務意義 | Demo 應該呈現的能力 |
|---|---|---|
| 成本可視化 | 知道錢花在哪裡 | 依 provider、service、project、business unit 彙總成本 |
| 責任歸屬 | 知道誰該負責 | 把 FOCUS 帳單映射到內部專案與 owner |
| 趨勢判斷 | 知道成本是否正在惡化 | 移動平均、成長率、波動與異常偵測 |
| 財務風險 | 知道是否會影響預算與預測 | 預算 run rate、超支機率、風險分級 |
| 治理行動 | 知道下一步該做什麼 | 風險 owner、建議 CFO 行動、治理期限 |

## 我如何評估一個 FinOps 指標

一個好的 CFO 指標必須同時滿足四件事：

1. 可解釋：分數高低可以追溯到 FOCUS 欄位、SQL 計算與原始成本資料。
2. 可比較：不同 business unit、project、cloud provider 可以放在同一張管理排序表。
3. 可行動：每個風險等級都要對應清楚的財務或工程治理動作。
4. 可反思：demo 跑完後，要能看出指標本身哪裡需要調整。

如果指標只能說「這裡花很多錢」，它還不是 CFO 指標。它必須回答「這筆錢是否正在破壞我們的財務承諾」。

## demo004 的實作回饋

demo004 把 `Cloud Financial Risk Score (CFRS)` 實作成 PostgreSQL 查詢與物化視圖，並在本機資料庫完成驗證。

驗證結果：

| 驗證項目 | 結果 |
|---|---:|
| `focus.cost_usage` 欄位數 | 107 |
| `focus.cost_usage` 資料列 | 493,020 |
| `business.project_budgets` 資料列 | 90 |
| `business.mv_project_financial_risk_score` 資料列 | 90 |

Top 10 風險專案集中在 research 類型的 GCP 與 Azure project，最高分為 `80.10`，等級為 `Critical`，主要風險來源是 `BudgetRunRateRisk`。風險來源彙總顯示：

| risk_level | primary_risk_driver | project_count | average_risk_score |
|---|---|---:|---:|
| Critical | BudgetRunRateRisk | 15 | 78.68 |
| High | BudgetRunRateRisk | 12 | 54.49 |
| Watch | BudgetRunRateRisk | 15 | 38.32 |
| Watch | ForecastVolatilityRisk | 30 | 36.89 |
| Low | ForecastVolatilityRisk | 2 | 23.86 |
| Low | BudgetRunRateRisk | 14 | 10.46 |
| Low | CommitmentCoverageRisk | 2 | 7.08 |

## 我的反思

第一個回饋是：CFRS 的方向正確。它成功把 FOCUS 成本資料、project budget、run rate、波動、折扣與集中度整合成 CFO 可以排序的管理視圖。

第二個回饋是：`BudgetRunRateRisk` 在 Critical 與 High 專案中明顯主導。這對第一版 demo 是合理的，因為 CFO 最容易理解「照這個速度會超支」。但如果每次結果都由 run rate 主導，其他風險訊號會被壓低，指標會變成預算差異分析，而不是完整的財務風險分數。

第三個回饋是：demo004 的預算是由成本資料推導而來，這很適合教學與可重跑 demo，但在真實公司裡，預算應該來自財務計畫、產品投資假設或年度規劃。下一版 demo 應該更清楚區分「量測到的成本事實」與「CFO 設定的財務承諾」。

第四個回饋是：建議行動已經有管理語言，但還可以更具體。例如 Critical 不只寫 CFO/CTO review，也可以要求專案 owner 在指定期限內提供三件事：需求驅動原因、30 天改善方案、以及是否需要正式調整預算。

## 下一步 Demo 想法

- 將 `business.project_budgets` 改成明確 seed，而不是完全由歷史成本推導。
- 建立風險分數趨勢表，觀察 CFRS 是否連續升高或治理後下降。
- 加入 owner SLA，例如 Critical 風險必須在 5 個工作天內提出改善計畫。
- 設計 commitment overcommitment risk，避免只懲罰折扣不足，而忽略買太多承諾的風險。
- 增加情境測試資料，讓 volatility、concentration、commitment risk 都有機會成為 primary risk driver。
- 參考 `docs/cfo_ai_tokenomics_finops_view.md`，持續校準 demo005 的 AI Financial Control Score，讓 token、agentic workflow、AI 周邊雲成本、owner/guardrail 與業務價值證據都能在不同情境下成為主要治理缺口。

## 給後續 Codex 的工作原則

當你用 CFO 視角繼續做這個專案時，請不要只新增查詢。每個 demo 都應該留下三樣東西：

1. 一個 CFO 會在會議上問的問題。
2. 一個能用 FOCUS 資料重跑的 SQL 實作。
3. 一段根據實際 demo 結果寫下的反思。

這樣 FinOps demo 才會從資料展示，逐步變成財務治理系統。
