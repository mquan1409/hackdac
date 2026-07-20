#!/usr/bin/env bash
# Run the five approved WDT/DOE/RAS smoke tests concurrently.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS="smoke_test_wdt,smoke_test_wdt_rst,smoke_test_doe_scan,smoke_test_ras,smoke_test_cg_wdt"

exec "$SCRIPT_DIR/run_all_smoke_tests_parallel.sh" \
  --jobs 5 \
  --tests "$TESTS" \
  "$@"
