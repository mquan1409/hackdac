#!/usr/bin/env bash
set -euo pipefail

# Build and run the Caliptra RTL Verilator smoke test.
# Run after install_new.sh and setup_new.sh:
#   ./scripts/simulate.sh
#   ./scripts/simulate.sh --trace
#   ./scripts/simulate.sh --test iccm_lock

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_NAME="hack_dac_26"
WORKSPACE="$REPO_ROOT/$WORKSPACE_NAME"
export CALIPTRA_WORKSPACE="$WORKSPACE"

# Verilator's precompiled headers embed the absolute run-directory path.  Do
# not allow ccache to restore a PCH produced for another smoke-test run.
export OBJCACHE=
export CCACHE_DISABLE=1

ENV_FILE="$WORKSPACE/caliptra_env.sh"
TEST="${TESTNAME:-iccm_lock}"
TRACE=0
LIST_ONLY=0
ALLOW_UNLISTED=0

usage() {
  cat <<USAGE
Usage: $0 [--test TESTNAME] [--trace] [--list] [--allow-unlisted]

Defaults:
  TESTNAME=iccm_lock

Options:
  --test TESTNAME   Caliptra integration test to run.
  --trace           Enable VCD tracing with VERILATOR_DEBUG=--trace.
  --list            List supported tests from Caliptra stimulus YAMLs.
  --allow-unlisted  Run a TESTNAME even if it is not in stimulus YAMLs.
USAGE
}

list_supported_tests() {
  local stimulus_dir="$WORKSPACE/third_party/caliptra-rtl/src/integration/stimulus"

  if [[ ! -d "$stimulus_dir" ]]; then
    echo "missing $stimulus_dir; run ./scripts/setup_new.sh first" >&2
    return 1
  fi

  python3 - "$stimulus_dir" <<'PY'
import pathlib
import re
import sys

stimulus_dir = pathlib.Path(sys.argv[1])
test_suites_dir = stimulus_dir.parent / "test_suites"
tests = set()
pattern = re.compile(r"test_suites/([^/\s:{]+)/\1(?:\.ya?ml)?")

for path in stimulus_dir.rglob("*.yml"):
    for match in pattern.finditer(path.read_text(errors="ignore")):
        tests.add(match.group(1))

for path in stimulus_dir.rglob("*.yaml"):
    for match in pattern.finditer(path.read_text(errors="ignore")):
        tests.add(match.group(1))

def is_direct_wrapper_test(test):
    test_dir = test_suites_dir / test
    if not test_dir.is_dir():
        return False

    direct_files = [
        test_dir / f"{test}.c",
        test_dir / f"{test}.S",
        test_dir / f"{test}.s",
        test_dir / f"{test}.hex",
        test_dir / f"{test}.makefile",
    ]
    return any(path.exists() for path in direct_files)

for test in sorted(test for test in tests if is_direct_wrapper_test(test)):
    print(test)
PY
}

validate_testname() {
  local testname="$1"
  local supported_tests

  if [[ "$ALLOW_UNLISTED" -eq 1 ]]; then
    return 0
  fi

  supported_tests="$(list_supported_tests)"
  if ! grep -Fxq "$testname" <<<"$supported_tests"; then
    echo "unsupported test for this simulate.sh flow: $testname" >&2
    echo "Use ./scripts/simulate.sh --list to see supported tests." >&2
    echo "Use --allow-unlisted only for experimental upstream test directories." >&2
    return 1
  fi
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
    --list)
      LIST_ONLY=1
      shift
      ;;
    --allow-unlisted)
      ALLOW_UNLISTED=1
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

if [[ -L "$WORKSPACE" ]]; then
  echo "workspace path is a symlink: $WORKSPACE -> $(readlink "$WORKSPACE")" >&2
  echo "run ./scripts/install_new.sh to recreate it as a real directory under this repo" >&2
  exit 1
fi

if [[ "$LIST_ONLY" -eq 1 ]]; then
  list_supported_tests
  exit 0
fi

validate_testname "$TEST"

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
