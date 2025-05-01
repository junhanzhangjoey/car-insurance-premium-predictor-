from flask import Flask, request, jsonify, send_from_directory
from google.cloud import bigquery

app = Flask(__name__)
client = bigquery.Client()

with open("region_risk_score.sql", "r") as f:
    QUERY = f.read()

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
