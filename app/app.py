"""
SimpleTimeService - Minimalist Microservice
Returns current timestamp and visitor IP in JSON format
"""

from flask import Flask, request, jsonify
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/', methods=['GET'])
def get_time_and_ip():
    """
    Main endpoint - returns current timestamp and visitor IP
    
    Returns:
        JSON: {
            "timestamp": "<ISO 8601 format>",
            "ip": "<visitor IP address>"
        }
    """
    try:
        # Get client IP (handle X-Forwarded-For for proxies/load balancers)
        if request.headers.get('X-Forwarded-For'):
            client_ip = request.headers.get('X-Forwarded-For').split(',')[0].strip()
        else:
            client_ip = request.remote_addr
        
        # Get current timestamp in ISO 8601 format
        current_timestamp = datetime.utcnow().isoformat() + 'Z'
        
        response = {
            "timestamp": current_timestamp,
            "ip": client_ip
        }
        
        logger.info(f"Request from {client_ip}")
        return jsonify(response), 200
    
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint for load balancers
    
    Returns:
        JSON: {"status": "healthy"}
    """
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    # Run with Gunicorn in production
    # For development: flask run
    app.run(host='0.0.0.0', port=5000, debug=False)
