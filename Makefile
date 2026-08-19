FPC ?= fpc
PREFIX ?= /usr/local
DESTDIR ?=
BUILD_DIR ?= build
UNIT_DIR := $(BUILD_DIR)/units
BIN_DIR := bin
TARGET := $(BIN_DIR)/fsim
DEBUG_TARGET := $(BIN_DIR)/fsim-debug

FPCBASEFLAGS ?= -Mobjfpc -Sh -O2 -XX -CX -Sa -vewnhibq
FPCPATHFLAGS := -Fu./src -FU$(UNIT_DIR)
FPCFLAGS ?= $(FPCBASEFLAGS) $(FPCPATHFLAGS)
DEBUG_FPCFLAGS ?= -Mobjfpc -Sh -O- -g -gl -gh -Cr -Co -Ci -Ct -Sa -vewnhibq $(FPCPATHFLAGS)

PASCAL_SOURCES := fsim.lpr $(sort $(wildcard src/*.pas))
STANDARD_LIBRARY := $(sort $(wildcard stdlib/*.sim))

.PHONY: all compiler debug rebuild check-fpc check-install-binary install uninstall clean help

all: compiler

help:
	@printf '%s\n' \
	  'fsim build targets:' \
	  '  make                 build bin/fsim' \
	  '  make debug           build bin/fsim-debug with runtime checks' \
	  '  make rebuild         force a clean dependency rebuild' \
	  '  make install         install compiler, stdlib, and docs' \
	  '  make clean           remove generated artifacts' \
	  '' \
	  'The clean public archive omits maintainer tests and release tooling.' \
	  'Use the maintainer distribution when running the full certification suite.'

$(UNIT_DIR) $(BIN_DIR):
	mkdir -p $@

check-fpc:
	@command -v $(FPC) >/dev/null 2>&1 || { \
	  echo 'error: Free Pascal Compiler was not found (set FPC=/path/to/fpc)' >&2; \
	  exit 127; \
	}
	@set -eu; \
	version=$$($(FPC) -iV); \
	major=$${version%%.*}; rest=$${version#*.}; minor=$${rest%%.*}; patch=$${rest#*.}; patch=$${patch%%[^0-9]*}; \
	: $${patch:=0}; \
	if [ "$$major" -lt 3 ] || { [ "$$major" -eq 3 ] && [ "$$minor" -lt 2 ]; } || \
	   { [ "$$major" -eq 3 ] && [ "$$minor" -eq 2 ] && [ "$$patch" -lt 2 ]; }; then \
	  echo "error: fsim requires Free Pascal 3.2.2 or newer (found $$version)" >&2; \
	  exit 2; \
	fi

$(TARGET): $(PASCAL_SOURCES) | check-fpc $(UNIT_DIR) $(BIN_DIR)
	$(FPC) $(FPCFLAGS) -FE$(BIN_DIR) -ofsim fsim.lpr

compiler: $(TARGET)

$(DEBUG_TARGET): $(PASCAL_SOURCES) | check-fpc $(UNIT_DIR) $(BIN_DIR)
	$(FPC) $(DEBUG_FPCFLAGS) -FE$(BIN_DIR) -ofsim-debug fsim.lpr

debug: $(DEBUG_TARGET)

rebuild: clean
	$(MAKE) compiler FPC="$(FPC)" FPCFLAGS="$(FPCFLAGS) -B"

check-install-binary:
	@set -eu; \
	if [ ! -x "$(TARGET)" ]; then \
	  echo 'error: bin/fsim is missing; build it as your normal user with `make` before `sudo make install`' >&2; \
	  exit 1; \
	fi; \
	expected=$$(cat VERSION); \
	actual=$$("$(TARGET)" --version | sed -n 's/^fsim \([^ ]*\).*/\1/p'); \
	if [ "$$actual" != "$$expected" ]; then \
	  echo "error: bin/fsim is version $$actual but this checkout is $$expected" >&2; \
	  echo 'fix: run `make clean && make` as your normal user, then install again' >&2; \
	  exit 1; \
	fi

install: check-install-binary
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 0755 $(TARGET) $(DESTDIR)$(PREFIX)/bin/fsim
	install -d $(DESTDIR)$(PREFIX)/share/fsim/stdlib
	install -m 0644 $(STANDARD_LIBRARY) $(DESTDIR)$(PREFIX)/share/fsim/stdlib/
	install -d $(DESTDIR)$(PREFIX)/share/doc/fsim
	install -m 0644 README.md CHANGELOG.md LICENSE docs/*.md $(DESTDIR)$(PREFIX)/share/doc/fsim/

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/fsim
	rm -rf $(DESTDIR)$(PREFIX)/share/fsim
	rm -rf $(DESTDIR)$(PREFIX)/share/doc/fsim

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)
	find . -type f \( -name '*.o' -o -name '*.ppu' -o -name '*.rst' \) -delete
