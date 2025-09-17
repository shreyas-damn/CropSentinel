import sqlite3

# Define the path to the database file to ensure consistency
DATABASE_PATH = 'app/database.db'

def save_analysis_result(field_id, health_status, image_path):
    """Saves a new analysis result to the SQLite database."""
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()

        # SQL command to insert a new row.
        # It uses the database's default CURRENT_TIMESTAMP for UTC time.
        insert_query = """
        INSERT INTO analysis_results (field_id, health_status, image_path)
        VALUES (?, ?, ?);
        """
        cursor.execute(insert_query, (field_id, health_status, image_path))
        
        conn.commit()
        print(f"Successfully saved result for {field_id} to the database.")

    except sqlite3.Error as e:
        print(f"Database error: {e}")
    finally:
        if conn:
            conn.close()

def get_sensor_data(field_id):
    """Fetches mock sensor data for a given field_id."""
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row 
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM mock_sensor_data WHERE field_id = ?", (field_id,))
    data = cursor.fetchone()
    
    conn.close()
    
    if data:
        return dict(data)
    return None

# ======================================================================
# VVV THIS IS THE NEW FUNCTION YOU ARE ADDING VVV
# ======================================================================
def get_latest_analysis_result():
    """
    Queries the database for the single most recent analysis result.
    This is the "fast lane" function for the instant demo.
    """
    conn = None
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        # conn.row_factory allows us to access columns by name (like a dictionary)
        conn.row_factory = sqlite3.Row 
        cursor = conn.cursor()

        # This SQL query orders all results by their timestamp in descending
        # order (newest first) and then takes only the top one (LIMIT 1).
        query = "SELECT * FROM analysis_results ORDER BY timestamp DESC LIMIT 1"
        cursor.execute(query)
        latest_result = cursor.fetchone()
        
        if latest_result:
            # Convert the database row object to a standard Python dictionary
            return dict(latest_result) 
        return None # Return None if the database is empty
    except sqlite3.Error as e:
        print(f"Database error while fetching latest result: {e}")
        return None
    finally:
        if conn:
            conn.close()

