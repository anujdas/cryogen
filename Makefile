SOURCES = src/*.cr src/**/*.cr shard.yml shard.lock

CRYSTAL_BIN ?= $(shell which crystal)
SHARDS_BIN ?= $(shell which shards)

DESTDIR =
PREFIX ?= /usr/local
BINDIR = $(DESTDIR)$(PREFIX)/bin
INSTALL = /usr/bin/install

all: bin/cryogen

clean:
	@rm -f bin/cryogen bin/cryogen.dwarf

bin/cryogen: $(SOURCES)
	@$(SHARDS_BIN) build $(CRFLAGS)

build-release: $(SOURCES)
	@$(SHARDS_BIN) build --release $(CRFLAGS)

build-docker: $(SOURCES)
	@docker run --rm -v `pwd`:/workspace -it crystallang/crystal:latest /workspace/script/docker-build.sh
	@docker build -t cryogen .

install: build-release
	@mkdir -p "$(BINDIR)"
	@$(INSTALL) -m 0755 bin/cryogen "$(BINDIR)"

uninstall:
	@rm -f "$(BINDIR)/cryogen"

release:
	@docker run --rm -v `pwd`:/workspace -it crystallang/crystal:latest /workspace/script/docker-build.sh
	@docker build -t cryogen .
	@tar czvf bin/cryogen-linux-x64.tgz -C bin cryogen
	@rm -f bin/cryogen bin/cryogen.dwarf
	@$(SHARDS_BIN) build --release $(CRFLAGS)
	@tar czvf bin/cryogen-darwin-x64.tgz -C bin cryogen

test: bin/cryogen
	@$(CRYSTAL_BIN) spec

format:
	@$(CRYSTAL_BIN) tool format $(FMTFLAGS)

.PHONY: clean uninstall format
