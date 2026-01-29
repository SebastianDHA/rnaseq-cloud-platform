#!/bin/bash

# Avoid silent failures
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------

# Fetch cached instance ID
INSTANCE_ID=$(cat .state/ec2_instance_id)

# Ensure SSM agent online
echo "Waiting for SSM agent..."
aws ssm wait instance-online --instance-ids "${INSTANCE_ID}"

# -----------------------------
# Dispatch command via SSM
# -----------------------------

echo "Dispatching batch job via SSM..."

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "${INSTANCE_ID}" \
  --document-name AWS-RunShellScript \
  --comment "RNA-seq batch run" \
  --parameters commands=["/opt/scripts/run_batch.sh"] \
  --query 'Command.CommandId' \
  --output text)

echo "SSM command dispatched: ${COMMAND_ID}"