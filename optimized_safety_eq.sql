-- 1. declare your three inputs
DECLARE input_make   STRING DEFAULT 'Chevrolet';
DECLARE input_model  STRING DEFAULT 'Camaro';
DECLARE input_year   INT64  DEFAULT 1974;

WITH
vehicle_stats_all AS (
  SELECT
    v.MAKE,
    v.MODEL,
    v.MOD_YEAR,
    COUNT(*)                                            AS total_crashes,
    SUM(CASE WHEN v.DEATHS > 0 THEN 1 ELSE 0 END)       AS serious_accidents,
    AVG(
      SAFE_CAST(
        (CASE WHEN s.NMHELMET = 'Yes'   THEN 1 ELSE 0 END) +
        (CASE WHEN s.NMPROPAD = 'Yes'   THEN 1 ELSE 0 END) +
        (CASE WHEN s.NMOTHPRO = 'Yes'   THEN 1 ELSE 0 END) +
        (CASE WHEN s.NMREFCLO = 'Yes'   THEN 1 ELSE 0 END) +
        (CASE WHEN s.NMLIGHT = 'Yes'    THEN 1 ELSE 0 END) +
        (CASE WHEN s.NMOTHPRE = 'Yes'   THEN 1 ELSE 0 END)
      AS FLOAT64)
    )                                                   AS avg_safety_eq_count
  FROM
    `bigquery-public-data.dataflix_traffic_safety.vehicle`  v
  LEFT JOIN
    `bigquery-public-data.dataflix_traffic_safety.safetyeq` s
  USING (STATE, ST_CASE, L_YEAR, VEH_NO)
  WHERE
    v.MAKE     = input_make
    AND v.MODEL = input_model
    AND v.MOD_YEAR = input_year
  GROUP BY
    v.MAKE, v.MODEL, v.MOD_YEAR
),
risk_scores_all AS (
  SELECT
    MAKE,
    MODEL,
    MOD_YEAR,
    total_crashes,
    serious_accidents,
    avg_safety_eq_count,
    (serious_accidents * 2 + (total_crashes - serious_accidents))     AS raw_risk,
    (serious_accidents * 2 + (total_crashes - serious_accidents))
      / (1 + IFNULL(avg_safety_eq_count, 0))                           AS adjusted_risk
  FROM vehicle_stats_all
),
ranked AS (
  SELECT
    *,
    NTILE(100) OVER (ORDER BY adjusted_risk ASC)                       AS risk_percentile
  FROM risk_scores_all
)
SELECT
  MAKE,
  MODEL,
  MOD_YEAR,
  total_crashes,
  serious_accidents,
  avg_safety_eq_count,
  adjusted_risk,
  ROUND(risk_percentile / 100.0 * 30, 2)                               AS estimated_safety_discount_percent
FROM
  ranked;
