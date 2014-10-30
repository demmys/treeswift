SRC_DIR = src/
BIN_DIR = bin/

INCLUDES = /usr/include
FRAMEWORKS = /System/Library/Frameworks

SWIFTC = swiftc
SWIFTCFLAGS = -F $(FRAMEWORKS) -I $(INCLUDES) -module-name TreeSwift

TARGET = $(BIN_DIR)treeswift

SRCS = $(wildcard $(SRC_DIR)*.swift)

.PHONY: all clean prepare

$(TARGET): $(SRCS)
	@[ -d $(BIN_DIR) ] || mkdir -p $(BIN_DIR)
	$(SWIFTC) $(SWIFTCFLAGS) -o $@ $^

all: clean $(TARGET)

clean:
	rm $(TARGET)
