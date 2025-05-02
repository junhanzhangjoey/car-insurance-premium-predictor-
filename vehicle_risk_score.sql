DECLARE input_make   STRING DEFAULT 'Chevrolet';
DECLARE input_model  STRING DEFAULT 'Camaro';
DECLARE input_year   INT64  DEFAULT 74;  

WITH target AS (
  SELECT
    SAFE_CAST(v.MOD_YEAR  AS INT64) AS mod_year,
    SAFE_CAST(v.ROLLOVER  AS INT64) AS rollover,
    SAFE_CAST(v.FIRE_EXP  AS INT64) AS fire_exp,
    SAFE_CAST(v.PREV_ACC  AS INT64) AS prev_acc,
    v.MAKE                          AS make_str,
    SAFE_CAST(v.SPEEDREL  AS INT64) AS speedrel,
    SAFE_CAST(v.BODY_TYP  AS INT64) AS body_typ
  FROM
    `bigquery-public-data.dataflix_traffic_safety.vehicle` AS v
  WHERE
    v.MAKE                  = input_make
    AND v.MODEL             = input_model
    AND SAFE_CAST(v.MOD_YEAR AS INT64) = input_year
  LIMIT 1
),


risk_components AS (
  SELECT
    CASE
      WHEN mod_year IS NULL           THEN 4
      WHEN (2025 - mod_year) <= 3     THEN 1
      WHEN (2025 - mod_year) <= 7     THEN 2
      WHEN (2025 - mod_year) <= 12    THEN 3
      ELSE 4
    END AS vehicle_age_risk,
    CASE
      WHEN body_typ IN (1,2,3)       THEN 1
      WHEN body_typ IN (14,15,16)    THEN 2
      WHEN body_typ IN (20,21,22)    THEN 3
      ELSE 2.5
    END AS body_type_risk,
    CASE
      WHEN rollover = 0 THEN 0
      WHEN rollover > 0 THEN 3
      ELSE 1
    END AS rollover_risk,
    CASE
      WHEN fire_exp = 0 THEN 0
      WHEN fire_exp > 0 THEN 2
      ELSE 0
    END AS fire_exp_risk,
    CASE
      WHEN prev_acc = 0 THEN 0
      WHEN prev_acc = 1 THEN 1
      WHEN prev_acc = 2 THEN 2
      WHEN prev_acc >= 3 THEN 3
      ELSE 0
    END AS prev_accident_risk,
    CASE
      WHEN make_str IN ('Chevrolet','Ford','Toyota') THEN 1 
      WHEN make_str IN ('Ferrari','Lamborghini')      THEN 3 
      ELSE 2
    END AS make_risk,

    CASE
      WHEN speedrel > 0 THEN 3
      ELSE 0
    END AS speed_risk,

    (
      CASE WHEN mod_year IS NULL           THEN 4
           WHEN (2025 - mod_year) <= 3     THEN 1
           WHEN (2025 - mod_year) <= 7     THEN 2
           WHEN (2025 - mod_year) <= 12    THEN 3
           ELSE 4 END
    + CASE WHEN body_typ IN (1,2,3)       THEN 1
           WHEN body_typ IN (14,15,16)    THEN 2
           WHEN body_typ IN (20,21,22)    THEN 3
           ELSE 2.5 END
    + CASE WHEN rollover = 0 THEN 0 WHEN rollover > 0 THEN 3 ELSE 1 END
    + CASE WHEN fire_exp = 0 THEN 0 WHEN fire_exp > 0 THEN 2 ELSE 0 END
    + CASE WHEN prev_acc = 0 THEN 0 WHEN prev_acc = 1 THEN 1 WHEN prev_acc = 2 THEN 2 WHEN prev_acc >= 3 THEN 3 ELSE 0 END
    + CASE WHEN make_str IN ('Chevrolet','Ford','Toyota') THEN 1 WHEN make_str IN ('Ferrari','Lamborghini') THEN 3 ELSE 2 END
    + CASE WHEN speedrel > 0 THEN 3 ELSE 0 END
    ) AS raw_vehicle_risk_score

  FROM
    target
)

SELECT
  vehicle_age_risk,
  body_type_risk,
  rollover_risk,
  fire_exp_risk,
  prev_accident_risk,
  make_risk,
  speed_risk,
  raw_vehicle_risk_score,
  ROUND(
    (raw_vehicle_risk_score - 3)
    / (21 - 3)
    * 100,
  2) AS vehicle_risk_score
FROM
  risk_components;
