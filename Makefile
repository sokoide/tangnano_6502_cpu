.DEFAULT_GOAL := help

BOARD ?= 9k
DAYS := $(sort $(wildcard day*_completed))
# SVFILES = \( -name '*.sv' -o -name '*.svh' \)
SVFILES = \( -name '*.sv' -o -name '*.svh' \)

.PHONY: all clean download help test sim format build

all: build

build:
	@echo "Building all projects (BOARD=$(BOARD))"
	@for day in $(DAYS); do \
		echo "************************************************"; \
		echo "* Building $$day (BOARD=$(BOARD))"; \
		echo "************************************************"; \
		$(MAKE) -C $$day BOARD=$(BOARD) || exit 1; \
		done

# Program the final Day 99 design for the selected board.
download:
	$(MAKE) -C day99_completed BOARD=$(BOARD) download

sim:
	@echo "Running simulation for all projects (BOARD=$(BOARD))"
	@for day in $(DAYS); do \
		echo "************************************************"; \
		echo "* Running sim for $$day (BOARD=$(BOARD))"; \
		echo "************************************************"; \
		$(MAKE) -C $$day BOARD=$(BOARD) sim || exit 1; \
	done

test:
	python3 scripts/test_program_fpga.py
	@set -e; for day in $(DAYS); do \
		echo "[test] $$day (BOARD=$(BOARD))"; \
		$(MAKE) -C $$day BOARD=$(BOARD) test; \
	done

format:
	@echo "Formatting all projects"
	pnpm dlx markdownlint-cli "**/*.md" --ignore "conductor/**" --ignore "CLAUDE.md" --ignore "AGENTS.md" --fix
	pnpm dlx textlint --fix "**/*.md" --ignore-path .textlintignore
	find . $(SVFILES) -not -path "./conductor/*" \
		-not -path "*/deps/*" -not -path "*/gowin_*/*" -not -path "*/legacy/*" \
		-not -path "*/impl/*" -not -path "*/build/*" -not -path "*/obj_dir/*" \
		-not -name boot_program.sv -not -name cpu_ifo_auto_generated.svh \
		-print0 | xargs -0 verible-verilog-format --inplace --indentation_spaces=4 --column_limit=100


clean:
	@echo "Cleaning all projects"
	@for day in $(DAYS); do \
		echo "************************************************"; \
		echo "* Cleaning $$day"; \
		echo "************************************************"; \
		$(MAKE) -C $$day clean || exit 1; \
	done

help:
	@echo "Tang Nano 6502 CPU project commands."
	@echo
	@echo "Usage:"
	@echo "  make                 # show this help"
	@echo "  make build BOARD=9k  # build every day*_completed project"
	@echo "  make build BOARD=20k  # build every project for 20k"
	@echo "  make download BOARD=9k  # build and program the Day 99 design"
	@echo "  make sim            # runs simulation for each day"
	@echo
	@echo "Available targets:"
	@echo "  build  - build every project"
	@echo "  download - build and program the Day 99 design"
	@echo "  sim    - run simulation for every project"
	@echo "  test   - run each project's CPU/module and LCD tests"
	@echo "  clean  - run clean in every day directory"
	@echo "  help   - show this message (default target)"
