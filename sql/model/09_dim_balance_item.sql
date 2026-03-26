-- =============================================================================
-- CONTRACT FIRST — Weekend 3: Dim_BalanceItem
-- =============================================================================
-- 142 balance item codes grouped into categories.
-- Eurostat NRG_BAL codes define what aspect of energy balance the row measures.
-- =============================================================================

CREATE OR REPLACE TABLE dim_balance_item AS

WITH balance_categories AS (
    SELECT * FROM (VALUES
        ('PPRD',            'Primary production',                   'Supply'),
        ('IMP',             'Imports',                              'Supply'),
        ('EXP',             'Exports',                              'Supply'),
        ('STK_CHG',         'Stock changes',                        'Supply'),
        ('NRGSUP',          'Total energy supply',                  'Supply'),
        ('GAE',             'Gross available energy',               'Supply'),
        ('GIC',             'Gross inland consumption',             'Supply'),
        ('STATDIFF',        'Statistical difference',               'Supply'),
        ('INTMARB',         'International maritime bunkers',        'Supply'),
        ('INTAVI',          'International aviation',                'Supply'),

        ('TI_E',            'Transformation input — total',          'Transformation'),
        ('TI_EHG_E',        'Transformation input — electricity',    'Transformation'),
        ('TI_EHG_MAPE_E',   'Transformation input — main activity', 'Transformation'),
        ('TO',              'Transformation output — total',         'Transformation'),

        ('NRG_E',           'Energy sector — total',                'Energy sector'),
        ('DL',              'Distribution losses',                  'Energy sector'),
        ('NRG_CM_E',        'Coal mines',                           'Energy sector'),
        ('NRG_BF_E',        'Blast furnaces',                       'Energy sector'),

        ('AFC',             'Available for final consumption',      'Consumption'),
        ('FC_E',            'Final consumption — total',            'Consumption'),
        ('FC_IND_E',        'Industry — total',                     'Consumption'),
        ('FC_TRA_E',        'Transport — total',                    'Consumption'),
        ('FC_OTH_E',        'Other sectors — total',                'Consumption'),
        ('FC_OTH_HH_E',    'Households',                           'Consumption'),
        ('FC_OTH_CP_E',     'Commerce and public services',         'Consumption'),
        ('FC_OTH_NSP_E',    'Not specified',                        'Consumption'),
        ('FEC2020-2030',    'Final energy consumption (EU target)',  'Consumption'),
        ('PEC2020-2030',    'Primary energy consumption (EU target)','Consumption'),
        ('GIC2020-2030',    'Gross inland consumption (EU target)',  'Consumption'),
        ('FEC_EED',         'Final consumption (EED)',               'Consumption'),
        ('PEC_EED',         'Primary consumption (EED)',             'Consumption'),
        ('GIC_EED',         'Gross inland consumption (EED)',        'Consumption')
    ) AS t(balance_code, balance_name, balance_category)
),

actual_items AS (
    SELECT DISTINCT balance_item AS balance_code
    FROM stg_energy_clean
)

SELECT
    ROW_NUMBER() OVER (ORDER BY ai.balance_code) AS balance_key,
    ai.balance_code,
    COALESCE(bc.balance_name, ai.balance_code) AS balance_name,
    COALESCE(bc.balance_category, 'Other') AS balance_category
FROM actual_items ai
LEFT JOIN balance_categories bc ON ai.balance_code = bc.balance_code
ORDER BY ai.balance_code;

-- Verify
SELECT COUNT(*) AS balance_count FROM dim_balance_item;
SELECT balance_category, COUNT(*) AS items FROM dim_balance_item GROUP BY balance_category ORDER BY items DESC;
