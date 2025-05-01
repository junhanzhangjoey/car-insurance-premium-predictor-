from flask import Flask, request, jsonify, send_from_directory
from google.cloud import bigquery

app = Flask(__name__)
client = bigquery.Client()

# 你的 Query，注意要用 @state 和 @county 作为参数
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
      a.STATE = @state -- 或者直接去掉STATE限制，算全美国
    GROUP BY 
      a.COUNTY
  ),
  scores AS(
  SELECT
    COUNTY,
    
    pedestrian_count,
    fire_count,
    motor_count,
    rollover_count,
    (total_count - pedestrian_count - fire_count - motor_count - rollover_count) AS other_count,

    -- 各事故类型比例
    SAFE_DIVIDE(pedestrian_count, total_count) AS pedestrian_rate,
    SAFE_DIVIDE(fire_count, total_count) AS fire_rate,
    SAFE_DIVIDE(motor_count, total_count) AS motor_rate,
    SAFE_DIVIDE(rollover_count, total_count) AS rollover_rate,
    SAFE_DIVIDE(total_count - pedestrian_count - fire_count - motor_count - rollover_count, total_count) AS other_rate,

    -- 加权得分
    (
      SAFE_DIVIDE(pedestrian_count, total_count) * 1.7 +
      SAFE_DIVIDE(fire_count, total_count) * 1.8 +
      SAFE_DIVIDE(motor_count, total_count) * 1.2 +
      SAFE_DIVIDE(rollover_count, total_count) * 1.5 +
      SAFE_DIVIDE(total_count - pedestrian_count - fire_count - motor_count - rollover_count, total_count) * 1.0
    ) AS weighted_score,

    -- Raw Risk Score
    (
      (
        SAFE_DIVIDE(pedestrian_count, total_count) * 1.7 +
        SAFE_DIVIDE(fire_count, total_count) * 1.8 +
        SAFE_DIVIDE(motor_count, total_count) * 1.2 +
        SAFE_DIVIDE(rollover_count, total_count) * 1.5 +
        SAFE_DIVIDE(total_count - pedestrian_count - fire_count - motor_count - rollover_count, total_count) * 1.0
      ) * LOG(total_count + 1)--* total_count
    ) AS raw_risk_score,

    -- 归一化成0-100
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
    ) * 100 AS region_risk_score

  FROM crashes
  --ORDER BY region_risk_score DESC
)
SELECT *
FROM scores
WHERE county=@county
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
