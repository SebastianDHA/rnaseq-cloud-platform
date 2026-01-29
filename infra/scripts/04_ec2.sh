#!/bin/bash

echo "Commencing EC2 launch..."

# Avoid silent failures (e: exit on error; u: error on undefined; o pipeline: exit if any line fails)
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------

source ./config/env.sh

# Resolve Security group ID
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values="${EC2_SG_NAME}" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Extract VPC ID (as string) from the assigned, default VPC
VPC_ID=$(aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' \
  --output text)

# Resolve subnet ID for chosen AZ
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters \
    Name=vpc-id,Values="${VPC_ID}" \
    Name=availability-zone,Values="${AZ}" \
  --query 'Subnets[0].SubnetId' \
  --output text)

# EBS block device mapping
sed \
  -e "s/__EBS_VOLUME_SIZE__/${EBS_VOLUME_SIZE}/g" \
  -e "s/__EBS_VOLUME_TYPE__/${EBS_VOLUME_TYPE}/g" \
  ec2/block-device-mapping.json >\
  /tmp/block-device-mapping.json

# Ensure EC2 instance profile exists
aws iam wait instance-profile-exists \
  --instance-profile-name "${INSTANCE_PROFILE}"

# -----------------------------
# Launch instance
# -----------------------------

echo "Launching EC2 instance: ${INSTANCE_NAME}..."

# User data with global variables exported
sed \
  -e "s|__BUCKET_NAME__|${BUCKET_NAME}|g" \
  -e "s|__PROJECT__|${PROJECT}|g" \
  -e "s|__TAG__|${TAG}|g" \
  config/user_data.sh > /tmp/user_data.sh

# Launch EC2
aws ec2 run-instances \
  --region "${REGION}" \
  --image-id "${AMI_ID}" \
  --instance-type "${INSTANCE_TYPE}" \
  --placement AvailabilityZone="${AZ}" \
  --iam-instance-profile Name="${INSTANCE_PROFILE}" \
  --network-interfaces '[
    {
      "DeviceIndex": 0,
      "SubnetId": "'"${SUBNET_ID}"'",
      "Groups": ["'"${SG_ID}"'"],
      "AssociatePublicIpAddress": false
    }
  ]' \
  --user-data file:///tmp/user_data.sh \
  --block-device-mappings file:///tmp/block-device-mapping.json \
  --tag-specifications \
  "ResourceType=instance,Tags=[
    {Key=Name,Value=${INSTANCE_NAME}},
    {Key=Project,Value=${PROJECT}},
    {Key=Env,Value=${TAG}},
    {Key=Component,Value=ec2}
  ]"

# -----------------------------
# Cache instance ID
# -----------------------------

echo "Caching instance ID..."

mkdir -p .state

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters \
    "Name=tag:Name,Values=${INSTANCE_NAME}" \
    "Name=tag:Project,Values=${PROJECT}" \
    "Name=tag:Env,Values=${TAG}" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

STATE_FILE=".state/ec2_instance_id"
echo "${INSTANCE_ID}" > "${STATE_FILE}"

echo "EC2 launch complete."
