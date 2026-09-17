
from flask import Flask, render_template_string
import os
import socket
from datetime import datetime, timezone

app = Flask(__name__)

HTML = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Docker Demo Dashboard</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #f4f7fb;
            color: #1e293b;
        }

        header {
            background: linear-gradient(135deg, #0f3d68, #2563a6);
            color: white;
            padding: 25px 8%;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        header h2 {
            margin: 0;
            font-size: 25px;
        }

        .status {
            background: #16a34a;
            padding: 8px 18px;
            border-radius: 25px;
            font-size: 14px;
        }

        .hero {
            text-align: center;
            padding: 60px 20px 45px;
            background: linear-gradient(180deg, #e3f2ff, #f4f7fb);
        }

        .hero h1 {
            font-size: 42px;
            margin: 0 0 15px;
            color: #123b66;
        }

        .hero p {
            font-size: 18px;
            color: #64748b;
        }

        .tags {
            margin-top: 20px;
            color: #2563eb;
            font-weight: 600;
            letter-spacing: 1px;
        }

        .container {
            max-width: 1200px;
            margin: auto;
            padding: 30px 20px;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
            gap: 20px;
        }

        .card {
            background: white;
            padding: 25px;
            border-radius: 18px;
            box-shadow: 0 8px 25px rgba(15, 61, 104, 0.06);
            border: 1px solid #e2e8f0;
            transition: transform 0.2s;
        }

        .card:hover {
            transform: translateY(-4px);
        }

        .card h4 {
            color: #64748b;
            margin: 0 0 12px;
            font-weight: 500;
        }

        .card h3 {
            margin: 0;
            font-size: 21px;
            color: #123b66;
            word-break: break-word;
        }

        .icon {
            font-size: 30px;
            margin-bottom: 15px;
        }

        .section {
            margin-top: 25px;
        }

        .wide {
            grid-column: span 2;
        }

        .footer {
            margin-top: 30px;
            padding: 25px;
            text-align: center;
            background: #123b66;
            color: #cbd5e1;
        }

        @media (max-width: 600px) {
            .hero h1 {
                font-size: 30px;
            }

            header {
                padding: 20px;
            }

            .wide {
                grid-column: span 1;
            }
        }
    </style>
</head>

<body>

<header>
    <h2>🐳 Docker Demo</h2>
    <div class="status">● Running</div>
</header>

<section class="hero">
    <h1>Docker All-Instructions Demo</h1>
    <p>A modern Flask application running inside a Docker container.</p>
    <div class="tags">FLASK &nbsp; • &nbsp; PYTHON &nbsp; • &nbsp; DOCKER</div>
</section>

<div class="container">

    <div class="grid">

        <div class="card">
            <div class="icon">📦</div>
            <h4>Application</h4>
            <h3>{{ application }}</h3>
        </div>

        <div class="card">
            <div class="icon">🌱</div>
            <h4>Environment</h4>
            <h3>{{ environment }}</h3>
        </div>

        <div class="card">
            <div class="icon">🌐</div>
            <h4>Port</h4>
            <h3>{{ port }}</h3>
        </div>

        <div class="card">
            <div class="icon">🖥️</div>
            <h4>Container Hostname</h4>
            <h3>{{ hostname }}</h3>
        </div>

        <div class="card wide">
            <div class="icon">✨</div>
            <h4>Status Message</h4>
            <h3>Docker application is running successfully!</h3>
        </div>

        <div class="card">
            <div class="icon">🕒</div>
            <h4>Current Time (UTC)</h4>
            <h3>{{ time_utc }}</h3>
        </div>

        <div class="card wide">
            <div class="icon">💾</div>
            <h4>Volume File Content</h4>
            <h3>{{ volume_file }}</h3>
        </div>

    </div>

</div>

<div class="footer">
    Docker All-Instructions Demo &nbsp; | &nbsp; Flask • Python • Docker
    <br><br>
    ● Healthy &nbsp; | &nbsp; Port 5001
</div>

</body>
</html>
"""


def read_volume_file():
    path = '/data/runtime.txt'

    try:
        with open(path, 'r', encoding='utf-8') as file:
            return file.read().strip()
    except FileNotFoundError:
        return 'runtime.txt not created yet'


@app.route('/')
def home():
    return render_template_string(
        HTML,
        application=os.getenv('APP_NAME', 'docker-demo'),
        environment=os.getenv('APP_ENV', 'unknown'),
        hostname=socket.gethostname(),
        port=5001,
        time_utc=datetime.now(timezone.utc).isoformat(),
        volume_file=read_volume_file()
    )


@app.route('/health')
def health():
    return {'status': 'healthy'}, 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
