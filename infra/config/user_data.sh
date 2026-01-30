#!/bin/bash

# Abort immediately if any step below exits with non-zero status
# Fail early and loud, avoid half-configured instance
set -euo pipefail

# Export global configuration variables
export BUCKET_NAME="__BUCKET_NAME__"
export PROJECT="__PROJECT__"
export TAG="__TAG__"

# Persist variables on instance in /etc/platform.env
cat <<EOF >/etc/platform.env
BUCKET_NAME=${BUCKET_NAME}
PROJECT=${PROJECT}
TAG=${TAG}
EOF

# Install Docker using dnf (RHEL/Fedora package manager for Amazon Linux 2023 AMI)
# Update metadata and apply security patches - before install always
dnf update -y
dnf install -y docker

# Automatically register & start Docker on boot always (systemctl)
systemctl enable docker
systemctl start docker

# Add SSM Agent explicitly (in case not included by default in AMI)
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install awscli (if not there)
dnf install -y awscli

# Create working directory mount point
mkdir -p /work

# Create directory for instance-side runtime scripts
mkdir -p /opt/scripts

# Create directory for image digests
mkdir -p /opt/containers

# Change ownership of created directories from root to ec2-user
chown ec2-user:ec2-user /work
chown ec2-user:ec2-user /opt/scripts
chown ec2-user:ec2-user /opt/containers

# Copy over run-time scripts
aws s3 cp s3://${BUCKET_NAME}/scripts/ /opt/scripts/ --recursive
aws s3 cp s3://${BUCKET_NAME}/containers/ /opt/containers/ --recursive
aws s3 cp s3://${BUCKET_NAME}/work/ /work --recursive

# Make scripts executable
chmod +x /opt/scripts/*
chmod +x /work/*

# Pull docker images by digest
echo "Pulling docker images..."
docker pull "$(cat /opt/containers/batch/image-digest.txt)"
docker pull "$(cat /opt/containers/rstudio/image-digest.txt)"
echo "Successfully pulled images."

echo "Bootstrap complete!"

# Write bootstrap success marker to SSM Parameter Store for client-side verification of successful provisioning and configuration
aws ssm put-parameter \
  --name "/${PROJECT}/${TAG}/bootstrap/complete" \
  --type String \
  --value "Bootstrap successful: $(date -Is)" \
  --overwrite

# Confirm successful launch by inspecting "/var/log/cloud-init-output.log"
