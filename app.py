from flask import Flask, request, jsonify, send_from_directory
from google.cloud import bigquery
import re

app = Flask(__name__)
client = bigquery.Client()

def normalize_county(county):
    if not isinstance(county, str):
        print("Warning: county is not a string:", county)
        return ""
    return re.sub(r'\s*\(.*\)', '', county).strip().lower()

with open("region_risk_severity.sql", "r") as f:
    QUERY1 = f.read()

with open("region_risk_weather.sql", "r") as f:
    QUERY2 = f.read()

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

    query_job1 = client.query(QUERY1, job_config=job_config)
    query_job2 = client.query(QUERY2, job_config=job_config)

    score1_result = {normalize_county(row["COUNTY"]): row["risk_score"] for row in query_job1.result()}
    score2_result = {normalize_county(row["COUNTY"]): row["risk_score"] for row in query_job2.result()}


    county_key = normalize_county(county)
    
    if county_key in score1_result and county_key in score2_result:
        avg_score = (score1_result[county_key] + score2_result[county_key]) / 2
        return jsonify({
            "county": county,
            "risk_score": round(avg_score, 2)
        })
    else:
        return jsonify({"error": "No data found for given county"}), 404


if __name__ == '__main__':
    app.run(debug=True)
