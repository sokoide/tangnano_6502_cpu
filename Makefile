BOARD ?= 9k
DAYS := $(sort $(wildcard day*_completed))

.PHONY: all clean help $(DAYS)

all: $(DAYS)

$(DAYS):
	@echo "Building $@ (BOARD=$(BOARD))"
	$(MAKE) -C $@ BOARD=$(BOARD)

clean:
	@echo "Cleaning $(DAYS)"
	@for day in $(DAYS); do \
		echo "  $$day"; \
		$(MAKE) -C $$day clean; \
	done

help:
	@echo "Build every day*_completed project for Tang Nano boards."
	@echo
	@echo "Usage:"
	@echo "  make BOARD=<9k|20k>"
	@echo "  make BOARD=20k      # builds each day for 20k"
	@echo
	@echo "Available targets:"
	@echo "  all    - build every project (default)"
	@echo "  clean  - run clean in every day directory"
	@echo "  help   - show this message"
