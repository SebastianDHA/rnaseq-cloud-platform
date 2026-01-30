#! /bin/bash

# Avoid silent failures (e: exit on error; u: error on undefined; o pipeline: exit if any line fails)
set -euo pipefail

source /etc/platform.env

# -----------------------------
# Retrieve RStudio password
# -----------------------------

# Retrieve one-time password stored in SSM Parameter Store
PASSWORD=$(aws ssm get-parameter \
  --name "/${PROJECT}/${TAG}/rstudio/password" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text)

# -----------------------------
# Run RStudio container
# -----------------------------

# Fetch docker image digest
IMAGE_DIGEST=$(cat /opt/containers/rstudio/image-digest.txt)

# Launch rocker-rstudio image in background (-d) to allow ssm command to return while container still runs
sudo docker run \
  -d \
  --rm \
  -p 8787:8787 \
  -e USER=rstudio \
  -e PASSWORD="${PASSWORD}" \
  --mount type=bind,source=/work,target=/work \
  "${IMAGE_DIGEST}"