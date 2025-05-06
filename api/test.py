# test_queries.py

import os
from google.cloud import bigquery

# ── Configuration ───────────────────────────────────────────────────────────────
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

client = bigquery.Client()

# ── Helpers ────────────────────────────────────────────────────────────────────
def run_query_scalar(sql_path: str, params: dict):
    """Runs a query that should return one row/one column. Returns None if no rows."""
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
    rows = list(job.result())      # ← consume all rows
    if not rows:
        print(f"⚠️  Query returned 0 rows: {os.path.basename(sql_path)} with {params}")
        return None
    return rows[0][0]              # first row, first column


def run_query_list(sql_path: str, params: dict):
    """Runs a query that returns multiple rows; returns a list of dicts."""
    with open(sql_path, "r") as f:
        sql = f.read()
    job = client.query(
        sql,
        job_config=bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter(name, ptype, value)
                for name, (ptype, value) in params.items()
            ]
        )
    )
    return [dict(r) for r in job.result()]

# ── Wrappers ───────────────────────────────────────────────────────────────────
def driver_age_risk(state: str, age: int):
    return run_query_scalar(
        FILES["driver_age"],
        {"state": ("STRING", state), "age": ("INT64", age)}
    )

def driver_drug_risk(state: str, age: int, drug: str):
    return run_query_scalar(
        FILES["driver_drug"],
        {
            "state": ("STRING", state),
            "age":   ("INT64", age),
            "drug":  ("STRING", drug),
        }
    )

def vehicle_risk(make: str, model: str, year: int):
    return run_query_scalar(
        FILES["vehicle"],
        {"make": ("STRING", make), "model": ("STRING", model), "year": ("INT64", year)}
    )

def safety_discount_pct(make: str, model: str, year: int):
    return run_query_scalar(
        FILES["safety_eq"],
        {"make": ("STRING", make), "model": ("STRING", model), "year": ("INT64", year)}
    )

# def region_severity(state: str):
#     return run_query_list(
#         FILES["region_sev"],
#         {"state": ("STRING", state)}
#     )

# def region_weather(state: str):
#     return run_query_list(
#         FILES["region_weath"],
#         {"state": ("STRING", state)}
#     )

def region_severity_by_county(state: str, county: str):
    return run_query_scalar(
        FILES["region_sev"],
        {"state": ("STRING", state), "county": ("STRING", county)}
    )

def region_weather_by_county(state: str, county: str):
    return run_query_scalar(
        FILES["region_weath"],
        {"state": ("STRING", state), "county": ("STRING", county)}
    )

# ── Tester Harness ─────────────────────────────────────────────────────────────
if __name__ == "__main__":
    sample = {
        "state":      "California",
        "age":         35,
        "drug":      "Cannabinoid",
        "make":      "Chevrolet",
        "model":     "Camaro",
        "year":       72,
        "county": "SANTA CLARA (85)"
    }

    print("=== Scalar results ===")
    print("Driver (age) fatality ratio:", driver_age_risk(sample["state"], sample["age"]))
    print("Driver (drug) fatality ratio:", driver_drug_risk(sample["state"], sample["age"], sample["drug"]))
    print("Vehicle risk score:",        vehicle_risk(sample["make"], sample["model"], sample["year"]))
    print("Safety discount %:",         safety_discount_pct(sample["make"], sample["model"], sample["year"]))

    sev_county = region_severity_by_county(sample["state"], sample["county"])
    weath_county = region_weather_by_county(sample["state"], sample["county"])
    print(f"Severity risk for {sample['county']}: {sev_county}")
    print(f"Weather risk for  {sample['county']}: {weath_county}")