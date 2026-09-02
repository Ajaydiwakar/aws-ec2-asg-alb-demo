from flask import Flask, render_template_string
import requests
import os

app = Flask(__name__)

# EC2 Instance Metadata Service
METADATA_URL = "http://169.254.169.254/latest/meta-data/"

# Cache IMDSv2 token so we don't request a new token for every metadata call.
_METADATA_TOKEN = None


def get_metadata_token():
    """
    Get an IMDSv2 token from the EC2 Instance Metadata Service.
    """
    global _METADATA_TOKEN

    if _METADATA_TOKEN:
        return _METADATA_TOKEN

    try:
        response = requests.put(
            "http://169.254.169.254/latest/api/token",
            headers={
                "X-aws-ec2-metadata-token-ttl-seconds": "21600"
            },
            timeout=2,
        )

        if response.status_code == 200:
            _METADATA_TOKEN = response.text
            return _METADATA_TOKEN

    except Exception:
        pass

    return None


def get_metadata(path):
    """
    Read metadata from the EC2 Instance Metadata Service.
    """

    headers = {}

    token = get_metadata_token()

    if token:
        headers["X-aws-ec2-metadata-token"] = token

    try:
        response = requests.get(
            METADATA_URL + path,
            headers=headers,
            timeout=2,
        )

        if response.status_code == 200:
            return response.text.strip()

    except Exception:
        pass

    return "Unavailable"


def get_network_metadata():
    """
    Retrieve subnet ID and VPC ID from EC2 metadata.
    """

    macs = get_metadata("network/interfaces/macs")

    if macs == "Unavailable":
        return "Unavailable", "Unavailable"

    lines = macs.splitlines()

    if not lines:
        return "Unavailable", "Unavailable"

    # Remove the trailing slash returned by IMDS.
    mac = lines[0].strip().rstrip("/")

    if not mac:
        return "Unavailable", "Unavailable"

    subnet = get_metadata(
        f"network/interfaces/macs/{mac}/subnet-id"
    )

    vpc = get_metadata(
        f"network/interfaces/macs/{mac}/vpc-id"
    )

    return subnet, vpc


@app.route("/health")
def health():
    """
    ALB health check endpoint.

    The ALB should receive HTTP 200 from this endpoint.
    """

    return "OK", 200


@app.route("/")
def home():

    instance_id = get_metadata("instance-id")

    private_ip = get_metadata("local-ipv4")

    public_ip = get_metadata("public-ipv4")

    hostname = get_metadata("hostname")

    az = get_metadata("placement/availability-zone")

    subnet, vpc = get_network_metadata()

    if subnet == "Unavailable":
        subnet = "Not available"

    if vpc == "Unavailable":
        vpc = "Not available"

    if public_ip == "Unavailable":
        public_ip = "No public IP assigned"

    html = f"""
    <!DOCTYPE html>

    <html>

    <head>

        <title>AWS EC2 ASG ALB Demo</title>

        <meta name="viewport"
              content="width=device-width, initial-scale=1.0">

        <style>

            body {{
                margin: 0;
                font-family: Arial, sans-serif;
                background: #f4f6f8;
                color: #222;
            }}

            .header {{
                background: #232f3e;
                color: white;
                padding: 30px 20px;
                text-align: center;
            }}

            .header h1 {{
                margin: 0 0 10px 0;
            }}

            .header p {{
                margin: 0;
                font-size: 17px;
            }}

            .container {{
                max-width: 950px;
                margin: 40px auto;
                padding: 20px;
            }}

            .welcome {{
                background: white;
                padding: 30px;
                border-radius: 12px;
                box-shadow: 0 4px 15px rgba(0,0,0,0.10);
                text-align: center;
            }}

            .welcome h1 {{
                color: #232f3e;
            }}

            .welcome p {{
                font-size: 17px;
                line-height: 1.6;
            }}

            .instance {{
                background: #ff9900;
                color: white;
                padding: 18px;
                border-radius: 8px;
                font-size: 20px;
                font-weight: bold;
                word-break: break-word;
            }}

            .status {{
                display: inline-block;
                margin-top: 20px;
                padding: 10px 18px;
                border-radius: 20px;
                background: #e8f5e9;
                color: #1b5e20;
                font-weight: bold;
            }}

            .server {{
                margin-top: 30px;
                background: white;
                padding: 25px;
                border-radius: 12px;
                box-shadow: 0 4px 15px rgba(0,0,0,0.10);
            }}

            .server h2 {{
                color: #232f3e;
                margin-top: 0;
            }}

            .row {{
                display: flex;
                justify-content: space-between;
                gap: 20px;
                padding: 15px;
                border-bottom: 1px solid #ddd;
            }}

            .row:last-child {{
                border-bottom: none;
            }}

            .label {{
                font-weight: bold;
                color: #555;
            }}

            .value {{
                font-family: monospace;
                color: #111;
                text-align: right;
                word-break: break-all;
            }}

            .architecture {{
                margin-top: 30px;
                background: #232f3e;
                color: white;
                padding: 25px;
                border-radius: 12px;
            }}

            .architecture h2 {{
                margin-top: 0;
            }}

            .architecture pre {{
                overflow-x: auto;
                line-height: 1.5;
            }}

            @media (max-width: 700px) {{

                .row {{
                    flex-direction: column;
                    gap: 5px;
                }}

                .value {{
                    text-align: left;
                }}

            }}

        </style>

    </head>


    <body>

        <div class="header">

            <h1>AWS EC2 + ASG + ALB Demo</h1>

            <p>
                Application successfully deployed!
            </p>

        </div>


        <div class="container">


            <div class="welcome">

                <div class="instance">

                    🚀 SERVED BY:

                    {instance_id}

                </div>


                <div class="status">

                    ✓ Application Healthy

                </div>


                <h1>
                    Hello! Welcome 👋
                </h1>


                <p>

                    This request is being served by EC2 instance

                    <strong>{instance_id}</strong>

                    running in Availability Zone

                    <strong>{az}</strong>.

                </p>


                <p>

                    The instance belongs to subnet

                    <strong>{subnet}</strong>

                    inside VPC

                    <strong>{vpc}</strong>.

                </p>

            </div>



            <div class="server">

                <h2>
                    🖥️ EC2 Instance Information
                </h2>


                <div class="row">

                    <span class="label">
                        Instance ID
                    </span>

                    <span class="value">
                        {instance_id}
                    </span>

                </div>


                <div class="row">

                    <span class="label">
                        Private IP
                    </span>

                    <span class="value">
                        {private_ip}
                    </span>

                </div>


                <div class="row">

                    <span class="label">
                        Public IP
                    </span>

                    <span class="value">
                        {public_ip}
                    </span>

                </div>


                <div class="row">

                    <span class="label">
                        Hostname
                    </span>

                    <span class="value">
                        {hostname}
                    </span>

                </div>


                <div class="row">

                    <span class="label">
                        Availability Zone
                    </span>

                    <span class="value">
                        {az}
                    </span>

                </div>


                <div class="row">

                    <span class="label">
                        Subnet
                    </span>

                    <span class="value">
                        {subnet}
                    </span>

                </div>


                <div class="row">

                    <span class="label">
                        VPC
                    </span>

                    <span class="value">
                        {vpc}
                    </span>

                </div>

            </div>



            <div class="architecture">

                <h2>
                    AWS Architecture
                </h2>

                <pre>
Internet
   |
   v
Application Load Balancer
   |
   v
Target Group :6100
   |
   +--------------------+
   |                    |
   v                    v
EC2 Instance A      EC2 Instance B
Private Subnet      Private Subnet
   |                    |
   +--------+-----------+
            |
         ASG
            |
        systemd
            |
          Flask
                </pre>

            </div>


        </div>

    </body>

    </html>
    """

    return render_template_string(html)


if __name__ == "__main__":

    app.run(
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", "6100")),
        debug=False,
        use_reloader=False,
        threaded=True,
    )