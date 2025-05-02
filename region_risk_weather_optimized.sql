WITH
  bad_rate AS(
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
      )/COUNT(*) AS bad_Weather_rate
    FROM 
      `bigquery-public-data.dataflix_traffic_safety.accident`
    WHERE 
      STATE = @state
    GROUP BY 
      COUNTY
  ),
  score2 AS(
    SELECT COUNTY, bad_Weather_rate,(bad_Weather_rate/MAX(bad_Weather_rate) OVER())*100 AS risk_score
    FROM bad_rate
    ORDER BY risk_score DESC
  )

  SELECT *
  FROM score2
