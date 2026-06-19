#!/usr/bin/env bash
set -euo pipefail

# Fresh Ubuntu 24.04 tool install for the Caliptra RTL Verilator smoke flow.
# Run first:
#   ./scripts/install_new.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE="${CALIPTRA_WORKSPACE:-$REPO_ROOT/hack_dac}"
VERILATOR_VERSION="${VERILATOR_VERSION:-v5.044}"
VERILATOR_SRC="$WORKSPACE/tools/verilator-src-$VERILATOR_VERSION"
RISCV_ROOT="$WORKSPACE/tools/riscv"
PICOLIBC_SYSTEM_ROOT="/usr/lib/picolibc/riscv64-unknown-elf"
PICOLIBC_LOCAL_LINK="$RISCV_ROOT/picolibc/usr/lib/picolibc/riscv64-unknown-elf"
JOBS="${JOBS:-$(nproc)}"

log() {
  printf '\n[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"
}

require_sudo() {
  if [[ "$(id -u)" -ne 0 ]]; then
    sudo -v
  fi
}

run_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

apt_install() {
  if [[ "$(id -u)" -eq 0 ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get "$@"
  else
    sudo DEBIAN_FRONTEND=noninteractive apt-get "$@"
  fi
}

log "workspace: $WORKSPACE"
mkdir -p "$WORKSPACE"/{downloads,logs,runs,third_party,tools} "$RISCV_ROOT/bin"

require_sudo

log "installing Ubuntu packages"
apt_install update
apt_install install -y --no-install-recommends ca-certificates software-properties-common
run_root add-apt-repository -y universe
apt_install update
apt_install install -y --no-install-recommends \
  autoconf \
  binutils-riscv64-unknown-elf \
  bison \
  build-essential \
  ca-certificates \
  ccache \
  clang \
  cmake \
  flex \
  g++ \
  gcc \
  gcc-riscv64-unknown-elf \
  git \
  help2man \
  libfl-dev \
  libfl2 \
  make \
  ninja-build \
  perl \
  picolibc-riscv64-unknown-elf \
  python3 \
  python3-pip \
  python3-venv \
  zlib1g-dev

log "creating project-local RISC-V toolchain entry points"
shopt -s nullglob
for tool in /usr/bin/riscv64-unknown-elf-*; do
  ln -sf "$tool" "$RISCV_ROOT/bin/$(basename "$tool")"
done
shopt -u nullglob

if [[ ! -x "$RISCV_ROOT/bin/riscv64-unknown-elf-gcc" ]]; then
  echo "missing riscv64-unknown-elf-gcc after package install" >&2
  exit 1
fi

if [[ ! -d "$PICOLIBC_SYSTEM_ROOT" ]]; then
  echo "missing $PICOLIBC_SYSTEM_ROOT after picolibc package install" >&2
  exit 1
fi

log "linking picolibc into workspace"
mkdir -p "$(dirname "$PICOLIBC_LOCAL_LINK")"
ln -sfn "$PICOLIBC_SYSTEM_ROOT" "$PICOLIBC_LOCAL_LINK"

log "installing Verilator $VERILATOR_VERSION from source"
if [[ ! -d "$VERILATOR_SRC/.git" ]]; then
  rm -rf "$VERILATOR_SRC"
  git clone --depth 1 --branch "$VERILATOR_VERSION" https://github.com/verilator/verilator "$VERILATOR_SRC"
else
  git -C "$VERILATOR_SRC" fetch --depth 1 origin "$VERILATOR_VERSION"
  git -C "$VERILATOR_SRC" checkout -f "$VERILATOR_VERSION"
fi

(
  cd "$VERILATOR_SRC"
  autoconf
  CC=clang CXX=clang++ ./configure
  make -C src optimize -j "$JOBS" CC=clang CXX=clang++
)

if [[ ! -x "$VERILATOR_SRC/bin/verilator" ]]; then
  echo "Verilator binary was not produced at $VERILATOR_SRC/bin/verilator" >&2
  exit 1
fi

log "tool versions"
"$RISCV_ROOT/bin/riscv64-unknown-elf-gcc" --version | head -1
"$VERILATOR_SRC/bin/verilator" --version

log "install_new.sh complete"
