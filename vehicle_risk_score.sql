DECLARE input_make   STRING DEFAULT 'Chevrolet';
DECLARE input_model  STRING DEFAULT 'Camaro';
DECLARE input_year   INT64  DEFAULT 74;

WITH group_metrics AS (
  SELECT
    MAKE,
    MODEL,
    MOD_YEAR,
    COUNT(*)                           AS accidents_count,
    SUM(SAFE_CAST(ROLLOVER AS INT64))  AS rollover_count,
    SUM(SAFE_CAST(FIRE_EXP AS INT64))  AS fire_exp_count,
    SUM(SAFE_CAST(PREV_ACC AS INT64))  AS prev_acc_count
  FROM
    `bigquery-public-data.dataflix_traffic_safety.vehicle`
  WHERE
    MAKE     IS NOT NULL
    AND MODEL IS NOT NULL
    AND MOD_YEAR IS NOT NULL
  GROUP BY
    MAKE, MODEL, MOD_YEAR
)
SELECT
  ROUND((
    0.4 * (
      SELECT accidents_count
      FROM group_metrics
      WHERE MAKE = input_make
        AND MODEL = input_model
        AND MOD_YEAR = input_year
    ) / (
      SELECT MAX(accidents_count) FROM group_metrics
    )
  + 0.2 * ((2025 - input_year) / (
      SELECT MAX(2025 - MOD_YEAR) FROM group_metrics
    ))
  + 0.1 * (
      SELECT rollover_count
      FROM group_metrics
      WHERE MAKE = input_make
        AND MODEL = input_model
        AND MOD_YEAR = input_year
    ) / (
      SELECT MAX(rollover_count) FROM group_metrics
    )
  + 0.1 * (
      SELECT fire_exp_count
      FROM group_metrics
      WHERE MAKE = input_make
        AND MODEL = input_model
        AND MOD_YEAR = input_year
    ) / (
      SELECT MAX(fire_exp_count) FROM group_metrics
    )
  + 0.2 * (
      SELECT prev_acc_count
      FROM group_metrics
      WHERE MAKE = input_make
        AND MODEL = input_model
        AND MOD_YEAR = input_year
    ) / (
      SELECT MAX(prev_acc_count) FROM group_metrics
    )
  ) * 100, 2) AS vehicle_risk_score;
