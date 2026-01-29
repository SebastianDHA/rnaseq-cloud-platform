#! /bin/bash

echo "Commencing S3 bucket setup..."

# Avoid silent failures (e: exit on error; u: error on undefined; o pipeline: exit if any line fails)
set -euo pipefail

# -----------------------------
# File checks
# -----------------------------

echo "Checking set-up files..."

require_file() {
  [[ -f "$1" ]] || {
    echo "ERROR: Required file missing: $1" >&2
    exit 1
  }
}

# Config files
require_file config/env.sh
require_file config/run_batch.sh
require_file config/run_rstudio.sh
require_file config/user_data.sh
require_file ../config.yaml

# IAM policies
require_file iam/ec2-self-stop-policy.json
require_file iam/ec2-ssm-parameter-access-policy.json
require_file iam/s3-access-policy.json
require_file iam/trust-ec2.json

# EC2 EBS config
require_file ec2/block-device-mapping.json

# Snakefile
require_file ../workflow/Snakefile

# Docker image digests
require_file ../containers/batch/image-digest.txt
require_file ../containers/rstudio/image-digest.txt

echo "Checks done."

# -----------------------------
# Configuration
# -----------------------------

source ./config/env.sh

echo "Bucket name: ${BUCKET_NAME}"
echo "Region: ${REGION}"

# -----------------------------
# S3 bucket creation
# -----------------------------

# s3api requires LocationConstraint parameter for backwards-compatibility reasons
aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

# -----------------------------
# Enable default encryption
# -----------------------------

# Encryption at rest defaults (AES256)
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault":
        {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# -----------------------------
# Block public access
# -----------------------------

# Default public access blocks (S3 only privately accessible by EC2 via IAM policy - least privilege)
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

# -----------------------------
# Upload instance-side run-time scripts
# -----------------------------

echo "Confirming bucket exists..."

# Ensure bucket exists
aws s3api wait bucket-exists \
    --bucket "${BUCKET_NAME}"

echo "Uploading server-side run-time scripts"

# Upload run-time files to S3
aws s3 cp config/run_batch.sh s3://${BUCKET_NAME}/scripts/
aws s3 cp config/run_rstudio.sh s3://${BUCKET_NAME}/scripts/
aws s3 cp ../workflow/Snakefile s3://${BUCKET_NAME}/work/
aws s3 cp ../config.yaml s3://${BUCKET_NAME}/work/
aws s3 cp ../containers/batch/image-digest.txt s3://${BUCKET_NAME}/containers/batch/
aws s3 cp ../containers/rstudio/image-digest.txt s3://${BUCKET_NAME}/containers/rstudio/

echo "S3 bucket setup complete."