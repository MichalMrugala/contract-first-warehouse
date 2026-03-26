-- =============================================================================
-- CONTRACT FIRST — Weekend 3: Dim_Year
-- =============================================================================
-- 35 rows (1990-2024). Year key = year itself (natural key as surrogate).
-- Attributes for easy Power BI filtering without DAX.
-- =============================================================================

CREATE OR REPLACE TABLE dim_year AS

SELECT
    year AS year_key,
    year,
    CAST(FLOOR(year / 10) * 10 AS VARCHAR) || 's' AS decade,
    year >= 2000 AS is_post_2000,
    year >= 2010 AS is_post_2010,
    year >= 2020 AS is_post_2020
FROM generate_series(1990, 2024) AS t(year);

-- Verify
SELECT COUNT(*) AS year_count FROM dim_year;
SELECT * FROM dim_year WHERE year IN (1990, 2000, 2010, 2020, 2024);
