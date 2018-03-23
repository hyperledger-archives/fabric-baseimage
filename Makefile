#
# Copyright Greg Haskins All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

DOCKER_NS ?= hyperledger
BASENAME ?= $(DOCKER_NS)/fabric
VERSION ?= 0.4.8
IS_RELEASE=false

ARCH=$(shell uname -m)
BASE_VERSION ?= $(ARCH)-$(VERSION)

ifneq ($(IS_RELEASE),true)
EXTRA_VERSION ?= snapshot-$(shell git rev-parse --short HEAD)
DOCKER_TAG=$(BASE_VERSION)-$(EXTRA_VERSION)
else
DOCKER_TAG=$(BASE_VERSION)
endif

DOCKER_BASE_x86_64=ubuntu:xenial
DOCKER_BASE_s390x=s390x/debian:jessie
DOCKER_BASE_ppc64le=ppc64le/ubuntu:xenial
DOCKER_BASE_armv7l=armv7/armhf-ubuntu

DOCKER_BASE=$(DOCKER_BASE_$(ARCH))

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
BASE_IMAGE_RELEASE=0.4.5
BASE_DOCKER_NS ?= hyperledger
BASE_DOCKER_TAG=$(ARCH)-$(BASE_IMAGE_RELEASE)

ifeq ($(DOCKER_BASE), )
$(error "Architecture \"$(ARCH)\" is unsupported")
endif

DOCKER_IMAGES = baseos basejvm baseimage
DUMMY = .$(DOCKER_TAG)

all: docker dependent-images

build/docker/basejvm/$(DUMMY): build/docker/baseos/$(DUMMY)
build/docker/baseimage/$(DUMMY): build/docker/basejvm/$(DUMMY)

build/docker/%/$(DUMMY):
	$(eval TARGET = ${patsubst build/docker/%/$(DUMMY),%,${@}})
	$(eval DOCKER_NAME = $(BASENAME)-$(TARGET))
	@mkdir -p $(@D)
	@echo "Building docker $(TARGET)"
	@cat config/$(TARGET)/Dockerfile.in \
		| sed -e 's|_DOCKER_BASE_|$(DOCKER_BASE)|g' \
		| sed -e 's|_NS_|$(DOCKER_NS)|g' \
		| sed -e 's|_TAG_|$(DOCKER_TAG)|g' \
		> $(@D)/Dockerfile
	docker build -f $(@D)/Dockerfile \
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

dependent-images: couchdb kafka zookeeper

couchdb: build/image/couchdb/.dummy

kafka: build/image/kafka/.dummy

zookeeper: build/image/zookeeper/.dummy

build/image/%/payload:
	mkdir -p $@
	cp $^ $@

build/image/zookeeper/payload:  images/zookeeper/docker-entrypoint.sh
build/image/kafka/payload:      images/kafka/docker-entrypoint.sh \
				images/kafka/kafka-run-class.sh
build/image/couchdb/payload:	images/couchdb/docker-entrypoint.sh \
				images/couchdb/local.ini \
				images/couchdb/vm.args

.PRECIOUS: build/image/%/Dockerfile

build/image/%/Dockerfile: images/%/Dockerfile.in
	@cat $< \
		| sed -e 's/_BASE_NS_/$(BASE_DOCKER_NS)/g' \
		| sed -e 's/_NS_/$(DOCKER_NS)/g' \
		| sed -e 's/_BASE_TAG_/$(BASE_DOCKER_TAG)/g' \
		| sed -e 's/_TAG_/$(BASE_VERSION)/g' \
		> $@
	@echo LABEL $(BASE_DOCKER_LABEL).version=$(PROJECT_VERSION) \\>>$@
	@echo "     " $(BASE_DOCKER_LABEL).base.version=$(BASE_VERSION)>>$@

build/image/%/.dummy: Makefile build/image/%/payload build/image/%/Dockerfile
	$(eval TARGET = ${patsubst build/image/%/.dummy,%,${@}})
	@echo "Building docker $(TARGET)-image"
	$(DBUILD) -t $(DOCKER_NS)/fabric-$(TARGET) $(@D)
	docker tag $(DOCKER_NS)/fabric-$(TARGET) $(DOCKER_NS)/fabric-$(TARGET):$(BASE_VERSION)
	@touch $@

clean:
	-rm -rf build
