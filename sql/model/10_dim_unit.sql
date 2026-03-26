-- =============================================================================
-- CONTRACT FIRST — Weekend 3: Dim_Unit
-- =============================================================================
-- 3 rows. Simplest dimension. Conversion factors included for reference.
-- Decision: keep all 3 units in fact table. Unit = slicer, not calculation.
-- =============================================================================

CREATE OR REPLACE TABLE dim_unit AS

SELECT * FROM (VALUES
    (1, 'TJ',   'Terajoules',                    1.0),
    (2, 'KTOE', 'Kilotonnes of oil equivalent',  41.868),
    (3, 'GWH',  'Gigawatt hours',                3.6)
) AS t(unit_key, unit_code, unit_name, conversion_to_tj);

-- Verify
SELECT * FROM dim_unit;
