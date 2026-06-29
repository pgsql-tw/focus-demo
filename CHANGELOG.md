# Changelog

本檔案記錄使用者請 Codex 協助完成的專案變更。後續每次調整專案文件、SQL、範例資料或工具程式時，請同步更新此檔。

## 2026-06-29

### Added

- 新增 `sql/03_seed_daily_5_years.sql`，產生 2022-2026 五個完整年度的每日 FOCUS 測試資料。
- 擴張 5 年每日測試資料：每朵雲各 30 個 project，三朵雲共 90 個 project。
- 在大型測試資料中加入多種 workload pattern，例如穩定正式環境、上班時間型、週末批次、月底尖峰、季節性訓練與成長尖峰。
- 在 `sql/01_schema.sql` 加上 `focus.cost_usage` 的中文 table comment。
- 在 `sql/01_schema.sql` 加上所有欄位的中文 column comment。
- 新增 `CHANGELOG.md`，記錄使用者請 Codex 完成的專案變更。
- 新增 FOCUS 官方 MCP server：`https://focus.finops.org/wp-json/focus/v1/mcp`。

### Changed

- README 改為假設使用者已能自行連線到自己的 PostgreSQL 環境。
- README 移除確認本機 PostgreSQL service、固定本機安裝路徑與本機 `psql` 指令。
- README 的建立專案資料庫步驟改為只提供 SQL 指令。
- README 的 CLI 範例改為 bash 寫法。
- README 專案結構補充 `sql/03_seed_daily_5_years.sql`。

### Verified

- 已安裝 `requirements.txt` 內的 Python 套件：`psycopg[binary]` 與 `PyYAML`。
- 使用 Python 匯入驗證套件版本：`psycopg 3.3.4`、`PyYAML 6.0.3`。
- 已用 PostgreSQL transaction 驗證 `sql/01_schema.sql` 可成功執行 table 與 column comments，最後 `ROLLBACK`。
- 已用 Python/psycopg 驗證 `sql/03_seed_daily_5_years.sql` 可產生 `493020` 筆資料、`3` 朵雲、`90` 個 project、`1826` 天，最後 `ROLLBACK`。
