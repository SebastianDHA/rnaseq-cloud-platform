#!/bin/bash

# Abort immediately if any step below exits with non-zero status
# Fail early and loud, avoid half-configured instance
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------

source config/env.sh

# -----------------------------
# SSM parameter store fetch
# -----------------------------

echo "Verifying bootstrap..."

# Fetch bootstrap success marker
BOOTSTRAP_CHECK=$(aws ssm get-parameter \
  --name /${PROJECT}/${TAG}/bootstrap/complete \
  --query 'Parameter.Value' \
  --output text)

echo "$BOOTSTRAP_CHECK}"