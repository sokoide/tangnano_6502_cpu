.DEFAULT_GOAL := help

BOARD ?= 9k
DAYS := $(sort $(wildcard day*_completed))
# SVFILES = \( -name '*.sv' -o -name '*.svh' \)
SVFILES = \( -name '*.sv' -o -name '*.svh' \)

TEST_JOBS ?= 6
TEST_LOG_DIR := build/test-logs

.PHONY: all clean download help test test-days test-summary sim format build $(DAYS:%=test-%)

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

# Run every day's test in parallel (up to TEST_JOBS directories at once).
# Each day's output goes to $(TEST_LOG_DIR)/<day>.log; the summary at the end
# reports PASS/FAIL and elapsed time per directory (failure log tails included).
test:
	python3 scripts/test_program_fpga.py
	@rm -rf $(TEST_LOG_DIR)
	@mkdir -p $(TEST_LOG_DIR)
	@start=$$(date +%s); \
	$(MAKE) --no-print-directory -j$(TEST_JOBS) -k test-days; \
	rc=$$?; \
	echo $$(( $$(date +%s) - start )) > $(TEST_LOG_DIR)/elapsed; \
	$(MAKE) --no-print-directory test-summary; \
	if grep -qx FAIL $(TEST_LOG_DIR)/*.status 2>/dev/null; then rc=1; fi; \
	exit $$rc

test-days: $(DAYS:%=test-%)

$(DAYS:%=test-%): test-%:
	@mkdir -p $(TEST_LOG_DIR)
	@s=$$(date +%s); \
	if MAKEFLAGS= $(MAKE) -C $* BOARD=$(BOARD) test > $(TEST_LOG_DIR)/$*.log 2>&1; then \
		st=PASS; \
	else \
		st=FAIL; \
	fi; \
	echo $$st > $(TEST_LOG_DIR)/$*.status; \
	echo $$(( $$(date +%s) - s )) > $(TEST_LOG_DIR)/$*.time; \
	echo "[$$st] $* ($$(cat $(TEST_LOG_DIR)/$*.time)s)"

test-summary:
	@echo; \
	echo "==================== make test summary (BOARD=$(BOARD)) ===================="; \
	pass=0; fail=0; skip=0; \
	for day in $(DAYS); do \
		st=$$(cat $(TEST_LOG_DIR)/$$day.status 2>/dev/null || echo SKIP); \
		t=$$(cat $(TEST_LOG_DIR)/$$day.time 2>/dev/null || echo 0); \
		printf '  %-4s %6ss  %s\n' "$$st" "$$t" "$$day"; \
		case $$st in \
			PASS) pass=$$((pass+1));; \
			FAIL) fail=$$((fail+1));; \
			*) skip=$$((skip+1));; \
		esac; \
	done; \
	elapsed=$$(cat $(TEST_LOG_DIR)/elapsed 2>/dev/null || echo 0); \
	echo "============================================================"; \
	echo "  PASS $$pass / FAIL $$fail / SKIP $$skip   total $${elapsed}s (TEST_JOBS=$(TEST_JOBS))"; \
	echo "  logs: $(TEST_LOG_DIR)/<day>.log"; \
	for day in $(DAYS); do \
		if [ "$$(cat $(TEST_LOG_DIR)/$$day.status 2>/dev/null)" = FAIL ]; then \
			echo; echo "---- $$day.log (last 20 lines) ----"; \
			tail -n 20 $(TEST_LOG_DIR)/$$day.log; \
		fi; \
	done

format:
	@echo "Formatting all projects"
	pnpm dlx markdownlint-cli "**/*.md" --ignore "AGENTS.md" --fix
	pnpm dlx textlint --fix "**/*.md" --ignore-path .textlintignore
	find . $(SVFILES) \
		-not -path "*/deps/*" -not -path "*/gowin_*/*" -not -path "*/legacy/*" \
		-not -path "*/impl/*" -not -path "*/build/*" -not -path "*/obj_dir/*" \
		-not -name boot_program.sv -not -name cpu_ifo_auto_generated.svh \
		-print0 | xargs -0 verible-verilog-format --inplace --indentation_spaces=4 --column_limit=100


clean:
	@echo "Cleaning all projects"
	@rm -rf $(TEST_LOG_DIR)
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
	@echo "  make test TEST_JOBS=8  # run tests in parallel (default: 6 dirs at once)"
	@echo
	@echo "Available targets:"
	@echo "  build  - build every project"
	@echo "  download - build and program the Day 99 design"
	@echo "  sim    - run simulation for every project"
	@echo "  test   - run each project's tests in parallel, then show a summary"
	@echo "  clean  - run clean in every day directory"
	@echo "  help   - show this message (default target)"
