#!/bin/bash

echo "Commencing infrastructure teardown..."

# Avoid silent failures (e: exit on error; u: error on undefined; o pipeline: exit if any line fails)
set -euo pipefail

# -----------------------------
# Config
# -----------------------------

source ./config/env.sh

# -----------------------------
# Terminate EC2 instance
# -----------------------------

# Fetch EC2 instance IDs associated with project
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters \
    "Name=tag:Name,Values=${INSTANCE_NAME}" \
    "Name=tag:Project,Values=${PROJECT}" \
    "Name=tag:Env,Values=${TAG}" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [ -n "${INSTANCE_IDS}" ]; then
  aws ec2 terminate-instances --instance-ids ${INSTANCE_IDS}
  aws ec2 wait instance-terminated --instance-ids ${INSTANCE_IDS}
fi

# Remove instance ID cache
rm -r .state

# -----------------------------
# Delete VPC endpoints
# -----------------------------

# Fetch VPC interface endpoint IDs
VPC_ENDPOINT_IDS=$(aws ec2 describe-vpc-endpoints \
  --filters \
    "Name=tag:Project,Values=${PROJECT}" \
    "Name=tag:Env,Values=${TAG}" \
    "Name=tag:Component,Values=ssm,s3" \
  --query "VpcEndpoints[].VpcEndpointId" \
  --output text)

if [ -n "${VPC_ENDPOINT_IDS}" ]; then
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids ${VPC_ENDPOINT_IDS}
  echo "Waiting for endpoint teardown..."
  sleep 180
fi

# -----------------------------
# Delete security groups
# -----------------------------

SG_IDS=$(aws ec2 describe-security-groups \
  --filters \
    "Name=tag:Project,Values=${PROJECT}" \
    "Name=tag:Env,Values=${TAG}" \
  --query "SecurityGroups[].GroupId" \
  --output text)

for SG_ID in ${SG_IDS}; do
  aws ec2 delete-security-group --group-id "${SG_ID}" || true
done

# -----------------------------
# Remove IAM instance profile
# -----------------------------

# Note: instance profiles cannot be deleted with an attached role
aws iam remove-role-from-instance-profile \
  --instance-profile-name "${INSTANCE_PROFILE}" \
  --role-name "${ROLE_NAME}" \
  || true

aws iam delete-instance-profile \
  --instance-profile-name "${INSTANCE_PROFILE}" \
  || true

# -----------------------------
# Remove IAM policies & roles
# -----------------------------

# Delete inline policies
# S3 access
aws iam delete-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name "${S3_POLICY_NAME}" \
  || true

# SSM parameter access
aws iam delete-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name "${SSM_POLICY_NAME}" \
  || true

# EC2 self-stop
aws iam delete-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name "${EC2_SELF_STOP_POLICY_NAME}" \
  || true

# Detach managed policy
# SSM
aws iam detach-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore \
  || true

# Delete role
aws iam delete-role \
  --role-name "${ROLE_NAME}" \
  || true

# -----------------------------
# Empty and delete S3 bucket
# -----------------------------

aws s3 rm "s3://${BUCKET_NAME}" --recursive \
  || true

aws s3api delete-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  || true
