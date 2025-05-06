DECLARE input_make   STRING DEFAULT 'Chevrolet';
DECLARE input_model  STRING DEFAULT 'Camaro';
DECLARE input_year   INT64  DEFAULT 74;

WITH
  risk_scores_all AS (
    SELECT
      v.MAKE,
      v.MODEL,
      v.MOD_YEAR,
      SUM(CASE WHEN v.DEATHS > 0 THEN 2 ELSE 1 END)                     AS raw_risk,
      AVG(
        IF(s.NMHELMET = 'Yes', 1, 0)
      + IF(s.NMPROPAD = 'Yes', 1, 0)
      + IF(s.NMOTHPRO = 'Yes', 1, 0)
      + IF(s.NMREFCLO = 'Yes', 1, 0)
      + IF(s.NMLIGHT = 'Yes', 1, 0)
      + IF(s.NMOTHPRE = 'Yes', 1, 0)
      )                                                                  AS avg_safety_eq_count
    FROM
      `bigquery-public-data.dataflix_traffic_safety.vehicle` AS v
    LEFT JOIN
      `bigquery-public-data.dataflix_traffic_safety.safetyeq` AS s
    USING (STATE, ST_CASE, L_YEAR, VEH_NO)
    GROUP BY
      MAKE, MODEL, MOD_YEAR
  ),
  adj_risks AS (
    SELECT
      MAKE,
      MODEL,
      MOD_YEAR,
      raw_risk    / (1 + IFNULL(avg_safety_eq_count, 0))                AS adjusted_risk
    FROM
      risk_scores_all
  ),
  target AS (
    SELECT
      adjusted_risk AS t_risk
    FROM
      adj_risks
    WHERE
      MAKE     = input_make
      AND MODEL  = input_model
      AND MOD_YEAR = input_year
  ),
  stats AS (
    SELECT
      COUNTIF(adjusted_risk <= t.t_risk)                              AS le_count,
      COUNT(*)                                                        AS total_count
    FROM
      adj_risks
    CROSS JOIN
      target AS t
  )
SELECT
  ROUND(le_count / total_count * 30, 2)                               AS estimated_safety_discount_percent
FROM
  stats;
