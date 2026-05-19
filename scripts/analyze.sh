#!/usr/bin/env bash
# analyze.sh — reads a RISC-V log file and prints a summary report
# Usage: bash scripts/analyze.sh <logfile> [--format text|csv] [--output <path>] [--verbose] [--help]

set -euo pipefail

# default values
FORMAT="text"
OUTPUT_PATH=""
VERBOSE=false
LOG_FILE=""

# print help message
print_help() {
    echo "Usage: analyze.sh <logfile> [--format text|csv] [--output path] [--verbose] [--help]"
    echo ""
    echo "  --format    text or csv output (default: text)"
    echo "  --output    save output to file instead of terminal"
    echo "  --verbose   show extra details"
    echo "  --help      show this message"
    exit 0
}

# print message only if --verbose is on
log_verbose() {
    if $VERBOSE; then
        echo "[VERBOSE] $*" >&2
    fi
}

# read and validate arguments
parse_arguments() {
    if [[ $# -eq 0 ]]; then
        echo "Error: no log file given." >&2
        exit 2
    fi

    if [[ "$1" == "--help" ]]; then
        print_help
    fi

    LOG_FILE="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format)
                FORMAT="$2"
                if [[ "$FORMAT" != "text" && "$FORMAT" != "csv" ]]; then
                    echo "Error: format must be text or csv" >&2
                    exit 2
                fi
                shift 2
                ;;
            --output)
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
                echo "Error: unknown option $1" >&2
                exit 2
                ;;
        esac
    done
}

# check log file exists and is readable
validate_inputs() {
    if [[ ! -e "$LOG_FILE" ]]; then
        echo "Error: file not found: $LOG_FILE" >&2
        exit 2
    fi
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "Error: not a regular file: $LOG_FILE" >&2
        exit 2
    fi
    if [[ ! -r "$LOG_FILE" ]]; then
        echo "Error: cannot read file: $LOG_FILE" >&2
        exit 2
    fi
    log_verbose "file ok: $LOG_FILE"
}

# parse the log file and count results
analyze_log() {
    log_verbose "analyzing log..."

    # count PASS, FAIL, SKIP lines
    TOTAL_PASS=$(grep -c "TEST PASS:" "$LOG_FILE" || true)
    TOTAL_FAIL=$(grep -c "TEST FAIL:" "$LOG_FILE" || true)
    TOTAL_SKIP=$(grep -c "TEST SKIP:" "$LOG_FILE" || true)
    TOTAL_TESTS=$(( TOTAL_PASS + TOTAL_FAIL + TOTAL_SKIP ))

    # calculate percentages
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        PASS_RATE=$(awk "BEGIN { printf \"%.1f\", ($TOTAL_PASS/$TOTAL_TESTS)*100 }")
        FAIL_RATE=$(awk "BEGIN { printf \"%.1f\", ($TOTAL_FAIL/$TOTAL_TESTS)*100 }")
        SKIP_RATE=$(awk "BEGIN { printf \"%.1f\", ($TOTAL_SKIP/$TOTAL_TESTS)*100 }")
    else
        PASS_RATE="0.0"; FAIL_RATE="0.0"; SKIP_RATE="0.0"
    fi

    # get names of failed tests
    FAILED_TESTS=$(grep "TEST FAIL:" "$LOG_FILE" | sed 's/.*TEST FAIL: \([^ ]*\).*/\1/' || true)

    # extract timing values from log lines like: TEST PASS: rv32i-add (0.82s)
    TIMES=$(grep -E "TEST (PASS|FAIL):" "$LOG_FILE" | grep -oE '\([0-9]+\.[0-9]+s\)' | tr -d '()s' || true)

    if [[ -n "$TIMES" ]]; then
        read -r MIN_TIME MAX_TIME AVG_TIME <<< "$(echo "$TIMES" | awk '
            BEGIN { min=999999; max=0; sum=0; count=0 }
            { val=$1+0; sum+=val; count++
              if(val<min) min=val
              if(val>max) max=val }
            END { printf "%.2f %.2f %.2f", min, max, sum/count }
        ')"
        MIN_TEST=$(grep -E "TEST (PASS|FAIL):" "$LOG_FILE" | grep "(${MIN_TIME}s)" | head -1 | sed 's/.*TEST [A-Z]*: \([^ ]*\).*/\1/' || echo "unknown")
        MAX_TEST=$(grep -E "TEST (PASS|FAIL):" "$LOG_FILE" | grep "(${MAX_TIME}s)" | head -1 | sed 's/.*TEST [A-Z]*: \([^ ]*\).*/\1/' || echo "unknown")
        TIMING_AVAILABLE=true
    else
        MIN_TIME="N/A"; MAX_TIME="N/A"; AVG_TIME="N/A"
        MIN_TEST="N/A"; MAX_TEST="N/A"
        TIMING_AVAILABLE=false
    fi
}

# print text format report
render_text() {
    local verdict
    [[ $TOTAL_FAIL -gt 0 ]] && verdict="FAIL" || verdict="PASS"

    cat <<EOF
=== RISC-V Simulation Log Analysis ===
Log file: $LOG_FILE
Analysis date: $(date "+%Y-%m-%d %H:%M:%S")

 --- Results Summary ---
Total tests: $TOTAL_TESTS
Passed:      $TOTAL_PASS ($PASS_RATE%)
Failed:      $TOTAL_FAIL ($FAIL_RATE%)
Skipped:     $TOTAL_SKIP ($SKIP_RATE%)

 --- Failed Tests ---
EOF
    if [[ -z "$FAILED_TESTS" ]]; then
        echo "  (none)"
    else
        local i=1
        while IFS= read -r t; do
            printf "  %d. %s\n" "$i" "$t"
            (( i++ ))
        done <<< "$FAILED_TESTS"
    fi

    if $TIMING_AVAILABLE; then
        cat <<EOF

 --- Timing Statistics ---
Min time:  ${MIN_TIME}s ($MIN_TEST)
Max time:  ${MAX_TIME}s ($MAX_TEST)
Avg time:  ${AVG_TIME}s
EOF
    fi

    echo ""
    echo " --- Verdict: $verdict ---"
    echo "Exit code: $( [[ $TOTAL_FAIL -gt 0 ]] && echo 1 || echo 0 )"
}

# print csv format report
render_csv() {
    local failed_list
    failed_list=$(echo "$FAILED_TESTS" | tr '\n' ';' | sed 's/;$//')
    echo "log_file,date,total,passed,failed,skipped,pass_rate,fail_rate,skip_rate,min_time,max_time,avg_time,failed_tests"
    echo "\"$LOG_FILE\",\"$(date "+%Y-%m-%d %H:%M:%S")\",$TOTAL_TESTS,$TOTAL_PASS,$TOTAL_FAIL,$TOTAL_SKIP,$PASS_RATE,$FAIL_RATE,$SKIP_RATE,$MIN_TIME,$MAX_TIME,$AVG_TIME,\"$failed_list\""
}

# write output to file or terminal
write_output() {
    local out
    [[ "$FORMAT" == "csv" ]] && out=$(render_csv) || out=$(render_text)

    if [[ -n "$OUTPUT_PATH" ]]; then
        mkdir -p "$(dirname "$OUTPUT_PATH")"
        echo "$out" > "$OUTPUT_PATH"
        echo "saved to: $OUTPUT_PATH" >&2
    else
        echo "$out"
    fi
}

# main
main() {
    parse_arguments "$@"
    validate_inputs
    analyze_log
    write_output
    [[ $TOTAL_FAIL -gt 0 ]] && exit 1 || exit 0
}

main "$@"
