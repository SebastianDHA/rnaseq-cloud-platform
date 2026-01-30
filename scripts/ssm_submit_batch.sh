#!/bin/bash

# Avoid silent failures
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------

# Fetch cached instance ID
INSTANCE_ID=$(cat infra/.state/ec2_instance_id)

# -----------------------------
# Dispatch command via SSM
# -----------------------------

echo "Dispatching batch job via SSM..."

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "${INSTANCE_ID}" \
  --document-name AWS-RunShellScript \
  --comment "RNA-seq batch run" \
  --parameters commands=["sudo /opt/scripts/run_batch.sh"] \
  --query 'Command.CommandId' \
  --output text)

echo "SSM command dispatched: ${COMMAND_ID}"