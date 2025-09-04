import logging
from flask import Flask, request, jsonify
from hyperon import MeTTa

logging.basicConfig(level=logging.INFO)

app = Flask(__name__)

@app.route('/recommend', methods=['POST'])
def recommend_properties():
    data = request.get_json()
    if not data:
        logging.warning("Recommendation request missing payload.")
        return jsonify({"error": "Invalid input: No JSON payload"}), 400

    user_id = data.get('user_id')
    if not user_id:
        logging.warning("Recommendation request missing user_id.")
        return jsonify({"error": "Invalid input: user_id is required"}), 400

    user_history = data.get('user_history', []) # List of viewed property IDs
    all_properties = data.get('all_properties', []) # List of property dicts

    # Create a fresh MeTTa instance for each request for thread safety
    metta = MeTTa()
    metta.run("!(import! &self ./recommendation_rules.metta)")

    # Add facts about all available properties
    for prop in all_properties:
        if "id" in prop and "location" in prop and "type" in prop:
            metta.run(f'(location {prop["id"]} "{prop["location"]}")')
            metta.run(f'(type {prop["id"]} "{prop["type"]}")')

    # Add facts about user history
    for viewed_id in user_history:
        metta.run(f'(viewed-by {user_id} {viewed_id})')

    # Run query to find all recommendations
    query = f"!(should-recommend {user_id} $rec)"
    logging.info(f"Running MeTTa query: {query}")
    result = metta.run(query)
    logging.info(f"MeTTa result: {result}")

    recommendations = set()
    if result:
        # Safely parse results, expecting a list of tuples with one atom
        for res in result:
            try:
                # Expected structure: ((SymbolAtom:,),)
                recommendations.add(res[0][0].get_object().value)
            except (IndexError, AttributeError) as e:
                logging.error(f"Error parsing recommendation result: {e}\nResult item was: {res}")

    return jsonify({"user_id": user_id, "recommendations": list(recommendations)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5003)