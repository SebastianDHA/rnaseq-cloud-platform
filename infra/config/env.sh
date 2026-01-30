# Global project configs
PROJECT="rnaseq-platform"
TAG="dev"
REGION="eu-west-1"
AZ="eu-west-1a"

# S3 config (01_s3.sh)
# Unique S3 bucket name with caller's Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="${PROJECT}-${TAG}-${ACCOUNT_ID}"

# IAM config (02_iam.sh)
ROLE_NAME="${PROJECT}-${TAG}-EC2-S3-SSM-Access"
S3_POLICY_NAME="${PROJECT}-${TAG}-EC2-S3-Policy"
SSM_POLICY_NAME="${PROJECT}-${TAG}-EC2-SSM-Parameter-Store-Policy"
EC2_SELF_STOP_POLICY_NAME="${PROJECT}-${TAG}-EC2-Self-Stop-Policy"
INSTANCE_PROFILE="${PROJECT}-${TAG}-EC2-instance-profile"

# Security group (03_security_group.sh)
EC2_SG_NAME="${PROJECT}-${TAG}-EC2-SG"
SSM_SG_NAME="${PROJECT}-${TAG}-ssm-endpoints-SG"

# EC2 (04_ec2.sh)
# Amazon Linux 2023 with c6i.4xlarge
AMI_ID="ami-03e091ef64f3907f8"
INSTANCE_TYPE="c6i.4xlarge"
INSTANCE_NAME="${PROJECT}-${TAG}-ec2"
EBS_VOLUME_TYPE="gp3"
EBS_VOLUME_SIZE=500
VPC_NAME="default"
USER_DATA="user_data.sh"
