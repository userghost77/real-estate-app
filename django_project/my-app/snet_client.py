import requests
import logging

# It's recommended to move these URLs to your Django settings.py for better configuration management.
BASE_URL_VALIDATION = "http://localhost:5001"
BASE_URL_VALUATION = "http://localhost:5002"
BASE_URL_RECOMMENDATION = "http://localhost:5003"

def _handle_request_error(e: requests.exceptions.RequestException, agent_name: str) -> dict:
    """Centralized error handler for request exceptions."""
    error_message = f"Error connecting to {agent_name} Agent: {e}"
    logging.error(error_message)
    return {"error": error_message, "status": "ERROR"}

def validate_property(property_data):
    """Calls the Validation Agent."""
    try:
        response = requests.post(f"{BASE_URL_VALIDATION}/validate", json=property_data)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return _handle_request_error(e, "Validation")

def get_valuation(property_data):
    """Calls the Valuation Agent."""
    try:
        response = requests.post(f"{BASE_URL_VALUATION}/value", json=property_data)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return _handle_request_error(e, "Valuation")

def get_recommendations(user_data):
    """Calls the Recommendation Agent."""
    try:
        response = requests.post(f"{BASE_URL_RECOMMENDATION}/recommend", json=user_data)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return _handle_request_error(e, "Recommendation")