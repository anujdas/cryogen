CRYSTAL_BIN ?= $(shell which crystal)
SHARDS_BIN ?= $(shell which shards)
CRYOGEN_BIN ?= $(shell which cryogen)
PREFIX ?= /usr/local

build:
	$(SHARDS_BIN) build $(CRFLAGS)
build-release:
	$(SHARDS_BIN) build --release $(CRFLAGS)
format:
	$(CRYSTAL_BIN) tool format
clean:
	rm -f ./bin/cryogen ./bin/cryogen.dwarf
test: build
	$(CRYSTAL_BIN) spec
install: build-release
	mkdir -p $(PREFIX)/bin
	cp ./bin/cryogen $(PREFIX)/bin
reinstall: build-release
	cp ./bin/cryogen $(CRYOGEN_BIN) -f
