# USAGE Guide — riscv-log-analyzer

## Main Script
bash scripts/analyze.sh <logfile> [options]

Options:
  --format text     plain text output (default)
  --format csv      csv output
  --output <path>   save to file instead of terminal
  --verbose         show extra details while running
  --help            show usage

## Examples
bash scripts/analyze.sh test_data/sample_sim.log
bash scripts/analyze.sh test_data/sample_fail.log --verbose
bash scripts/analyze.sh test_data/sample_sim.log --format csv
bash scripts/analyze.sh test_data/sample_sim.log --output output/report.txt

## Other Scripts
bash scripts/setup_env.sh       # check tools installed
bash scripts/generate_report.sh # run analyzer on all logs

## Makefile
make setup    # check tools
make all      # analyze all logs
make test     # run test suite
make report   # save report to output/
make clean    # delete output files
make help     # show all targets

## Log Format Expected
[2026-05-01 10:23:45] TEST START: rv32i-add
[2026-05-01 10:23:46] TEST PASS: rv32i-add (0.82s)
[2026-05-01 10:23:48] TEST FAIL: rv32i-sll (1.02s)
[2026-05-01 10:23:48] TEST SKIP: rv32i-srl (not supported)

## Exit Codes
0 = all tests passed
1 = some tests failed
2 = wrong usage or file not found
