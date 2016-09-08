
GO_SRC := $(shell find . -type f -name "*.go")

CONTAINER_NAME ?= wrouesnel/postgres_exporter:latest

all: vet test postgres_exporter

# Simple go build
postgres_exporter: $(GO_SRC)
	CGO_ENABLED=0 go build -a -ldflags "-extldflags '-static' -X main.Version=git:$(shell git rev-parse HEAD)" -o postgres_exporter .

# Take a go build and turn it into a minimal container
docker: postgres_exporter
	docker build -t $(CONTAINER_NAME) .

vet:
	go vet .

test:
	go test -v .

test-integration:
	tests/test-smoke

# Do a self-contained docker build - we pull the official upstream container
# and do a self-contained build.
docker-build: postgres_exporter
	docker run -v $(shell pwd):/go/src/github.com/wrouesnel/postgres_exporter \
	    -v $(shell pwd):/real_src \
	    -e SHELL_UID=$(shell id -u) -e SHELL_GID=$(shell id -g) \
	    -w /go/src/github.com/wrouesnel/postgres_exporter \
		golang:1.7-wheezy \
		/bin/bash -c "make >&2 && chown $$SHELL_UID:$$SHELL_GID ./postgres_exporter"
	docker build -t $(CONTAINER_NAME) .

.PHONY: docker-build docker test vet
