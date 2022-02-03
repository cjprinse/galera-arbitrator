SHELL=/bin/bash

# Ensure targets are deleted when an error occurred executing the recipe
.DELETE_ON_ERROR:

# Allows usage of automatic variables in prerequisites
.SECONDEXPANSION:

MAKEFLAGS += --warn-undefined-variables

DOCKER_IMAGE := cprinse/galera-arbitrator
VERSION=$(filter-out publish, $(MAKECMDGOALS))

.PHONY: build
build: DOCKER_TAG = $(shell echo ${DOCKER_IMAGE}:${VERSION} | tr '[:upper:]' '[:lower:]')
build:
	@echo $(DOCKER_IMAGE)
	@echo VERSION: ${VERSION}
	docker build --progress plain -t $(DOCKER_TAG) .

.PHONY: publish
publish: DOCKER_TAG = $(shell echo ${DOCKER_IMAGE}:${VERSION} | tr '[:upper:]' '[:lower:]')
publish: build
	docker push $(DOCKER_TAG)


.DEFAULT_GOAL := publish

