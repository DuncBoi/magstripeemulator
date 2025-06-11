CC      := gcc
CFLAGS  := -Wall -O2
TARGET  := uhid
SRC     := uhid.c

.PHONY: all clean run

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $<
	@sudo chmod +s $@

# Run under sudo so it can open /dev/uhid
run: $(TARGET)
	@echo "[*] Starting UHID swipe..."
	@sudo ./$(TARGET)

clean:
	@rm -f $(TARGET)

