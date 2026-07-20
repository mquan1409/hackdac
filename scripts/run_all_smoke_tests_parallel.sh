#!/usr/bin/env bash
# Run every regression-approved smoke_test_* target in parallel, with bounded workers.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_LIST="$REPO_ROOT/smoke_tests_available.md"
RUNS_ROOT="$REPO_ROOT/hack_dac_26/runs"
SIMULATE="$SCRIPT_DIR/simulate_container.sh"
REQUESTED_JOBS=""
REUSE_RUNS=0
SELECTED_TESTS=""

usage() {
  cat <<'USAGE'
Usage: ./scripts/run_all_smoke_tests_parallel.sh [--jobs N] [--reuse-runs] [--tests TEST1,TEST2,...]

Run only the passing, regression-approved smoke_test_* targets listed in the
"Passing Smoke Tests — Approved For Use" section of smoke_tests_available.md.
Each test runs in an independent child process. Workers receive disjoint CPU
sets; nested Verilator builds use only the CPUs assigned to their worker.

Options:
  --jobs N      Number of concurrent test workers. Default: min(available CPUs, 4).
  --reuse-runs  Keep existing generated test directories. Default: remove each
                test's own verilator_<test>_main directory before rebuilding.
  --tests LIST  Comma-separated subset of the approved passing smoke tests.
  -h, --help    Show this help text.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --jobs)
      REQUESTED_JOBS="${2:?missing value for --jobs}"
      shift 2
      ;;
    --reuse-runs)
      REUSE_RUNS=1
      shift
      ;;
    --tests)
      SELECTED_TESTS="${2:?missing value for --tests}"
      shift 2
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

if [[ "$(id -u)" -ne 0 ]]; then
  echo "run this script as root inside the HackDAC Docker container" >&2
  exit 1
fi
if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
  echo "run this script inside the HackDAC Docker container" >&2
  exit 1
fi
if [[ ! -x "$SIMULATE" || ! -f "$TEST_LIST" ]]; then
  echo "missing simulation wrapper or smoke-test list" >&2
  exit 1
fi
if ! command -v taskset >/dev/null || ! command -v flock >/dev/null; then
  echo "taskset and flock are required for bounded parallel execution" >&2
  exit 1
fi

mapfile -t TESTS < <(
  awk '
    /^### Passing Smoke Tests — Approved For Use$/ { approved = 1; next }
    /^### / { approved = 0 }
    approved && /^smoke_test_[A-Za-z0-9_]+$/ { print $1 }
  ' "$TEST_LIST" | sort -u
)
if (( ${#TESTS[@]} == 0 )); then
  echo "no regression-approved passing smoke_test_* entries found in $TEST_LIST" >&2
  exit 1
fi
if [[ -n "$SELECTED_TESTS" ]]; then
  declare -A APPROVED_TESTS=()
  for test_name in "${TESTS[@]}"; do
    APPROVED_TESTS["$test_name"]=1
  done

  IFS=',' read -r -a REQUESTED_TESTS <<< "$SELECTED_TESTS"
  TESTS=()
  for test_name in "${REQUESTED_TESTS[@]}"; do
    if [[ -z "$test_name" || -z "${APPROVED_TESTS[$test_name]+present}" ]]; then
      echo "--tests contains a missing or non-approved test: $test_name" >&2
      exit 2
    fi
    TESTS+=("$test_name")
  done
fi

mapfile -t AVAILABLE_CPUS < <(python3 - <<'PY'
import os
for cpu in sorted(os.sched_getaffinity(0)):
    print(cpu)
PY
)
CPU_COUNT="${#AVAILABLE_CPUS[@]}"
if (( CPU_COUNT == 0 )); then
  echo "unable to determine available CPUs" >&2
  exit 1
fi

if [[ -n "$REQUESTED_JOBS" ]]; then
  if ! [[ "$REQUESTED_JOBS" =~ ^[1-9][0-9]*$ ]]; then
    echo "--jobs must be a positive integer" >&2
    exit 2
  fi
  JOBS="$REQUESTED_JOBS"
else
  JOBS="$CPU_COUNT"
  if (( JOBS > 4 )); then JOBS=4; fi
fi
if (( JOBS > CPU_COUNT )); then
  echo "--jobs ($JOBS) exceeds available CPUs ($CPU_COUNT)" >&2
  exit 2
fi

mkdir -p "$RUNS_ROOT"
STAMP="$(date +%Y%m%d_%H%M%S)"
SUMMARY_FILE="$RUNS_ROOT/all_smoke_tests_summary_${STAMP}.log"
LOG_DIR="$RUNS_ROOT/all_smoke_tests_logs_${STAMP}"
mkdir -p "$LOG_DIR"

{
  echo "HackDAC parallel smoke-test summary"
  echo "Started: $(date -Is)"
  echo "Tests: ${#TESTS[@]}"
  echo "Workers: $JOBS"
  echo "Available CPUs: ${AVAILABLE_CPUS[*]}"
  echo "Per-test logs: $LOG_DIR"
  echo
} > "$SUMMARY_FILE"

write_summary() {
  local line="$1"
  {
    flock -x 9
    printf '%s\n' "$line" >&9
  } 9>>"$SUMMARY_FILE"
}

cpu_set_for_worker() {
  local worker="$1"
  local first=$(( worker * CPU_COUNT / JOBS ))
  local after_last=$(( (worker + 1) * CPU_COUNT / JOBS ))
  local -a assigned=("${AVAILABLE_CPUS[@]:first:after_last-first}")
  local IFS=,
  printf '%s' "${assigned[*]}"
}

run_test() {
  local worker="$1"
  local cpu_set="$2"
  local test_name="$3"
  local run_dir="$RUNS_ROOT/verilator_${test_name}_main"
  local log_file="$LOG_DIR/${test_name}.log"
  local start end elapsed

  write_summary "START | $(date -Is) | $test_name | worker=$worker cpus=$cpu_set | log=$log_file"
  if [[ "$REUSE_RUNS" -eq 0 && -d "$run_dir" ]]; then
    rm -rf -- "$run_dir"
  fi

  start="$(date +%s)"
  if taskset -c "$cpu_set" "$SIMULATE" --test "$test_name" >"$log_file" 2>&1; then
    end="$(date +%s)"
    elapsed="$(( end - start ))"
    write_summary "PASS  | $(date -Is) | $test_name | ${elapsed}s | log=$log_file"
  else
    end="$(date +%s)"
    elapsed="$(( end - start ))"
    write_summary "FAIL  | $(date -Is) | $test_name | ${elapsed}s | log=$log_file"
  fi
}

worker() {
  local worker_id="$1"
  local cpu_set="$2"
  local index
  for (( index=worker_id; index<${#TESTS[@]}; index+=JOBS )); do
    run_test "$worker_id" "$cpu_set" "${TESTS[index]}"
  done
}

write_summary "Launching ${#TESTS[@]} tests across $JOBS workers."
echo "Summary file: $SUMMARY_FILE"
echo "Per-test logs: $LOG_DIR"

worker_pids=()
for (( worker_id=0; worker_id<JOBS; worker_id++ )); do
  cpu_set="$(cpu_set_for_worker "$worker_id")"
  write_summary "WORKER | $(date -Is) | id=$worker_id cpus=$cpu_set"
  worker "$worker_id" "$cpu_set" &
  worker_pids+=("$!")
done

for pid in "${worker_pids[@]}"; do
  wait "$pid" || true
done

passed="$(awk -F ' \| ' '$1 == "PASS" { count++ } END { print count + 0 }' "$SUMMARY_FILE")"
failed="$(awk -F ' \| ' '$1 == "FAIL" { count++ } END { print count + 0 }' "$SUMMARY_FILE")"
write_summary ""
write_summary "FINAL | $(date -Is) | total=${#TESTS[@]} passed=$passed failed=$failed"

if (( failed > 0 )); then
  exit 1
fi
