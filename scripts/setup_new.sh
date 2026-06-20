#!/usr/bin/env bash
set -euo pipefail

# Clone/pin Caliptra RTL and write the workspace environment helper.
# Run after install_new.sh:
#   ./scripts/setup_new.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_NAME="hack_dac_26"
WORKSPACE="$REPO_ROOT/$WORKSPACE_NAME"
export CALIPTRA_WORKSPACE="$WORKSPACE"
CALIPTRA_REPO="${CALIPTRA_REPO:-https://github.com/chipsalliance/caliptra-rtl}"
CALIPTRA_REF="${CALIPTRA_REF:-a687e263ab4550b40ab428dee1494a07a9add7d5}"
CALIPTRA_ROOT="$WORKSPACE/third_party/caliptra-rtl"
VERILATOR_VERSION="${VERILATOR_VERSION:-v5.044}"
ENV_FILE="$WORKSPACE/caliptra_env.sh"

log() {
  printf '\n[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"
}

prepare_workspace_dirs() {
  if [[ -L "$WORKSPACE" ]]; then
    log "removing workspace symlink: $WORKSPACE -> $(readlink "$WORKSPACE")"
    rm "$WORKSPACE"
  fi

  mkdir -p "$WORKSPACE"
  for dir in downloads logs runs third_party tools; do
    if [[ -L "$WORKSPACE/$dir" ]]; then
      log "removing workspace subdir symlink: $WORKSPACE/$dir -> $(readlink "$WORKSPACE/$dir")"
      rm "$WORKSPACE/$dir"
    fi
  done

  mkdir -p "$WORKSPACE"/{downloads,logs,runs,third_party,tools}
}

log "workspace: $WORKSPACE"
prepare_workspace_dirs

log "checking required tools"
for tool in git make riscv64-unknown-elf-gcc; do
  if ! command -v "$tool" >/dev/null 2>&1 && [[ ! -x "$WORKSPACE/tools/riscv/bin/$tool" ]]; then
    echo "missing required tool: $tool; run ./scripts/install_new.sh first" >&2
    exit 1
  fi
done

if [[ ! -x "$WORKSPACE/tools/verilator-src-$VERILATOR_VERSION/bin/verilator" ]]; then
  echo "missing workspace Verilator $VERILATOR_VERSION; run ./scripts/install_new.sh first" >&2
  exit 1
fi

log "cloning/updating Caliptra RTL"
if [[ ! -d "$CALIPTRA_ROOT/.git" ]]; then
  rm -rf "$CALIPTRA_ROOT"
  git clone --recursive "$CALIPTRA_REPO" "$CALIPTRA_ROOT"
fi

(
  cd "$CALIPTRA_ROOT"
  git fetch origin
  git checkout -f "$CALIPTRA_REF"
  git clean -ffdx
  git submodule sync --recursive
  git submodule update --init --recursive
)

ACTUAL_REF="$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)"
if [[ "$ACTUAL_REF" != "$CALIPTRA_REF" ]]; then
  echo "Caliptra checkout mismatch: expected $CALIPTRA_REF, got $ACTUAL_REF" >&2
  exit 1
fi

log "writing $ENV_FILE"
cat > "$ENV_FILE" <<'ENV_EOF'
#!/usr/bin/env bash
# Source this file, do not execute it:
#   source hack_dac_26/caliptra_env.sh

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This file must be sourced, not executed." >&2
  echo "Use: source ${BASH_SOURCE[0]}" >&2
  exit 1
fi

_caliptra_env_prepend_path() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

export CALIPTRA_WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CALIPTRA_RTL_FLAVOR="${CALIPTRA_RTL_FLAVOR:-main}"
export CALIPTRA_ROOT="$CALIPTRA_WORKSPACE/third_party/caliptra-rtl"
export CALIPTRA_PRIM_ROOT="$CALIPTRA_ROOT/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX="caliptra_prim_generic"

# Caliptra provides a guarded Verilator-safe Axi4PC placeholder here.
export CALIPTRA_AXI4PC_DIR="$CALIPTRA_ROOT/src/integration/tb"

export RISCV_TOOLCHAIN_ROOT="$CALIPTRA_WORKSPACE/tools/riscv"
_caliptra_env_prepend_path "$RISCV_TOOLCHAIN_ROOT/bin"

if [[ -d "$RISCV_TOOLCHAIN_ROOT/picolibc/usr/lib/picolibc/riscv64-unknown-elf" ]]; then
  export PICOLIBC_ROOT="$RISCV_TOOLCHAIN_ROOT/picolibc/usr/lib/picolibc/riscv64-unknown-elf"
elif [[ -d /usr/lib/picolibc/riscv64-unknown-elf ]]; then
  export PICOLIBC_ROOT="/usr/lib/picolibc/riscv64-unknown-elf"
else
  export PICOLIBC_ROOT=""
fi

export VERILATOR_VERSION="${VERILATOR_VERSION:-v5.044}"
if [[ -x "$CALIPTRA_WORKSPACE/tools/verilator-src-$VERILATOR_VERSION/bin/verilator" ]]; then
  export VERILATOR_ROOT="$CALIPTRA_WORKSPACE/tools/verilator-src-$VERILATOR_VERSION"
  _caliptra_env_prepend_path "$VERILATOR_ROOT/bin"
fi

export TESTNAME="${TESTNAME:-iccm_lock}"
export CALIPTRA_VERILATOR_RUN_ROOT="${CALIPTRA_VERILATOR_RUN_ROOT:-$CALIPTRA_WORKSPACE/runs}"
export CALIPTRA_VERILATOR_DEBUG="${CALIPTRA_VERILATOR_DEBUG:-}"

caliptra_run_dir() {
  local testname="${1:-${TESTNAME:-iccm_lock}}"
  printf '%s/verilator_%s_main\n' "$CALIPTRA_VERILATOR_RUN_ROOT" "$testname"
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

  if [[ -n "${PICOLIBC_ROOT:-}" && -d "$PICOLIBC_ROOT/include" ]]; then
    make_args+=(BUILD_CFLAGS="-I$PICOLIBC_ROOT/include ${CALIPTRA_EXTRA_BUILD_CFLAGS:-}")
  fi

  if [[ -n "${PICOLIBC_ROOT:-}" && -d "$PICOLIBC_ROOT/lib/release/rv32imac/ilp32" ]]; then
    make_args+=(TEST_LIBS="-nostdlib -L$PICOLIBC_ROOT/lib/release/rv32imac/ilp32 -L$PICOLIBC_ROOT/lib/release -lc -lm -lgcc ${CALIPTRA_EXTRA_TEST_LIBS:-}")
  fi

  if [[ -n "${VERILATOR_ROOT:-}" && -x "$VERILATOR_ROOT/bin/verilator" ]]; then
    make_args+=(VERILATOR="$VERILATOR_ROOT/bin/verilator")
  fi

  # For VCDs use CALIPTRA_VERILATOR_DEBUG=--trace.
  # Avoid debug=1 because it adds --trace-structs and hit a Verilator
  # internal error in this workspace's Caliptra flow.
  if [[ -n "${CALIPTRA_VERILATOR_DEBUG:-}" ]]; then
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
  echo "CALIPTRA_ROOT=$CALIPTRA_ROOT"
  echo "CALIPTRA_AXI4PC_DIR=$CALIPTRA_AXI4PC_DIR"
  echo "CALIPTRA_PRIM_ROOT=$CALIPTRA_PRIM_ROOT"
  echo "RISCV_TOOLCHAIN_ROOT=$RISCV_TOOLCHAIN_ROOT"
  echo "PICOLIBC_ROOT=$PICOLIBC_ROOT"
  echo "VERILATOR_ROOT=${VERILATOR_ROOT:-}"
  echo "CALIPTRA_VERILATOR_DEBUG=${CALIPTRA_VERILATOR_DEBUG:-}"
  echo "TESTNAME=$TESTNAME"
  command -v riscv64-unknown-elf-gcc >/dev/null && riscv64-unknown-elf-gcc --version | head -1
  command -v verilator >/dev/null && verilator --version
}
ENV_EOF

chmod +x "$ENV_FILE"

log "environment summary"
(
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  caliptra_env_summary
)

log "setup_new.sh complete"
