from flask import Flask
from flask_cors import CORS # <-- Import the new library

# Create the main Flask application object
app = Flask(__name__)

# --- THIS IS THE NEW PART ---
# Set up CORS. This tells your server to accept requests
# from any origin, which is perfect for development.
CORS(app)

# Import the routes to connect them to the application
from app import routes