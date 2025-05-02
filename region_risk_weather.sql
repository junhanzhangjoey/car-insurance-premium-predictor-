WITH
  raw AS (
    SELECT *
    FROM `bigquery-public-data.dataflix_traffic_safety.accident`
    WHERE TRUE
  ),

  bad_rate AS (
    SELECT 
      COUNTY,
      SUM(
        CASE
          WHEN WEATHER = 'Freezing Rain or Drizzle' THEN 1
          WHEN WEATHER = 'Blowing Snow' THEN 1
          WHEN WEATHER = 'Rain' THEN 1
          WHEN WEATHER = 'Snow' THEN 1
          WHEN WEATHER = 'Fog, Smog, Smoke' THEN 1
          WHEN WEATHER = 'Severe Crosswinds' THEN 1
          WHEN WEATHER = 'Blowing Sand, Soil, Dirt' THEN 1
          ELSE 0
        END
      ) AS bad_count,
      COUNT(*) AS total_count
    FROM raw
    WHERE STATE = @state OR STATE IS NULL 
    GROUP BY COUNTY
    ORDER BY total_count DESC
  ),

  score2 AS (
    SELECT
      *,
      SAFE_DIVIDE(bad_count, total_count) AS bad_weather_rate
    FROM bad_rate
  )

SELECT
  COUNTY,
  ROUND((bad_weather_rate / MAX(bad_weather_rate) OVER()) * 100, 2) AS risk_score
FROM score2
ORDER BY risk_score DESC;

