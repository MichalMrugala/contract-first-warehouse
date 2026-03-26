-- =============================================================================
-- CONTRACT FIRST — Weekend 3: Dim_ObsStatus
-- =============================================================================
-- Minimal dimension for audit trail. 2 rows.
-- In fact table context only 'measured' rows exist.
-- Exists for documentation and future extensibility.
-- =============================================================================

CREATE OR REPLACE TABLE dim_obs_status AS

SELECT * FROM (VALUES
    (1, 'measured', 'Validated observation with numeric value', true),
    (2, 'missing',  'Observation flagged m by Eurostat — unavailable or confidential', false)
) AS t(obs_status_key, status_code, status_description, is_measured);

-- Verify
SELECT * FROM dim_obs_status;
