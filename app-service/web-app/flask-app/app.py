import logging
from flask import Flask, jsonify, request

# Configure logging
logging.basicConfig(level=logging.INFO)
app = Flask(__name__)
app.logger.setLevel(logging.INFO)

@app.route('/', methods=['GET'])
def hello_world():
    app.logger.info('Hello World API endpoint hit')
    return jsonify({
        "message": "Hello World!",
        "status": "success",
        "timestamp": "2026-02-02T11:59:00Z"
    })

@app.route('/api/health', methods=['GET'])
def health_check():
    app.logger.info('Health check endpoint hit')
    return jsonify({
        "status": "healthy",
        "service": "flask-hello-api"
    })

@app.route('/api/hello/<name>', methods=['GET'])
def greet_user(name):
    app.logger.info(f'Greet endpoint hit for user: {name}')
    return jsonify({
        "message": f"Hello, {name}!",
        "status": "success"
    })

if __name__ == '__main__':
    app.logger.info('Starting Hello World Flask API')
    app.run(debug=True, host='0.0.0.0', port=8000)
