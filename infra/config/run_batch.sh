#! /bin/bash

# Avoid silent failures (e: exit on error; u: error on undefined; o pipeline: exit if any line fails)
set -euo pipefail

source /etc/platform.env

# -----------------------------
# Lock file to prevent racing
# -----------------------------

LOCK_FILE="/var/lock/platform_batch.lock"
exec 9>"${LOCK_FILE}"

if ! flock -n 9; then
  echo "Another batch job is already running. Exiting..."
  exit 1
fi

# If fail, attempt to sync partial results and then stop instance
cleanup() {
  echo "Syncing results to S3 (best effort)..."
  aws s3 sync /work "s3://${BUCKET_NAME}/work" || true

  echo "Stopping instance..."
  INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  aws ec2 stop-instances --instance-ids "${INSTANCE_ID}" || true
}

trap cleanup EXIT

# -----------------------------
# S3 sync to EC2
# -----------------------------

echo "Syncing from S3 to EC2..."

aws s3 sync "s3://${BUCKET_NAME}/work" "/work"

echo "Sync complete."

# -----------------------------
# Run docker batch container
# -----------------------------

IMAGE_DIGEST=$(cat /opt/containers/batch/image-digest.txt)

# Run batch container & mount work directory
sudo docker run \
  --rm \
  --mount type=bind,source=/work,target=/work \
  "${IMAGE_DIGEST}" \
  snakemake

# -----------------------------
# S3 sync from EC2
# -----------------------------

echo "Syncing results to S3..."

aws s3 sync "/work" "s3://${BUCKET_NAME}/work"

echo "Sync complete."

# -----------------------------
# Auto-stop EC2
# -----------------------------

echo "Stopping instance..."

# Fetch instance ID
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Stop instance
aws ec2 stop-instances --instance-ids "${INSTANCE_ID}"