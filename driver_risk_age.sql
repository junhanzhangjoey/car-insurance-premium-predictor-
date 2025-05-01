WITH total_fatalities AS (
  SELECT SUM(a.FATALS) AS overall_total
  FROM `bigquery-public-data.dataflix_traffic_safety.person` p
  JOIN `bigquery-public-data.dataflix_traffic_safety.accident` a
    ON p.ST_CASE = a.ST_CASE AND p.L_YEAR = a.L_YEAR
  WHERE p.PER_TYP = "Driver of a Motor Vehicle in Transport"
    AND p.AGE BETWEEN 5 AND 94
    AND p.STATE = 'California'
),
age_group_fatalities AS (
  SELECT
    CONCAT(FLOOR(p.AGE / 5) * 5, '-', FLOOR(p.AGE / 5) * 5 + 4) AS age_group,
    SUM(a.FATALS) AS total_fatalities
  FROM `bigquery-public-data.dataflix_traffic_safety.person` p
  JOIN `bigquery-public-data.dataflix_traffic_safety.accident` a
    ON p.ST_CASE = a.ST_CASE AND p.L_YEAR = a.L_YEAR 
  WHERE p.PER_TYP = "Driver of a Motor Vehicle in Transport"
    AND p.AGE BETWEEN 5 AND 94
    AND p.STATE = 'California'
  GROUP BY age_group
)
SELECT ROUND(agf.total_fatalities / tf.overall_total, 4) AS fatality_ratio
FROM age_group_fatalities agf, total_fatalities tf
WHERE agf.age_group = CONCAT(FLOOR(34 / 5) * 5, '-', FLOOR(34 / 5) * 5 + 4);
