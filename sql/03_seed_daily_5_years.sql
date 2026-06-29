TRUNCATE TABLE focus.cost_usage RESTART IDENTITY;

WITH days AS (
    SELECT generate_series(
        '2022-01-01'::date,
        '2026-12-31'::date,
        '1 day'::interval
    )::date AS charge_day
),
clouds AS (
    SELECT *
    FROM (VALUES
        (
            'AWS', 'AWS', 'ba-aws-001', 'Shared AWS Payer',
            'aws-prj', 'AWS Project', 'us-east-1', 'US East (N. Virginia)'
        ),
        (
            'Microsoft', 'Microsoft', 'ba-azure-002', 'Azure Enterprise Agreement',
            'az-prj', 'Azure Project', 'eastus', 'East US'
        ),
        (
            'Google Cloud', 'Google Cloud', 'ba-gcp-003', 'GCP Billing Account',
            'gcp-prj', 'GCP Project', 'asia-east1', 'Taiwan'
        )
    ) AS cloud_def (
        provider_name, publisher_name, billing_account_id, billing_account_name,
        project_prefix, project_label, region_id, region_name
    )
),
patterns AS (
    SELECT *
    FROM (VALUES
        (0, 'orders', 'platform', 'finops', 'steady-prod', 1.00),
        (1, 'api', 'app-team', 'product', 'business-hours', 0.86),
        (2, 'etl', 'data', 'finance', 'weekend-batch', 1.18),
        (3, 'finance-mart', 'analytics', 'finance', 'month-end-burst', 0.92),
        (4, 'ml-training', 'data-science', 'research', 'seasonal-training', 1.35),
        (5, 'checkout', 'app-team', 'product', 'growth-spiky', 1.10)
    ) AS pattern_def (
        pattern_id, app, owner, cost_center, workload_pattern, project_scale
    )
),
projects AS (
    SELECT
        c.*,
        p.project_no,
        format('%s-%s', c.project_prefix, lpad(p.project_no::text, 2, '0')) AS project_id,
        format('%s %s', c.project_label, lpad(p.project_no::text, 2, '0')) AS project_name,
        patterns.app,
        patterns.owner,
        patterns.cost_center,
        patterns.workload_pattern,
        patterns.project_scale,
        CASE
            WHEN p.project_no <= 18 THEN 'prod'
            WHEN p.project_no <= 24 THEN 'stage'
            ELSE 'dev'
        END AS env
    FROM clouds c
    CROSS JOIN generate_series(1, 30) AS p(project_no)
    JOIN patterns
        ON patterns.pattern_id = (p.project_no - 1) % 6
),
service_catalog AS (
    SELECT *
    FROM (VALUES
        (
            'AWS', 1, 'Database', 'Amazon RDS',
            'PostgreSQL-compatible database compute hours',
            'Database', 'db.m6g.large', 'ondemand-us-east-1-db.m6g.large',
            'Hour', 48.000000, 0.330000, 0.400000
        ),
        (
            'AWS', 2, 'Storage', 'Amazon S3',
            'Object storage requests and capacity',
            'Storage Bucket', 'standard-storage', 's3-standard-us-east-1',
            'GB-Month', 920.000000, 0.023500, 0.025000
        ),
        (
            'AWS', 3, 'Compute', 'AWS Lambda',
            'Serverless function requests and duration',
            'Function', 'lambda-requests', 'lambda-requests-us-east-1',
            'Request', 860000.000000, 0.000010, 0.000012
        ),
        (
            'Microsoft', 1, 'Compute', 'Virtual Machines',
            'Virtual machine compute usage',
            'Virtual Machine', 'D4s_v5', 'paygo-eastus-d4s-v5',
            'Hour', 72.000000, 0.520000, 0.600000
        ),
        (
            'Microsoft', 2, 'Database', 'Azure Database for PostgreSQL',
            'Azure Database for PostgreSQL storage',
            'Database', 'storage-p10', 'postgres-storage-eastus',
            'GB-Month', 512.000000, 0.115000, 0.125000
        ),
        (
            'Microsoft', 3, 'Analytics', 'Azure Synapse Analytics',
            'Dedicated SQL pool compute usage',
            'Data Warehouse', 'dw100c', 'synapse-dw100c-eastus',
            'Hour', 24.000000, 1.200000, 1.350000
        ),
        (
            'Google Cloud', 1, 'Analytics', 'BigQuery',
            'BigQuery analysis bytes processed',
            'Dataset', 'analysis', 'bq-analysis-asia-east1',
            'GiBy', 1830.000000, 0.005000, 0.005000
        ),
        (
            'Google Cloud', 2, 'Compute', 'Cloud Run',
            'Cloud Run request and CPU allocation',
            'Service', 'requests', 'cloud-run-requests-asia-east1',
            'Request', 1250000.000000, 0.000009, 0.000010
        ),
        (
            'Google Cloud', 3, 'Storage', 'Cloud Storage',
            'Cloud Storage standard capacity',
            'Storage Bucket', 'standard-storage', 'gcs-standard-asia-east1',
            'GB-Month', 760.000000, 0.020000, 0.023000
        )
    ) AS service_def (
        provider_name, service_ordinal, service_category, service_name,
        charge_description, resource_type, sku_id, sku_price_id,
        consumed_unit, base_quantity, contracted_unit_cost, list_unit_cost
    )
),
project_services AS (
    SELECT
        p.*,
        s.service_ordinal,
        s.service_category,
        s.service_name,
        s.charge_description,
        s.resource_type,
        s.sku_id,
        s.sku_price_id,
        s.consumed_unit,
        s.base_quantity,
        s.contracted_unit_cost,
        s.list_unit_cost,
        CASE p.provider_name
            WHEN 'AWS' THEN format(
                'arn:aws:focus:%s:111122223333:%s/%s-%s',
                p.region_id,
                lower(replace(s.service_name, ' ', '-')),
                p.project_id,
                s.service_ordinal
            )
            WHEN 'Microsoft' THEN format(
                '/subscriptions/%s/resourceGroups/rg-%s/providers/Microsoft.Focus/%s/%s-%s',
                p.project_id,
                p.project_id,
                replace(s.service_name, ' ', ''),
                p.project_id,
                s.service_ordinal
            )
            ELSE format(
                '//focus.googleapis.com/projects/%s/locations/%s/services/%s-%s',
                p.project_id,
                p.region_id,
                lower(replace(s.service_name, ' ', '-')),
                s.service_ordinal
            )
        END AS resource_id,
        format(
            '%s-%s-%s',
            p.app,
            lower(regexp_replace(s.service_name, '[^a-zA-Z0-9]+', '-', 'g')),
            lpad(p.project_no::text, 2, '0')
        ) AS resource_name
    FROM projects p
    JOIN service_catalog s
        ON s.provider_name = p.provider_name
),
daily_usage AS (
    SELECT
        d.charge_day,
        ps.*,
        CASE ps.workload_pattern
            WHEN 'steady-prod' THEN
                1.000000
                + (EXTRACT(DOY FROM d.charge_day)::int % 17) * 0.003000
            WHEN 'business-hours' THEN
                CASE WHEN EXTRACT(ISODOW FROM d.charge_day)::int BETWEEN 1 AND 5
                    THEN 1.180000
                    ELSE 0.380000
                END
            WHEN 'weekend-batch' THEN
                CASE WHEN EXTRACT(ISODOW FROM d.charge_day)::int IN (6, 7)
                    THEN 1.700000
                    ELSE 0.720000
                END
            WHEN 'month-end-burst' THEN
                CASE WHEN d.charge_day >= (date_trunc('month', d.charge_day::timestamp) + interval '24 days')::date
                    THEN 1.820000
                    ELSE 0.760000
                END
            WHEN 'seasonal-training' THEN
                CASE WHEN EXTRACT(MONTH FROM d.charge_day)::int IN (3, 6, 9, 12)
                    THEN 1.650000
                    ELSE 0.700000
                END
            WHEN 'growth-spiky' THEN
                0.850000
                + (EXTRACT(YEAR FROM d.charge_day)::int - 2022) * 0.120000
                + CASE WHEN EXTRACT(DOY FROM d.charge_day)::int % 29 = 0
                    THEN 0.900000
                    ELSE 0.000000
                  END
            ELSE 1.000000
        END
        * (1.000000 + (EXTRACT(YEAR FROM d.charge_day)::int - 2022) * 0.045000)
        * project_scale
        * (1.000000 + (project_no % 10) * 0.018000)
        * CASE env
            WHEN 'prod' THEN 1.000000
            WHEN 'stage' THEN 0.430000
            ELSE 0.180000
          END
        * CASE service_ordinal
            WHEN 1 THEN 1.000000
            WHEN 2 THEN 0.620000
            ELSE 0.440000
          END AS usage_factor
    FROM days d
    CROSS JOIN project_services ps
)
INSERT INTO focus.cost_usage (
    "BillingAccountId", "BillingAccountName", "BillingCurrency",
    "BillingPeriodStart", "BillingPeriodEnd", "ChargePeriodStart", "ChargePeriodEnd",
    "ChargeCategory", "ChargeClass", "ChargeDescription", "ChargeFrequency", "ChargeSubcategory",
    "ConsumedQuantity", "ConsumedUnit", "ContractedCost", "EffectiveCost", "ListCost",
    "PricingQuantity", "PricingUnit", "ProviderName", "PublisherName", "RegionId", "RegionName",
    "ResourceId", "ResourceName", "ResourceType", "ServiceCategory", "ServiceName",
    "SkuId", "SkuPriceId", "SubAccountId", "SubAccountName", "Tags", "x_DemoEnvironment"
)
SELECT
    billing_account_id,
    billing_account_name,
    'USD',
    date_trunc('month', charge_day::timestamp) AT TIME ZONE 'UTC',
    (date_trunc('month', charge_day::timestamp) + interval '1 month') AT TIME ZONE 'UTC',
    charge_day::timestamp AT TIME ZONE 'UTC',
    (charge_day::timestamp + interval '1 day') AT TIME ZONE 'UTC',
    'Usage',
    'Standard',
    charge_description,
    'Usage-Based',
    'On-Demand',
    round((base_quantity * usage_factor)::numeric, 6),
    consumed_unit,
    round((base_quantity * usage_factor * contracted_unit_cost)::numeric, 6),
    round((base_quantity * usage_factor * contracted_unit_cost * 0.900000)::numeric, 6),
    round((base_quantity * usage_factor * list_unit_cost)::numeric, 6),
    round((base_quantity * usage_factor)::numeric, 6),
    consumed_unit,
    provider_name,
    publisher_name,
    region_id,
    region_name,
    resource_id,
    resource_name,
    resource_type,
    service_category,
    service_name,
    sku_id,
    sku_price_id,
    project_id,
    project_name,
    jsonb_build_object(
        'app', app,
        'owner', owner,
        'env', env,
        'project', project_id,
        'cost_center', cost_center,
        'workload_pattern', workload_pattern
    ),
    env
FROM daily_usage
ORDER BY charge_day, provider_name, project_id, service_ordinal;
