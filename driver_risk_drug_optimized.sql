WITH drug_fatalities AS (
  SELECT 
    d.DRUGRES, 
    SUM(a.FATALS) AS total_fatalities
  FROM `bigquery-public-data.dataflix_traffic_safety.person` p 
  JOIN `bigquery-public-data.dataflix_traffic_safety.drugs` d 
    ON p.L_YEAR = d.L_YEAR AND p.ST_CASE = d.ST_CASE 
  JOIN `bigquery-public-data.dataflix_traffic_safety.accident` a
    ON p.L_YEAR = a.L_YEAR AND p.ST_CASE = a.ST_CASE 
  WHERE p.PER_TYP = "Driver of a Motor Vehicle in Transport" AND p.STATE = "California" -- @state
    AND d.DRUGRES IN (
      "Depressant", 
      "Other Drug", 
      "Stimulant", 
      "Cannabinoid", 
      "Tested for Drugs, Drugs Found, Type Unknown/Positive", 
      "Reported as Unknown If Tested for Drugs", 
      "Narcotic", 
      "Phencyclidine (PCP)", 
      "Hallucinogen", 
      "Inhalant", 
      "Anabolic Steroid", 
      "Tested for Drugs, Results Unknown"
    )
  GROUP BY d.DRUGRES
)

SELECT
  fatality_ratio 
FROM (
  SELECT
    DRUGRES,
    ROUND(total_fatalities / SUM(total_fatalities) OVER (), 4) AS fatality_ratio
  FROM drug_fatalities
)
WHERE DRUGRES = "Other Drug" -- @drug
;
