#!/bin/bash

# Avoid silent failures
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------

source infra/config/env.sh

# -----------------------------
# Password
# -----------------------------

echo "Generating one-time login password..."

# Generate one-time, cryptograhpically secure password
PASSWORD=$(openssl rand -base64 24)

# Store in SSM Parameter Store with overwrite and encryption at rest
aws ssm put-parameter \
  --name "/${PROJECT}/${TAG}/rstudio/password" \
  --type SecureString \
  --value "${PASSWORD}" \
  --overwrite

echo ""
echo "======================================================"
echo "RStudio login credentials"
echo "Username: rstudio"
echo "Password: ${PASSWORD}"
echo "======================================================"
echo ""
