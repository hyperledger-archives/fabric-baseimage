DOCKER_NS ?= hyperledger
BASENAME ?= $(DOCKER_NS)/fabric
VERSION ?= 0.3.2
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

ifeq ($(DOCKER_BASE), )
$(error "Architecture \"$(ARCH)\" is unsupported")
endif

DOCKER_IMAGES = baseos basejvm baseimage
DUMMY = .$(DOCKER_TAG)

all: docker

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
		--email=$(DOCKER_HUB_EMAIL) \
		--username=$(DOCKER_HUB_USERNAME) \
		--password=$(DOCKER_HUB_PASSWORD)
	@docker push $(BASENAME)-$(patsubst build/docker/%/.push,%,$@):$(DOCKER_TAG)

docker: $(patsubst %,build/docker/%/$(DUMMY),$(DOCKER_IMAGES))

install: $(patsubst %,build/docker/%/.push,$(DOCKER_IMAGES))

clean: remove
	-rm -rf build
