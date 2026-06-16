#!/usr/bin/env bash
# Source this file, do not execute it:
#   source /home/sethi5/hack_dac_26/caliptra_env.sh [main|v2.1]

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This file must be sourced, not executed." >&2
  echo "Use: source ${BASH_SOURCE[0]} [main|v2.1]" >&2
  exit 1
fi

_caliptra_env_prepend_path() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

export CALIPTRA_WORKSPACE="/home/sethi5/hack_dac_26"
export CALIPTRA_RTL_FLAVOR="${1:-${CALIPTRA_RTL_FLAVOR:-main}}"

case "$CALIPTRA_RTL_FLAVOR" in
  main)
    export CALIPTRA_ROOT="$CALIPTRA_WORKSPACE/third_party/caliptra-rtl"
    ;;
  v2.1|2.1)
    export CALIPTRA_RTL_FLAVOR="v2.1"
    export CALIPTRA_ROOT="$CALIPTRA_WORKSPACE/third_party/caliptra-rtl-v2.1"
    ;;
  *)
    echo "Unknown CALIPTRA_RTL_FLAVOR: $CALIPTRA_RTL_FLAVOR" >&2
    echo "Use: source caliptra_env.sh [main|v2.1]" >&2
    return 2
    ;;
esac

export CALIPTRA_PRIM_ROOT="$CALIPTRA_ROOT/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX="caliptra_prim_generic"

# For Verilator, Caliptra provides a guarded placeholder Axi4PC.sv here.
# Commercial simulators need the licensed Arm AXI4PC package instead.
export CALIPTRA_AXI4PC_DIR="$CALIPTRA_ROOT/src/integration/tb"

export RISCV_TOOLCHAIN_ROOT="$CALIPTRA_WORKSPACE/tools/riscv"
export PICOLIBC_ROOT="$RISCV_TOOLCHAIN_ROOT/picolibc/usr/lib/picolibc/riscv64-unknown-elf"
_caliptra_env_prepend_path "$RISCV_TOOLCHAIN_ROOT/bin"

if [[ -x "$CALIPTRA_WORKSPACE/tools/verilator-src-v5.044/bin/verilator" ]]; then
  export VERILATOR_ROOT="$CALIPTRA_WORKSPACE/tools/verilator-src-v5.044"
  _caliptra_env_prepend_path "$VERILATOR_ROOT/bin"
fi

export TESTNAME="${TESTNAME:-iccm_lock}"
export CALIPTRA_VERILATOR_RUN_ROOT="$CALIPTRA_WORKSPACE/runs"
export CALIPTRA_VERILATOR_DEBUG="${CALIPTRA_VERILATOR_DEBUG:-}"

caliptra_run_dir() {
  local testname="${1:-${TESTNAME:-iccm_lock}}"
  local flavor="${CALIPTRA_RTL_FLAVOR//./_}"
  printf '%s/verilator_%s_%s\n' "$CALIPTRA_VERILATOR_RUN_ROOT" "$testname" "$flavor"
}

caliptra_prepare_run_dir() {
  local testname="${1:-${TESTNAME:-iccm_lock}}"
  local run_dir
  run_dir="$(caliptra_run_dir "$testname")"
  mkdir -p "$run_dir"
  printf '%s\n' "$run_dir"
}

_caliptra_make() {
  local run_dir="$1"
  local testname="$2"
  local target="$3"
  shift 3

  local make_args=(
    -C "$run_dir"
    -f "$CALIPTRA_ROOT/tools/scripts/Makefile"
    TESTNAME="$testname"
  )

  if [[ -n "${VERILATOR_ROOT:-}" && -x "$VERILATOR_ROOT/bin/verilator" ]]; then
    make_args+=(VERILATOR="$VERILATOR_ROOT/bin/verilator")
  fi

  # Use CALIPTRA_VERILATOR_DEBUG=--trace for VCDs. Avoid the README's
  # debug=1 path in this workspace; it adds --trace-structs and currently
  # trips a Verilator internal error during Caliptra trace elaboration.
  if [[ -n "$CALIPTRA_VERILATOR_DEBUG" ]]; then
    make_args+=(VERILATOR_DEBUG="$CALIPTRA_VERILATOR_DEBUG")
  fi

  make "${make_args[@]}" "$@" "$target"
}

caliptra_build_program_hex() {
  local testname="${1:-${TESTNAME:-iccm_lock}}"
  local run_dir
  run_dir="$(caliptra_prepare_run_dir "$testname")"
  _caliptra_make "$run_dir" "$testname" program.hex
}

caliptra_build_verilator() {
  local testname="${1:-${TESTNAME:-iccm_lock}}"
  local run_dir
  run_dir="$(caliptra_prepare_run_dir "$testname")"
  _caliptra_make "$run_dir" "$testname" verilator-build
}

caliptra_run_verilator() {
  local testname="${1:-${TESTNAME:-iccm_lock}}"
  local run_dir
  run_dir="$(caliptra_run_dir "$testname")"
  (cd "$run_dir" && ./obj_dir/Vcaliptra_top_tb)
}

caliptra_smoke_test() {
  local testname="${1:-${TESTNAME:-iccm_lock}}"
  local run_dir
  run_dir="$(caliptra_prepare_run_dir "$testname")"
  _caliptra_make "$run_dir" "$testname" verilator
}

caliptra_env_summary() {
  echo "CALIPTRA_WORKSPACE=$CALIPTRA_WORKSPACE"
  echo "CALIPTRA_RTL_FLAVOR=$CALIPTRA_RTL_FLAVOR"
  echo "CALIPTRA_ROOT=$CALIPTRA_ROOT"
  echo "CALIPTRA_AXI4PC_DIR=$CALIPTRA_AXI4PC_DIR"
  echo "CALIPTRA_PRIM_ROOT=$CALIPTRA_PRIM_ROOT"
  echo "RISCV_TOOLCHAIN_ROOT=$RISCV_TOOLCHAIN_ROOT"
  echo "PICOLIBC_ROOT=$PICOLIBC_ROOT"
  echo "VERILATOR_ROOT=${VERILATOR_ROOT:-}"
  echo "CALIPTRA_VERILATOR_DEBUG=$CALIPTRA_VERILATOR_DEBUG"
  echo "TESTNAME=$TESTNAME"
  command -v riscv64-unknown-elf-gcc >/dev/null && riscv64-unknown-elf-gcc --version | head -1
  command -v verilator >/dev/null && verilator --version
}

caliptra_env_summary
