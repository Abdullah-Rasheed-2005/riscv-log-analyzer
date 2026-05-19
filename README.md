# riscv-log-analyzer

A shell-based tool that processes RISC-V simulation log files, extracts test
results, and generates human-readable or CSV summary reports.

Built as the **MEDS Module 1 Capstone** project — demonstrating Linux commands,
shell scripting, Git workflows, and Makefile automation.

---

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Sample Output](#sample-output)
- [Project Structure](#project-structure)

---

## Description

`riscv-log-analyzer` reads simulation log files produced by RISC-V test
environments. It counts PASS / FAIL / SKIP results, calculates the pass rate,
lists failing test names, and reports timing statistics (min / max / average
execution time per test).

---

## Installation

No installation required. Clone the repository and make the scripts executable:

```bash
git clone <your-repo-url>
cd riscv-log-analyzer
chmod +x scripts/*.sh
```

Verify all required tools are present:

```bash
make setup
```

---

## Quick Start

```bash
# Analyze a single log file (text output to terminal)
bash scripts/analyze.sh test_data/sample_sim.log

# Run all tests and generate a report
make test
make report
```

---

## Usage

```
scripts/analyze.sh <logfile> [OPTIONS]

Arguments:
  <logfile>              Path to the simulation log file (required)

Options:
  --format [text|csv]    Output format (default: text)
  --output <path>        Write output to file instead of stdout
  --verbose              Show extra processing details
  --help                 Show help message and exit
```

### Makefile Targets

| Target       | Description                                           |
|--------------|-------------------------------------------------------|
| `make all`   | Run analyzer on all test log files (stdout)           |
| `make test`  | Run automated test suite (verifies exit codes)        |
| `make report`| Generate combined report in `output/`                 |
| `make clean` | Remove all generated output files                     |
| `make setup` | Check required tools and project structure            |
| `make help`  | Print all available targets                           |

---

## Sample Output

```
=== RISC-V Simulation Log Analysis ===
Log file: test_data/sample_fail.log
Analysis date: 2026-05-05 14:30:00

 --- Results Summary ---
Total tests: 25
Passed:      22 (88.0%)
Failed:       2  (8.0%)
Skipped:      1  (4.0%)

 --- Failed Tests ---
  1. rv32i-sll
  2. rv32i-beq

 --- Timing Statistics ---
Min time:  0.42s (rv32i-nop)
Max time:  2.31s (rv32i-mul)
Avg time:  0.87s

 --- Verdict: FAIL ---
Exit code: 1
```

---

## Project Structure

```
riscv-log-analyzer/
├── README.md
├── Makefile
├── .gitignore
├── scripts/
│   ├── analyze.sh          # Main analysis script
│   ├── setup_env.sh        # Environment setup & tool checker
│   └── generate_report.sh  # Batch report generator
├── test_data/
│   ├── sample_sim.log      # Mixed pass/fail/skip log
│   ├── sample_pass.log     # All tests passing
│   └── sample_fail.log     # Multiple failures
├── output/                 # Generated reports (gitignored)
└── docs/
    └── USAGE.md            # Detailed command reference
```

---

## Exit Codes

| Code | Meaning                              |
|------|--------------------------------------|
| `0`  | All tests in the log passed          |
| `1`  | One or more tests failed             |
| `2`  | Usage error or file not found        |

---

## Author

MEDS Lab — Module 1 Capstone Project
