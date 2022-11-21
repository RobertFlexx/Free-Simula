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
DOCS := README.md CHANGELOG.md LICENSE $(sort $(wildcard docs/*.md))

.PHONY: all compiler debug check check-fpc install uninstall clean help

all: compiler

help:
	@printf '%s\n' \
	  'Free Simula build targets:' \
	  '  make          build bin/fsim' \
	  '  make check    build and run the compiler self-test' \
	  '  make debug    build bin/fsim-debug with FPC runtime checks' \
	  '  make install  install an already-built compiler and stdlib' \
	  '  make clean    remove generated artifacts'

$(UNIT_DIR) $(BIN_DIR):
	mkdir -p $@

check-fpc:
	@command -v "$(FPC)" >/dev/null 2>&1 || { \
	  echo 'error: Free Pascal was not found (set FPC=/path/to/fpc)' >&2; exit 127; }
	@version=$$("$(FPC)" -iV 2>/dev/null); \
	  first=$$(printf '%s\n' 3.2.2 "$$version" | sort -V | head -n 1); \
	  if [ "$$first" != 3.2.2 ]; then \
	    echo "error: Free Pascal 3.2.2 or newer is required (found $$version)" >&2; exit 2; \
	  fi

$(TARGET): $(PASCAL_SOURCES) | check-fpc $(UNIT_DIR) $(BIN_DIR)
	$(FPC) $(FPCFLAGS) -FE$(BIN_DIR) -ofsim fsim.lpr

compiler: $(TARGET)

$(DEBUG_TARGET): $(PASCAL_SOURCES) | check-fpc $(UNIT_DIR) $(BIN_DIR)
	$(FPC) $(DEBUG_FPCFLAGS) -FE$(BIN_DIR) -ofsim-debug fsim.lpr

debug: $(DEBUG_TARGET)

check: compiler
	./bin/fsim --self-test

install:
	@set -eu; \
	  test -x "$(TARGET)" || { echo 'error: build fsim with `make` before installing' >&2; exit 1; }; \
	  expected=$$(cat VERSION); \
	  actual=$$("$(TARGET)" --version | sed -n 's/^fsim \([^ ]*\).*/\1/p'); \
	  test "$$actual" = "$$expected" || { \
	    echo "error: bin/fsim is $$actual but this source tree is $$expected" >&2; exit 1; }
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 0755 $(TARGET) $(DESTDIR)$(PREFIX)/bin/fsim
	install -d $(DESTDIR)$(PREFIX)/share/fsim/stdlib
	install -m 0644 $(STANDARD_LIBRARY) $(DESTDIR)$(PREFIX)/share/fsim/stdlib/
	install -d $(DESTDIR)$(PREFIX)/share/doc/fsim
	install -m 0644 $(DOCS) $(DESTDIR)$(PREFIX)/share/doc/fsim/

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/fsim
	rm -rf $(DESTDIR)$(PREFIX)/share/fsim
	rm -rf $(DESTDIR)$(PREFIX)/share/doc/fsim

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)
	find . -type f \( -name '*.o' -o -name '*.ppu' -o -name '*.rst' \) -delete
