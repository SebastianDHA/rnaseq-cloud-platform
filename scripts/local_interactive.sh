#! /bin/bash

# Avoid silent failures (e: exit on error; u: error on undefined; o pipeline: exit if any line fails)
set -euo pipefail

# -----------------------------
# Password
# -----------------------------

echo "Generating one-time login password..."

# Generate one-time, cryptograhpically secure password
PASSWORD=$(openssl rand -base64 24)

echo "==========================="
echo "RStudio login credentials"
echo "Username: rstudio"
echo "Password: ${PASSWORD}"
echo "==========================="

# -----------------------------
# Run RStudio container
# -----------------------------

# Fetch docker image digest
IMAGE_DIGEST=$(cat containers/rstudio/image-digests.txt)

# Launch rocker-rstudio image in background (-d) to allow ssm command to return while container still runs
docker run \
  -it \
  --rm \
  -p 8787:8787 \
  -e USER=rstudio \
  -e PASSWORD="${PASSWORD}" \
  --mount type=bind,source=${DATA_DIR},target=/work \
  "${IMAGE_DIGEST}"

echo "==========================="
echo "RStudio running on: http://localhost:8787"
echo "Login with one-time password and username"
echo "==========================="