CREATE SCHEMA IF NOT EXISTS focus;

CREATE TABLE IF NOT EXISTS focus.cost_usage (
    "Id" bigserial PRIMARY KEY,
    "BillingAccountId" text NOT NULL,
    "BillingAccountName" text,
    "BillingCurrency" char(3) NOT NULL,
    "BillingPeriodStart" timestamptz NOT NULL,
    "BillingPeriodEnd" timestamptz NOT NULL,
    "ChargePeriodStart" timestamptz NOT NULL,
    "ChargePeriodEnd" timestamptz NOT NULL,
    "ChargeCategory" text NOT NULL,
    "ChargeClass" text,
    "ChargeDescription" text,
    "ChargeFrequency" text,
    "ChargeSubcategory" text,
    "ConsumedQuantity" numeric(20, 6),
    "ConsumedUnit" text,
    "ContractedCost" numeric(20, 6),
    "EffectiveCost" numeric(20, 6) NOT NULL,
    "ListCost" numeric(20, 6),
    "PricingQuantity" numeric(20, 6),
    "PricingUnit" text,
    "ProviderName" text NOT NULL,
    "PublisherName" text,
    "RegionId" text,
    "RegionName" text,
    "ResourceId" text,
    "ResourceName" text,
    "ResourceType" text,
    "ServiceCategory" text,
    "ServiceName" text NOT NULL,
    "SkuId" text,
    "SkuPriceId" text,
    "SubAccountId" text,
    "SubAccountName" text,
    "Tags" jsonb NOT NULL DEFAULT '{}'::jsonb,
    "x_DemoEnvironment" text,
    "CreatedAt" timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE focus.cost_usage IS
    'FOCUS 成本與用量示範資料表，保存跨雲供應商的每日費用、用量、資源與標籤資訊。';

COMMENT ON COLUMN focus.cost_usage."Id" IS
    '資料列流水號，作為本示範資料表的 PostgreSQL 主鍵。';
COMMENT ON COLUMN focus.cost_usage."BillingAccountId" IS
    '帳單帳戶識別碼，代表雲端供應商帳務層級的帳號或付款帳戶。';
COMMENT ON COLUMN focus.cost_usage."BillingAccountName" IS
    '帳單帳戶顯示名稱，方便人工辨識付款帳戶或合約帳戶。';
COMMENT ON COLUMN focus.cost_usage."BillingCurrency" IS
    '帳單使用的三碼貨幣代碼，例如 USD。';
COMMENT ON COLUMN focus.cost_usage."BillingPeriodStart" IS
    '帳單週期開始時間，使用含時區時間戳記。';
COMMENT ON COLUMN focus.cost_usage."BillingPeriodEnd" IS
    '帳單週期結束時間，使用含時區時間戳記。';
COMMENT ON COLUMN focus.cost_usage."ChargePeriodStart" IS
    '此筆費用或用量紀錄的計費期間開始時間。';
COMMENT ON COLUMN focus.cost_usage."ChargePeriodEnd" IS
    '此筆費用或用量紀錄的計費期間結束時間。';
COMMENT ON COLUMN focus.cost_usage."ChargeCategory" IS
    '費用類別，例如用量、購買、稅金、調整或折抵。';
COMMENT ON COLUMN focus.cost_usage."ChargeClass" IS
    '費用分類，用來區分標準費用、修正、承諾折扣等情境。';
COMMENT ON COLUMN focus.cost_usage."ChargeDescription" IS
    '費用項目的文字描述，說明此筆成本或用量的來源。';
COMMENT ON COLUMN focus.cost_usage."ChargeFrequency" IS
    '費用發生頻率，例如用量型、一次性或週期性費用。';
COMMENT ON COLUMN focus.cost_usage."ChargeSubcategory" IS
    '費用子類別，補充說明更細的收費或折扣類型。';
COMMENT ON COLUMN focus.cost_usage."ConsumedQuantity" IS
    '實際消耗量，搭配 ConsumedUnit 解讀，例如小時、請求數或容量。';
COMMENT ON COLUMN focus.cost_usage."ConsumedUnit" IS
    '實際消耗量單位，例如 Hour、Request、GB-Month 或 GiBy。';
COMMENT ON COLUMN focus.cost_usage."ContractedCost" IS
    '依合約價格計算出的成本，未必等同於最終有效成本。';
COMMENT ON COLUMN focus.cost_usage."EffectiveCost" IS
    '有效成本，代表分攤、折扣或調整後用於分析的成本金額。';
COMMENT ON COLUMN focus.cost_usage."ListCost" IS
    '依公開牌價或清單價格計算出的成本。';
COMMENT ON COLUMN focus.cost_usage."PricingQuantity" IS
    '計價用量，搭配 PricingUnit 解讀，可能與實際消耗量不同。';
COMMENT ON COLUMN focus.cost_usage."PricingUnit" IS
    '計價單位，例如 Hour、Request、GB-Month 或 GiBy。';
COMMENT ON COLUMN focus.cost_usage."ProviderName" IS
    '雲端服務供應商名稱，例如 AWS、Microsoft 或 Google Cloud。';
COMMENT ON COLUMN focus.cost_usage."PublisherName" IS
    '費用發布者或服務發布者名稱，通常與供應商相同或為 Marketplace 發布者。';
COMMENT ON COLUMN focus.cost_usage."RegionId" IS
    '雲端區域識別碼，例如 us-east-1、eastus 或 asia-east1。';
COMMENT ON COLUMN focus.cost_usage."RegionName" IS
    '雲端區域顯示名稱，例如 US East 或 Taiwan。';
COMMENT ON COLUMN focus.cost_usage."ResourceId" IS
    '雲端資源唯一識別碼，用於追蹤成本來源資源。';
COMMENT ON COLUMN focus.cost_usage."ResourceName" IS
    '雲端資源顯示名稱，方便人工閱讀與報表呈現。';
COMMENT ON COLUMN focus.cost_usage."ResourceType" IS
    '資源類型，例如 Database、Virtual Machine、Dataset 或 Storage Bucket。';
COMMENT ON COLUMN focus.cost_usage."ServiceCategory" IS
    '服務大類，例如 Compute、Database、Storage 或 Analytics。';
COMMENT ON COLUMN focus.cost_usage."ServiceName" IS
    '雲端服務名稱，例如 Amazon RDS、Virtual Machines、BigQuery 或 Cloud Run。';
COMMENT ON COLUMN focus.cost_usage."SkuId" IS
    '雲端服務 SKU 識別碼，用於表示產品規格或計價項目。';
COMMENT ON COLUMN focus.cost_usage."SkuPriceId" IS
    'SKU 價格識別碼，用於表示特定區域、方案或計價價格。';
COMMENT ON COLUMN focus.cost_usage."SubAccountId" IS
    '子帳戶、專案或訂閱識別碼，本示範用來代表 project。';
COMMENT ON COLUMN focus.cost_usage."SubAccountName" IS
    '子帳戶、專案或訂閱顯示名稱。';
COMMENT ON COLUMN focus.cost_usage."Tags" IS
    '資源或成本分攤標籤，使用 JSONB 保存 owner、app、env、cost_center 等維度。';
COMMENT ON COLUMN focus.cost_usage."x_DemoEnvironment" IS
    '示範用擴充欄位，表示資料所屬環境，例如 prod、stage 或 dev。';
COMMENT ON COLUMN focus.cost_usage."CreatedAt" IS
    '資料列建立時間，由 PostgreSQL 預設為目前時間。';

CREATE INDEX IF NOT EXISTS idx_cost_usage_charge_period
    ON focus.cost_usage ("ChargePeriodStart", "ChargePeriodEnd");

CREATE INDEX IF NOT EXISTS idx_cost_usage_provider_service
    ON focus.cost_usage ("ProviderName", "ServiceName");

CREATE INDEX IF NOT EXISTS idx_cost_usage_tags_gin
    ON focus.cost_usage USING gin ("Tags");
