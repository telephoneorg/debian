USER = sip-li 
PROJECT = debian
TAG = $(shell git tag | sort -n | tail -1)

BIN_FILES = $(shell ls bin)


init:
    @cd base-repo && ./init.sh

build:
    @cd base-repo && ./build.sh

push:
    @cd base-repo && ./push.sh

clean:
    @rm -rf base-repo/build/*

bump-tag:
    @git tag -a $(shell echo $(TAG) | awk -F. '1{$$NF+=1; OFS="."; print $$0}') -m "New Release"

commit-all:
    @git add .
    @git commit

push:
    @git push origin master

release:
    @-git push origin $(TAG)
    @github-release release --user $(USER) --repo $(PROJECT) --tag $(TAG)

upload-release:
    @for f in $(BIN_FILES); do github-release upload --user $(USER) --repo $(PROJECT) --tag $(TAG) --name "$$f" --file "bin/$$f"; done

default: build

