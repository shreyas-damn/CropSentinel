import matlab.engine
import numpy as np
from datetime import datetime
import os
import shutil

# --- Path Setup ---
# This robustly defines the necessary folder paths so your script works on any computer.
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
ml_model_path = os.path.join(project_root, 'ml_model')
uploads_path = os.path.join(project_root, 'backend', 'app', 'static', 'uploads')

def run_ai_analysis(field_id):
    """
    Calls the final, definitive all-in-one MATLAB script (runFullAnalysis.m),
    which trains, predicts, and saves all three output PNGs.
    """
    print("--- [Service] Starting MATLAB Engine... ---")
    eng = matlab.engine.start_matlab()
    # Tell the engine where to find our custom MATLAB scripts
    eng.addpath(ml_model_path, nargout=0)
    
    # Define a temporary directory for MATLAB to save its output files.
    # This keeps our main ml_model folder clean.
    temp_output_dir = os.path.join(ml_model_path, 'temp_outputs')
    if not os.path.exists(temp_output_dir):
        os.makedirs(temp_output_dir)
        
    print(f"--- [Service] Calling final runFullAnalysis.m script... This will be slow. ---")
    # Call the all-in-one function and tell it where to save the image files.
    # We get the raw data map back for our own analysis.
    prediction_map_matlab = eng.runFullAnalysis(temp_output_dir, nargout=1)
    
    eng.quit()
    print("--- [Service] MATLAB Engine stopped. ---")

    # --- INTELLIGENCE: Analyze the returned data ---
    prediction_map = np.array(prediction_map_matlab._data).reshape(prediction_map_matlab.size, order='F')
    total_pixels = prediction_map.size
    # In MATLAB: 1=Unhealthy, 2=Moderate, 3=Healthy
    unhealthy_pixels = np.sum(prediction_map == 1)
    unhealthy_percent = (unhealthy_pixels / total_pixels) * 100
    
    # Define the final status based on the percentage of unhealthy pixels
    overall_status = "Field is Predominantly Healthy"
    if unhealthy_percent > 20:
        overall_status = "Significant Stress Detected"
    elif unhealthy_percent > 5:
        overall_status = "Minor Stress Detected"

    # --- File Management: Move the 3 PNGs to the final uploads folder ---
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    files_to_move = {
        "NDVI.png": f"NDVI_{field_id}_{timestamp}.png",
        "NDWI.png": f"NDWI_{field_id}_{timestamp}.png",
        "Predicted_health_map.png": f"Prediction_{field_id}_{timestamp}.png"
    }
    
    output_image_names = {}

    for original_name, new_name in files_to_move.items():
        original_path = os.path.join(temp_output_dir, original_name)
        new_path = os.path.join(uploads_path, new_name)
        
        if os.path.exists(original_path):
            shutil.move(original_path, new_path)
            # We store the new, unique filename to send back to the frontend
            output_image_names[original_name.split('.')[0]] = new_name
            print(f"Moved {original_name} to {new_name}")
        else:
            print(f"CRITICAL ERROR: {original_name} not found in {temp_output_dir}.")
            
    # Return the final dictionary with the status and the new names of the three image files
    return {"health_status": overall_status, "image_names": output_image_names}



    

