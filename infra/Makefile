.PHONY: s3 iam sg ec2 up down

s3:
	./scripts/01_s3.sh

iam:
	./scripts/02_iam.sh

sg:
	./scripts/03_security_group.sh

ec2:
	./scripts/04_ec2.sh

up: s3 iam sg ec2
	@echo "Infrastructure provisioned"

down:
	./scripts/99_teardown.sh
	@echo "Infrastructure teardown complete"