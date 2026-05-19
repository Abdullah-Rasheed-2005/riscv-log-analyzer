# Makefile — riscv-log-analyzer
# Abdullah Rasheed — MEDS Module 1

SHELL := /bin/bash
SCRIPTS_DIR  := scripts
TEST_DATA    := test_data
OUTPUT_DIR   := output
ANALYZE      := $(SCRIPTS_DIR)/analyze.sh
SETUP        := $(SCRIPTS_DIR)/setup_env.sh
REPORT_GEN   := $(SCRIPTS_DIR)/generate_report.sh
LOG_FILES    := $(wildcard $(TEST_DATA)/*.log)

.DEFAULT_GOAL := all

# run analyzer on all log files
.PHONY: all
all: $(LOG_FILES)
	@echo "=== Running analyzer on all test logs ==="
	@for log in $(LOG_FILES); do \
		echo ""; \
		echo ">>> $$log"; \
		bash $(ANALYZE) $$log || true; \
	done

# test each log file and check exit codes
.PHONY: test
test:
	@echo "=== Running test suite ==="
	@echo ""
	@echo "[TEST 1] sample_pass.log — expect exit 0"
	@bash $(ANALYZE) $(TEST_DATA)/sample_pass.log > /dev/null && \
		echo "  RESULT: PASS" || \
		(echo "  RESULT: FAIL" && exit 1)
	@echo ""
	@echo "[TEST 2] sample_fail.log — expect exit 1"
	@bash $(ANALYZE) $(TEST_DATA)/sample_fail.log > /dev/null; \
		if [ $$? -eq 1 ]; then echo "  RESULT: PASS"; \
		else echo "  RESULT: FAIL"; exit 1; fi
	@echo ""
	@echo "[TEST 3] sample_sim.log — expect exit 1"
	@bash $(ANALYZE) $(TEST_DATA)/sample_sim.log > /dev/null; \
		if [ $$? -eq 1 ]; then echo "  RESULT: PASS"; \
		else echo "  RESULT: FAIL"; exit 1; fi
	@echo ""
	@echo "[TEST 4] csv format test"
	@bash $(ANALYZE) $(TEST_DATA)/sample_sim.log --format csv > /dev/null; \
		EXIT=$$?; \
		if [ $$EXIT -eq 0 ] || [ $$EXIT -eq 1 ]; then echo "  RESULT: PASS"; \
		else echo "  RESULT: FAIL"; exit 1; fi
	@echo ""
	@echo "[TEST 5] --output flag test"
	@mkdir -p $(OUTPUT_DIR)
	@bash $(ANALYZE) $(TEST_DATA)/sample_pass.log \
		--output $(OUTPUT_DIR)/test_output.txt 2>/dev/null || true
	@test -f $(OUTPUT_DIR)/test_output.txt && \
		echo "  RESULT: PASS" || \
		(echo "  RESULT: FAIL" && exit 1)
	@echo ""
	@echo "[TEST 6] missing file — expect exit 2"
	@bash $(ANALYZE) nonexistent.log > /dev/null 2>&1; \
		if [ $$? -eq 2 ]; then echo "  RESULT: PASS"; \
		else echo "  RESULT: FAIL"; exit 1; fi
	@echo ""
	@echo "=== All tests passed! ==="

# generate combined report in output/
.PHONY: report
report:
	@mkdir -p $(OUTPUT_DIR)
	@bash $(REPORT_GEN)

# delete all output files
.PHONY: clean
clean:
	@rm -rf $(OUTPUT_DIR)/*
	@echo "output/ cleaned."

# check tools and project structure
.PHONY: setup
setup:
	@bash $(SETUP)

# show available targets
.PHONY: help
help:
	@echo ""
	@echo "Available targets:"
	@echo "  make all     — analyze all log files"
	@echo "  make test    — run test suite"
	@echo "  make report  — save report to output/"
	@echo "  make clean   — delete output files"
	@echo "  make setup   — check tools and files"
	@echo "  make help    — show this message"
	@echo ""
