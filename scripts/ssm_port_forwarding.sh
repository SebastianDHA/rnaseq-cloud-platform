#!/bin/bash

# Avoid silent failures
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------

# Fetch cached instance ID
INSTANCE_ID=$(cat .state/ec2_instance_id)

# -----------------------------
# SSM Port-forwarding 8787
# -----------------------------

echo "Launching SSM port-forwarding..."

aws ssm start-session \
  --target "${INSTANCE_ID}" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["8787"],"localPortNumber":["8787"]}'

echo "==========================="
echo "RStudio running on: http://localhost:8787"
echo "Login with one-time password and username"
echo "Remember to stop EC2 instance when done!"
echo "==========================="