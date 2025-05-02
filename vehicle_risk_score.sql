DECLARE input_make   STRING DEFAULT 'Chevrolet';
DECLARE input_model  STRING DEFAULT 'Camaro';
DECLARE input_year   INT64  DEFAULT 74;

WITH
  group_metrics AS (
    SELECT
      MAKE,
      MODEL,
      MOD_YEAR,
      COUNT(*)                            AS accidents_count,
      SUM(SAFE_CAST(ROLLOVER AS INT64))   AS rollover_count,
      SUM(SAFE_CAST(FIRE_EXP AS INT64))   AS fire_exp_count,
      SUM(SAFE_CAST(PREV_ACC AS INT64))   AS prev_acc_count,
      2025 - MOD_YEAR                     AS vehicle_age
    FROM
      `bigquery-public-data.dataflix_traffic_safety.vehicle`
    WHERE
      MAKE    IS NOT NULL
      AND MODEL IS NOT NULL
      AND MOD_YEAR IS NOT NULL
    GROUP BY
      MAKE, MODEL, MOD_YEAR
  ),
  stats AS (
    SELECT
      MAX(accidents_count)  OVER() AS max_accidents,
      MAX(vehicle_age)       OVER() AS max_age,
      MAX(rollover_count)    OVER() AS max_rollover,
      MAX(fire_exp_count)    OVER() AS max_fire_exp,
      MAX(prev_acc_count)    OVER() AS max_prev_acc
    FROM
      group_metrics
    LIMIT 1
  ),
  combined AS (
    SELECT
      gm.MAKE,
      gm.MODEL,
      gm.MOD_YEAR,
      COALESCE(gm.accidents_count/NULLIF(s.max_accidents,0),0) AS norm_accidents,
      COALESCE(gm.vehicle_age      /NULLIF(s.max_age,0),0)      AS norm_age,
      COALESCE(gm.rollover_count   /NULLIF(s.max_rollover,0),0) AS norm_rollover,
      COALESCE(gm.fire_exp_count   /NULLIF(s.max_fire_exp,0),0) AS norm_fire_exp,
      COALESCE(gm.prev_acc_count   /NULLIF(s.max_prev_acc,0),0) AS norm_prev_acc
    FROM
      group_metrics AS gm
      CROSS JOIN stats AS s
  ),
  input_row AS (
    SELECT * FROM combined
    WHERE
      MAKE    = input_make
      AND MODEL   = input_model
      AND MOD_YEAR= input_year
  )
SELECT
  ROUND(
    (
      0.4 * norm_accidents
    + 0.2 * norm_age
    + 0.1 * norm_rollover
    + 0.1 * norm_fire_exp
    + 0.2 * norm_prev_acc
    ) * 100
  ,2) AS vehicle_risk_score
FROM
  input_row;
