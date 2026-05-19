# riscv-log-analyzer

MEDS Module 1 Grand Assignment
Student: Abdullah Rasheed

## What it does
Parses RISC-V simulation log files using bash scripts.
Counts PASS, FAIL, SKIP results and shows timing stats.

## How to run
chmod +x scripts/*.sh
make setup
bash scripts/analyze.sh test_data/sample_sim.log
make test
make report

## Scripts
- analyze.sh   — reads log file, counts results, shows report
- setup_env.sh — checks if bash/grep/awk/git are installed
- generate_report.sh — runs analyzer on all logs in test_data/

## Git workflow
- 4 feature branches merged into main
- 13 commits with meaningful messages
- 1 merge conflict manually resolved in nano
