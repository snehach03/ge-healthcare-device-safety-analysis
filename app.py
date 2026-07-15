"""
GE HealthCare Device Severity Prediction API
Loads the trained model and exposes a /predict endpoint.
"""

from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import pandas as pd

app = FastAPI(
    title="GE HealthCare Device Severity Predictor",
    description="Predicts whether a medical device adverse event report is likely Severe (Death/Injury) or Non-Severe (Malfunction/Other), based on device type and event description text. Trained on FDA MAUDE adverse event data.",
    version="1.0"
)

# Load the trained pipeline once at startup
model = joblib.load("severity_model.pkl")


class EventInput(BaseModel):
    device_name: str
    event_description: str

    class Config:
        json_schema_extra = {
            "example": {
                "device_name": "CENTRAL MONITORING SYSTEM",
                "event_description": "The device screen went blank during patient monitoring and the alarm failed to trigger."
            }
        }


class PredictionOutput(BaseModel):
    prediction: str
    confidence: float


@app.get("/")
def root():
    return {
        "message": "GE HealthCare Device Severity Prediction API is running.",
        "docs": "/docs",
        "predict_endpoint": "/predict"
    }


@app.post("/predict", response_model=PredictionOutput)
def predict_severity(event: EventInput):
    input_df = pd.DataFrame([{
        "device_name": event.device_name,
        "event_description": event.event_description
    }])

    prediction = model.predict(input_df)[0]
    probabilities = model.predict_proba(input_df)[0]
    confidence = round(float(max(probabilities)), 3)

    return PredictionOutput(prediction=prediction, confidence=confidence)