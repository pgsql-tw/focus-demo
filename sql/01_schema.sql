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

CREATE INDEX IF NOT EXISTS idx_cost_usage_charge_period
    ON focus.cost_usage ("ChargePeriodStart", "ChargePeriodEnd");

CREATE INDEX IF NOT EXISTS idx_cost_usage_provider_service
    ON focus.cost_usage ("ProviderName", "ServiceName");

CREATE INDEX IF NOT EXISTS idx_cost_usage_tags_gin
    ON focus.cost_usage USING gin ("Tags");
