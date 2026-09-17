from flask import Flask, jsonify
import os
import socket
from datetime import datetime, timezone

app = Flask(__name__)

@app.get('/')
def home():
    return jsonify({
        'message': 'Docker all-instructions demo is running!',
        'application': os.getenv('APP_NAME', 'docker-demo'),
        'environment': os.getenv('APP_ENV', 'unknown'),
        'hostname': socket.gethostname(),
        'port': 5001,
        'time_utc': datetime.now(timezone.utc).isoformat(),
        'volume_file': read_volume_file()
    })

@app.get('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

def read_volume_file():
    path = '/data/runtime.txt'
    try:
        with open(path, 'r', encoding='utf-8') as file:
            return file.read().strip()
    except FileNotFoundError:
        return 'runtime.txt not created yet'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
