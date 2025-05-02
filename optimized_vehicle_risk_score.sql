-- User Input Variables (would be replaced with actual user inputs in application)
DECLARE input_age INT64 DEFAULT 35;
DECLARE input_gender STRING DEFAULT 'M';
DECLARE input_years_licensed INT64 DEFAULT 10;
DECLARE input_zip_code STRING DEFAULT '90210';
DECLARE input_annual_mileage INT64 DEFAULT 12000;
DECLARE input_make STRING DEFAULT 'Chevrolet';
DECLARE input_model STRING DEFAULT 'Camaro';
DECLARE input_year INT64 DEFAULT 2018;
DECLARE input_has_abs BOOL DEFAULT TRUE;
DECLARE input_has_airbags BOOL DEFAULT TRUE;
DECLARE input_has_esc BOOL DEFAULT TRUE;
DECLARE input_prev_accidents INT64 DEFAULT 0;
DECLARE input_prev_violations INT64 DEFAULT 0;
DECLARE input_defensive_course BOOL DEFAULT FALSE;

-- Main Safety Score Calculation
WITH 
-- Base vehicle risk (similar to your example but enhanced)
vehicle_risk AS (
  SELECT
    v.MAKE,
    v.MODEL,
    v.MOD_YEAR,
    COUNT(*) AS accident_count,
    AVG(CASE WHEN p.INJ_SEV = 4 THEN 1 ELSE 0 END) AS fatal_rate,
    AVG(CASE WHEN v.ROLLOVER = 1 THEN 1 ELSE 0 END) AS rollover_rate,
    AVG(CASE WHEN v.SPEEDREL > 0 THEN 1 ELSE 0 END) AS speeding_involved_rate
  FROM `bigquery-public-data.dataflix_traffic_safety.vehicle` v
  JOIN `bigquery-public-data.dataflix_traffic_safety.person` p 
    ON v.STATE = p.STATE AND v.ST_CASE = p.ST_CASE AND v.L_YEAR = p.L_YEAR
  WHERE v.MAKE IS NOT NULL AND v.MODEL IS NOT NULL AND v.MOD_YEAR IS NOT NULL
  GROUP BY v.MAKE, v.MODEL, v.MOD_YEAR
),

-- Driver age/gender risk factors
demographic_risk AS (
  SELECT
    p.AGE,
    p.SEX,
    COUNT(*) AS accident_count,
    AVG(CASE WHEN p.INJ_SEV = 4 THEN 1 ELSE 0 END) AS fatal_rate
  FROM `bigquery-public-data.dataflix_traffic_safety.person` p
  WHERE p.PER_TYP = 1 -- Drivers only
  GROUP BY p.AGE, p.SEX
),

-- Location risk factors
location_risk AS (
  SELECT
    a.COUNTY,
    a.CITY,
    COUNT(*) AS accident_count,
    AVG(a.FATALS) AS fatality_rate,
    AVG(CASE WHEN a.WEATHER != 1 THEN 1 ELSE 0 END) AS bad_weather_rate,
    AVG(CASE WHEN a.LGT_COND > 2 THEN 1 ELSE 0 END) AS low_light_rate
  FROM `bigquery-public-data.dataflix_traffic_safety.accident` a
  GROUP BY a.COUNTY, a.CITY
),

-- Vehicle safety equipment impact
safety_equipment_impact AS (
  SELECT
    v.MAKE,
    v.MODEL,
    v.MOD_YEAR,
    AVG(CASE WHEN p.REST_USE = 1 THEN 1 ELSE 0 END) AS seatbelt_use_rate,
    AVG(CASE WHEN p.AIR_BAG = 1 THEN 1 ELSE 0 END) AS airbag_deploy_rate,
    AVG(CASE WHEN se.NMPROPAD = 1 THEN 1 ELSE 0 END) AS protective_gear_rate
  FROM `bigquery-public-data.dataflix_traffic_safety.vehicle` v
  JOIN `bigquery-public-data.dataflix_traffic_safety.person` p 
    ON v.STATE = p.STATE AND v.ST_CASE = p.ST_CASE AND v.L_YEAR = p.L_YEAR
  LEFT JOIN `bigquery-public-data.dataflix_traffic_safety.safetyeq` se 
    ON p.STATE = se.STATE AND p.ST_CASE = se.ST_CASE AND p.L_YEAR = se.L_YEAR 
    AND p.VEH_NO = se.VEH_NO AND p.PER_NO = se.PER_NO
  GROUP BY v.MAKE, v.MODEL, v.MOD_YEAR
),

-- Calculate normalized scores for each factor
score_components AS (
  SELECT
    -- Vehicle risk (30% weight)
    (SELECT PERCENT_RANK() OVER (ORDER BY accident_count DESC) FROM vehicle_risk 
     WHERE MAKE = input_make AND MODEL = input_model AND MOD_YEAR = input_year) * 0.30 AS vehicle_accident_score,
    
    (SELECT 1 - PERCENT_RANK() OVER (ORDER BY fatal_rate DESC) FROM vehicle_risk 
     WHERE MAKE = input_make AND MODEL = input_model AND MOD_YEAR = input_year) * 0.20 AS vehicle_fatality_score,
    
    (SELECT 1 - PERCENT_RANK() OVER (ORDER BY rollover_rate DESC) FROM vehicle_risk 
     WHERE MAKE = input_make AND MODEL = input_model AND MOD_YEAR = input_year) * 0.10 AS vehicle_rollover_score,
    
    -- Demographic risk (20% weight)
    (SELECT 1 - PERCENT_RANK() OVER (ORDER BY accident_count DESC) FROM demographic_risk 
     WHERE AGE = input_age AND SEX = input_gender) * 0.15 AS demographic_accident_score,
    
    (SELECT 1 - PERCENT_RANK() OVER (ORDER BY fatal_rate DESC) FROM demographic_risk 
     WHERE AGE = input_age AND SEX = input_gender) * 0.05 AS demographic_fatality_score,
    
    -- Driving history (25% weight)
    CASE 
      WHEN input_prev_accidents = 0 THEN 0.15
      WHEN input_prev_accidents = 1 THEN 0.10
      WHEN input_prev_accidents = 2 THEN 0.05
      ELSE 0
    END AS accident_history_score,
    
    CASE 
      WHEN input_prev_violations = 0 THEN 0.10
      WHEN input_prev_violations = 1 THEN 0.05
      ELSE 0
    END AS violation_score,
    
    -- Safety features (15% weight)
    CASE WHEN input_has_abs THEN 0.03 ELSE 0 END AS abs_score,
    CASE WHEN input_has_airbags THEN 0.05 ELSE 0 END AS airbag_score,
    CASE WHEN input_has_esc THEN 0.04 ELSE 0 END AS esc_score,
    CASE WHEN input_defensive_course THEN 0.03 ELSE 0 END AS course_score,
    
    -- Mileage adjustment (10% weight)
    CASE 
      WHEN input_annual_mileage < 5000 THEN 0.10
      WHEN input_annual_mileage < 10000 THEN 0.07
      WHEN input_annual_mileage < 15000 THEN 0.04
      WHEN input_annual_mileage < 20000 THEN 0.02
      ELSE 0
    END AS mileage_score
)

-- Final safety discount score calculation (scale 300-850)
SELECT
  ROUND(
    300 + (
      COALESCE(vehicle_accident_score, 0) +
      COALESCE(vehicle_fatality_score, 0) +
      COALESCE(vehicle_rollover_score, 0) +
      COALESCE(demographic_accident_score, 0) +
      COALESCE(demographic_fatality_score, 0) +
      COALESCE(accident_history_score, 0) +
      COALESCE(violation_score, 0) +
      COALESCE(abs_score, 0) +
      COALESCE(airbag_score, 0) +
      COALESCE(esc_score, 0) +
      COALESCE(course_score, 0) +
      COALESCE(mileage_score, 0)
    ) * 550, 0
  ) AS safety_discount_score,
  
  -- Individual component scores for transparency
  vehicle_accident_score,
  vehicle_fatality_score,
  vehicle_rollover_score,
  demographic_accident_score,
  demographic_fatality_score,
  accident_history_score,
  violation_score,
  abs_score,
  airbag_score,
  esc_score,
  course_score,
  mileage_score
FROM score_components;
