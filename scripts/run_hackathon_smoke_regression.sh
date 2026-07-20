#!/usr/bin/env bash
# Run the HackDAC functional regression inside the project Docker container.
#
# Runs functional smoke tests sequentially.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RTL_ROOT="$REPO_ROOT/hack_dac_26/third_party/caliptra-rtl/src"
RUNS_ROOT="$REPO_ROOT/hack_dac_26/runs"
SIMULATE="$SCRIPT_DIR/simulate_container.sh"
EXTENDED=0
CLEAN_RUNS=1

usage() {
  cat <<'USAGE'
Usage: ./scripts/run_hackathon_smoke_regression.sh [--extended] [--reuse-runs]

Run the core HackDAC functional smoke regression sequentially.

Options:
  --extended  Also run longer AES/DMA and KeyVault/HMAC stress smoke tests.
  --reuse-runs  Keep existing per-test build directories. Default: rebuild each test.
  -h, --help  Show this help text.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --extended) EXTENDED=1 ;;
    --reuse-runs) CLEAN_RUNS=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$(id -u)" -ne 0 ]]; then
  echo "run this script as root inside the HackDAC Docker container" >&2
  exit 1
fi
if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
  echo "run this script inside the HackDAC Docker container" >&2
  exit 1
fi
if [[ ! -x "$SIMULATE" ]]; then
  echo "missing executable simulation wrapper: $SIMULATE" >&2
  exit 1
fi

mkdir -p "$RUNS_ROOT"
SUMMARY_FILE="$RUNS_ROOT/hackathon_smoke_regression_summary_$(date +%Y%m%d_%H%M%S).log"
{
  echo "HackDAC smoke regression summary"
  echo "Started: $(date -Is)"
  echo "Repository: $REPO_ROOT"
  echo
} > "$SUMMARY_FILE"

summary_line() {
  printf '%s\n' "$*" | tee -a "$SUMMARY_FILE"
}

CORE_TESTS=(
  smoke_test_aes_kv_rand
)

EXTENDED_TESTS=(
  smoke_test_dma_aes_gcm_collision_test
  smoke_test_dma_aes_gcm_long
  smoke_test_dma_aes_gcm_non_gcm_en_dec
  smoke_test_dma_aes_gcm_rd_enc_axi_err
  smoke_test_dma_aes_gcm_wr_enc_axi_err
  smoke_test_hmac_errortrigger
  smoke_test_fw_kv_backtoback_hmac
  smoke_test_kv_hmac_multiblock_flow
  smoke_test_kv_lock_use_mid_read
)

summary_line "Summary file: $SUMMARY_FILE"
summary_line "Running functional smoke tests."

# ccache can restore a precompiled header created under another run directory.
# Disable it here; do not delete runs/ while a simulation is in progress.
export OBJCACHE=
export CCACHE_DISABLE=1

TESTS=("${CORE_TESTS[@]}")
if [[ "$EXTENDED" -eq 1 ]]; then
  TESTS+=("${EXTENDED_TESTS[@]}")
fi

failures=()
results=()
summary_line "== Running ${#TESTS[@]} smoke tests sequentially =="
for test_name in "${TESTS[@]}"; do
  echo
  echo "===== START $test_name ====="
  run_dir="$RUNS_ROOT/verilator_${test_name}_main"
  if [[ "$CLEAN_RUNS" -eq 1 && -d "$run_dir" ]]; then
    echo "Removing generated build artifacts: $run_dir"
    rm -rf -- "$run_dir"
  fi
  start_seconds="$(date +%s)"
  if "$SIMULATE" --test "$test_name"; then
    elapsed_seconds="$(( $(date +%s) - start_seconds ))"
    echo "===== PASS  $test_name (${elapsed_seconds}s) ====="
    results+=("PASS  $test_name (${elapsed_seconds}s)")
  else
    elapsed_seconds="$(( $(date +%s) - start_seconds ))"
    echo "===== FAIL  $test_name (${elapsed_seconds}s) =====" >&2
    failures+=("$test_name")
    results+=("FAIL  $test_name (${elapsed_seconds}s)")
  fi
done

passed_count="$(( ${#TESTS[@]} - ${#failures[@]} ))"
summary_line ""
summary_line "== Final smoke-test results =="
for result in "${results[@]}"; do
  summary_line "$result"
done
summary_line "Total: ${#TESTS[@]}  Passed: $passed_count  Failed: ${#failures[@]}"

if (( ${#failures[@]} )); then
  summary_line "Smoke regression failed: ${failures[*]}"
  exit 1
fi

summary_line "All ${#TESTS[@]} smoke tests passed."
