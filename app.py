from flask import Flask, request, jsonify, send_from_directory
from google.cloud import bigquery

app = Flask(__name__)
client = bigquery.Client()

QUERY = """
WITH
  crashes AS (
    SELECT
      a.COUNTY,
      COUNTIF(v.SOE = 'Pedestrian') AS pedestrian_count,
      COUNTIF(v.SOE = 'Fire/Explosion') AS fire_count,
      COUNTIF(v.SOE = 'Motor Vehicle in Transport') AS motor_count,
      COUNTIF(v.SOE = 'Rollover/Overturn') AS rollover_count,
      COUNT(*) AS total_count
    FROM 
      `bigquery-public-data.dataflix_traffic_safety.vsoe` v
    JOIN 
      `bigquery-public-data.dataflix_traffic_safety.accident` a
    ON 
      v.ST_CASE = a.ST_CASE AND v.L_YEAR = a.YEAR
    WHERE 
      a.STATE = @state
    GROUP BY 
      a.COUNTY
  ),

  score1 AS(
  SELECT
    COUNTY,
    (
      ( 
        (
          SAFE_DIVIDE(pedestrian_count, total_count) * 1.7 +
          SAFE_DIVIDE(fire_count, total_count) * 1.8 +
          SAFE_DIVIDE(motor_count, total_count) * 1.2 +
          SAFE_DIVIDE(rollover_count, total_count) * 1.5 +
          SAFE_DIVIDE(total_count - pedestrian_count - fire_count - motor_count - rollover_count, total_count) * 1.0
        ) * LOG(total_count + 1)--* total_count
      ) / MAX(
        (
          SAFE_DIVIDE(pedestrian_count, total_count) * 1.7 +
          SAFE_DIVIDE(fire_count, total_count) * 1.8 +
          SAFE_DIVIDE(motor_count, total_count) * 1.2 +
          SAFE_DIVIDE(rollover_count, total_count) * 1.5 +
          SAFE_DIVIDE(total_count - pedestrian_count - fire_count - motor_count - rollover_count, total_count) * 1.0
        ) * LOG(total_count + 1) --* total_count
      ) OVER ()
    ) * 100 AS risk_score

  FROM crashes
  --ORDER BY risk_score DESC
)


,
bad_rate AS(
  SELECT 
    COUNTY,
    COUNTIF(
      WEATHER IN (
        'Freezing Rain or Drizzle',
        'Blowing Snow',
        'Rain',
        'Snow',
        'Fog, Smog, Smoke',
        'Severe Crosswinds',
        'Blowing Sand, Soil, Dirt'
      )
    )/COUNT(*) AS bad_Weather_rate
  FROM 
    `bigquery-public-data.dataflix_traffic_safety.accident`
  WHERE 
    STATE = @state
  GROUP BY 
    COUNTY
  ORDER BY bad_Weather_rate DESC
),
score2 AS(
  SELECT COUNTY, bad_Weather_rate,(bad_Weather_rate/MAX(bad_Weather_rate) OVER())*100 AS risk_score
  FROM bad_rate
  ORDER BY risk_score DESC
)


SELECT s1.COUNTY, (s1.risk_score+s2.risk_score)/2 AS region_risk_score
FROM score1 s1
JOIN score2 s2
on s1.COUNTY=s2.COUNTY
--WHERE s1.COUNTY=@county
WHERE LOWER(REGEXP_REPLACE(s1.COUNTY, r'\\s*\\(.*\\)', '')) = LOWER(@county)
"""
@app.route('/')
def home():
    return send_from_directory('.', 'index.html')

@app.route('/get-risk-score', methods=['POST'])
def get_risk_score():
    data = request.get_json()
    state = data['state']
    county = data['county']

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("state", "STRING", state),
            bigquery.ScalarQueryParameter("county", "STRING", county),
        ]
    )

    query_job = client.query(QUERY, job_config=job_config)
    result = query_job.result()

    for row in result:
        return jsonify({
            "county": row["COUNTY"],
            "risk_score": row["region_risk_score"]
        })

    return jsonify({"error": "No data found"}), 404

if __name__ == '__main__':
    app.run(debug=True)
