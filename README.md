# riscv-log-analyzer
MEDS Module 1 Grand Assignment
Student: Abdullah Rasheed — Summer Training 2026

## What it does
Reads RISC-V simulation log files using bash scripts.
Counts PASS, FAIL, SKIP results and shows timing stats.
Can output as plain text or CSV format.

## Setup
git clone https://github.com/Abdullah-Rasheed-2005/riscv-log-analyzer.git
cd riscv-log-analyzer
chmod +x scripts/*.sh
make setup

## How to run
bash scripts/analyze.sh test_data/sample_sim.log
bash scripts/analyze.sh test_data/sample_fail.log --verbose
bash scripts/analyze.sh test_data/sample_sim.log --format csv
bash scripts/analyze.sh test_data/sample_sim.log --output output/report.txt
make test
make report
make clean

## Scripts
- analyze.sh          reads log file, counts results, prints report
- setup_env.sh        checks if bash/grep/awk/sed/git/make are installed
- generate_report.sh  runs analyzer on all logs in test_data/

## Makefile
make all     # analyze all logs
make test    # run test suite
make report  # save report to output/
make clean   # delete output files
make setup   # check tools and files
make help    # show all targets

## Git workflow
- 4 feature branches created and merged into main
- 1 merge conflict created intentionally and resolved
- pushed to GitHub from WSL terminal

## Project Structure
riscv-log-analyzer/
├── Makefile
├── README.md
├── .gitignore
├── scripts/
│   ├── analyze.sh
│   ├── setup_env.sh
│   └── generate_report.sh
├── test_data/
│   ├── sample_sim.log
│   ├── sample_pass.log
│   └── sample_fail.log
├── output/
└── docs/
    └── USAGE.md
