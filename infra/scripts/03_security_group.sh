#!/bin/bash

echo "Commencing SSM security group & VPC endpoint setup..."

# Avoid silent failures (e: exit on error; u: error on undefined; o pipeline: exit if any line fails)
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------

source ./config/env.sh

# -----------------------------
# Get default VPC ID
# -----------------------------

# Extract VPC ID (as string) from the assigned, default VPC
# Default VPC comes with internet gateway & default/main route table allowing 0.0.0.0/0 -> igw
VPC_ID=$(aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "Using VPC: ${VPC_ID}"

# Resolve subnet in default VPC & chosen AZ
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters \
    Name=vpc-id,Values="${VPC_ID}" \
    Name=availability-zone,Values="${AZ}" \
  --query 'Subnets[0].SubnetId' \
  --output text)

echo "Using subnet: ${SUBNET_ID}"

# -----------------------------
# EC2 security group (egress-only)
# -----------------------------sub

# Create security group & return the generated security group ID
EC2_SG_ID=$(aws ec2 create-security-group \
  --group-name "${EC2_SG_NAME}" \
  --description "Security group for RNA-seq EC2 instance" \
  --vpc-id "${VPC_ID}" \
  --query 'GroupId' \
  --output text \
  --tag-specifications \
  "ResourceType=security-group,Tags=[
  {Key=Project,Value=${PROJECT}},
  {Key=Env,Value=${TAG}},
  {Key=Component,Value=ec2}
  ]")

echo "Created EC2 security group: ${EC2_SG_ID}"

# No inbound traffic by default
# Allow outbound HTTPS port 443 (SSM), includes default VPC internet gateway
aws ec2 authorize-security-group-egress \
  --group-id "${EC2_SG_ID}" \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0 \
  --description "Allow outbound HTTPS via port 443 only"

# Revoke default egress rule (all protocols; all ports; all cidr)
aws ec2 revoke-security-group-egress \
  --group-id "${EC2_SG_ID}" \
  --protocol -1 \
  --cidr 0.0.0.0/0 \
  --description "Revoke default egress rule"

# -----------------------------
# VPC Endpoint security group
# -----------------------------

# Create security group for VPC Endpoint
VPCE_SG_ID=$(aws ec2 create-security-group \
  --group-name "${SSM_SG_NAME}" \
  --description "SG for SSM VPC endpoints" \
  --vpc-id "${VPC_ID}" \
  --query 'GroupId' \
  --output text \
  --tag-specifications \
  "ResourceType=security-group,Tags=[
    {Key=Project,Value=${PROJECT}},
    {Key=Env,Value=${TAG}},
    {Key=Component,Value=ssm}
  ]")

# Allow EC2 SG to reach VPC Endpoints on 443
aws ec2 authorize-security-group-ingress \
  --group-id "${VPCE_SG_ID}" \
  --protocol tcp \
  --port 443 \
  --source-group "${EC2_SG_ID}"

echo "Created VPC Endpoint security group: ${VPCE_SG_ID}"

# -----------------------------
# Create Interface VPC Endpoints
# -----------------------------

# Set up VPC Endpoints for the 3 SSM services for fully private networking (human-AWS-EC2)
for SERVICE in ssm ec2messages ssmmessages; do
  aws ec2 create-vpc-endpoint \
    --vpc-id "${VPC_ID}" \
    --service-name "com.amazonaws.${REGION}.${SERVICE}" \
    --vpc-endpoint-type Interface \
    --subnet-ids "${SUBNET_ID}" \
    --security-group-ids "${VPCE_SG_ID}" \
    --tag-specifications \
    "ResourceType=vpc-endpoint,Tags=[
      {Key=Project,Value=${PROJECT}},
      {Key=Env,Value=${TAG}},
      {Key=Component,Value=ssm}
    ]"
done

echo "SSM VPC Interface endpoints setup complete."

# -----------------------------
# Create Gateway VPC Endpoint
# -----------------------------

# Resolve default VPC main route table (association.main=true)
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters Name=vpc-id,Values="${VPC_ID}" Name=association.main,Values=true \
  --query 'RouteTables[0].RouteTableId' \
  --output text)

# Set up VPC Gateway Endpoint for S3-EC2 networking
aws ec2 create-vpc-endpoint \
  --vpc-id "${VPC_ID}" \
  --service-name "com.amazonaws.${REGION}.s3" \
  --vpc-endpoint-type Gateway \
  --route-table-ids "${ROUTE_TABLE_ID}" \
  --tag-specifications \
  "ResourceType=vpc-endpoint,Tags=[
    {Key=Project,Value=${PROJECT}},
    {Key=Env,Value=${TAG}},
    {Key=Component,Value=s3}
  ]"

echo "SSM VPC Gateway endpoint setup complete."

echo "Security group setup complete."