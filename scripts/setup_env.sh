#!/usr/bin/env bash
# setup_env.sh — checks that all required tools are installed
# and project files are present
# Usage: bash scripts/setup_env.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MISSING_COUNT=0

# check if a single tool is installed
check_tool() {
    local tool="$1"
    if command -v "$tool" &>/dev/null; then
        echo "  [OK]  $tool  ->  $(command -v "$tool")"
    else
        echo "  [MISSING]  $tool"
        MISSING_COUNT=$(( MISSING_COUNT + 1 ))
    fi
}

# check all required project files exist
check_directory_structure() {
    echo ""
    echo "=== Checking Project Structure ==="

    local required=(
        "scripts/analyze.sh"
        "scripts/setup_env.sh"
        "scripts/generate_report.sh"
        "test_data/sample_sim.log"
        "test_data/sample_pass.log"
        "test_data/sample_fail.log"
        "Makefile"
        "README.md"
        "docs/USAGE.md"
        ".gitignore"
    )

    local missing_files=0
    for item in "${required[@]}"; do
        if [[ -e "$PROJECT_ROOT/$item" ]]; then
            echo "  [OK]  $item"
        else
            echo "  [MISSING]  $item"
            (( missing_files++ ))
        fi
    done

    # create output dir if not present
    if [[ ! -d "$PROJECT_ROOT/output" ]]; then
        mkdir -p "$PROJECT_ROOT/output"
        echo "  [CREATED]  output/"
    else
        echo "  [OK]  output/"
    fi

    if [[ $missing_files -gt 0 ]]; then
        echo ""
        echo "WARNING: $missing_files file(s) missing."
    else
        echo ""
        echo "All required project files are present."
    fi
}

main() {
    echo "=== RISC-V Log Analyzer — Environment Setup ==="
    echo "Project root: $PROJECT_ROOT"
    echo ""
    echo "=== Checking Required Tools ==="

    check_tool bash
    check_tool grep
    check_tool awk
    check_tool sed
    check_tool make
    check_tool git
    check_tool date
    check_tool cat
    check_tool tr
    check_tool wc

    echo ""
    if [[ $MISSING_COUNT -gt 0 ]]; then
        echo "ERROR: $MISSING_COUNT tool(s) not found."
        exit 1
    else
        echo "All required tools are installed."
    fi

    check_directory_structure

    echo ""
    echo "=== Setup Complete ==="
    exit 0
}

main "$@"
