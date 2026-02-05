# Cloud-native RNA-seq for everyone
This platform features a fully **containerized**, **Snakemake**-orchestrated RNA-seq analysis pipeline for paired-end bulk data. 
It can also be run locally with full parity.

<img src="https://raw.githubusercontent.com/SebastianDHA/rnaseq-cloud-platform/main/docs/images/RNAseq_platform_architecture.drawio.svg">

**Figure 1. AWS architecture diagram.** 
The platform runs on a single EC2 instance (c6i.4xlarge) inside a VPC with only outbound HTTPS (TCP; port 443) traffic.
All control-plane interaction is performed via AWS Systems Manager over VPC endpoints and fully IAM-governed. 
Batch workflow execution is containerized (Docker) and orchestrated with Snakemake. 
Batch mode is executed in a fire-and-forget fashion via SSM ``aws ssm run-command``.
Interactive RStudio execution is containerized and port-forwarded via SSM Session Manager.
RStudio Login is managed with ephemeral, session-based cryptographic passwords, managed with AWS SSM Parameter Store.
Data is stored in S3 and synced to and from the EC2 EBS volume via a VPC Gateway Endpoint over the AWS backbone.
Docker images are automatically pulled from Docker Hub during infrastructure provisioning.

## Features

- **RStudio**: edgeR & limma for the [*easy-as-1,2,3 workflow*](https://doi.org/10.12688/f1000research.9005.3) + Tidyverse & loads of plotting libraries
- **Snakemake**: orchestrated workflow that leverages **FASTQC**, **fastp**, **Salmon** for fast & accurate read mapping (*who needs time-consuming alignment, anyway?*).
- **Docker**: fully containerized workflows and execution modes with bind-mounted volumes for cloud-local parity.
- **AWS Cloud Infrastructure-as-Code (IaC)**: automatic and reproducible infrastructure provisioning and de-provisioning with AWS CLI.
- **Strong security posture**: AWS SSM-managed access, no inbound traffic, no SSH, HTTPS 443 egress-only over VPC endpoints, fully IAM-governed (not static credentials), tightly-scoped IAM policies, SSM Parameter store for session-based RStudio passwords.
- **Cost-aware**: right-sized EC2 instance and EBS volume, single-AZ placement, no NATs, automatic instance stopping after batch execution. Out-of-pocket friendly (*speaking from personal-wallet-experience...*).
- **Simple UX**: Makefile-orchestrated execution for provisioning, deprovisioning, starting, stopping, syncing. Config YAML for Snakemake batch execution.

## Installation
```
gh repo clone SebastianDHA/rnaseq-cloud-platform
```

## Quick-start
```
cd rnaseq-cloud-platform
make provision
make start
make aws-interactive
make stop
```