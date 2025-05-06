import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from google.cloud import bigquery

app = Flask(__name__)
CORS(app)
client = bigquery.Client()

# ── Load SQL paths ─────────────────────────────────────────────────────────────
BASE_DIR   = os.path.dirname(__file__)
SQL_DIR    = os.path.join(BASE_DIR, "sql")

FILES = {
    "driver_age":    os.path.join(SQL_DIR, "driver_risk_age.sql"),
    "driver_drug":   os.path.join(SQL_DIR, "driver_risk_drug_optimized.sql"),
    "vehicle":       os.path.join(SQL_DIR, "optimized_vehicle_risk_score.sql"),
    "safety_eq":     os.path.join(SQL_DIR, "optimized_safety_eq.sql"),
    "region_sev":    os.path.join(SQL_DIR, "region_risk_severity_optimized.sql"),
    "region_weath":  os.path.join(SQL_DIR, "region_risk_weather_optimized.sql"),
}

# ── Query helper ────────────────────────────────────────────────────────────────
def run_query_scalar(sql_path: str, params: dict):
    """Runs a query that returns a single value, or None if no rows."""
    with open(sql_path, "r") as f:
        sql = f.read()
    job = client.query(
        sql,
        job_config=bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter(name, ptype, value)
                for name, (ptype, value) in params.items()
            ]
        ),
    )
    rows = list(job.result())
    return rows[0][0] if rows else None

@app.route("/premium", methods=["POST"])
def api_premium():
    data = request.get_json() or {}

    # Required fields
    required = ["car_value", "state", "age", "drug", "make", "model", "year", "county"]
    for fld in required:
        if fld not in data:
            return jsonify({"error": f"missing required field '{fld}'"}), 400

    # Parse inputs
    car_value = float(data["car_value"])
    state     = data["state"]
    age       = int(data["age"])
    drug      = data["drug"]
    make      = data["make"]
    model     = data["model"]
    year      = int(data["year"])
    county    = data["county"]

    # Run each query
    age_ratio   = run_query_scalar(FILES["driver_age"], {"state": ("STRING", state), "age": ("INT64", age)}) or 0
    drug_ratio  = run_query_scalar(FILES["driver_drug"], {"state": ("STRING", state), "age": ("INT64", age), "drug": ("STRING", drug)}) or 0
    driver_score = (age_ratio + drug_ratio)*50

    vehicle_score = run_query_scalar(FILES["vehicle"], {"make": ("STRING", make), "model": ("STRING", model), "year": ("INT64", year)}) or 0

    safety_pct     = run_query_scalar(FILES["safety_eq"], {"make": ("STRING", make), "model": ("STRING", model), "year": ("INT64", year)}) or 0
    safety_discount = (safety_pct)

    region_sev_score   = run_query_scalar(FILES["region_sev"], {"state": ("STRING", state), "county": ("STRING", county)}) or 0
    region_weath_score = run_query_scalar(FILES["region_weath"], {"state": ("STRING", state), "county": ("STRING", county)}) or 0
    region_score       = (region_sev_score + region_weath_score)/2

    # Compute Base Premium
    base_premium = (
        (car_value/10)
        + (driver_score/100)  * 200
        + (vehicle_score/100) * 150
        + (region_score/100)  * 300
       
    )
    safety_discount = base_premium * safety_pct/100
    # base_premium  *= (100 - safety_pct)/100
    

    return jsonify({
        "car_value":            car_value,
        "driver_age_ratio":     age_ratio*100,
        "driver_drug_ratio":    drug_ratio*100,
        "driver_score":         driver_score,
        "vehicle_score":        vehicle_score*100,
        "safety_pct":           safety_pct,
        "safety_discount":      round(safety_discount, 2),
        "region_severity_score":   region_sev_score,
        "region_weather_score":    region_weath_score,
        "region_score":          region_score,
        "base_premium":         round(base_premium, 2),
    })

if __name__ == "__main__":
    app.run(debug=True)
