# Changelog

本檔記錄這個 FOCUS PostgreSQL 標準資料範例專案的主要變更。之後修改 schema、seed data、query、工具、文件或 skill 時，都要同步更新本檔。

## 2026-06-30

### Added

- 新增獨立 demo001 目錄 `demo/demo001/`，收納業務用量 Top 10、service 用量 Top 10、最近一個月費用增加比率 Top 10 業務三個查詢。
- 新增獨立 demo002 目錄 `demo/demo002/`，示範建立每日業務成本 materialized view，並以 M30、M90、M360 移動平均查詢近月成本趨勢。

### Changed

- 更新 `README.md`，改為連結到獨立的 demo001 說明頁。
- 更新 `demo/demo001/README.md`，直接放入與 `.sql` 檔一致的完整查詢 SQL 內容。
- 更新主 `README.md` 教學內容，直接放入 `sql/query_*.sql` 的完整查詢 SQL 內容。
- 調整 `demo/demo001/README.md`，移除執行方式並加入三個查詢的範例執行結果。
- 修正 `README.md`、`demo/demo001/README.md`、`demo/demo002/README.md` 的查詢結果呈現，改用有效 Markdown table 語法。

## 2026-06-29

### Added

- 新增 `AGENTS.md`，將專案層級的 Codex 工作規則集中管理，包含每次專案變更要同步更新 `CHANGELOG.md`。
- 新增完整 FOCUS v1.4 Cost and Usage schema，`focus.cost_usage` 維持 107 個標準欄位。
- 新增 `business` schema，用於記錄公司業務專案、雲端帳戶，以及業務專案到一個或多個雲端帳戶的對應關係。
- 新增 `business.company_projects`、`business.cloud_accounts`、`business.project_cloud_accounts` 三張業務用表。
- 新增 `sql/query_05_business_project_cost.sql`，可依業務專案彙總單雲與跨雲 account 的分攤成本。
- 新增 `sql/03_seed_daily_5_years.sql`，可產生 2022-2026 年的五年期分析用 FOCUS 範例資料。
- 新增 FOCUS MCP server 設定，用於查詢 FOCUS 欄位與規格資訊。

### Changed

- 將 demo 目標從小型 FOCUS 子集調整為完整 FOCUS v1.4 標準資料範例。
- 更新 `sql/02_seed_data.sql`，加入可讀的小型 FOCUS 成本資料、業務專案資料、雲端帳戶資料與專案帳戶對應資料。
- 更新 sample queries，改用 FOCUS v1.4 欄位名稱，例如 `"ServiceProviderName"`。
- 為 schema 中的 table、column、index 加入中文 PostgreSQL metadata comments。
- 改寫 `focus.cost_usage` 欄位註解，使其描述資料內容與業務語意，而不是只重複欄位名稱。
- 更新 `.codex/skills/focus-postgresql-demo`，要求後續變更維持完整 FOCUS v1.4 schema、補中文 metadata comments，並描述欄位資料語意。
- 將「同步更新 `CHANGELOG.md`」從 FOCUS skill 的能力描述移到 `AGENTS.md`，作為整個專案的通用工作規則。
- 整理 `CHANGELOG.md` 編碼與內容，使其成為可讀的中文變更紀錄。

### Verified

- `focus.cost_usage` 在 PostgreSQL metadata 中確認有 107 個欄位。
- `focus.cost_usage` 的 107 個欄位皆有中文欄位註解。
- schema metadata 確認有 4 個 table comments、130 個 column comments、9 個 index comments。
- `sql/02_seed_data.sql` 可成功載入 8 筆 FOCUS 成本資料、4 筆業務專案、6 筆雲端帳戶、7 筆專案帳戶對應。
- `sql/03_seed_daily_5_years.sql` 可產生 493020 筆五年期分析資料。
- `python scripts/focus_demo.py query` 可成功執行全部 sample queries。
- `python -m compileall scripts` 通過。
- `quick_validate.py .codex/skills/focus-postgresql-demo` 通過。
