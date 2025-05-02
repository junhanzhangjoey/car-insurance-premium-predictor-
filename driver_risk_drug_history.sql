SELECT 
  DRUGRES,
  total_fatalities / (SELECT SUM(total_fatalities) FROM (
    SELECT 
      d.DRUGRES, 
      SUM(a.FATALS) AS total_fatalities
    FROM 
      `bigquery-public-data.dataflix_traffic_safety.person` p,
      `bigquery-public-data.dataflix_traffic_safety.drugs` d,
      `bigquery-public-data.dataflix_traffic_safety.accident` a
    WHERE 
      p.L_YEAR = d.L_YEAR AND 
      p.ST_CASE = d.ST_CASE AND 
      p.L_YEAR = a.L_YEAR AND 
      p.ST_CASE = a.ST_CASE
    GROUP BY d.DRUGRES
  )) AS fatality_ratio
FROM (
  SELECT 
    d.DRUGRES, 
    SUM(a.FATALS) AS total_fatalities
  FROM `bigquery-public-data.dataflix_traffic_safety.person` p 
  JOIN `bigquery-public-data.dataflix_traffic_safety.drugs` d 
    ON p.L_YEAR = d.L_YEAR AND p.ST_CASE = d.ST_CASE 
  JOIN `bigquery-public-data.dataflix_traffic_safety.accident` a
    ON p.L_YEAR = a.L_YEAR AND p.ST_CASE = a.ST_CASE 
  WHERE 
    d.DRUGRES IN (
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
    AND p.PER_TYP = "Driver of a Motor Vehicle in Transport" AND p.STATE = "California" -- @state
  GROUP BY d.DRUGRES
)
WHERE DRUGRES = "Other Drug" --@drug;
