SWIFTC = swiftc
INCLUDES = -I /usr/include -I /usr/local/include

SRC_DIR = src
INC_DIR = include
OBJ_DIR = obj
BIN_DIR = bin

MOD_DEPS = Util Parser
MODS = $(addprefix $(INC_DIR)/,$(addsuffix .swiftmodule,$(MOD_DEPS)))
SRCS = $(shell find $(SRC_DIR) -name '*.swift')
OBJS = $(subst $(SRC_DIR),$(OBJ_DIR),$(patsubst %.swift,%.o,$(SRCS)))

MODULE_NAME = $(word 2,$(subst /, ,$@))

TARGET = $(BIN_DIR)/treeswift

.PHONY: all clean

$(TARGET): $(OBJS)
	@[ -d $(BIN_DIR) ] || mkdir -p $(BIN_DIR)
	$(SWIFTC) -o $@ $^

$(INC_DIR)/%.swiftmodule: $(SRC_DIR)/%/*.swift
	@[ -d $(INC_DIR) ] || mkdir -p $(INC_DIR)
	cd $(INC_DIR); $(SWIFTC) $(INCLUDES) -I . -module-name $(basename $(notdir $@)) -emit-module $(addprefix ../,$^)

$(OBJ_DIR)/main.o: $(MODS)
	@[ -d $(OBJ_DIR) ] || mkdir -p $(OBJ_DIR)
	cd $(OBJ_DIR); $(SWIFTC) $(INCLUDES) -I ../$(INC_DIR) -module-name TreeSwift -c ../$(SRC_DIR)/main.swift

$(OBJ_DIR)/%.o: $(MODS)
	@[ -d $(OBJ_DIR)/$(MODULE_NAME) ] || mkdir -p $(OBJ_DIR)/$(MODULE_NAME)
	cd $(OBJ_DIR)/$(MODULE_NAME); $(SWIFTC) $(INCLUDES) -I ../../$(INC_DIR) -module-name $(MODULE_NAME) -c ../../$(SRC_DIR)/$(MODULE_NAME)/*.swift

all: clean $(TARGET)

clean:
	rm -rf $(INC_DIR) $(OBJ_DIR) $(BIN_DIR)
