.DEFAULT_GOAL := all

PROJECT := day10_completed
PROGRAM ?= hello_world
PROGRAMS := hello_world counter_display scroll_text

BOARD ?= 9k

CA65 = ca65
LD65 = ld65
SREC = srec_cat

CONFIG = build.cfg
HEXFILE = $(PROGRAM).hex
BINARY = $(PROGRAM).bin
OBJECT = $(PROGRAM).o

SV_INCLUDE = include/boot_program.sv

DAY99_DIR := $(abspath ../day99_completed)
DAY99_INCLUDE := $(DAY99_DIR)/include/boot_program.sv

.PHONY: all include clean build download help

all: $(PROGRAMS:%=%.hex)

$(PROGRAMS:%=%.o): %.o: %.s
	$(CA65) -t none -o $@ $<

$(PROGRAMS:%=%.bin): %.bin: %.o
	$(LD65) -C $(CONFIG) -o $@ $<

$(PROGRAMS:%=%.hex): %.hex: %.bin
	$(SREC) $< -binary -offset 0x0200 -o $@ -intel

include: $(HEXFILE)
	@mkdir -p include
	python3 hex_to_sv.py $(HEXFILE) > $(SV_INCLUDE)

clean:
	rm -f $(PROGRAMS:%=%.o) $(PROGRAMS:%=%.bin) $(PROGRAMS:%=%.hex)
	rm -f $(SV_INCLUDE)

define _run_day99
	@backup="$(DAY99_INCLUDE).bak"; \
	cp $(DAY99_INCLUDE) $$backup 2>/dev/null || :; \
	cp $(SV_INCLUDE) $(DAY99_INCLUDE); \
	if ! $(MAKE) -C $(DAY99_DIR) BOARD=$(BOARD) $(1); then \
		if [ -f $$backup ]; then cp $$backup $(DAY99_INCLUDE); else rm -f $(DAY99_INCLUDE); fi; \
		rm -f $$backup; \
		exit 1; \
	fi; \
	if [ -f $$backup ]; then cp $$backup $(DAY99_INCLUDE); else rm -f $(DAY99_INCLUDE); fi; \
	rm -f $$backup
endef

build: include
	$(call _run_day99,)

download: include
	$(call _run_day99,download)

help:
	@echo "Usage:"
	@echo "  make                 # build every assembly sample (.hex)"
	@echo "  make PROGRAM=<name>  # build a specific sample (hello_world, counter_display, scroll_text)"
	@echo "  make include         # regenerate include/boot_program.sv for $(PROGRAM)"
	@echo "  make build BOARD=<9k|20k>    # build the FPGA bitstream with the generated boot ROM"
	@echo "  make download BOARD=<9k|20k> # program the Tang Nano SRAM with the selected demo"
	@echo "  make clean           # clean all generated files"

