CREATE SCHEMA IF NOT EXISTS focus;
CREATE SCHEMA IF NOT EXISTS business;

DROP TABLE IF EXISTS business.project_cloud_accounts;
DROP TABLE IF EXISTS business.cloud_accounts;
DROP TABLE IF EXISTS business.company_projects;

DROP TABLE IF EXISTS focus.cost_usage;

CREATE TABLE focus.cost_usage (
    "AllocatedMethodDetails" jsonb,
    "AllocatedMethodId" text,
    "AllocatedResourceId" text,
    "AllocatedResourceName" text,
    "AllocatedTags" jsonb,
    "AvailabilityZone" text,
    "BilledCost" numeric(20, 6),
    "BillingAccountId" text NOT NULL,
    "BillingAccountName" text,
    "BillingAccountType" text,
    "BillingCurrency" char(3) NOT NULL,
    "BillingPeriodCreated" timestamptz,
    "BillingPeriodEnd" timestamptz NOT NULL,
    "BillingPeriodLastUpdated" timestamptz,
    "BillingPeriodStart" timestamptz NOT NULL,
    "BillingPeriodStatus" text,
    "CapacityReservationId" text,
    "CapacityReservationStatus" text,
    "ChargeCategory" text NOT NULL,
    "ChargeClass" text,
    "ChargeDescription" text,
    "ChargeFrequency" text,
    "ChargePeriodEnd" timestamptz NOT NULL,
    "ChargePeriodStart" timestamptz NOT NULL,
    "CommitmentDiscountCategory" text,
    "CommitmentDiscountId" text,
    "CommitmentDiscountName" text,
    "CommitmentDiscountQuantity" numeric(20, 6),
    "CommitmentDiscountStatus" text,
    "CommitmentDiscountType" text,
    "CommitmentDiscountUnit" text,
    "CommitmentProgramEligibilityDetails" jsonb,
    "ConsumedQuantity" numeric(20, 6),
    "ConsumedUnit" text,
    "ContractApplied" boolean,
    "ContractCommitmentApplicability" text,
    "ContractCommitmentBenefitCategory" text,
    "ContractCommitmentCategory" text,
    "ContractCommitmentCost" numeric(20, 6),
    "ContractCommitmentCreated" timestamptz,
    "ContractCommitmentDescription" text,
    "ContractCommitmentDiscountPercentage" numeric(20, 6),
    "ContractCommitmentDurationType" text,
    "ContractCommitmentFulfillmentInterval" text,
    "ContractCommitmentId" text,
    "ContractCommitmentLastUpdated" timestamptz,
    "ContractCommitmentLifecycleStatus" text,
    "ContractCommitmentModel" text,
    "ContractCommitmentOfferCategory" text,
    "ContractCommitmentPaymentInterval" text,
    "ContractCommitmentPaymentModel" text,
    "ContractCommitmentPaymentUpfrontPercentage" numeric(20, 6),
    "ContractCommitmentPeriodEnd" timestamptz,
    "ContractCommitmentPeriodStart" timestamptz,
    "ContractCommitmentQuantity" numeric(20, 6),
    "ContractCommitmentType" text,
    "ContractCommitmentUnit" text,
    "ContractId" text,
    "ContractPeriodEnd" timestamptz,
    "ContractPeriodStart" timestamptz,
    "ContractedCost" numeric(20, 6),
    "ContractedUnitPrice" numeric(20, 6),
    "EffectiveCost" numeric(20, 6) NOT NULL,
    "HostProviderName" text,
    "InvoiceDetailCreated" timestamptz,
    "InvoiceDetailDescription" text,
    "InvoiceDetailGrain" text,
    "InvoiceDetailId" text,
    "InvoiceDetailLastUpdated" timestamptz,
    "InvoiceId" text,
    "InvoiceIssueDate" date,
    "InvoiceIssueStatus" text,
    "InvoiceIssuerName" text,
    "ListCost" numeric(20, 6),
    "ListUnitPrice" numeric(20, 6),
    "PaymentCurrency" char(3),
    "PaymentCurrencyBilledCost" numeric(20, 6),
    "PaymentCurrencyInvoiceDetailId" text,
    "PaymentDueDate" date,
    "PaymentTerms" text,
    "PricingCategory" text,
    "PricingCurrency" char(3),
    "PricingCurrencyContractCommitmentCost" numeric(20, 6),
    "PricingCurrencyContractedUnitPrice" numeric(20, 6),
    "PricingCurrencyEffectiveCost" numeric(20, 6),
    "PricingCurrencyListUnitPrice" numeric(20, 6),
    "PricingQuantity" numeric(20, 6),
    "PricingUnit" text,
    "PurchaseOrderNumber" text,
    "ReferenceInvoiceId" text,
    "RegionId" text,
    "RegionName" text,
    "ResourceId" text,
    "ResourceName" text,
    "ResourceType" text,
    "ServiceCategory" text,
    "ServiceName" text NOT NULL,
    "ServiceProviderName" text NOT NULL,
    "ServiceSubcategory" text,
    "SkuId" text,
    "SkuMeter" text,
    "SkuPriceDetails" jsonb,
    "SkuPriceId" text,
    "SubAccountId" text,
    "SubAccountName" text,
    "SubAccountType" text,
    "Tags" jsonb NOT NULL DEFAULT '{}'::jsonb
);

COMMENT ON TABLE focus.cost_usage IS
    'FOCUS v1.4 Cost and Usage 完整標準資料表，保存跨雲帳單、用量、價格、合約、發票、資源與標籤等成本明細。';

COMMENT ON COLUMN focus.cost_usage."AllocatedMethodDetails" IS
    '描述成本分攤方法的細節，例如分攤規則、依據或分攤流程的補充資訊。';

COMMENT ON COLUMN focus.cost_usage."AllocatedMethodId" IS
    '成本分攤方法的識別碼，用來追蹤此筆成本是透過哪一個分攤方法產生。';

COMMENT ON COLUMN focus.cost_usage."AllocatedResourceId" IS
    '分攤後成本歸屬的資源識別碼，可能不同於原始消耗資源。';

COMMENT ON COLUMN focus.cost_usage."AllocatedResourceName" IS
    '分攤後成本歸屬的資源顯示名稱，供報表與人工辨識使用。';

COMMENT ON COLUMN focus.cost_usage."AllocatedTags" IS
    '分攤後套用於成本歸屬對象的標籤集合。';

COMMENT ON COLUMN focus.cost_usage."AvailabilityZone" IS
    '產生成本或用量的可用區名稱或代碼。';

COMMENT ON COLUMN focus.cost_usage."BilledCost" IS
    '供應商在帳單幣別中實際列帳的成本金額。';

COMMENT ON COLUMN focus.cost_usage."BillingAccountId" IS
    '雲端或 SaaS 供應商帳單帳戶的唯一識別碼。';

COMMENT ON COLUMN focus.cost_usage."BillingAccountName" IS
    '帳單帳戶的顯示名稱，方便辨識付款帳戶或合約帳戶。';

COMMENT ON COLUMN focus.cost_usage."BillingAccountType" IS
    '帳單帳戶類型，例如組織帳戶、企業合約帳戶或付款帳戶。';

COMMENT ON COLUMN focus.cost_usage."BillingCurrency" IS
    '供應商開立帳單使用的三碼貨幣代碼。';

COMMENT ON COLUMN focus.cost_usage."BillingPeriodCreated" IS
    '此帳單週期資料首次建立或發布的時間。';

COMMENT ON COLUMN focus.cost_usage."BillingPeriodEnd" IS
    '帳單週期結束時間，通常為不含尾端的期間界線。';

COMMENT ON COLUMN focus.cost_usage."BillingPeriodLastUpdated" IS
    '此帳單週期資料最後更新的時間。';

COMMENT ON COLUMN focus.cost_usage."BillingPeriodStart" IS
    '帳單週期開始時間。';

COMMENT ON COLUMN focus.cost_usage."BillingPeriodStatus" IS
    '帳單週期狀態，例如開放、最終版或已關閉。';

COMMENT ON COLUMN focus.cost_usage."CapacityReservationId" IS
    '與此費用相關的容量保留或容量預留識別碼。';

COMMENT ON COLUMN focus.cost_usage."CapacityReservationStatus" IS
    '容量保留在此費用期間的使用或閒置狀態。';

COMMENT ON COLUMN focus.cost_usage."ChargeCategory" IS
    '費用高階類別，例如用量、購買、稅金、信用折抵或調整。';

COMMENT ON COLUMN focus.cost_usage."ChargeClass" IS
    '費用分類，用來區分標準費用、修正、承諾折扣或其他特殊處理。';

COMMENT ON COLUMN focus.cost_usage."ChargeDescription" IS
    '費用項目的文字描述，說明此筆成本或用量的來源。';

COMMENT ON COLUMN focus.cost_usage."ChargeFrequency" IS
    '費用發生頻率，例如一次性、週期性或依用量計費。';

COMMENT ON COLUMN focus.cost_usage."ChargePeriodEnd" IS
    '此筆費用或用量涵蓋期間的結束時間。';

COMMENT ON COLUMN focus.cost_usage."ChargePeriodStart" IS
    '此筆費用或用量涵蓋期間的開始時間。';

COMMENT ON COLUMN focus.cost_usage."CommitmentDiscountCategory" IS
    '承諾折扣的高階類別，例如保留執行個體、Savings Plan 或承諾用量方案。';

COMMENT ON COLUMN focus.cost_usage."CommitmentDiscountId" IS
    '承諾折扣資產或折扣方案的識別碼。';

COMMENT ON COLUMN focus.cost_usage."CommitmentDiscountName" IS
    '承諾折扣資產或折扣方案的顯示名稱。';

COMMENT ON COLUMN focus.cost_usage."CommitmentDiscountQuantity" IS
    '承諾折扣涵蓋的數量，例如保留容量、用量或單位數。';

COMMENT ON COLUMN focus.cost_usage."CommitmentDiscountStatus" IS
    '承諾折扣在此費用期間的狀態，例如已使用、未使用或閒置。';

COMMENT ON COLUMN focus.cost_usage."CommitmentDiscountType" IS
    '承諾折扣的類型或供應商方案類型。';

COMMENT ON COLUMN focus.cost_usage."CommitmentDiscountUnit" IS
    '承諾折扣數量的單位。';

COMMENT ON COLUMN focus.cost_usage."CommitmentProgramEligibilityDetails" IS
    '描述此筆用量是否符合承諾方案資格的細節。';

COMMENT ON COLUMN focus.cost_usage."ConsumedQuantity" IS
    '實際消耗量，需搭配 ConsumedUnit 解讀。';

COMMENT ON COLUMN focus.cost_usage."ConsumedUnit" IS
    '實際消耗量單位，例如 Hour、Request、GB-Month 或 GiBy。';

COMMENT ON COLUMN focus.cost_usage."ContractApplied" IS
    '標示此筆費用是否套用了合約、企業協議或私有價格條款。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentApplicability" IS
    '描述合約承諾是否適用於此筆費用或用量。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentBenefitCategory" IS
    '合約承諾帶來的優惠或效益類別。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentCategory" IS
    '合約承諾的高階分類，例如用量承諾或金額承諾。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentCost" IS
    '此筆資料中與合約承諾相關的成本金額。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentCreated" IS
    '合約承諾建立或生效記錄建立的時間。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentDescription" IS
    '合約承諾條款或承諾內容的文字描述。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentDiscountPercentage" IS
    '合約承諾提供的折扣百分比。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentDurationType" IS
    '合約承諾期間類型，例如固定期限、月繳或年度承諾。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentFulfillmentInterval" IS
    '衡量合約承諾履約或用量達成情況的時間間隔。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentId" IS
    '合約承諾項目的唯一識別碼。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentLastUpdated" IS
    '合約承諾資料最後更新的時間。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentLifecycleStatus" IS
    '合約承諾的生命週期狀態，例如啟用、過期或取消。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentModel" IS
    '合約承諾的計算或商業模型。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentOfferCategory" IS
    '合約承諾對應的供應商優惠或方案類別。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentPaymentInterval" IS
    '合約承諾付款的頻率或間隔。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentPaymentModel" IS
    '合約承諾付款模型，例如預付、後付或部分預付。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentPaymentUpfrontPercentage" IS
    '合約承諾中預付款占總承諾金額的比例。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentPeriodEnd" IS
    '合約承諾期間的結束時間。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentPeriodStart" IS
    '合約承諾期間的開始時間。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentQuantity" IS
    '合約承諾的數量或承諾用量。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentType" IS
    '合約承諾的類型。';

COMMENT ON COLUMN focus.cost_usage."ContractCommitmentUnit" IS
    '合約承諾數量的單位。';

COMMENT ON COLUMN focus.cost_usage."ContractId" IS
    '與此筆成本相關的合約識別碼。';

COMMENT ON COLUMN focus.cost_usage."ContractPeriodEnd" IS
    '合約期間的結束時間。';

COMMENT ON COLUMN focus.cost_usage."ContractPeriodStart" IS
    '合約期間的開始時間。';

COMMENT ON COLUMN focus.cost_usage."ContractedCost" IS
    '依合約價格計算出的成本金額。';

COMMENT ON COLUMN focus.cost_usage."ContractedUnitPrice" IS
    '依合約條款計算出的單位價格。';

COMMENT ON COLUMN focus.cost_usage."EffectiveCost" IS
    '用於成本分析與分攤的有效成本，通常已反映折扣、抵免或分攤效果。';

COMMENT ON COLUMN focus.cost_usage."HostProviderName" IS
    '實際承載資源或服務的供應商名稱。';

COMMENT ON COLUMN focus.cost_usage."InvoiceDetailCreated" IS
    '發票明細資料建立的時間。';

COMMENT ON COLUMN focus.cost_usage."InvoiceDetailDescription" IS
    '發票明細項目的文字描述。';

COMMENT ON COLUMN focus.cost_usage."InvoiceDetailGrain" IS
    '發票明細資料的粒度，例如明細列、彙總列或調整列。';

COMMENT ON COLUMN focus.cost_usage."InvoiceDetailId" IS
    '發票明細項目的識別碼。';

COMMENT ON COLUMN focus.cost_usage."InvoiceDetailLastUpdated" IS
    '發票明細資料最後更新的時間。';

COMMENT ON COLUMN focus.cost_usage."InvoiceId" IS
    '此筆費用所屬發票的識別碼。';

COMMENT ON COLUMN focus.cost_usage."InvoiceIssueDate" IS
    '發票開立日期。';

COMMENT ON COLUMN focus.cost_usage."InvoiceIssueStatus" IS
    '發票開立狀態，例如已開立、待開立或已作廢。';

COMMENT ON COLUMN focus.cost_usage."InvoiceIssuerName" IS
    '開立發票的供應商、代理商或法人實體名稱。';

COMMENT ON COLUMN focus.cost_usage."ListCost" IS
    '依公開牌價或清單價格計算的成本金額。';

COMMENT ON COLUMN focus.cost_usage."ListUnitPrice" IS
    '公開牌價或清單價格的單位價格。';

COMMENT ON COLUMN focus.cost_usage."PaymentCurrency" IS
    '實際付款使用的三碼貨幣代碼。';

COMMENT ON COLUMN focus.cost_usage."PaymentCurrencyBilledCost" IS
    '以付款幣別表示的列帳成本金額。';

COMMENT ON COLUMN focus.cost_usage."PaymentCurrencyInvoiceDetailId" IS
    '付款幣別下對應的發票明細識別碼。';

COMMENT ON COLUMN focus.cost_usage."PaymentDueDate" IS
    '此筆發票或費用的付款到期日。';

COMMENT ON COLUMN focus.cost_usage."PaymentTerms" IS
    '付款條件，例如付款天數、預付或月結條款。';

COMMENT ON COLUMN focus.cost_usage."PricingCategory" IS
    '計價方式分類，例如隨用隨付、承諾、階梯或合約價格。';

COMMENT ON COLUMN focus.cost_usage."PricingCurrency" IS
    '計價所使用的三碼貨幣代碼。';

COMMENT ON COLUMN focus.cost_usage."PricingCurrencyContractCommitmentCost" IS
    '以計價幣別表示的合約承諾成本。';

COMMENT ON COLUMN focus.cost_usage."PricingCurrencyContractedUnitPrice" IS
    '以計價幣別表示的合約單位價格。';

COMMENT ON COLUMN focus.cost_usage."PricingCurrencyEffectiveCost" IS
    '以計價幣別表示的有效成本。';

COMMENT ON COLUMN focus.cost_usage."PricingCurrencyListUnitPrice" IS
    '以計價幣別表示的清單單位價格。';

COMMENT ON COLUMN focus.cost_usage."PricingQuantity" IS
    '用於計價的數量，可能與實際消耗量不同。';

COMMENT ON COLUMN focus.cost_usage."PricingUnit" IS
    '計價數量的單位。';

COMMENT ON COLUMN focus.cost_usage."PurchaseOrderNumber" IS
    '採購單號或內部採購參考編號。';

COMMENT ON COLUMN focus.cost_usage."ReferenceInvoiceId" IS
    '此筆費用、調整或折抵所參照的原始發票識別碼。';

COMMENT ON COLUMN focus.cost_usage."RegionId" IS
    '產生成本或用量的雲端區域識別碼。';

COMMENT ON COLUMN focus.cost_usage."RegionName" IS
    '產生成本或用量的雲端區域顯示名稱。';

COMMENT ON COLUMN focus.cost_usage."ResourceId" IS
    '產生成本或用量的資源唯一識別碼。';

COMMENT ON COLUMN focus.cost_usage."ResourceName" IS
    '產生成本或用量的資源顯示名稱。';

COMMENT ON COLUMN focus.cost_usage."ResourceType" IS
    '產生成本或用量的資源類型，例如資料庫、虛擬機、資料集或儲存桶。';

COMMENT ON COLUMN focus.cost_usage."ServiceCategory" IS
    '服務大類，例如 Compute、Storage、Database 或 Analytics。';

COMMENT ON COLUMN focus.cost_usage."ServiceName" IS
    '供應商服務名稱，例如 Amazon RDS、Virtual Machines、BigQuery 或 Cloud Run。';

COMMENT ON COLUMN focus.cost_usage."ServiceProviderName" IS
    '提供服務並回報此筆成本資料的雲端或 SaaS 供應商名稱。';

COMMENT ON COLUMN focus.cost_usage."ServiceSubcategory" IS
    '服務子類別，用於比 ServiceCategory 更細的服務分類。';

COMMENT ON COLUMN focus.cost_usage."SkuId" IS
    '供應商 SKU 識別碼，代表可被計價的產品或服務規格。';

COMMENT ON COLUMN focus.cost_usage."SkuMeter" IS
    'SKU 對應的計量項目或 meter 名稱。';

COMMENT ON COLUMN focus.cost_usage."SkuPriceDetails" IS
    'SKU 價格的補充細節，例如階梯、區域、條款或計價屬性。';

COMMENT ON COLUMN focus.cost_usage."SkuPriceId" IS
    'SKU 價格識別碼，用於區分同一 SKU 在不同價格條件下的計價項目。';

COMMENT ON COLUMN focus.cost_usage."SubAccountId" IS
    '子帳戶、訂閱、專案或資源群組等成本歸屬層級的識別碼。';

COMMENT ON COLUMN focus.cost_usage."SubAccountName" IS
    '子帳戶、訂閱、專案或資源群組等成本歸屬層級的顯示名稱。';

COMMENT ON COLUMN focus.cost_usage."SubAccountType" IS
    '子帳戶層級的類型，例如 Project、Subscription 或 Account。';

COMMENT ON COLUMN focus.cost_usage."Tags" IS
    '供應商或使用者套用於成本、資源或帳戶的標籤集合，用於分攤與治理分析。';
CREATE INDEX IF NOT EXISTS idx_cost_usage_charge_period
    ON focus.cost_usage ("ChargePeriodStart", "ChargePeriodEnd");

CREATE INDEX IF NOT EXISTS idx_cost_usage_provider_service
    ON focus.cost_usage ("ServiceProviderName", "ServiceName");

CREATE INDEX IF NOT EXISTS idx_cost_usage_tags_gin
    ON focus.cost_usage USING gin ("Tags");

COMMENT ON INDEX focus.idx_cost_usage_charge_period IS
    '加速依費用期間查詢 FOCUS 成本與用量資料。';

COMMENT ON INDEX focus.idx_cost_usage_provider_service IS
    '加速依雲端服務供應商與服務名稱彙總 FOCUS 成本。';

COMMENT ON INDEX focus.idx_cost_usage_tags_gin IS
    '加速查詢 Tags JSONB 中的 owner、app、env、cost_center 等標籤。';

CREATE TABLE business.company_projects (
    project_id text PRIMARY KEY,
    project_name text NOT NULL,
    business_unit text NOT NULL,
    product_owner text NOT NULL,
    environment text NOT NULL,
    lifecycle_status text NOT NULL,
    start_date date NOT NULL,
    end_date date,
    tags jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE business.cloud_accounts (
    cloud_account_key text PRIMARY KEY,
    service_provider_name text NOT NULL,
    billing_account_id text NOT NULL,
    billing_account_name text,
    sub_account_id text NOT NULL,
    sub_account_name text,
    account_type text NOT NULL,
    environment text NOT NULL,
    tags jsonb NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_cloud_accounts_focus_account UNIQUE (service_provider_name, billing_account_id, sub_account_id)
);

CREATE TABLE business.project_cloud_accounts (
    project_id text NOT NULL REFERENCES business.company_projects (project_id),
    cloud_account_key text NOT NULL REFERENCES business.cloud_accounts (cloud_account_key),
    allocation_weight numeric(9, 6) NOT NULL DEFAULT 1.000000,
    is_primary boolean NOT NULL DEFAULT false,
    relationship_note text,
    PRIMARY KEY (project_id, cloud_account_key),
    CHECK (allocation_weight > 0)
);

COMMENT ON TABLE business.company_projects IS
    '公司業務專案主檔，用於將內部專案對應到一個或多個雲端帳戶。';

COMMENT ON TABLE business.cloud_accounts IS
    '雲端帳戶業務主檔，保存可與 FOCUS 成本資料對應的帳單帳戶與子帳戶。';

COMMENT ON TABLE business.project_cloud_accounts IS
    '業務專案與雲端帳戶的多對多對應表，支援單雲與跨雲專案成本分攤。';

COMMENT ON COLUMN business.company_projects.project_id IS
    '公司內部業務專案的穩定識別碼，用於和雲端帳戶對應。';

COMMENT ON COLUMN business.company_projects.project_name IS
    '公司內部業務專案的顯示名稱，供報表與人工辨識使用。';

COMMENT ON COLUMN business.company_projects.business_unit IS
    '負責此業務專案的公司部門或事業單位。';

COMMENT ON COLUMN business.company_projects.product_owner IS
    '此業務專案的產品或系統負責團隊。';

COMMENT ON COLUMN business.company_projects.environment IS
    '此業務專案所屬環境，例如 prod、stage 或 dev。';

COMMENT ON COLUMN business.company_projects.lifecycle_status IS
    '此業務專案的生命週期狀態，例如 Active、Planned 或 Retired。';

COMMENT ON COLUMN business.company_projects.start_date IS
    '此業務專案開始納入成本追蹤的日期。';

COMMENT ON COLUMN business.company_projects.end_date IS
    '此業務專案停止成本追蹤的日期；仍在使用時為 NULL。';

COMMENT ON COLUMN business.company_projects.tags IS
    '此業務專案的補充分類標籤，例如成本中心、重要性或內部管理維度。';

COMMENT ON COLUMN business.cloud_accounts.cloud_account_key IS
    '雲端帳戶對應表的穩定鍵值，通常由雲別、帳單帳戶與子帳戶組成。';

COMMENT ON COLUMN business.cloud_accounts.service_provider_name IS
    '雲端服務供應商名稱，需對應 FOCUS 欄位 ServiceProviderName。';

COMMENT ON COLUMN business.cloud_accounts.billing_account_id IS
    '雲端帳單帳戶識別碼，需對應 FOCUS 欄位 BillingAccountId。';

COMMENT ON COLUMN business.cloud_accounts.billing_account_name IS
    '雲端帳單帳戶顯示名稱，供人工辨識使用。';

COMMENT ON COLUMN business.cloud_accounts.sub_account_id IS
    '雲端子帳戶、訂閱或專案識別碼，需對應 FOCUS 欄位 SubAccountId。';

COMMENT ON COLUMN business.cloud_accounts.sub_account_name IS
    '雲端子帳戶、訂閱或專案顯示名稱。';

COMMENT ON COLUMN business.cloud_accounts.account_type IS
    '雲端帳戶類型，例如 Project、Subscription 或 Account。';

COMMENT ON COLUMN business.cloud_accounts.environment IS
    '此雲端帳戶主要承載的環境，例如 prod、stage 或 dev。';

COMMENT ON COLUMN business.cloud_accounts.tags IS
    '此雲端帳戶的補充分類標籤，例如 landing zone、雲別或治理維度。';

COMMENT ON COLUMN business.project_cloud_accounts.project_id IS
    '業務專案識別碼，參照 business.company_projects.project_id。';

COMMENT ON COLUMN business.project_cloud_accounts.cloud_account_key IS
    '雲端帳戶鍵值，參照 business.cloud_accounts.cloud_account_key。';

COMMENT ON COLUMN business.project_cloud_accounts.allocation_weight IS
    '此業務專案分攤該雲端帳戶成本的權重，用於 showback 或 chargeback。';

COMMENT ON COLUMN business.project_cloud_accounts.is_primary IS
    '標示該雲端帳戶是否為此業務專案的主要雲端落點。';

COMMENT ON COLUMN business.project_cloud_accounts.relationship_note IS
    '描述此業務專案與該雲端帳戶關係的補充說明。';

CREATE INDEX IF NOT EXISTS idx_cloud_accounts_focus_lookup
    ON business.cloud_accounts (service_provider_name, billing_account_id, sub_account_id);

CREATE INDEX IF NOT EXISTS idx_project_cloud_accounts_account
    ON business.project_cloud_accounts (cloud_account_key);

COMMENT ON INDEX business.company_projects_pkey IS
    '維護業務專案識別碼的唯一性並加速專案查找。';

COMMENT ON INDEX business.cloud_accounts_pkey IS
    '維護雲端帳戶鍵值的唯一性並加速帳戶查找。';

COMMENT ON INDEX business.uq_cloud_accounts_focus_account IS
    '確保同一組 FOCUS 供應商、帳單帳戶與子帳戶只對應一筆業務帳戶。';

COMMENT ON INDEX business.project_cloud_accounts_pkey IS
    '維護業務專案與雲端帳戶對應關係的唯一性。';

COMMENT ON INDEX business.idx_cloud_accounts_focus_lookup IS
    '加速從 FOCUS 成本資料欄位對應到業務雲端帳戶。';

COMMENT ON INDEX business.idx_project_cloud_accounts_account IS
    '加速從雲端帳戶反查相關業務專案。';
