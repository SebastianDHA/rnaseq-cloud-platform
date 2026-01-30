#!/bin/bash

# Avoid silent failures (e: exit on error; u: error on undefined; o pipeline: exit if any line fails)
set -euo pipefail

# -----------------------------
# Fetch instance state
# -----------------------------

source ./infra/config/env.sh

# Retrieved cached instance ID
STATE_FILE="infra/.state/ec2_instance_id"
if [[ -f ${STATE_FILE} ]]; then
  INSTANCE_ID=$(cat "${STATE_FILE}")
else
  echo "Instance ID cache is missing. Please re-provision architecture!"
  exit 1
fi

# Fetch EC2 instance state
STATE=$(aws ec2 describe-instances \
--instance-ids "${INSTANCE_ID}" \
--query "Reservations[0].Instances[0].State.Name" \
--output text)

# If instance ID does not resolve state, exit
if [[ -z "${STATE}" ]]; then
  echo "Cached EC2 instance no longer exists. Please re-provision."
  rm -r "${STATE_FILE}"
  exit 1
fi

# -----------------------------
# Configuration
# -----------------------------

echo "Checking EC2 instance status..."

case "${STATE}" in
  running)
    echo "Instance running"
    ;;

  pending)
    echo "Instance pending..."
    aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}"
    echo "Instance running."
    ;;

  stopped)
    echo "Instance stopped. Re-starting..."
    aws ec2 start-instances --instance-ids "${INSTANCE_ID}"
    aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}"
    echo "Instance running."
    ;;

  stopping)
    echo "Instance stopping... Waiting, then restarting.."
    aws ec2 wait instance-stopped --instance-ids "${INSTANCE_ID}"
    echo "Re-starting instance..."
    aws ec2 start-instances --instance-ids "${INSTANCE_ID}"
    aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}"
    echo "Instance running."
    ;;

  shutting-down)
    echo "Instance is preparing to be terminated..."
    aws ec2 wait instance-terminated --instance-ids "${INSTANCE_ID}"
    echo "Please re-provision architecture!"
    exit 0
    ;;

  terminated)
    echo "The instance has been permanently deleted and cannot be restarted. Please re-provision architecture!"
    exit 0
    ;;

  *)
    if [[ -z ${INSTANCE_ID} ]]; then
      echo "No instance found. Please provision architecture!"
      exit 0
    else
      echo "Unknown instance state..."
      exit 1
    fi
    ;;

esac