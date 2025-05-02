DECLARE input_make   STRING DEFAULT 'Chevrolet';
DECLARE input_model  STRING DEFAULT 'Camaro';
DECLARE input_year   INT64  DEFAULT 74;

WITH metrics AS (
  SELECT
    MAKE,
    MODEL,
    MOD_YEAR,
    COUNT(*)                             AS accidents_count,
    SUM(SAFE_CAST(ROLLOVER AS INT64))    AS rollover_count,
    SUM(SAFE_CAST(FIRE_EXP AS INT64))    AS fire_exp_count,
    SUM(SAFE_CAST(PREV_ACC AS INT64))    AS prev_acc_count,
    2025 - MOD_YEAR                      AS vehicle_age
  FROM
    `bigquery-public-data.dataflix_traffic_safety.vehicle`
  WHERE
    MAKE IS NOT NULL
    AND MODEL IS NOT NULL
    AND MOD_YEAR IS NOT NULL
  GROUP BY
    MAKE, MODEL, MOD_YEAR
),
normalized AS (
  SELECT
    MAKE,
    MODEL,
    MOD_YEAR,
    COALESCE(accidents_count / NULLIF(MAX(accidents_count) OVER(), 0), 0) AS norm_accidents,
    COALESCE(vehicle_age      / NULLIF(MAX(vehicle_age)      OVER(), 0), 0) AS norm_age,
    COALESCE(rollover_count   / NULLIF(MAX(rollover_count)   OVER(), 0), 0) AS norm_rollover,
    COALESCE(fire_exp_count   / NULLIF(MAX(fire_exp_count)   OVER(), 0), 0) AS norm_fire_exp,
    COALESCE(prev_acc_count   / NULLIF(MAX(prev_acc_count)   OVER(), 0), 0) AS norm_prev_acc
  FROM
    metrics
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
  , 2) AS vehicle_risk_score
FROM
  normalized
WHERE
  MAKE     = input_make
  AND MODEL  = input_model
  AND MOD_YEAR = input_year;
