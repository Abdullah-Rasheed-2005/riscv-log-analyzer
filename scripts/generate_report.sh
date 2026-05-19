#!/usr/bin/env bash
# generate_report.sh — runs analyze.sh on all log files in test_data/
# and saves a combined report to output/summary_report.txt
# Usage: bash scripts/generate_report.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANALYZE_SCRIPT="$SCRIPT_DIR/analyze.sh"
TEST_DATA_DIR="$PROJECT_ROOT/test_data"
OUTPUT_DIR="$PROJECT_ROOT/output"
REPORT_FILE="$OUTPUT_DIR/summary_report.txt"

# create output folder if it doesn't exist
ensure_output_dir() {
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        mkdir -p "$OUTPUT_DIR"
        echo "Created output directory: $OUTPUT_DIR"
    fi
}

# write report header with date
write_report_header() {
    cat > "$REPORT_FILE" <<EOF
=============================================================================
  RISC-V Log Analyzer — Batch Summary Report
  Generated: $(date "+%Y-%m-%d %H:%M:%S")
  Log directory: $TEST_DATA_DIR
=============================================================================

EOF
}

# run analyze.sh on every .log file and append results to report
analyze_all_logs() {
    shopt -s nullglob
    local log_files=("$TEST_DATA_DIR"/*.log)
    shopt -u nullglob

    if [[ ${#log_files[@]} -eq 0 ]]; then
        echo "ERROR: no .log files found in $TEST_DATA_DIR" >&2
        exit 1
    fi

    local total=0
    local passed=0
    local failed=0

    for log_file in "${log_files[@]}"; do
        local log_name
        log_name="$(basename "$log_file")"
        echo "Analyzing: $log_name ..."

        {
            echo "─────────────────────────────────────────"
            echo "  Log File: $log_name"
            echo "─────────────────────────────────────────"
        } >> "$REPORT_FILE"

        # run analyzer and capture exit code
        if bash "$ANALYZE_SCRIPT" "$log_file" >> "$REPORT_FILE" 2>&1; then
            (( passed++ )) || true
        else
            (( failed++ )) || true
        fi

        echo "" >> "$REPORT_FILE"
        (( total++ )) || true
    done

    # write batch summary at the bottom
    cat >> "$REPORT_FILE" <<EOF
=============================================================================
  BATCH SUMMARY
  Total log files : $total
  All passed      : $passed
  Had failures    : $failed
  Report saved to : $REPORT_FILE
=============================================================================
EOF
}

main() {
    echo "=== Generating Batch Report ==="
    ensure_output_dir
    write_report_header
    analyze_all_logs
    echo ""
    echo "Report complete: $REPORT_FILE"
}

main "$@"
