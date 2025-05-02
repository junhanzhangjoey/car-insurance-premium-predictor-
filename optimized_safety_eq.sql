WITH risk_factors AS (
  SELECT 
    p.STATE, 
    p.ST_CASE, 
    p.VEH_NO,
    p.AIR_BAG,
    p.REST_USE,
    v.MOD_YEAR,

    CASE 
      WHEN SAFE_CAST(p.AIR_BAG AS INT64) = 1 THEN 300
      WHEN SAFE_CAST(p.AIR_BAG AS INT64) = 2 THEN 300
      WHEN SAFE_CAST(p.AIR_BAG AS INT64) = 3 THEN 400
      WHEN SAFE_CAST(p.AIR_BAG AS INT64) IN (7, 8) THEN 200
      ELSE 0
    END AS airbag_discount,
    
    CASE 
      WHEN SAFE_CAST(p.REST_USE AS INT64) IN (1, 2, 3) THEN 250
      ELSE 0
    END AS restraint_discount,
    
    CASE 
      WHEN v.MOD_YEAR IS NULL THEN 0
      WHEN SAFE_CAST(v.MOD_YEAR AS INT64) >= 2018 THEN 350
      WHEN SAFE_CAST(v.MOD_YEAR AS INT64) >= 2010 THEN 200
      WHEN SAFE_CAST(v.MOD_YEAR AS INT64) >= 2000 THEN 100
      ELSE 0
    END AS modern_safety_discount
  FROM `bigquery-public-data.dataflix_traffic_safety.person` p
  JOIN `bigquery-public-data.dataflix_traffic_safety.vehicle` v 
    ON p.ST_CASE = v.ST_CASE AND p.VEH_NO = v.VEH_NO
  WHERE v.MOD_YEAR IS NOT NULL
)

SELECT
  STATE,
  ST_CASE,
  VEH_NO,
  AIR_BAG,
  REST_USE,
  MOD_YEAR,
  airbag_discount,
  restraint_discount,
  modern_safety_discount,
  (airbag_discount + restraint_discount + modern_safety_discount) AS raw_safety_discount,
  
  ROUND((airbag_discount + restraint_discount + modern_safety_discount) / 1000.0 * 100, 2) AS scaled_safety_discount_0_100
  
FROM risk_factors
LIMIT 1000;
