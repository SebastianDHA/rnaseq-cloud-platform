#!/bin/bash

# Avoid silent failures
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------

# Fetch cached instance ID
INSTANCE_ID=$(cat infra/.state/ec2_instance_id)

# -----------------------------
# SSM Port-forwarding 8787
# -----------------------------

echo "Launching SSM port-forwarding..."

echo "======================================================"
echo "RStudio runs on: http://localhost:8787"
echo "Login with one-time password and username above"
echo "Exit with CTRL/CMD+C"
echo "Remember to stop EC2 instance when done!"
echo "======================================================"

aws ssm start-session \
  --target "${INSTANCE_ID}" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["8787"],"localPortNumber":["8787"]}'
