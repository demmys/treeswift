COMPILER = $(shell xcrun -f swiftc)
LD = $(COMPILER)
LLVM_PATH = $(shell brew --prefix llvm)
LLVM_CONFIG = $(LLVM_PATH)/bin/llvm-config

SRC_DIR = src
OBJ_DIR = obj
INC_DIR = include
BIN_DIR = bin

BRIDGING_HEADER = $(CURDIR)/$(SRC_DIR)/llvm_bridging_header.h

CFLAGS = -enable-testing -I$(CURDIR)/$(INC_DIR) -I/usr/include -import-objc-header $(BRIDGING_HEADER) -Xcc -I$(LLVM_PATH)/include -Xcc -D__STDC_CONSTANT_MACROS -Xcc -D__STDC_FORMAT_MACROS -Xcc -D__STDC_LIMIT_MACROS
LDFLAGS = -lc++ -L$(LLVM_PATH)/lib $(shell $(LLVM_CONFIG) --libs --system-libs)

SRCS = $(shell find $(SRC_DIR) -name '*.swift' | sed -e 's/.*main.swift//g')
OBJS = $(subst $(SRC_DIR),$(OBJ_DIR),$(SRCS:.swift=.o))
MODS = Util Parser Generator
MODS_INC = $(addprefix $(INC_DIR)/,$(addsuffix .swiftmodule,$(MODS)))
MODULE_NAME = $(word 2,$(subst /, ,$@))

TARGET = $(BIN_DIR)/treeswift

TESTOBJ_DIR = $(OBJ_DIR)/test
TESTBIN_DIR = $(BIN_DIR)/test
TESTLIB_DIR = lib/PureSwiftUnit
TEST_DIR = test
TEST_SRCS = $(shell find $(TEST_DIR) -name '*.swift')
TEST_OBJS = $(subst $(TEST_DIR),$(TESTOBJ_DIR),$(TEST_SRCS:.swift=.o))
TEST_MODULE_NAME = Test
TEST_TARGET = $(TESTBIN_DIR)/treeswift-test

.PHONY: all test clean

$(TARGET): $(OBJS) $(OBJ_DIR)/main.o
	@[ -d $(BIN_DIR) ] || mkdir -p $(BIN_DIR)
	$(LD) $(LDFLAGS) -o $@ $^

$(INC_DIR)/%.swiftmodule: $(SRC_DIR)/%/*.swift
	@[ -d $(INC_DIR) ] || mkdir -p $(INC_DIR)
	cd $(INC_DIR); $(COMPILER) $(CFLAGS) -module-name $(basename $(notdir $@)) -emit-module $(addprefix ../,$^)

$(OBJ_DIR)/main.o: $(MODS_INC)
	@[ -d $(OBJ_DIR) ] || mkdir -p $(OBJ_DIR)
	cd $(OBJ_DIR); $(COMPILER) $(CFLAGS) -module-name TreeSwift -c ../$(SRC_DIR)/main.swift

$(OBJS): $(MODS_INC)
	@[ -d $(OBJ_DIR)/$(MODULE_NAME) ] || mkdir -p $(OBJ_DIR)/$(MODULE_NAME)
	cd $(OBJ_DIR)/$(MODULE_NAME); $(COMPILER) $(CFLAGS) -module-name $(MODULE_NAME) -emit-library -emit-object ../../$(SRC_DIR)/$(MODULE_NAME)/*.swift

all: clean $(TARGET)

test: $(TEST_TARGET)
	@./$(TEST_TARGET)

$(TEST_TARGET): $(TEST_OBJS) $(OBJS)
	@[ -d $(TESTBIN_DIR) ] || mkdir -p $(TESTBIN_DIR)
	$(COMPILER) $(shell cd $(TESTLIB_DIR); make libs) $(LDFLAGS) -o $@ $^

$(TEST_OBJS): $(MODS_INC) $(TEST_SRCS)
	@[ -d $(TESTOBJ_DIR) ] || mkdir -p $(TESTOBJ_DIR)
	cd $(TESTOBJ_DIR); $(COMPILER) $(shell cd $(TESTLIB_DIR); make includes) $(CFLAGS) -module-name $(TEST_MODULE_NAME) -emit-object $(addprefix ../../,$(TEST_SRCS))

clean:
	rm -rf $(INC_DIR) $(OBJ_DIR) $(BIN_DIR)
