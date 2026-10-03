# Prerequisites
#  Mac) brew install srecord cc65 golang
#  WSL / Linux) sudo apt install srecord cc65 golang

# Boot program selector: name one of the *.s files in this directory without
# the .s extension. Override on the command line to switch programs without
# editing this file:
#   make PROG=simple sv        # build simple.s and regenerate boot_program.sv
PROG ?= simple5
SRCS = $(PROG).s

ifeq ($(wildcard $(SRCS)),)
$(error $(SRCS) not found. Available programs: $(notdir $(basename $(wildcard *.s))))
endif

# target System Verilogy file path which is included by src/top.sv
SV = ../include/boot_program.sv

# Intermediate artifacts are per-program so switching PROG never mixes files
# from a previously built program.
HEX = $(PROG).hex
HEX_FPGA_DIR = ../utils/hex_fpga
HEX_FPGA = $(HEX_FPGA_DIR)/hex_fpga
HEX_FPGA_SRCS = $(HEX_FPGA_DIR)/main.go
TARGET = $(PROG).bin
OBJS=$(SRCS:.s=.o)
LST=$(PROG).lst

CC = cc65
LD = ld65
AS = ca65
DA = da65
OD = od65
CFG = baremetal.cfg

.PHONY: all disass od clean

all: sv
	cat $(LST)

$(TARGET): $(OBJS)
	$(LD) -C $(CFG) -o $@ $<

%.o: %.s
	$(AS) -l $(LST) -o $@ $<

sv: $(HEX) $(HEX_FPGA)
	@if [ $(SV) -ot $(HEX) ] || ! grep -q "^// source: $(SRCS)$$" $(SV); then \
	  $(HEX_FPGA) -hexfile $(HEX) -svfile $(SV) -srcname $(SRCS); \
	  echo "$(SV) file written from $(SRCS)"; \
	else \
	  echo "$(SV) is already built from $(SRCS)"; \
	fi

$(HEX_FPGA): $(HEX_FPGA_SRCS)
	cd $(HEX_FPGA_DIR); go clean; go mod tidy; go build

$(HEX): $(TARGET)
	srec_cat $(TARGET) -binary -offset 0x0200 -o $(HEX) -Intel

disass: $(TARGET)
	$(DA) $<

od: $(OBJS)
	$(OD) --dump-all $<

clean:
	rm -rf tags *.o *.bin *.hex *.lst
