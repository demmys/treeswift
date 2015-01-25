SWIFTC = swiftc
FLAGS = -I /usr/include -I $(CURDIR)/$(INC_DIR) -import-objc-header $(CURDIR)/$(BRIDGING_HEADER) -F /System/Library/Frameworks -g
LD = swiftc
LDFLAGS = -module-name TreeSwift

SRC_DIR = src
INC_DIR = include
OBJ_DIR = obj
LIB_DIR = lib
BIN_DIR = bin

MOD_DEPS = Util Parser Generator
MODS = $(addprefix $(INC_DIR)/,$(addsuffix .swiftmodule,$(MOD_DEPS)))
SRCS = $(shell find $(SRC_DIR) -name '*.swift')
OBJS = $(subst $(SRC_DIR),$(OBJ_DIR),$(SRCS:.swift=.o))
DEPS = $(OBJS:.o=.d)

BRIDGE_DIR = bridge
BRIDGING_HEADER = $(BRIDGE_DIR)/TreeSwift-Bridging-Header.h

OBJCXX = clang++
OBJCXX_FLAGS = -Wall `llvm-config --cxxflags --libs --ldflags --system-libs` -stdlib=libc++ -framework Foundation -g

OBJCXX_SRCS = $(shell find $(BRIDGE_DIR) -name '*.mm')
OBJCXX_LIB = $(LIB_DIR)/libllvmBridge.dylib
OBJCXX_DEPS = $(OBJCXX_LIB:.dylib=.d)

MODULE_NAME = $(word 2,$(subst /, ,$@))

TARGET = $(BIN_DIR)/treeswift

.PHONY: all clean

$(TARGET): $(OBJCXX_LIB) $(OBJS)
	@[ -d $(BIN_DIR) ] || mkdir -p $(BIN_DIR)
	$(LD) $(LDFLAGS) -o $@ $^

$(INC_DIR)/%.swiftmodule: $(SRC_DIR)/%/*.swift
	@[ -d $(INC_DIR) ] || mkdir -p $(INC_DIR)
	cd $(INC_DIR); $(SWIFTC) $(FLAGS) -module-name $(basename $(notdir $@)) -emit-module $(addprefix ../,$^)

$(OBJCXX_LIB): $(OBJCXX_SRCS)
	@[ -d $(LIB_DIR) ] || mkdir -p $(LIB_DIR)
	$(OBJCXX) $(OBJCXX_FLAGS) -dynamiclib -o $@ $^

$(OBJ_DIR)/main.o: $(MODS)
	@[ -d $(OBJ_DIR) ] || mkdir -p $(OBJ_DIR)
	cd $(OBJ_DIR); $(SWIFTC) $(FLAGS) -module-name TreeSwift -c ../$(SRC_DIR)/main.swift

$(OBJ_DIR)/%.o: $(MODS)
	@[ -d $(OBJ_DIR)/$(MODULE_NAME) ] || mkdir -p $(OBJ_DIR)/$(MODULE_NAME)
	cd $(OBJ_DIR)/$(MODULE_NAME); $(SWIFTC) $(FLAGS) -module-name $(MODULE_NAME) -emit-library -emit-object ../../$(SRC_DIR)/$(MODULE_NAME)/*.swift

all: clean $(TARGET)

clean:
	rm -rf $(INC_DIR) $(OBJ_DIR) $(LIB_DIR) $(BIN_DIR)
