WITH
  crashes AS (
    SELECT
      a.COUNTY,
      COUNTIF(v.SOE = 'Pedestrian') AS pedestrian_count,
      COUNTIF(v.SOE = 'Fire/Explosion') AS fire_count,
      COUNTIF(v.SOE = 'Motor Vehicle in Transport') AS motor_count,
      COUNTIF(v.SOE = 'Rollover/Overturn') AS rollover_count,
      COUNT(*) AS total_count
    FROM 
      `bigquery-public-data.dataflix_traffic_safety.accident` a
    JOIN 
      `bigquery-public-data.dataflix_traffic_safety.vsoe` v
    
    ON v.ST_CASE = a.ST_CASE AND v.L_YEAR = a.YEAR
    WHERE a.STATE = @state
    GROUP BY a.COUNTY
  ),

  score1 AS (
    SELECT
      COUNTY,
      (
        (
          SAFE_DIVIDE(pedestrian_count, total_count) * 1.7 +
          SAFE_DIVIDE(fire_count, total_count) * 1.8 +
          SAFE_DIVIDE(motor_count, total_count) * 1.2 +
          SAFE_DIVIDE(rollover_count, total_count) * 1.5 +
          SAFE_DIVIDE(
            total_count - pedestrian_count - fire_count - motor_count - rollover_count,
            total_count
          ) * 1.0
        ) * LOG(total_count + 1)
      ) AS raw_score
    FROM crashes
    WHERE total_count > 0 AND COUNTY IS NOT NULL
  )

SELECT
  COUNTY,
  ROUND((raw_score / MAX(raw_score) OVER ()) * 100, 2) AS risk_score
FROM score1
ORDER BY risk_score DESC;