# FOCUS 標準概要

本文件摘要介紹 FOCUS（FinOps Open Cost and Usage Specification）的訴求、版本脈絡、雲端與技術服務供應商支援情況，以及本專案採用方式。更新基準日：2026-07-01。

## FOCUS 是什麼

FOCUS 是由 FinOps Foundation 支援的開放技術規格，目標是讓雲端、SaaS、PaaS、資料平台、AI 服務與其他技術帳單資料產生者，用一致的欄位、命名、語意與資料規則輸出成本與用量資料。

對 FinOps 團隊而言，FOCUS 想解決的核心問題是：不同供應商的帳單欄位名稱、成本口徑、用量單位、折扣與承諾使用模型常常不一致，導致多雲成本分析、分攤、單位經濟、異常偵測與內部 showback/chargeback 都需要大量前處理。FOCUS 提供共同資料模型，讓資料可以更直接進入資料倉儲、BI、FinOps 工具與自動化流程。

## 標準訴求

- 統一成本與用量資料的欄位名稱、資料型別、必要性與商業語意。
- 區分可分組、篩選、歸因的維度欄位，以及可彙總、計算的度量欄位。
- 讓供應商輸出的帳單資料可被同一組查詢與分析流程消費。
- 降低多雲、多 SaaS、多技術平台的資料整合成本。
- 支援 FinOps 常見情境，例如成本透明化、預算追蹤、成本分攤、單位經濟、承諾使用分析與資料品質檢查。

FOCUS 不是會計總帳，也不是供應商原始帳單格式的替代品；它比較像是一個標準化分析層，讓不同來源的 billing data 可以用共同語言被查詢、比較與治理。

## 核心概念

- **資料產生者**：雲端服務商、SaaS/PaaS 廠商、資料平台、AI 服務、內部平台或工具供應商，負責產生符合 FOCUS 的資料。
- **資料消費者**：FinOps 團隊、財務、工程、平台、採購、資料分析與管理層，使用 FOCUS 資料做決策。
- **Column Library**：FOCUS 欄位庫，定義每個欄位的名稱、ID、描述、要求與適用版本。官方 v1.4 欄位庫目前列出 107 個欄位。
- **Dimensions 與 Metrics**：Dimensions 用於分類、篩選與歸因；Metrics 用於彙總、計算與比較，例如成本、用量或價格。
- **Conformance**：供應商或工具可以依 FOCUS 的符合性要求檢查資料是否符合指定版本規格。

## 版本歷史

官方網站目前保留 v0.5、v1.0、v1.1、v1.2、v1.3、v1.4 的規格頁。版本細節與逐版差異應以官方規格頁為準；本專案目前以 v1.4 作為主要目標版本。

| 版本 | 摘要定位 |
|---|---|
| v0.5 | 早期公開規格版本，用於建立共同欄位與資料模型方向。 |
| v1.0 | 第一個 1.x 正式規格基準，開始提供更穩定的成本與用量資料語意。 |
| v1.1 | 延續 v1.0 的修訂版本，用於強化欄位定義與一致性。 |
| v1.2 | 擴展 FOCUS 可涵蓋的技術帳單場景，官方 adoption 頁也提到 SaaS 對應在此階段開始被納入規劃。 |
| v1.3 | v1.4 前一版規格，本專案將它視為 v1.4 schema 演進的直接參考版本。 |
| v1.4 | 本專案採用版本；官方 v1.4 頁已發布，專案參考筆記記錄其於 2026-06-04 ratified，Column Library 對 v1.4 列出 107 欄。 |

## 公有雲與供應商支援情況

FOCUS 官方 Get Started 供應商頁目前列出下列入口：

| 類型 | 供應商 |
|---|---|
| 公有雲 / IaaS | Amazon Web Services、Microsoft Azure、Google Cloud、Oracle Cloud Infrastructure、Tencent Cloud、Alibaba Cloud |
| 資料與技術平台 | Databricks、Grafana |

這代表官方網站已提供這些供應商的 FOCUS 導入或取得資料指引；但各家支援的匯出方式、涵蓋帳單範圍、FOCUS 版本與欄位完整度可能不同。實務導入時，應逐一檢查供應商官方文件、FOCUS Get Started 頁、資料匯出設定與實際欄位品質。

## 在本專案中的採用方式

本專案用 PostgreSQL 建立一個完整的 FOCUS v1.4 成本與用量資料範例：

- `focus.cost_usage` 是 canonical FOCUS v1.4 Cost and Usage table，維持 107 個標準欄位。
- FOCUS 欄位在 SQL 中保留 quoted PascalCase 名稱，例如 `"EffectiveCost"`、`"ChargePeriodStart"`。
- 非標準的公司專案、雲帳號與分攤對應資料放在 `business` schema，不混入 canonical FOCUS table。
- 查詢範例聚焦 FinOps 場景，例如每日供應商成本、owner/service 成本、資源單位經濟、資料品質檢查與公司專案分攤。

## 參考資訊

- FOCUS 首頁：https://focus.finops.org/
- What is FOCUS：https://focus.finops.org/what-is-focus/
- About the FOCUS Project：https://focus.finops.org/about-focus/
- FOCUS Specification：https://focus.finops.org/focus-specification/
- FOCUS Specification v1.4：https://focus.finops.org/focus-specification/v1-4/
- FOCUS Column Library：https://focus.finops.org/focus-columns/
- FOCUS Adoption：https://focus.finops.org/adoption/
- Get Started：https://focus.finops.org/get-started/
- Certified FOCUS Conformance Program：https://focus.finops.org/certified-focus-program/
- FOCUS Validator：https://focus.finops.org/focus-validator/
- FOCUS MCP Server：https://focus.finops.org/mcp/
