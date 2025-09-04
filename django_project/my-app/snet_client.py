import requests
import logging
import json

# It's recommended to move these URLs to your Django settings.py for better configuration management.
BASE_URL_VALIDATION = "http://localhost:5001"
BASE_URL_VALUATION = "http://localhost:5002"
BASE_URL_RECOMMENDATION = "http://localhost:5003"

def _make_request(agent_name: str, url: str, data: dict):
    """
    Centralized request function to handle agent communication.
    Returns a tuple of (response_json, status_code).
    """
    try:
        response = requests.post(url, json=data, timeout=10)
        response.raise_for_status()
        return response.json(), response.status_code
    except requests.exceptions.HTTPError as e:
        # The agent responded with a 4xx or 5xx error
        logging.warning(f"HTTP error from {agent_name} Agent (status {e.response.status_code}): {e.response.text}")
        try:
            # Try to return the agent's JSON error body
            return e.response.json(), e.response.status_code
        except json.JSONDecodeError:
            # If the error body isn't JSON, return a generic error
            error_message = f"Received non-JSON error from {agent_name} Agent (status {e.response.status_code})"
            return {"error": error_message, "status": "ERROR"}, e.response.status_code
    except requests.exceptions.RequestException as e:
        # This catches connection errors, timeouts, etc.
        error_message = f"Error connecting to {agent_name} Agent: {e}"
        logging.error(error_message)
        return {"error": error_message, "status": "ERROR"}, 502 # Bad Gateway

def validate_property(property_data):
    """Calls the Validation Agent."""
    return _make_request("Validation", f"{BASE_URL_VALIDATION}/validate", property_data)

def get_valuation(property_data):
    """Calls the Valuation Agent."""
    return _make_request("Valuation", f"{BASE_URL_VALUATION}/value", property_data)

def get_recommendations(user_data):
    """Calls the Recommendation Agent."""
    return _make_request("Recommendation", f"{BASE_URL_RECOMMENDATION}/recommend", user_data)