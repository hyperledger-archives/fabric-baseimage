DOCKER_NS ?= hyperledger
BASENAME ?= $(DOCKER_NS)/fabric
NAME ?= $(BASENAME)-baseimage
VERSION ?= $(shell cat ./release)
IS_RELEASE=false

ARCH=$(shell uname -m)
DOCKER_TAG ?= $(ARCH)-$(VERSION)
VAGRANTIMAGE=baseimage-v$(VERSION).box

DOCKER_BASE_x86_64=ubuntu:xenial
DOCKER_BASE_s390x=s390x/debian:jessie
DOCKER_BASE_ppc64le=ppc64le/ubuntu:xenial

DOCKER_BASE=$(DOCKER_BASE_$(ARCH))

ifeq ($(DOCKER_BASE), )
$(error "Architecture \"$(ARCH)\" is unsupported")
endif

DOCKER_IMAGES = baseos basejvm baseimage
DUMMY = .$(DOCKER_TAG)

all: vagrant docker

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

# strips off the post-processors that try to upload artifacts to the cloud
packer-local.json: packer.json
	jq 'del(."post-processors"[0][1])' packer.json > $@

%.box:
	ATLAS_ARTIFACT=$(NAME) \
	BASEIMAGE_RELEASE=$(VERSION) \
	OUTPUT_FILE=$@ \
	packer build $<

baseimage-public.box: packer.json
$(VAGRANTIMAGE): packer-local.json

docker-local: $(patsubst %,build/docker/%/$(DUMMY),$(DOCKER_IMAGES))

docker: $(patsubst %,build/docker/%/.push,$(DOCKER_IMAGES))

vagrant: baseimage-public.box Makefile

vagrant-local: $(VAGRANTIMAGE) remove Makefile
	vagrant box add -name $(NAME) $<

remove:
	-vagrant box remove --box-version 0 $(NAME)

clean: remove
	-rm *.box
	-rm packer-local.json
	-rm -rf packer_cache
	-rm -rf build
