LLVM_PATH = $(shell brew --prefix llvm)
LLC = $(LLVM_PATH)/bin/llc
COMPILER = $(shell xcrun -f clang)
TRIPLE = x86_64-apple-macosx10.11.0

SRC_DIR = src
AS_DIR = as
BIN_DIR = bin

LLCFLAGS = -mtriple $(TRIPLE) -O2

$(BIN_DIR)/libTreeSwift.dylib: $(AS_DIR)/TreeSwift.s
	@[ -d $(BIN_DIR) ] || mkdir -p $(BIN_DIR)
	$(COMPILER) -dynamiclib -o $@ $^

$(AS_DIR)/TreeSwift.s: $(SRC_DIR)/TreeSwift.ll
	@[ -d $(AS_DIR) ] || mkdir -p $(AS_DIR)
	$(LLC) $(LLCFLAGS) -o $@ $^

clean:
	rm -r $(AS_DIR) $(BIN_DIR)

all: clean main
