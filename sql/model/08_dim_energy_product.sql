-- =============================================================================
-- CONTRACT FIRST — Weekend 3: Dim_EnergyProduct
-- =============================================================================
-- 72 products with 3-level hierarchy reconstructed from Eurostat SIEC codes.
-- Eurostat does NOT provide an explicit parent-child mapping.
-- This hierarchy was built manually from SIEC documentation.
-- =============================================================================

CREATE OR REPLACE TABLE dim_energy_product AS

WITH product_hierarchy AS (
    SELECT * FROM (VALUES
        -- TOTAL
        ('TOTAL',           'Total',                        'Total',            'Total',                'Total'),
        ('FE',              'Fossil energy',                'Total',            'Fossil energy',        'Fossil energy'),
        ('BIOE',            'Bioenergy',                    'Total',            'Bioenergy',            'Bioenergy'),

        -- SOLID FOSSIL FUELS
        ('C0000X0350-0370', 'Solid fossil fuels',           'Solid fossil fuels','Solid fossil fuels',  'Solid fossil fuels'),
        ('C0350-0370',      'Peat and peat products',       'Solid fossil fuels','Peat',                'Peat and peat products'),
        ('P1000',           'Peat',                         'Solid fossil fuels','Peat',                'Peat'),

        -- OIL AND PETROLEUM
        ('O4000XBIO',       'Oil and petroleum products',   'Oil and petroleum','Oil total',            'Oil and petroleum products'),
        ('O4100_TOT',       'Crude oil',                    'Oil and petroleum','Crude oil',            'Crude oil total'),
        ('O4200',           'Natural gas liquids',          'Oil and petroleum','NGL',                  'Natural gas liquids'),
        ('O4300',           'Additives and oxygenates',     'Oil and petroleum','Additives',            'Additives and oxygenates'),
        ('O4400X4410',      'Refinery feedstocks',          'Oil and petroleum','Refinery',             'Refinery feedstocks'),
        ('O4500',           'Other hydrocarbons',           'Oil and petroleum','Other hydro',          'Other hydrocarbons'),
        ('O4610',           'Refinery gas',                 'Oil and petroleum','Refined products',     'Refinery gas'),
        ('O4620',           'Ethane',                       'Oil and petroleum','Refined products',     'Ethane'),
        ('O4630',           'LPG',                          'Oil and petroleum','Refined products',     'LPG'),
        ('O4640',           'Naphtha',                      'Oil and petroleum','Refined products',     'Naphtha'),
        ('O4651',           'Motor gasoline excl bio',      'Oil and petroleum','Refined products',     'Motor gasoline'),
        ('O4652XR5210B',    'Aviation gasoline',            'Oil and petroleum','Refined products',     'Aviation gasoline'),
        ('O4653',           'Gasoline-type jet fuel',       'Oil and petroleum','Refined products',     'Gasoline jet fuel'),
        ('O4661XR5230B',    'Kerosene-type jet fuel',       'Oil and petroleum','Refined products',     'Kerosene jet fuel'),
        ('O4669',           'Other kerosene',               'Oil and petroleum','Refined products',     'Other kerosene'),
        ('O4671XR5220B',    'Gas/diesel oil excl bio',      'Oil and petroleum','Refined products',     'Gas diesel oil'),
        ('O4680',           'Fuel oil',                     'Oil and petroleum','Refined products',     'Fuel oil'),
        ('O4691',           'White spirit',                 'Oil and petroleum','Refined products',     'White spirit'),
        ('O4692',           'Lubricants',                   'Oil and petroleum','Refined products',     'Lubricants'),
        ('O4693',           'Bitumen',                      'Oil and petroleum','Refined products',     'Bitumen'),
        ('O4694',           'Paraffin waxes',               'Oil and petroleum','Refined products',     'Paraffin waxes'),
        ('O4695',           'Petroleum coke',               'Oil and petroleum','Refined products',     'Petroleum coke'),
        ('O4699',           'Other petroleum products',     'Oil and petroleum','Refined products',     'Other petroleum'),

        -- NATURAL GAS
        ('G3000',           'Natural gas',                  'Natural gas',      'Natural gas',          'Natural gas'),

        -- RENEWABLES
        ('RA000',           'Renewables and biofuels',      'Renewables',       'Renewables total',     'Renewables and biofuels'),
        ('RA100',           'Renewables (specific)',         'Renewables',       'Renewables specific',  'Renewables specific'),
        ('RA110',           'Hydro',                        'Renewables',       'Hydro',                'Hydro'),
        ('RA120',           'Geothermal',                   'Renewables',       'Geothermal',           'Geothermal'),
        ('RA130',           'Wind',                         'Renewables',       'Wind',                 'Wind'),
        ('RA200',           'Solar',                        'Renewables',       'Solar',                'Solar'),
        ('RA300',           'Tide wave ocean',              'Renewables',       'Marine',               'Tide wave ocean'),
        ('RA410',           'Biogasoline',                  'Renewables',       'Biofuels',             'Biogasoline'),
        ('RA420',           'Biodiesels',                   'Renewables',       'Biofuels',             'Biodiesels'),
        ('RA500',           'Biogas',                       'Renewables',       'Biogas',               'Biogas'),
        ('RA600',           'Renewable municipal waste',    'Renewables',       'Waste',                'Renewable municipal waste'),

        -- NUCLEAR
        ('N9000',           'Nuclear heat',                 'Nuclear',          'Nuclear',              'Nuclear heat'),
        ('N900H',           'Nuclear heat (derived)',        'Nuclear',          'Nuclear',              'Nuclear heat derived'),

        -- ELECTRICITY AND HEAT
        ('E7000',           'Electricity',                  'Electricity',      'Electricity',          'Electricity'),
        ('H8000',           'Heat',                         'Heat',             'Heat',                 'Heat'),

        -- WASTE
        ('W6100',           'Industrial waste',             'Waste',            'Industrial waste',     'Industrial waste'),
        ('W6210',           'Renewable municipal waste',    'Waste',            'Municipal waste',      'Renewable municipal waste'),
        ('W6220',           'Non-renewable municipal waste','Waste',            'Municipal waste',      'Non-renewable municipal waste'),

        -- BLENDED BIOFUELS
        ('R5110-5150_W6000','Solid biofuels and waste',     'Renewables',       'Solid biofuels',       'Solid biofuels and waste'),
        ('R5160',           'Charcoal',                     'Renewables',       'Solid biofuels',       'Charcoal'),
        ('R5210B',          'Biogasoline blend',            'Renewables',       'Biofuels',             'Biogasoline blend'),
        ('R5220B',          'Biodiesel blend',              'Renewables',       'Biofuels',             'Biodiesel blend'),
        ('R5230B',          'Bio jet kerosene blend',       'Renewables',       'Biofuels',             'Bio jet kerosene blend'),
        ('R5230P',          'Bio jet kerosene pure',        'Renewables',       'Biofuels',             'Bio jet kerosene pure')
    ) AS t(product_code, product_name, level1_category, level2_group, level3_detail)
),

-- Get all product codes actually in the data
actual_products AS (
    SELECT DISTINCT energy_product AS product_code
    FROM stg_energy_clean
)

SELECT
    ROW_NUMBER() OVER (ORDER BY ap.product_code) AS product_key,
    ap.product_code,
    COALESCE(ph.product_name, ap.product_code) AS product_name,
    COALESCE(ph.level1_category, 'Other') AS level1_category,
    COALESCE(ph.level2_group, 'Other') AS level2_group,
    COALESCE(ph.level3_detail, ap.product_code) AS level3_detail
FROM actual_products ap
LEFT JOIN product_hierarchy ph ON ap.product_code = ph.product_code
ORDER BY ap.product_code;

-- Verify
SELECT COUNT(*) AS product_count FROM dim_energy_product;
SELECT level1_category, COUNT(*) AS products FROM dim_energy_product GROUP BY level1_category ORDER BY products DESC;
SELECT * FROM dim_energy_product WHERE level1_category = 'Other' ORDER BY product_code;
