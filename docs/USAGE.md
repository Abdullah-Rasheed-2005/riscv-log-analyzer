# USAGE — riscv-log-analyzer

Detailed command reference for all scripts and Makefile targets.

---

## analyze.sh

The main script. Parses a single RISC-V simulation log file.

### Synopsis

```
bash scripts/analyze.sh <logfile> [--format text|csv] [--output <path>]
                         [--verbose] [--help]
```

### Arguments

| Argument          | Required | Description                                   |
|-------------------|----------|-----------------------------------------------|
| `<logfile>`       | Yes      | Path to the `.log` file to analyze            |
| `--format`        | No       | Output format: `text` (default) or `csv`      |
| `--output <path>` | No       | Write output to this file instead of stdout   |
| `--verbose`       | No       | Print debug/progress messages to stderr       |
| `--help`          | No       | Print usage info and exit                     |

### Examples

```bash
# Basic usage — text output to terminal
bash scripts/analyze.sh test_data/sample_sim.log

# Save text report to a file
bash scripts/analyze.sh test_data/sample_sim.log --output output/report.txt

# Generate CSV output and save it
bash scripts/analyze.sh test_data/sample_sim.log --format csv --output output/report.csv

# Verbose mode (shows parsing progress on stderr)
bash scripts/analyze.sh test_data/sample_fail.log --verbose

# Show help
bash scripts/analyze.sh --help
```

### Exit Codes

| Code | Meaning                                  |
|------|------------------------------------------|
| `0`  | Log analyzed; all tests passed           |
| `1`  | Log analyzed; one or more tests failed   |
| `2`  | Bad usage (missing file, invalid flag)   |

---

## setup_env.sh

Checks that all required tools (`bash`, `grep`, `awk`, `sed`, `make`, `git`,
etc.) are installed, and verifies the project directory structure.

```bash
bash scripts/setup_env.sh
# or via Make:
make setup
```

---

## generate_report.sh

Runs `analyze.sh` on **every** `.log` file inside `test_data/` and writes
a combined report to `output/summary_report.txt`.

```bash
bash scripts/generate_report.sh
# or via Make:
make report
```

---

## Makefile Targets

```
make all      — Analyze all test logs, print results to stdout
make test     — Automated test suite (verifies exit codes & file creation)
make report   — Run generate_report.sh; saves to output/summary_report.txt
make clean    — Delete all files inside output/
make setup    — Run setup_env.sh to check tools and structure
make help     — Print all available Makefile targets with descriptions
```

---

## Log File Format

The analyzer expects log files in this format:

```
[YYYY-MM-DD HH:MM:SS] TEST START: <test-name>
[YYYY-MM-DD HH:MM:SS] TEST PASS: <test-name> (<time>s)
[YYYY-MM-DD HH:MM:SS] TEST FAIL: <test-name> (<time>s)
[YYYY-MM-DD HH:MM:SS] TEST SKIP: <test-name> (<reason>)
[YYYY-MM-DD HH:MM:SS] ERROR: <error message>
[YYYY-MM-DD HH:MM:SS] SUMMARY: N tests, N passed, N failed, N skipped
```

Timing information in parentheses (e.g. `(0.82s)`) is optional — if absent,
the Timing Statistics section is omitted from the report.

---

## CSV Output Format

When `--format csv` is used, a single-row CSV is produced:

```
log_file, analysis_date, total_tests, passed, failed, skipped,
pass_rate, fail_rate, skip_rate, min_time, max_time, avg_time, failed_tests
```

Failed test names in the last column are separated by semicolons.
