#!/bin/bash
# Install Node.js and npm
apt-get update
apt-get install -y nodejs npm awscli

# Get the RDS endpoint using AWS CLI
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "three-tier-app" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text \
    --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region))

# Create a directory for our application
mkdir -p /app
cd /app

# Initialize a new Node.js application
npm init -y

# Install Express.js and MySQL client
npm install express mysql2

# Create the backend API server
cat <<NODEFILE > /app/server.js
const express = require('express');
const mysql = require('mysql2');
const app = express();

const db = mysql.createConnection({
    host: '$${DB_ENDPOINT}',
    user: 'admin',
    password: process.env.DB_PASSWORD,
    database: 'appdb'
});

app.use(express.json());

// Enable CORS for frontend
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    next();
});

// Sample API endpoint
app.get('/api/data', async (req, res) => {
    db.query('SELECT * FROM sample_table', (err, results) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(results);
    });
});

app.listen(80, () => {
    console.log('Backend server running on port 80');
});
NODEFILE

# Create a systemd service for the Node.js application
cat <<'SERVICEFILE' > /etc/systemd/system/backend.service
[Unit]
Description=Backend Node.js Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/app
ExecStart=/usr/bin/node server.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICEFILE

# Start the backend service
systemctl enable backend
systemctl start backend 