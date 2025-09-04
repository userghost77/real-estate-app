import json
from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from . import snet_client


def index(request):
    """Serves the main index.html page from 'my-app/templates/'."""
    return render(request, 'index.html')

def _process_agent_request(request, agent_function):
    """Helper to process a POST request and call an agent function from snet_client."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST method is allowed'}, status=405)
    try:
        data = json.loads(request.body)
        result, status_code = agent_function(data)
        return JsonResponse(result, status=status_code)
    except json.JSONDecodeError:
        # Handle malformed JSON from the client
        return JsonResponse({'error': 'Invalid JSON in request body'}, status=400)

@csrf_exempt
def validation_proxy(request):
    """Proxies requests to the validation agent."""
    return _process_agent_request(request, snet_client.validate_property)

@csrf_exempt
def valuation_proxy(request):
    """Proxies requests to the valuation agent."""
    return _process_agent_request(request, snet_client.get_valuation)

@csrf_exempt
def recommendation_proxy(request):
    """
    Proxies requests to the recommendation agent.
    """
    return _process_agent_request(request, snet_client.get_recommendations)