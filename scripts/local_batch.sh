#! /bin/bash

# Avoid silent failures (e: exit on error; u: error on undefined; o pipeline: exit if any line fails)
set -euo pipefail

# -----------------------------
# Prepare local work directory
# -----------------------------

mkdir -p local-work
cp workflow/Snakefile local-work/
cp config.yaml local-work/

# -----------------------------
# Launch docker batch container
# -----------------------------

# Fetch docker image digest
IMAGE_DIGEST=$(cat containers/batch/image-digest.txt)

docker run --rm \
  --mount type=bind,source=$(PWD)/local-work,target=/work \
  --mount type=bind,source=${DATA_DIR},target=/work/samples \
  "${IMAGE_DIGEST}" \
  snakemake --directory /work/samples --Snakefile /work/Snakefile --configfile /work/config.yaml