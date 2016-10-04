NAME ?= hyperledger/fabric-baseimage
VERSION ?= $(shell cat ./release)
IS_RELEASE=true

ARCH=$(shell uname -m)
DOCKER_TAG ?= $(ARCH)-$(VERSION)
VAGRANTIMAGE=baseimage-v$(VERSION).box

DOCKER_BASE_x86_64=ubuntu:xenial
DOCKER_BASE_s390x=s390x/ubuntu:xenial
DOCKER_BASE_ppc64le=ppc64le/ubuntu:xenial

DOCKER_BASE=$(DOCKER_BASE_$(ARCH))

ifeq ($(DOCKER_BASE), )
$(error "Architecture \"$(ARCH)\" is unsupported")
endif

all: vagrant docker

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

Dockerfile: Dockerfile.in Makefile
	@echo "# Generated from Dockerfile.in.  DO NOT EDIT!" > $@
	@cat Dockerfile.in | \
	sed -e  "s|_DOCKER_BASE_|$(DOCKER_BASE)|" >> $@

docker-local: Dockerfile
	@echo "Generating docker"
	@docker build -t $(NAME):$(DOCKER_TAG) .

docker: docker-local
	@docker login \
		--email=$(DOCKER_HUB_EMAIL) \
		--username=$(DOCKER_HUB_USERNAME) \
		--password=$(DOCKER_HUB_PASSWORD)
	@docker push $(NAME):$(DOCKER_TAG)

vagrant: baseimage-public.box Makefile

vagrant-local: $(VAGRANTIMAGE) remove Makefile
	vagrant box add -name $(NAME) $<

remove:
	-vagrant box remove --box-version 0 $(NAME)

clean: remove
	-rm *.box
	-rm Dockerfile
	-rm packer-local.json
	-rm -rf packer_cache
