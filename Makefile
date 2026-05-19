# =============================================================================
# Makefile — riscv-log-analyzer
# MEDS Module 1 Capstone
#
# Usage:
#   make           (runs 'all' target)
#   make help      (shows all targets)
# =============================================================================

# Shell to use for all recipe commands
SHELL := /bin/bash

# Project layout variables — change these if you rename directories
SCRIPTS_DIR  := scripts
TEST_DATA    := test_data
OUTPUT_DIR   := output

ANALYZE      := $(SCRIPTS_DIR)/analyze.sh
SETUP        := $(SCRIPTS_DIR)/setup_env.sh
REPORT_GEN   := $(SCRIPTS_DIR)/generate_report.sh

# Log files (automatically discovered)
LOG_FILES    := $(wildcard $(TEST_DATA)/*.log)

# ─────────────────────────────────────────────────────────────────────────────
# DEFAULT TARGET
# ─────────────────────────────────────────────────────────────────────────────
.DEFAULT_GOAL := all

# ─────────────────────────────────────────────────────────────────────────────
# all: Run the analyzer on every test log file and print results to stdout
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: all
all: $(LOG_FILES)
	@echo "========================================"
	@echo " Running analyzer on all test log files "
	@echo "========================================"
	@for log in $(LOG_FILES); do \
		echo ""; \
		echo ">>> Analyzing: $$log"; \
		bash $(ANALYZE) $$log || true; \
	done
	@echo ""
	@echo "Done. Use 'make report' to save output to $(OUTPUT_DIR)/"

# ─────────────────────────────────────────────────────────────────────────────
# test: Run analyzer on each log file and verify expected behavior
#   - sample_pass.log  must exit with code 0
#   - sample_fail.log  must exit with code 1
#   - sample_sim.log   must exit with code 1 (has failures)
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: test
test:
	@echo "========================================"
	@echo "         Running test suite             "
	@echo "========================================"
	@echo ""

	@echo "[TEST 1] sample_pass.log — expect exit 0 (all pass)"
	@bash $(ANALYZE) $(TEST_DATA)/sample_pass.log > /dev/null && \
		echo "  RESULT: PASS (exit 0 as expected)" || \
		(echo "  RESULT: FAIL (expected exit 0)" && exit 1)

	@echo ""
	@echo "[TEST 2] sample_fail.log — expect exit 1 (has failures)"
	@bash $(ANALYZE) $(TEST_DATA)/sample_fail.log > /dev/null; \
		if [ $$? -eq 1 ]; then \
			echo "  RESULT: PASS (exit 1 as expected)"; \
		else \
			echo "  RESULT: FAIL (expected exit 1)"; exit 1; \
		fi

	@echo ""
	@echo "[TEST 3] sample_sim.log — expect exit 1 (has failures)"
	@bash $(ANALYZE) $(TEST_DATA)/sample_sim.log > /dev/null; \
		if [ $$? -eq 1 ]; then \
			echo "  RESULT: PASS (exit 1 as expected)"; \
		else \
			echo "  RESULT: FAIL (expected exit 1)"; exit 1; \
		fi

	@echo ""
	@echo "[TEST 4] CSV output format — sample_sim.log"
	@bash $(ANALYZE) $(TEST_DATA)/sample_sim.log --format csv > /dev/null; \
		EXIT=$$?; \
		if [ $$EXIT -eq 0 ] || [ $$EXIT -eq 1 ]; then \
			echo "  RESULT: PASS (csv format ran, exit $$EXIT)"; \
		else \
			echo "  RESULT: FAIL (csv format errored with exit $$EXIT)"; exit 1; \
		fi

	@echo ""
	@echo "[TEST 5] --output flag — writes to file"
	@mkdir -p $(OUTPUT_DIR)
	@bash $(ANALYZE) $(TEST_DATA)/sample_pass.log \
		--output $(OUTPUT_DIR)/test_output.txt 2>/dev/null || true
	@test -f $(OUTPUT_DIR)/test_output.txt && \
		echo "  RESULT: PASS (output file created)" || \
		(echo "  RESULT: FAIL (output file not created)" && exit 1)

	@echo ""
	@echo "[TEST 6] Missing file — expect exit 2"
	@bash $(ANALYZE) nonexistent_file.log > /dev/null 2>&1; \
		if [ $$? -eq 2 ]; then \
			echo "  RESULT: PASS (exit 2 for missing file)"; \
		else \
			echo "  RESULT: FAIL (expected exit 2 for missing file)"; exit 1; \
		fi

	@echo ""
	@echo "========================================"
	@echo "         All tests passed!              "
	@echo "========================================"

# ─────────────────────────────────────────────────────────────────────────────
# report: Generate a combined summary report saved to output/
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: report
report:
	@echo "Generating batch report..."
	@mkdir -p $(OUTPUT_DIR)
	@bash $(REPORT_GEN)
	@echo ""
	@echo "Report saved to: $(OUTPUT_DIR)/summary_report.txt"

# ─────────────────────────────────────────────────────────────────────────────
# clean: Remove all generated output files
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	@echo "Cleaning output directory..."
	@rm -rf $(OUTPUT_DIR)/*
	@echo "Done. Output directory is now empty."

# ─────────────────────────────────────────────────────────────────────────────
# setup: Check that all required tools and files are present
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: setup
setup:
	@bash $(SETUP)

# ─────────────────────────────────────────────────────────────────────────────
# help: Print a description of every available target
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: help
help:
	@echo ""
	@echo "riscv-log-analyzer — Available Makefile Targets"
	@echo "================================================"
	@echo ""
	@echo "  make all      Run the analyzer on all test log files (prints to stdout)"
	@echo "  make test     Run test suite — verifies correct exit codes and output"
	@echo "  make report   Generate combined summary report in output/"
	@echo "  make clean    Remove all files in the output/ directory"
	@echo "  make setup    Check that all required tools and project files are present"
	@echo "  make help     Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make                              # same as 'make all'"
	@echo "  make report                       # save full report to output/"
	@echo "  make test && make report          # test first, then generate report"
	@echo ""
