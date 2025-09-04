import requests
import json
from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

# The addresses of your running Flask agents
VALIDATION_AGENT_URL = "http://127.0.0.1:5001/validate"
VALUATION_AGENT_URL = "http://127.0.0.1:5002/value"
# TODO: Add the URL for your recommendation agent when it's ready
# RECOMMENDATION_AGENT_URL = "http://127.0.0.1:5003/recommend"

def index(request):
    """Serves the main index.html page from 'my-app/templates/'."""
    return render(request, 'index.html')

def _proxy_request(agent_url, request):
    """Helper function to forward a request to a backing agent."""
    try:
        data = json.loads(request.body)
        # Forward the request to the specified agent
        agent_response = requests.post(agent_url, json=data, timeout=10)
        # Raise an exception for bad status codes (4xx or 5xx)
        agent_response.raise_for_status()
        # Return the agent's response
        return JsonResponse(agent_response.json(), status=agent_response.status_code)
    except requests.exceptions.RequestException as e:
        # Handle connection errors to the agent
        return JsonResponse({'error': f'Failed to connect to the agent: {e}'}, status=502) # 502 Bad Gateway
    except json.JSONDecodeError:
        # Handle malformed JSON from the client
        return JsonResponse({'error': 'Invalid JSON in request body'}, status=400)

@csrf_exempt
def validation_proxy(request):
    """Proxies requests to the validation agent."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST method is allowed'}, status=405)
    return _proxy_request(VALIDATION_AGENT_URL, request)

@csrf_exempt
def valuation_proxy(request):
    """Proxies requests to the valuation agent."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST method is allowed'}, status=405)
    return _proxy_request(VALUATION_AGENT_URL, request)

@csrf_exempt
def recommendation_proxy(request):
    """
    A placeholder proxy for the recommendation agent.
    This should be updated when the agent is implemented.
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST method is allowed'}, status=405)

    # This is a placeholder. When your recommendation agent is ready,
    # you can replace this with a call to _proxy_request.
    # return _proxy_request(RECOMMENDATION_AGENT_URL, request)

    try:
        # We can still parse the body to make sure it's valid
        json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON in request body'}, status=400)

    return JsonResponse({
        "status": "Not Implemented",
        "message": "The recommendation agent is not yet connected.",
        "recommendations": ["p_placeholder_1", "p_placeholder_2"]
    }, status=501)