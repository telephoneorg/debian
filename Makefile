USER = sip-li
PROJECT = debian
TAG = $(shell git tag | sort -n | tail -1)

ROOTFS = base-repo/build/rootfs.tar.gz

init:
	@cd base-repo && ./init.sh

build:
	@cd base-repo && ./build.sh

build-docker:
	@cd base-repo && ./build-docker.sh

push:
	@cd base-repo && ./push.sh

clean:
	@rm -rf base-repo/build/*

init-tag:
	@git tag -a v1.0 -m "Initial"
	@git push origin v1.0

bump-tag:
	@git tag -a $(shell echo $(TAG) | awk -F. '1{$$NF+=1; OFS="."; print $$0}') -m "New Release"

commit-all:
	@git add .
	@git commit

release:
	@-git push origin $(TAG)
	@github-release release --user $(USER) --repo $(PROJECT) --tag $(TAG)

upload-release:
	@github-release upload --user $(USER) --repo $(PROJECT) --tag $(TAG) --name $(shell basename $(ROOTFS)) --file $(ROOTFS)

default: build

