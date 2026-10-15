#!/bin/bash
# Launch Template User Data for the App tier (Amazon Linux 2023)
# Replace the placeholders before use. Never commit real credentials.

dnf install -y python3-pip
pip3 install flask pymysql
mkdir -p /opt/app

cat > /opt/app/app.py << 'EOF'
import os, pymysql
from flask import Flask
app = Flask(__name__)

def conn():
    return pymysql.connect(host=os.environ["DB_HOST"], user=os.environ["DB_USER"],
                           password=os.environ["DB_PASS"], database=os.environ["DB_NAME"],
                           connect_timeout=5)

@app.route("/health")
def health():
    return "ok", 200

@app.route("/")
def home():
    try:
        c = conn(); cur = c.cursor()
        cur.execute("SELECT NOW()")
        t = cur.fetchone()[0]; c.close()
        return f"<h1>3-Tier App</h1><p>DB connected. Time: {t}</p><p>Server: {os.uname().nodename}</p>"
    except Exception as e:
        return f"DB error: {e}", 500

app.run(host="0.0.0.0", port=80)
EOF

cat > /etc/systemd/system/app.service << 'EOF'
[Unit]
Description=3-Tier Flask App
After=network-online.target

[Service]
Environment=DB_HOST=YOUR_RDS_ENDPOINT
Environment=DB_USER=admin
Environment=DB_NAME=appdb
Environment=DB_PASS=YOUR_DB_PASSWORD
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now app
