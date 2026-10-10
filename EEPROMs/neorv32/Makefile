TARGET = main

# Toolchain setup
CROSS_COMPILE ?= riscv-none-elf-
CC      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
SIZE    = $(CROSS_COMPILE)size

# Matching your VHDL top-level (RV32I core + Zicntr counter extension)
MARCH = rv32i_zicntr
MABI  = ilp32

CFLAGS  = -march=$(MARCH) -mabi=$(MABI) -O2 -Wall -ffunction-sections -fdata-sections -nostdlib -I.
LDFLAGS = -T neorv32.ld -Wl,--gc-sections -nostdlib -lgcc

SRCS = crt0.S main.c bus_periph.c
OBJS = $(SRCS:.c=.o)
OBJS := $(OBJS:.S=.o)

all: raw

raw: $(TARGET).elf
	$(OBJCOPY) -O binary --pad-to=0x30001000 --gap-fill=0x00 $(TARGET).elf $(TARGET)_raw_exe.bin
	@echo "--------------------------------------------------"
	@echo "Build Successful: $(TARGET)_raw_exe.bin generated!"
	@echo "--------------------------------------------------"
	$(SIZE) $(TARGET).elf

$(TARGET).elf: $(OBJS) neorv32.ld
	$(CC) $(CFLAGS) $(OBJS) -o $@ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o *.elf *.bin *.hex

.PHONY: all raw clean