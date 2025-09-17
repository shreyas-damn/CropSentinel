import sqlite3


conn = sqlite3.connect('app/database.db')
cursor = conn.cursor()


create_table_query = """
CREATE TABLE IF NOT EXISTS analysis_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    field_id TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    health_status TEXT NOT NULL,
    image_path TEXT NOT NULL
);
"""


cursor.execute(create_table_query)

print("Database 'database.db' and table 'analysis_results' created successfully.")


conn.commit()
conn.close()