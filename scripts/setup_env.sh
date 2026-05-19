#!/usr/bin/env bash
# =============================================================================
# setup_env.sh — Environment Setup & Tool Checker
# Part of riscv-log-analyzer (MEDS Module 1 Capstone)
#
# Verifies that all required tools are installed and that the project
# directory structure is correct. Safe to run multiple times.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# FUNCTION: check_tool
# Checks if a single command-line tool is available on PATH
# Arguments: $1 = tool name
# ---------------------------------------------------------------------------
check_tool() {
    local tool="$1"
    if command -v "$tool" &>/dev/null; then
        # command -v returns the path if found
        echo "  [OK]  $tool  ->  $(command -v "$tool")"
    else
        echo "  [MISSING]  $tool  —  Please install it before continuing."
        MISSING_COUNT=$(( MISSING_COUNT + 1 ))
    fi
}

# ---------------------------------------------------------------------------
# FUNCTION: check_directory_structure
# Verifies that all required project directories/files exist
# ---------------------------------------------------------------------------
check_directory_structure() {
    echo ""
    echo "=== Checking Project Structure ==="

    # List of files/dirs that must exist relative to PROJECT_ROOT
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

    # Ensure output directory exists (it's gitignored but must be present)
    if [[ ! -d "$PROJECT_ROOT/output" ]]; then
        mkdir -p "$PROJECT_ROOT/output"
        echo "  [CREATED]  output/ directory"
    else
        echo "  [OK]  output/"
    fi

    if [[ $missing_files -gt 0 ]]; then
        echo ""
        echo "WARNING: $missing_files required file(s) are missing."
    else
        echo ""
        echo "All required project files are present."
    fi
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
main() {
    # Resolve project root: two levels up from this script (scripts/ -> project/)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

    MISSING_COUNT=0

    echo "=== RISC-V Log Analyzer — Environment Setup ==="
    echo "Project root: $PROJECT_ROOT"
    echo ""
    echo "=== Checking Required Tools ==="

    # Core tools needed by the analyzer scripts
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
        echo "ERROR: $MISSING_COUNT required tool(s) not found."
        echo "Install them and re-run this script."
    else
        echo "All required tools are installed."
    fi

    check_directory_structure

    echo ""
    echo "=== Setup Complete ==="

    # Exit non-zero if tools are missing so Makefile 'setup' target can fail
    if [[ $MISSING_COUNT -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
