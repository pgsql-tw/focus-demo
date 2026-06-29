# FOCUS Demo Notes

FOCUS is the FinOps Open Cost and Usage Specification. It defines common names, meanings, and expected behavior for cloud cost and usage data so teams can compare spend across providers and internal platforms.

This demo intentionally keeps the table compact. It includes common Cost and Usage dimensions and metrics:

- account context: `"BillingAccountId"`, `"SubAccountId"`
- time windows: `"BillingPeriodStart"`, `"ChargePeriodStart"`
- charge semantics: `"ChargeCategory"`, `"ChargeClass"`, `"ChargeFrequency"`
- cost metrics: `"ListCost"`, `"ContractedCost"`, `"EffectiveCost"`
- usage metrics: `"ConsumedQuantity"`, `"ConsumedUnit"`, `"PricingQuantity"`, `"PricingUnit"`
- provider and service context: `"ProviderName"`, `"ServiceName"`, `"ServiceCategory"`
- resource context: `"ResourceId"`, `"ResourceName"`, `"ResourceType"`
- allocation context: `"Tags"`

Use the sample queries to explain common FinOps workflows:

- daily cost by provider
- service cost grouped by owner tag
- resource unit economics
- basic data quality checks before analysis
