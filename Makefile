#
# Copyright Greg Haskins All Rights Reserved.
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# -------------------------------------------------------------
# This makefile defines the following targets
#
#   - all - Builds the baseimages and the thirdparty images
#   - docker - Builds the baseimages (baseimage,basejvm,baseos)
#   - dependent-images - Builds the thirdparty images (couchdb,kafka,zookeeper)
#   - couchdb - Builds the couchdb image
#   - kafka - Builds the kafka image
#   - zookeeper - Builds the zookeeper image
#   - install - Builds the baseimage,baseos,basejvm and publishes the images to dockerhub
#   - clean - Cleans all the docker images

DOCKER_NS ?= hyperledger
BASENAME ?= $(DOCKER_NS)/fabric
VERSION ?= 0.4.16
IS_RELEASE=false

ARCH=$(shell go env GOARCH)
BASE_VERSION ?= $(ARCH)-$(VERSION)

ifneq ($(IS_RELEASE),true)
EXTRA_VERSION ?= snapshot-$(shell git rev-parse --short HEAD)
DOCKER_TAG=$(BASE_VERSION)-$(EXTRA_VERSION)
else
DOCKER_TAG=$(BASE_VERSION)
endif

ifneq ($(http_proxy),)
DOCKER_BUILD_FLAGS+=--build-arg 'http_proxy=$(http_proxy)'
endif
ifneq ($(https_proxy),)
DOCKER_BUILD_FLAGS+=--build-arg 'https_proxy=$(https_proxy)'
endif
ifneq ($(HTTP_PROXY),)
DOCKER_BUILD_FLAGS+=--build-arg 'HTTP_PROXY=$(HTTP_PROXY)'
endif
ifneq ($(HTTPS_PROXY),)
DOCKER_BUILD_FLAGS+=--build-arg 'HTTPS_PROXY=$(HTTPS_PROXY)'
endif
ifneq ($(no_proxy),)
DOCKER_BUILD_FLAGS+=--build-arg 'no_proxy=$(no_proxy)'
endif
ifneq ($(NO_PROXY),)
DOCKER_BUILD_FLAGS+=--build-arg 'NO_PROXY=$(NO_PROXY)'
endif

DBUILD = docker build $(DOCKER_BUILD_FLAGS)

# NOTE this is for building the dependent images (kafka, zk, couchdb)
BASE_DOCKER_NS ?= hyperledger

DOCKER_IMAGES = baseos baseimage
DEPENDENT_IMAGES = couchdb kafka zookeeper
DUMMY = .$(DOCKER_TAG)

all: docker dependent-images

build/docker/%/$(DUMMY):
	$(eval TARGET = ${patsubst build/docker/%/$(DUMMY),%,${@}})
	$(eval DOCKER_NAME = $(BASENAME)-$(TARGET))
	@mkdir -p $(@D)
	@echo "Building docker $(TARGET)"
	docker build -f config/$(TARGET)/Dockerfile \
		-t $(DOCKER_NAME) \
		-t $(DOCKER_NAME):$(DOCKER_TAG) \
		.
	@touch $@

build/docker/%/.push: build/docker/%/$(DUMMY)
	@docker login \
		--username=$(DOCKER_HUB_USERNAME) \
		--password=$(DOCKER_HUB_PASSWORD)
	@docker push $(BASENAME)-$(patsubst build/docker/%/.push,%,$@):$(DOCKER_TAG)

docker: $(patsubst %,build/docker/%/$(DUMMY),$(DOCKER_IMAGES))

install: $(patsubst %,build/docker/%/.push,$(DOCKER_IMAGES))

dependent-images: $(DEPENDENT_IMAGES)

dependent-images-install:  $(patsubst %,build/image/%/.push,$(DEPENDENT_IMAGES))

couchdb: build/image/couchdb/$(DUMMY)

kafka: build/image/kafka/$(DUMMY)

zookeeper: build/image/zookeeper/$(DUMMY)

build/image/%/$(DUMMY):
	@mkdir -p $(@D)
	$(eval TARGET = ${patsubst build/image/%/$(DUMMY),%,${@}})
	@echo "Docker: building $(TARGET) image"
	$(DBUILD) ${BUILD_ARGS} -t $(DOCKER_NS)/fabric-$(TARGET) -f images/${TARGET}/Dockerfile images/${TARGET}
	docker tag $(DOCKER_NS)/fabric-$(TARGET) $(DOCKER_NS)/fabric-$(TARGET):$(DOCKER_TAG)
	@touch $@

build/image/%/.push: build/image/%/$(DUMMY)
	@docker login \
		--username=$(DOCKER_HUB_USERNAME) \
		--password=$(DOCKER_HUB_PASSWORD)
	@docker push $(BASENAME)-$(patsubst build/image/%/.push,%,$@):$(DOCKER_TAG)

clean:
	-rm -rf build
