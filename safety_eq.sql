DECLARE input_make   STRING DEFAULT 'Chevrolet';
DECLARE input_model  STRING DEFAULT 'Camaro';
DECLARE input_year   INT64  DEFAULT 74;

WITH
risk_scores_all AS (
  SELECT
    v.MAKE,
    v.MODEL,
    v.MOD_YEAR,
    SUM(CASE WHEN v.DEATHS > 0 THEN 2 ELSE 1 END) AS raw_risk,
    AVG(
      SAFE_CAST(
        (CASE WHEN s.NMHELMET = 'Yes' THEN 1 ELSE 0 END)
      + (CASE WHEN s.NMPROPAD = 'Yes' THEN 1 ELSE 0 END)
      + (CASE WHEN s.NMOTHPRO = 'Yes' THEN 1 ELSE 0 END)
      + (CASE WHEN s.NMREFCLO = 'Yes' THEN 1 ELSE 0 END)
      + (CASE WHEN s.NMLIGHT = 'Yes'  THEN 1 ELSE 0 END)
      + (CASE WHEN s.NMOTHPRE = 'Yes' THEN 1 ELSE 0 END)
      AS FLOAT64)
    )                                               AS avg_safety_eq_count
  FROM
    `bigquery-public-data.dataflix_traffic_safety.vehicle` AS v
  LEFT JOIN
    `bigquery-public-data.dataflix_traffic_safety.safetyeq` AS s
  USING (STATE, ST_CASE, L_YEAR, VEH_NO)
  GROUP BY MAKE, MODEL, MOD_YEAR
),
target AS (
  SELECT
    MAKE, MODEL, MOD_YEAR,
    raw_risk,
    raw_risk / (1 + IFNULL(avg_safety_eq_count, 0)) AS adjusted_risk
  FROM risk_scores_all
  WHERE MAKE     = input_make
    AND MODEL    = input_model
    AND MOD_YEAR = input_year
)
SELECT
  t.MAKE,
  t.MODEL,
  t.MOD_YEAR,
  t.adjusted_risk,
  ROUND(
    (
      (SELECT COUNT(*)
         FROM risk_scores_all AS r2
        WHERE r2.raw_risk / (1 + IFNULL(r2.avg_safety_eq_count, 0)) 
              <= t.adjusted_risk
      )
      /
      (SELECT COUNT(*) FROM risk_scores_all)
    ) * 30
  , 2) AS estimated_safety_discount_percent
FROM target AS t;
