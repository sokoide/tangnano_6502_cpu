BOARD ?= 9k
DAYS := $(sort $(wildcard day*_completed))
# SVFILES = \( -name '*.sv' -o -name '*.svh' \)
SVFILES = \( -name '*.sv' -o -name '*.svh' \)

.PHONY: all clean help test format build

all: build

build:
	@echo "Building all projects (BOARD=$(BOARD))"
	@for day in $(DAYS); do \
		echo "* Building $$day (BOARD=$(BOARD))"; \
		$(MAKE) -C $$day BOARD=$(BOARD); \
	done

test:
	@echo "Running simulation for all projects (BOARD=$(BOARD))"
	@for day in $(DAYS); do \
		echo "* Running sim for $$day (BOARD=$(BOARD))"; \
		$(MAKE) -C $$day BOARD=$(BOARD) sim; \
	done

format:
	@echo "Formatting all projects"
	npx markdownlint "**/*.md" --fix
	find . $(SVFILES) -print0 | xargs -0 verible-verilog-format --inplace --indentation_spaces=4 --column_limit=100


clean:
	@echo "Cleaning all projects"
	@for day in $(DAYS); do \
		echo "* Cleaning $$day"; \
		$(MAKE) -C $$day clean; \
	done

help:
	@echo "Build every day*_completed project for Tang Nano boards."
	@echo
	@echo "Usage:"
	@echo "  make BOARD=<9k|20k>"
	@echo "  make BOARD=20k      # builds each day for 20k"
	@echo "  make sim            # runs simulation for each day"
	@echo
	@echo "Available targets:"
	@echo "  all    - build every project (default)"
	@echo "  sim    - run simulation for every project"
	@echo "  clean  - run clean in every day directory"
	@echo "  help   - show this message"
