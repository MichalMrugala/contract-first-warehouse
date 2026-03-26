-- =============================================================================
-- CONTRACT FIRST — Weekend 3: Dim_Country
-- =============================================================================
-- 40 individual countries. Aggregates (EU27_2020) EXCLUDED.
-- Decision: aggregates out. If users need EU totals, they SUM countries.
-- =============================================================================

CREATE OR REPLACE TABLE dim_country AS

WITH country_mapping AS (
    SELECT * FROM (VALUES
        ('AL', 'Albania', 'Southern Europe'),
        ('AT', 'Austria', 'Western Europe'),
        ('BA', 'Bosnia and Herzegovina', 'Southern Europe'),
        ('BE', 'Belgium', 'Western Europe'),
        ('BG', 'Bulgaria', 'Eastern Europe'),
        ('CY', 'Cyprus', 'Southern Europe'),
        ('CZ', 'Czechia', 'Eastern Europe'),
        ('DE', 'Germany', 'Western Europe'),
        ('DK', 'Denmark', 'Northern Europe'),
        ('EE', 'Estonia', 'Northern Europe'),
        ('EL', 'Greece', 'Southern Europe'),
        ('ES', 'Spain', 'Southern Europe'),
        ('FI', 'Finland', 'Northern Europe'),
        ('FR', 'France', 'Western Europe'),
        ('GE', 'Georgia', 'Eastern Europe'),
        ('HR', 'Croatia', 'Southern Europe'),
        ('HU', 'Hungary', 'Eastern Europe'),
        ('IE', 'Ireland', 'Northern Europe'),
        ('IS', 'Iceland', 'Northern Europe'),
        ('IT', 'Italy', 'Southern Europe'),
        ('LT', 'Lithuania', 'Northern Europe'),
        ('LU', 'Luxembourg', 'Western Europe'),
        ('LV', 'Latvia', 'Northern Europe'),
        ('MD', 'Moldova', 'Eastern Europe'),
        ('ME', 'Montenegro', 'Southern Europe'),
        ('MK', 'North Macedonia', 'Southern Europe'),
        ('MT', 'Malta', 'Southern Europe'),
        ('NL', 'Netherlands', 'Western Europe'),
        ('NO', 'Norway', 'Northern Europe'),
        ('PL', 'Poland', 'Eastern Europe'),
        ('PT', 'Portugal', 'Southern Europe'),
        ('RO', 'Romania', 'Eastern Europe'),
        ('RS', 'Serbia', 'Southern Europe'),
        ('SE', 'Sweden', 'Northern Europe'),
        ('SI', 'Slovenia', 'Southern Europe'),
        ('SK', 'Slovakia', 'Eastern Europe'),
        ('TR', 'Turkey', 'Southern Europe'),
        ('UA', 'Ukraine', 'Eastern Europe'),
        ('UK', 'United Kingdom', 'Northern Europe'),
        ('XK', 'Kosovo', 'Southern Europe')
    ) AS t(geo_code, country_name, region)
)

SELECT
    ROW_NUMBER() OVER (ORDER BY cm.geo_code) AS country_key,
    cm.geo_code,
    cm.country_name,
    cm.region,
    COALESCE(stats.total_observations, 0) AS total_observations,
    COALESCE(stats.years_covered, 0) AS years_covered,
    COALESCE(stats.first_year, 0) AS first_year,
    COALESCE(stats.last_year, 0) AS last_year
FROM country_mapping cm
LEFT JOIN (
    SELECT
        country_code,
        COUNT(*) AS total_observations,
        COUNT(DISTINCT year) AS years_covered,
        MIN(year) AS first_year,
        MAX(year) AS last_year
    FROM stg_energy_clean
    WHERE LENGTH(country_code) = 2
    GROUP BY country_code
) stats ON cm.geo_code = stats.country_code
ORDER BY cm.geo_code;

-- Verify
SELECT COUNT(*) AS country_count FROM dim_country;
SELECT * FROM dim_country ORDER BY country_key LIMIT 5;
