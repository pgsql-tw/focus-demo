# FOCUS PostgreSQL 入門教學

這個專案示範如何把 FinOps Foundation 的 FOCUS（FinOps Open Cost and Usage Specification）概念落到 PostgreSQL 裡：

- 建立一個 FOCUS 風格的成本與用量資料表
- 載入跨雲供應商的測試資料
- 執行常見 FinOps 分析查詢
- 用 Python 管理 schema 初始化、測試資料與查詢流程

以下範例假設你已經能連線到自己的 PostgreSQL 環境。教學使用的資料庫名稱為 `focus-demo`，使用者為 `focus-user`。

## 1. 建立專案資料庫

請使用具備建立 role 與 database 權限的 PostgreSQL 帳號，連線到你的資料庫環境後執行下列 SQL。角色與資料庫名稱含有 `-`，所以 SQL 需要使用雙引號。

```sql
CREATE ROLE "focus-user" WITH LOGIN PASSWORD '<focus-user 密碼>';
CREATE DATABASE "focus-demo" OWNER "focus-user";
```

確認資料庫 owner：

```sql
SELECT
  d.datname,
  pg_catalog.pg_get_userbyid(d.datdba) AS owner
FROM pg_database d
WHERE d.datname = 'focus-demo';
```

預期結果：

```text
  datname   |   owner
------------+------------
 focus-demo | focus-user
```

## 2. 設定連線檔

複製範本：

```bash
cp config/postgres.example.ini config/postgres.ini
```

編輯 `config/postgres.ini`：

```ini
[postgresql]
host = <你的 PostgreSQL host>
port = <你的 PostgreSQL port>
database = focus-demo
user = focus-user
password = <focus-user 密碼>
sslmode = prefer
```

`config/postgres.ini` 已在 `.gitignore`，不會被提交到 git。

## 3. 安裝 Python 套件

建議使用 virtual environment：

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

本專案目前使用：

- `psycopg[binary]`：連線 PostgreSQL
- `PyYAML`：驗證 project skill

## 4. 檢查設定

```bash
python scripts/focus_demo.py check-config
```

預期會看到密碼被遮蔽的連線資訊：

```text
Loaded PostgreSQL configuration:
- host: <你的 PostgreSQL host>
- port: <你的 PostgreSQL port>
- database: focus-demo
- user: focus-user
- password: ***
- sslmode: prefer
```

## 5. 建立 FOCUS 資料表

```bash
python scripts/focus_demo.py init-db
```

預期結果：

```text
Applied 01_schema.sql
```

這會建立：

- schema：`focus`
- table：`focus.cost_usage`
- 常用索引：時間區間、供應商/服務、`Tags` JSONB

## 6. 載入測試資料

```bash
python scripts/focus_demo.py seed
```

預期結果：

```text
Applied 01_schema.sql
Applied 02_seed_data.sql
```

測試資料包含 AWS、Microsoft Azure、Google Cloud 的成本與用量紀錄，並使用 FOCUS 風格欄位，例如：

- `"EffectiveCost"`
- `"ChargePeriodStart"`
- `"ProviderName"`
- `"ServiceName"`
- `"ConsumedQuantity"`
- `"Tags"`

## 7. 執行範例查詢

執行全部查詢：

```bash
python scripts/focus_demo.py query
```

執行單一查詢：

```bash
python scripts/focus_demo.py query query_01_daily_cost_by_provider
```

測試結果範例：

```text
charge_day | ProviderName | BillingCurrency | effective_cost
-----------+--------------+-----------------+---------------
2026-06-01 | AWS          | USD             | 32.63
2026-06-01 | Microsoft    | USD             | 31.82
2026-06-01 | Google Cloud | USD             | 8.24
2026-06-02 | Microsoft    | USD             | 47.10
2026-06-02 | Google Cloud | USD             | 10.13
2026-06-02 | AWS          | USD             | 9.76
```

## 8. 用 SQL 直接檢查資料

```sql
SELECT count(*) AS rows
FROM focus.cost_usage;
```

預期結果：

```text
 rows
------
    8
```

## 9. 你可以怎麼延伸

- 在 `sql/query_*.sql` 增加新的 FinOps 分析問題
- 在 `sql/02_seed_data.sql` 增加更多雲服務或帳務情境
- 在 `sql/01_schema.sql` 擴充更多 FOCUS v1.4 欄位
- 用 `Tags` 的 `owner`、`app`、`env`、`cost_center` 做分攤分析

## 專案結構

- `config/postgres.example.ini`：PostgreSQL 連線設定範本
- `scripts/focus_demo.py`：Python CLI
- `sql/01_schema.sql`：FOCUS 風格 PostgreSQL schema
- `sql/02_seed_data.sql`：測試資料
- `sql/query_*.sql`：FinOps 範例查詢
- `docs/focus_overview.md`：FOCUS 概念簡介
- `.codex/skills/focus-postgresql-demo`：專案維護用 skill
