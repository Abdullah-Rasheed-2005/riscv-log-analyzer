#!/usr/bin/env bash
# =============================================================================
# analyze.sh — RISC-V Simulation Log Analyzer
# Part of riscv-log-analyzer (MEDS Module 1 Capstone)
#
# Usage:
#   ./scripts/analyze.sh <logfile> [--format text|csv] [--output <path>]
#                        [--verbose] [--help]
# =============================================================================

# Strict mode: exit on error, undefined variable, or pipe failure
set -euo pipefail

# ---------------------------------------------------------------------------
# GLOBAL VARIABLES
# ---------------------------------------------------------------------------
SCRIPT_NAME="$(basename "$0")"
FORMAT="text"          # Default output format
OUTPUT_PATH=""         # Empty means stdout
VERBOSE=false          # Verbose mode off by default
LOG_FILE=""            # Path to the log file (positional arg)

# ---------------------------------------------------------------------------
# FUNCTION: print_help
# Shows usage information and exits
# ---------------------------------------------------------------------------
print_help() {
    cat <<EOF
Usage: $SCRIPT_NAME <logfile> [OPTIONS]

Analyzes a RISC-V simulation log file and produces a summary report.

Arguments:
  <logfile>              Path to the simulation log file (required)

Options:
  --format [text|csv]    Output format (default: text)
  --output <path>        Write output to file instead of stdout
  --verbose              Show extra processing details
  --help                 Show this help message and exit

Examples:
  $SCRIPT_NAME test_data/sample_sim.log
  $SCRIPT_NAME test_data/sample_fail.log --format csv --output output/report.csv
  $SCRIPT_NAME test_data/sample_pass.log --verbose

Exit Codes:
  0  All tests passed (or no failures found)
  1  One or more tests failed
  2  Script usage / file error
EOF
    exit 0
}

# ---------------------------------------------------------------------------
# FUNCTION: log_verbose
# Prints a message only when --verbose flag is set
# ---------------------------------------------------------------------------
log_verbose() {
    if $VERBOSE; then
        echo "[VERBOSE] $*" >&2
    fi
}

# ---------------------------------------------------------------------------
# FUNCTION: parse_arguments
# Reads command-line arguments and sets global variables
# ---------------------------------------------------------------------------
parse_arguments() {
    # First positional argument must be the log file
    if [[ $# -eq 0 ]]; then
        echo "Error: No log file specified." >&2
        echo "Run '$SCRIPT_NAME --help' for usage." >&2
        exit 2
    fi

    # Handle --help even as the first argument
    if [[ "$1" == "--help" ]]; then
        print_help
    fi

    # First argument is the log file path
    LOG_FILE="$1"
    shift  # Remove log file from argument list

    # Parse remaining optional flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format)
                # Ensure a value follows --format
                if [[ $# -lt 2 ]]; then
                    echo "Error: --format requires an argument (text or csv)." >&2
                    exit 2
                fi
                FORMAT="$2"
                # Validate the format value
                if [[ "$FORMAT" != "text" && "$FORMAT" != "csv" ]]; then
                    echo "Error: Invalid format '$FORMAT'. Use 'text' or 'csv'." >&2
                    exit 2
                fi
                shift 2
                ;;
            --output)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --output requires a file path argument." >&2
                    exit 2
                fi
                OUTPUT_PATH="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                print_help
                ;;
            *)
                echo "Error: Unknown option '$1'." >&2
                echo "Run '$SCRIPT_NAME --help' for usage." >&2
                exit 2
                ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# FUNCTION: validate_inputs
# Checks that the log file exists and is readable
# ---------------------------------------------------------------------------
validate_inputs() {
    if [[ ! -e "$LOG_FILE" ]]; then
        echo "Error: File not found: '$LOG_FILE'" >&2
        exit 2
    fi

    if [[ ! -f "$LOG_FILE" ]]; then
        echo "Error: '$LOG_FILE' is not a regular file." >&2
        exit 2
    fi

    if [[ ! -r "$LOG_FILE" ]]; then
        echo "Error: Cannot read file: '$LOG_FILE'" >&2
        exit 2
    fi

    log_verbose "Log file validated: $LOG_FILE"
}

# ---------------------------------------------------------------------------
# FUNCTION: analyze_log
# Core parsing logic — reads the log and populates result variables
# ---------------------------------------------------------------------------
analyze_log() {
    log_verbose "Starting log analysis..."

    # Count result types using grep (returns 0 even if no match with || true)
    TOTAL_PASS=$(grep -c "TEST PASS:" "$LOG_FILE" || true)
    TOTAL_FAIL=$(grep -c "TEST FAIL:" "$LOG_FILE" || true)
    TOTAL_SKIP=$(grep -c "TEST SKIP:" "$LOG_FILE" || true)

    # Total tests = pass + fail + skip
    TOTAL_TESTS=$(( TOTAL_PASS + TOTAL_FAIL + TOTAL_SKIP ))

    log_verbose "Parsed counts — PASS:$TOTAL_PASS FAIL:$TOTAL_FAIL SKIP:$TOTAL_SKIP"

    # Calculate pass rate percentage (avoid division by zero)
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        # Use awk for floating-point percentage calculation
        PASS_RATE=$(awk "BEGIN { printf \"%.1f\", ($TOTAL_PASS / $TOTAL_TESTS) * 100 }")
        FAIL_RATE=$(awk "BEGIN { printf \"%.1f\", ($TOTAL_FAIL / $TOTAL_TESTS) * 100 }")
        SKIP_RATE=$(awk "BEGIN { printf \"%.1f\", ($TOTAL_SKIP / $TOTAL_TESTS) * 100 }")
    else
        PASS_RATE="0.0"
        FAIL_RATE="0.0"
        SKIP_RATE="0.0"
    fi

    # Extract names of failed tests (text after "TEST FAIL: " and before " (")
    # Example line: [2026-05-01 10:23:48] TEST FAIL: rv32i-sll (1.02s)
    FAILED_TESTS=$(grep "TEST FAIL:" "$LOG_FILE" \
        | sed 's/.*TEST FAIL: \([^ ]*\).*/\1/' || true)

    log_verbose "Failed tests extracted."

    # ---------------------------------------------------------------------------
    # Timing statistics — extract seconds values from PASS/FAIL lines
    # Lines look like: TEST PASS: rv32i-add (0.82s)
    # We grab the number inside parentheses before 's)'
    # ---------------------------------------------------------------------------
    TIMES=$(grep -E "TEST (PASS|FAIL):" "$LOG_FILE" \
        | grep -oE '\([0-9]+\.[0-9]+s\)' \
        | tr -d '()s' || true)

    if [[ -n "$TIMES" ]]; then
        # Use awk to compute min, max, avg and find which tests hit min/max
        read -r MIN_TIME MAX_TIME AVG_TIME <<< "$(echo "$TIMES" | awk '
            BEGIN { min=999999; max=0; sum=0; count=0 }
            {
                val = $1 + 0
                sum += val
                count++
                if (val < min) min = val
                if (val > max) max = val
            }
            END {
                if (count > 0)
                    printf "%.2f %.2f %.2f", min, max, sum/count
                else
                    printf "N/A N/A N/A"
            }
        ')"

        # Find the test name associated with the minimum time
        MIN_TEST=$(grep -E "TEST (PASS|FAIL):" "$LOG_FILE" \
            | grep "(${MIN_TIME}s)" \
            | head -1 \
            | sed 's/.*TEST [A-Z]*: \([^ ]*\).*/\1/' || echo "unknown")

        # Find the test name associated with the maximum time
        MAX_TEST=$(grep -E "TEST (PASS|FAIL):" "$LOG_FILE" \
            | grep "(${MAX_TIME}s)" \
            | head -1 \
            | sed 's/.*TEST [A-Z]*: \([^ ]*\).*/\1/' || echo "unknown")

        TIMING_AVAILABLE=true
    else
        MIN_TIME="N/A"
        MAX_TIME="N/A"
        AVG_TIME="N/A"
        MIN_TEST="N/A"
        MAX_TEST="N/A"
        TIMING_AVAILABLE=false
    fi

    log_verbose "Timing analysis complete. Timing available: $TIMING_AVAILABLE"
}

# ---------------------------------------------------------------------------
# FUNCTION: render_text
# Formats and prints the analysis result in human-readable text format
# ---------------------------------------------------------------------------
render_text() {
    local analysis_date
    analysis_date=$(date "+%Y-%m-%d %H:%M:%S")

    # Determine overall verdict
    local verdict
    if [[ $TOTAL_FAIL -gt 0 ]]; then
        verdict="FAIL"
    else
        verdict="PASS"
    fi

    cat <<EOF
=== RISC-V Simulation Log Analysis ===
Log file: $LOG_FILE
Analysis date: $analysis_date

 --- Results Summary ---
Total tests: $TOTAL_TESTS
Passed:      $TOTAL_PASS ($PASS_RATE%)
Failed:      $TOTAL_FAIL ($FAIL_RATE%)
Skipped:     $TOTAL_SKIP ($SKIP_RATE%)

 --- Failed Tests ---
EOF

    # List failed tests or show "None" if all passed
    if [[ -z "$FAILED_TESTS" ]]; then
        echo "  (none)"
    else
        local i=1
        while IFS= read -r test_name; do
            printf "  %d. %s\n" "$i" "$test_name"
            (( i++ ))
        done <<< "$FAILED_TESTS"
    fi

    # Only show timing section if timing data was found in the log
    if $TIMING_AVAILABLE; then
        cat <<EOF

 --- Timing Statistics ---
Min time:  ${MIN_TIME}s ($MIN_TEST)
Max time:  ${MAX_TIME}s ($MAX_TEST)
Avg time:  ${AVG_TIME}s
EOF
    fi

    cat <<EOF

 --- Verdict: $verdict ---
Exit code: $( [[ $TOTAL_FAIL -gt 0 ]] && echo 1 || echo 0 )
EOF
}

# ---------------------------------------------------------------------------
# FUNCTION: render_csv
# Formats and prints the analysis result in CSV format
# ---------------------------------------------------------------------------
render_csv() {
    local analysis_date
    analysis_date=$(date "+%Y-%m-%d %H:%M:%S")

    # CSV header row
    echo "log_file,analysis_date,total_tests,passed,failed,skipped,pass_rate,fail_rate,skip_rate,min_time,max_time,avg_time,failed_tests"

    # Convert newline-separated failed test names to semicolon-separated
    local failed_list
    failed_list=$(echo "$FAILED_TESTS" | tr '\n' ';' | sed 's/;$//')

    # Single data row
    echo "\"$LOG_FILE\",\"$analysis_date\",$TOTAL_TESTS,$TOTAL_PASS,$TOTAL_FAIL,$TOTAL_SKIP,$PASS_RATE,$FAIL_RATE,$SKIP_RATE,$MIN_TIME,$MAX_TIME,$AVG_TIME,\"$failed_list\""
}

# ---------------------------------------------------------------------------
# FUNCTION: write_output
# Sends rendered output to stdout or a file depending on --output flag
# ---------------------------------------------------------------------------
write_output() {
    # Choose renderer based on --format flag
    local rendered_output
    if [[ "$FORMAT" == "csv" ]]; then
        rendered_output=$(render_csv)
    else
        rendered_output=$(render_text)
    fi

    # Write to file or print to stdout
    if [[ -n "$OUTPUT_PATH" ]]; then
        # Create parent directory if it doesn't exist
        mkdir -p "$(dirname "$OUTPUT_PATH")"
        echo "$rendered_output" > "$OUTPUT_PATH"
        echo "Report saved to: $OUTPUT_PATH" >&2
    else
        echo "$rendered_output"
    fi
}

# ---------------------------------------------------------------------------
# MAIN ENTRY POINT
# ---------------------------------------------------------------------------
main() {
    parse_arguments "$@"
    validate_inputs
    analyze_log
    write_output

    # Exit with code 1 if any tests failed, 0 if all passed
    if [[ $TOTAL_FAIL -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main with all passed arguments
main "$@"
