#!/usr/bin/env bash
# =============================================================================
# generate_report.sh — Batch Report Generator
# Part of riscv-log-analyzer (MEDS Module 1 Capstone)
#
# Runs analyze.sh on ALL log files in test_data/ and writes a combined
# summary report to output/summary_report.txt
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve paths relative to this script's location
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANALYZE_SCRIPT="$SCRIPT_DIR/analyze.sh"
TEST_DATA_DIR="$PROJECT_ROOT/test_data"
OUTPUT_DIR="$PROJECT_ROOT/output"
REPORT_FILE="$OUTPUT_DIR/summary_report.txt"

# ---------------------------------------------------------------------------
# FUNCTION: ensure_output_dir
# Creates the output directory if it doesn't exist yet
# ---------------------------------------------------------------------------
ensure_output_dir() {
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        mkdir -p "$OUTPUT_DIR"
        echo "Created output directory: $OUTPUT_DIR"
    fi
}

# ---------------------------------------------------------------------------
# FUNCTION: write_report_header
# Writes the top section of the combined report file
# ---------------------------------------------------------------------------
write_report_header() {
    cat > "$REPORT_FILE" <<EOF
=============================================================================
  RISC-V Log Analyzer — Batch Summary Report
  Generated: $(date "+%Y-%m-%d %H:%M:%S")
  Log directory: $TEST_DATA_DIR
=============================================================================

EOF
}

# ---------------------------------------------------------------------------
# FUNCTION: analyze_all_logs
# Iterates over every *.log file in test_data/ and appends its analysis
# to the combined report
# ---------------------------------------------------------------------------
analyze_all_logs() {
    # Check that at least one log file exists
    shopt -s nullglob   # prevents literal "*.log" if no files match
    local log_files=("$TEST_DATA_DIR"/*.log)
    shopt -u nullglob

    if [[ ${#log_files[@]} -eq 0 ]]; then
        echo "ERROR: No .log files found in $TEST_DATA_DIR" >&2
        exit 1
    fi

    local total_logs=0
    local total_pass_logs=0
    local total_fail_logs=0

    for log_file in "${log_files[@]}"; do
        local log_name
        log_name="$(basename "$log_file")"

        echo "Analyzing: $log_name ..."

        # Append a separator and filename header to the report
        {
            echo "─────────────────────────────────────────────────────────────────"
            echo "  Log File: $log_name"
            echo "─────────────────────────────────────────────────────────────────"
        } >> "$REPORT_FILE"

        # Run analyze.sh and append its output; capture exit code without crashing
        # (set -e would stop us if analyze.sh exits 1 for failed tests)
        if bash "$ANALYZE_SCRIPT" "$log_file" >> "$REPORT_FILE" 2>&1; then
            (( total_pass_logs++ )) || true
        else
            (( total_fail_logs++ )) || true
        fi

        echo "" >> "$REPORT_FILE"
        (( total_logs++ )) || true
    done

    # Append an overall batch summary at the bottom
    cat >> "$REPORT_FILE" <<EOF
=============================================================================
  BATCH SUMMARY
  Total log files analyzed : $total_logs
  Log files with all PASS  : $total_pass_logs
  Log files with FAILures  : $total_fail_logs
  Report saved to          : $REPORT_FILE
=============================================================================
EOF
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
main() {
    echo "=== Generating Batch Report ==="
    ensure_output_dir
    write_report_header
    analyze_all_logs

    echo ""
    echo "Report complete: $REPORT_FILE"
}

main "$@"
