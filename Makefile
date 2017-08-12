# NOTE: To use github-release, be sure GITHUB_TOKEN is defined in the
#       environment

SHELL := /bin/bash

RELEASE ?= debian/jessie
CODENAME := $(notdir $(RELEASE))

GITHUB_USER := joeblackwaslike
GITHUB_REPO := debian
GITHUB_TAG = $(shell git tag | sort -n | tail -1)

DOCKER_USER = joeblackwaslike
DOCKER_REPO := debian
DOCKER_IMAGE := $(DOCKER_USER)/$(DOCKER_REPO):$(CODENAME)


.PHONY: build-builder build-rootfs build-docker clean test release tag
.PHONY: create-release upload-release

all: build test

build: clean build-paths build-builder build-rootfs build-docker

build-paths:
	mkdir -p base-repo/build

build-builder:
	docker build -t deb-builder base-repo/builder

build-rootfs:
	base-repo/builder/run chanko-upgrade -f
	base-repo/builder/run make clean
	base-repo/builder/run make

build-docker:
	docker build -t $(DOCKER_IMAGE) base-repo
	docker run -i --rm $(DOCKER_IMAGE) bash -lc env

clean:
	-rm -rf base-repo/build

test:
	echo "run tests here"

release: tag create-release upload-release

tag:
	if (( $(shell git tag | wc -l | xargs) == 0 )); then \
		echo git tag 1.0; \
	else \
		echo git tag $(GITHUB_TAG) | awk -F. '1{$$NF+=1; OFS="."; print $$0}'); \
	fi

create-release:
	-git push origin --tags
	docker run -it --rm \
		-e "GITHUB_TOKEN=$(GITHUB_TOKEN)" \
		socialengine/github-release \
		github-release release --user $(GITHUB_USER) --repo $(GITHUB_REPO) \
			--tag $(GITHUB_TAG)

upload-release:
	docker run -it --rm \
		-v "$(PWD):/release" \
        -e "GITHUB_TOKEN=$(GITHUB_TOKEN)" \
		-w /release \
		socialengine/github-release \
		github-release upload --user $(GITHUB_USER) --repo $(GITHUB_REPO) \
			--tag $(GITHUB_TAG) \
			--name $(notdir base-repo/build/rootfs.tar.gz) \
			--file base-repo/build/rootfs.tar.gz

# push-image:
# 	if [[ $(TRAVIS) == 'true' ]]; then \
# 		docker login -u $(DOCKER_USER) -p $(DOCKER_PASS); \
# 	fi
# 	docker push $(DOCKER_IMAGE)
