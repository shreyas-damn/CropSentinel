from app import app
from flask import jsonify, send_from_directory
from .services import run_ai_analysis
from .models import save_analysis_result, get_latest_analysis_result
import os

# --- Path Setup ---
UPLOADS_FOLDER_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), 'static', 'uploads'))

def build_response_json(result_data):
    """
    A single, reusable helper function to build the final JSON response.
    This guarantees that both endpoints produce the exact same output structure.
    """
    main_image_name = result_data.get('image_path', "")
    # Robustly create the base name for reconstructing other image names
    base_name = main_image_name.replace('Prediction_', '').replace('.png', '')
    
    return {
        "field_id": result_data['field_id'],
        "overall_status": result_data['health_status'],
        "image_urls": {
            "vegetation_stress": f"/api/images/NDVI_{base_name}.png",
            "water_stress": f"/api/images/NDWI_{base_name}.png",
            "health_map": f"/api/images/{main_image_name}"
        }
    }


@app.route("/api/analyze/<string:field_id>")
def analyze_field(field_id):
    """
    This is the 'slow lane' endpoint that runs the full, live AI analysis.
    """
    analysis_data = run_ai_analysis(field_id)
    
    # --- THIS IS THE CRITICAL FIX ---
    # We now use the correct key 'Predicted_health_map' to get the filename.
    main_image_path = analysis_data["image_names"].get("Predicted_health_map", "N/A")
    # ^^^ THIS IS THE CRITICAL FIX ^^^
    
    save_analysis_result(
        field_id,
        analysis_data["health_status"],
        main_image_path
    )

    # We create a new dictionary that has the exact same keys
    # as a database row, making it compatible with our helper function.
    response_data_for_helper = {
        'field_id': field_id,
        'health_status': analysis_data['health_status'],
        'image_path': main_image_path
    }
    
    return jsonify(build_response_json(response_data_for_helper))


@app.route("/api/latest-result")
def get_latest_result():
    """
    This is the 'fast lane' endpoint. It fetches the most
    recent result directly from the database.
    """
    latest_result = get_latest_analysis_result()

    if not latest_result:
        return jsonify({"error": "No past results found. Please run a new analysis first."}), 404

    return jsonify(build_response_json(latest_result))


@app.route("/api/images/<string:filename>")
def get_image(filename):
    """
    This endpoint serves the actual image files (PNGs).
    """
    return send_from_directory(UPLOADS_FOLDER_PATH, filename)
