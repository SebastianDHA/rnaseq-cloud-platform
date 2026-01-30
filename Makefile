SHELL := /bin/bash
.ONESHELL:

BUCKET_NAME := $(shell sh -c '. infra/config/env.sh && printf "%s" "$$BUCKET_NAME"')
export BUCKET_NAME

# -----------------------------
# 1. Project configuration
# -----------------------------

# Path to project data (replace here or include in make calls as argument)
export DATA_DIR ?= $(PWD)

# -----------------------------
# 2a. Architecture provisioning
# -----------------------------

provision:
	$(MAKE) -C infra up
	@./scripts/ec2_stop.sh

deprovision:
	@./scripts/ec2_stop.sh
	$(MAKE) -C infra down

# -----------------------------
# 2b. Docker image pull - local
# -----------------------------

pull-images:
	$(MAKE) -C containers/batch pull
	$(MAKE) -C containers/rstudio pull

# -----------------------------
# 3a. AWS execution modes
# -----------------------------

aws-batch:
	@./scripts/ec2_start.sh
	@./scripts/ssm_submit_batch.sh

aws-interactive:
	@./scripts/ec2_start.sh
	@./scripts/generate_rstudio_password.sh
	@./scripts/ssm_launch_rstudio.sh
	@./scripts/ssm_port_forwarding.sh

# -----------------------------
# 3b. Local execution modes
# -----------------------------

# Example usage: make local-batch DATA_DIR=path/to/myproject
local-batch:
	@./scripts/local_batch.sh

local-interactive:
	@./scripts/local_interactive.sh

# -----------------------------
# AWS resource helpers
# -----------------------------

# EC2
# Start & stop instance
start:
	@./scripts/ec2_start.sh

stop:
	@./scripts/ec2_stop.sh

# Fetch EC2 instance ID
get-ec2:
	@cat infra/.state/ec2_instance_id

# S3
# EC2 -> S3 sync
to-s3:
	aws s3 sync "/work" "s3://$(BUCKET_NAME)/work"

# S3 -> EC2 sync
from-s3:
	aws s3 sync "s3://$(BUCKET_NAME)/work" "/work"

# Fetch S3 bucket name
get-s3:
	@echo $(BUCKET_NAME)
