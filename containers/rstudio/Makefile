.ONESHELL:

IMAGE_REPO := sebastiandha/rnaseq-cloud-rstudio
IMAGE_TAG := 1.0.1
DIGEST_FILE := image-digest.txt

build:
	docker build -t $(IMAGE_REPO):$(IMAGE_TAG) .

push:
	docker push $(IMAGE_REPO):$(IMAGE_TAG)
	docker pull $(IMAGE_REPO):$(IMAGE_TAG)
	docker inspect \
	--format='{{range .RepoDigests}}{{println .}}{{end}}' \
	$(IMAGE_REPO):$(IMAGE_TAG) \
	| grep '^$(IMAGE_REPO)@' \
	> $(DIGEST_FILE)
	@echo "Resolved image digest:"
	@cat $(DIGEST_FILE)

pull:
	docker pull $$(cat $(DIGEST_FILE))