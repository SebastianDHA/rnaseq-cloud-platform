#! /bin/bash

echo "Commencing IAM role setup..."

# Avoid silent failures (e: exit on error; u: error on undefined; o pipeline: exit if any line fails)
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------

source config/env.sh

# -----------------------------
# Create IAM role
# -----------------------------

echo "Creating IAM role: ${ROLE_NAME}"

# Allow role to assume role (no permissions yet)
aws iam create-role \
  --role-name "${ROLE_NAME}" \
  --assume-role-policy-document file://iam/trust-ec2.json

# -----------------------------
# Attach S3 access policy to role
# -----------------------------

# Create temp policy with BUCKET_NAME substituted for global variable
# Note that IAM cannot interpolate variable names like ${VAR} and can only use wildcards (*)
# Policies must be static not dynamic
sed "s/BUCKET_NAME/${BUCKET_NAME}/g" \
  iam/s3-access-policy.json > /tmp/s3-policy.json

echo "Attaching S3 access policy"

# Inline policy attachment (specific to role not globally used)
aws iam put-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name "${S3_POLICY_NAME}" \
  --policy-document file:///tmp/s3-policy.json

# -----------------------------
# Attach EC2 self-stop policy
# -----------------------------

# Project-scoped EC2 self-stopping policy
sed \
  -e "s/__PROJECT__/${PROJECT}/g" \
  -e "s/__TAG__/${TAG}/g" \
  -e "s/__REGION__/${REGION}/g" \
  iam/ec2-self-stop-policy.json >\
  /tmp/ec2-self-stop-policy.json

echo "Attaching EC2 self-stop policy"

# Inline policy attachment (specific to role not globally used)
aws iam put-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name "${EC2_SELF_STOP_POLICY_NAME}" \
  --policy-document file:///tmp/ec2-self-stop-policy.json

# -----------------------------
# AWS managed SSM policy
# -----------------------------

echo "Attaching AWS-managed SSM policy"

aws iam attach-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# -----------------------------
# SSM Parameter Store access policy
# -----------------------------

echo "Attaching inline SSM Parameter Store access policy"

# Project-scoped SSM Parameter Store
sed \
  -e "s/__PROJECT__/${PROJECT}/g" \
  -e "s/__TAG__/${TAG}/g" \
  -e "s/__REGION__/${REGION}/g" \
  iam/ec2-ssm-parameter-access-policy.json >\
  /tmp/ec2-ssm-parameter-access-policy.json

# Inline policy attachment (specific to role not globally used)
aws iam put-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name "${SSM_POLICY_NAME}" \
  --policy-document file:///tmp/ec2-ssm-parameter-access-policy.json

# -----------------------------
# EC2 Instance profile
# -----------------------------

# Create instance profile (AWS legacy CLI logic)
aws iam create-instance-profile \
  --instance-profile-name "${INSTANCE_PROFILE}"

# Attach role+policy to instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name "${INSTANCE_PROFILE}" \
  --role-name "${ROLE_NAME}"

echo "IAM role setup complete."