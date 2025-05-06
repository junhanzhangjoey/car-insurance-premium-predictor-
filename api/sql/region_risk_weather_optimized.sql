-- region_risk_weather_by_county.sql

DECLARE input_state  STRING DEFAULT "California";
DECLARE input_county STRING DEFAULT "SANTA CLARA (85)";

WITH bad_rate AS (
  SELECT 
    COUNTY,
    COUNTIF(
      WEATHER IN (
        'Freezing Rain or Drizzle',
        'Blowing Snow',
        'Rain',
        'Snow',
        'Fog, Smog, Smoke',
        'Severe Crosswinds',
        'Blowing Sand, Soil, Dirt'
      )
    ) / COUNT(*) AS bad_weather_rate
  FROM 
    `bigquery-public-data.dataflix_traffic_safety.accident`
  WHERE 
    STATE = input_state
  GROUP BY 
    COUNTY
),
score2 AS (
  SELECT
    COUNTY,
    bad_weather_rate,
    SAFE_DIVIDE(bad_weather_rate, MAX(bad_weather_rate) OVER()) * 100 AS raw_score
  FROM bad_rate
)
SELECT
  ROUND(raw_score, 2) AS weather_risk_score
FROM score2
WHERE COUNTY = input_county;
