import logging
from flask import Flask, request, jsonify
from hyperon import MeTTa

logging.basicConfig(level=logging.INFO)

app = Flask(__name__)

def sanitize_string(value: str) -> str:
    """Sanitizes a string for safe inclusion in a MeTTa expression."""
    if not isinstance(value, str):
        value = str(value)
    return value.replace('\\', '\\\\').replace('"', '\\"')

@app.route('/value', methods=['POST'])
def value_property():
    data = request.get_json()
    if not data:
        logging.warning("Received request with no JSON payload.")
        return jsonify({"error": "Invalid input: No JSON payload"}), 400

    # --- Input Validation and Fact Preparation ---
    prop_id = "temp_prop"  # ID is only for context within the query

    try:
        area = int(data.get("area_sqft", 1000))
        location = sanitize_string(data.get("location", "Delhi"))
    except (ValueError, TypeError):
        logging.error(f"Invalid 'area_sqft' in request: {data.get('area_sqft')}")
        return jsonify({"error": "Invalid input: 'area_sqft' must be a number."}), 400

    # Create a fresh MeTTa instance for each request for thread safety
    metta = MeTTa()
    metta.run("!(import! &self ./valuation_rules.metta)")

    # Add facts from JSON
    facts = [f'(area-sqft {prop_id} {area})', f'(location {prop_id} "{location}")']
    feature = data.get("feature")
    if feature:
        facts.append(f'(has-feature {prop_id} "{sanitize_string(feature)}")')

    for fact in facts:
        metta.run(fact)

    # Run query
    query = f"!(get-valuation-range {prop_id})"
    logging.info(f"Running MeTTa query: {query}")
    result = metta.run(query)
    logging.info(f"MeTTa result: {result}")

    if result:
        try:
            # Expected structure: (((Number, Number),),)
            range_values = [item.get_object().value for item in result[0][0]]
            if len(range_values) == 2:
                lower_bound = float(range_values[0])
                upper_bound = float(range_values[1])
                return jsonify({
                    "property_id": prop_id,
                    "valuation_range": {
                        "lower_bound": lower_bound,
                        "upper_bound": upper_bound,
                    }
                })
        except (IndexError, AttributeError, TypeError, ValueError) as e:
            logging.error(f"Error parsing valuation result: {e}\nResult was: {result}")
            # Fallback for unexpected result format, falls through to the generic error
            pass

    return jsonify({"error": "Could not compute valuation. Check logs for details."}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)