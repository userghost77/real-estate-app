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

@app.route('/validate', methods=['POST'])
def validate_property():
    data = request.get_json()
    if not data or 'property_id' not in data:
        logging.warning("Validation request missing payload or property_id.")
        return jsonify({"error": "Invalid input: No JSON payload or property_id missing"}), 400

    # --- Input Validation and Fact Preparation ---
    try:
        prop_id = sanitize_string(data['property_id'])
        kyc_status = sanitize_string(data.get("kyc_status", "pending"))
        area = int(data.get("area_sqft", 0))
        documents = data.get("documents", [])
        if not isinstance(documents, list):
            logging.error(f"Invalid 'documents' format for prop {prop_id}: {documents}")
            return jsonify({"error": "Invalid input: 'documents' must be a list of strings."}), 400
    except (ValueError, TypeError):
        logging.error(f"Invalid 'area_sqft' in request: {data.get('area_sqft')}")
        return jsonify({"error": "Invalid input: 'area_sqft' must be a number."}), 400

    # Create a fresh MeTTa instance for each request for thread safety
    metta = MeTTa()
    metta.run("!(import! &self ./validation_rules.metta)")

    # Dynamically add facts from the JSON payload
    facts = [f'(kyc-status "{prop_id}" "{kyc_status}")', f'(area-sqft "{prop_id}" {area})']
    for doc in documents:
        facts.append(f'(has-document "{prop_id}" "{sanitize_string(doc)}")')

    for fact in facts:
        metta.run(fact)

    # Execute the query
    query = f'!(validate-property "{prop_id}" $status $reason)'
    logging.info(f"Running MeTTa query: {query}")
    result = metta.run(query)
    logging.info(f"MeTTa result: {result}")

    # Prepare response
    if result:
        try:
            # Expected structure: ((('STATUS', 'REASON'),),)
            res_tuple = result[0][0]
            status = str(res_tuple[0].get_object().value)
            reason = str(res_tuple[1].get_object().value) if len(res_tuple) > 1 else "OK"
            return jsonify({"property_id": prop_id, "status": status, "reason": reason})
        except (IndexError, AttributeError, TypeError) as e:
            logging.error(f"Error parsing validation result: {e}\nResult was: {result}")
            # Fallback if result format is unexpected
            return jsonify({"property_id": prop_id, "status": "ERROR", "reason": "Could not parse validation result. Check logs."}), 500
    else:
        # Fallback if no specific rule matches
        return jsonify({"property_id": prop_id, "status": "REJECTED", "reason": "No matching validation rule found."})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)