SHELL := /bin/bash
PWD = $(shell pwd)

clean:
	@source makescript.sh; clean "$(PWD)"

init:
	@source makescript.sh; initialize "$(PWD)"

build:
	@source makescript.sh; build "$(PWD)"

build-ipxe:
	@source makescript.sh; build_ipxe "$(PWD)"

.PHONY: build