#!/bin/bash
# Install nginx for serving static content
apt-get update
apt-get install -y nginx

# Wait for instance metadata service to be available
while ! curl -s http://169.254.169.254/latest/meta-data/; do
    sleep 1
done

# Get the backend instance private IP using AWS CLI
apt-get install -y awscli
BACKEND_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=Backend" \
              "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text \
    --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region))

# Create a simple HTML page that will make API calls to backend
cat <<HTMLFILE > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Three Tier App</title>
</head>
<body>
    <h1>Welcome to Our Application</h1>
    <div id="result"></div>
    <script>
        const backendUrl = 'http://' + '$${BACKEND_IP}' + '/api/data';
        fetch(backendUrl)
            .then(response => response.json())
            .then(data => {
                document.getElementById('result').innerHTML = JSON.stringify(data);
            })
            .catch(error => {
                document.getElementById('result').innerHTML = 'Error: ' + error.message;
            });
    </script>
</body>
</html>
HTMLFILE

systemctl enable nginx
systemctl start nginx 