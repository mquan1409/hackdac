#!/usr/bin/env bash
set -euo pipefail

# Build and run the Caliptra RTL Verilator smoke test.
# Run after install_new.sh and setup_new.sh:
#   ./scripts/simulate.sh
#   ./scripts/simulate.sh --trace
#   ./scripts/simulate.sh --test iccm_lock

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE="${CALIPTRA_WORKSPACE:-$REPO_ROOT/hack_dac}"
ENV_FILE="$WORKSPACE/caliptra_env.sh"
TEST="${TESTNAME:-iccm_lock}"
TRACE=0

usage() {
  cat <<USAGE
Usage: $0 [--test TESTNAME] [--trace]

Defaults:
  TESTNAME=iccm_lock

Options:
  --test TESTNAME  Caliptra integration test to run.
  --trace          Enable VCD tracing with VERILATOR_DEBUG=--trace.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test)
      TEST="${2:?missing value for --test}"
      shift 2
      ;;
    --trace)
      TRACE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$ENV_FILE" ]]; then
  echo "missing $ENV_FILE; run ./scripts/setup_new.sh first" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

export TESTNAME="$TEST"
if [[ "$TRACE" -eq 1 ]]; then
  export CALIPTRA_VERILATOR_DEBUG="--trace"
else
  unset CALIPTRA_VERILATOR_DEBUG
fi

mkdir -p "$CALIPTRA_WORKSPACE/logs"
RUN_DIR="$(caliptra_prepare_run_dir "$TESTNAME")"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="$CALIPTRA_WORKSPACE/logs/smoke_${TESTNAME}_main_${STAMP}.log"

{
  echo "CALIPTRA smoke simulation"
  echo "timestamp=$STAMP"
  echo "run_dir=$RUN_DIR"
  echo "log=$LOG"
  caliptra_env_summary
  echo
  caliptra_smoke_test "$TESTNAME"
} 2>&1 | tee "$LOG"
STATUS="${PIPESTATUS[0]}"

if [[ "$STATUS" -ne 0 ]]; then
  echo "simulation command failed; see $LOG" >&2
  exit "$STATUS"
fi

if grep -q "TESTCASE PASSED" "$RUN_DIR/verilator_sim.log" "$LOG"; then
  echo "smoke test passed"
  echo "log: $LOG"
  echo "run dir: $RUN_DIR"
  if [[ "$TRACE" -eq 1 ]]; then
    echo "waveform: $RUN_DIR/sim.vcd"
  fi
else
  echo "simulation finished but TESTCASE PASSED was not found; see $LOG" >&2
  exit 1
fi
