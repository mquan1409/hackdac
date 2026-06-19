# Caliptra RTL Verilator Dry Run Setup

Workspace used for all local artifacts:

```sh
$HOME/hackdac/hack_dac_26
```

I intentionally did not use the Caliptra software emulator flow. This document
tracks the RTL/Verilator path only.

## Requested Result

The requested dry run was a Verilator simulation of the Caliptra SoC. That did
not complete.

The `program.hex` build below is documented only because the Caliptra Verilator
Makefile requires a memory image before it can launch the SoC testbench. It is
not the requested result and should not be read as a successful simulation.

Prerequisite steps that completed:

- Cloned `caliptra-rtl` locally.
- Set up a project-local RISC-V toolchain entry point.
- Added local RISC-V C library headers/libs from `picolibc`.
- Built the `iccm_lock` dummy/smoke firmware image:
  - `runs/verilator_iccm_lock/program.hex`
  - `runs/verilator_iccm_lock/dccm.hex`
  - `runs/verilator_iccm_lock/iccm_lock.exe`

Requested step that failed:

- Verilator failed during RTL elaboration before generating the simulator binary.
- Host Verilator 5.028 failed with:

```text
%Error: Verilator internal fault, sorry. Suggest trying --debug --gdbbt
```

- A local optimized Verilator 5.044 binary was built from source and retried.
  It failed at the same Caliptra RTL elaboration step with the same internal
  Verilator fault.

Final evidence:

```text
runs/verilator_iccm_lock/verilator_build.log
```

## 1. Create Local Workspace Folders

```sh
cd $HOME/hackdac/hack_dac_26
mkdir -p third_party tools/riscv/bin runs logs downloads
```

## 2. RISC-V Toolchain Setup

The host already had the RISC-V bare-metal tools installed:

```text
riscv64-unknown-elf-gcc (13.2.0-11ubuntu1+12) 13.2.0
```

To keep the run commands project-local, I created a local prefix with symlinks
to the available `riscv64-unknown-elf-*` binaries:

```sh
cd $HOME/hackdac/hack_dac_26
for f in /usr/bin/riscv64-unknown-elf-*; do
  ln -sf "$f" "tools/riscv/bin/$(basename "$f")"
done

tools/riscv/bin/riscv64-unknown-elf-gcc --version | head -1
```

## 3. Local RISC-V C Library Headers and Libs

The first firmware build failed because the RISC-V GCC package did not include
target C headers like `string.h`.

I downloaded and extracted `picolibc-riscv64-unknown-elf` into this workspace:

```sh
cd $HOME/hackdac/hack_dac_26
cd downloads
apt-get download picolibc-riscv64-unknown-elf
cd ..
dpkg-deb -x downloads/picolibc-riscv64-unknown-elf_1.8.6-2_all.deb \
  tools/riscv/picolibc
```

Paths used later:

```sh
PICOLIBC=$HOME/hackdac/hack_dac_26/tools/riscv/picolibc/usr/lib/picolibc/riscv64-unknown-elf
PICOLIBC_INC=$PICOLIBC/include
PICOLIBC_LIB=$PICOLIBC/lib/release/rv32imac/ilp32
```

## 4. Clone Caliptra RTL

```sh
cd $HOME/hackdac/hack_dac_26
git clone --recursive https://github.com/chipsalliance/caliptra-rtl \
  third_party/caliptra-rtl
```

Observed revision:

```text
caliptra-rtl: a687e263
submodules/adams-bridge: c2f863176bcc773c01a9c2f631536cbcd77a68a0
```

## 5. Environment for Caliptra RTL

```sh
export CALIPTRA_WORKSPACE=$HOME/hackdac/hack_dac_26
export CALIPTRA_ROOT=$HOME/hackdac/hack_dac_26/third_party/caliptra-rtl
export CALIPTRA_PRIM_ROOT=$CALIPTRA_ROOT/src/caliptra_prim_generic
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR=$CALIPTRA_ROOT/src/integration/tb
export PATH=$HOME/hackdac/hack_dac_26/tools/riscv/bin:$PATH
export TESTNAME=iccm_lock
```

`CALIPTRA_AXI4PC_DIR` points at the repo-provided Verilator-safe placeholder:

```text
third_party/caliptra-rtl/src/integration/tb/Axi4PC.sv
```

That file is guarded so it only errors for non-Verilator flows.

## 6. Build the Required Dummy/Smoke Memory Image

Run directory:

```sh
cd $HOME/hackdac/hack_dac_26
mkdir -p runs/verilator_iccm_lock
```

Firmware build command:

```sh
make -C $HOME/hackdac/hack_dac_26/runs/verilator_iccm_lock \
  -f $HOME/hackdac/hack_dac_26/third_party/caliptra-rtl/tools/scripts/Makefile \
  TESTNAME=iccm_lock \
  BUILD_CFLAGS="-I$HOME/hackdac/hack_dac_26/tools/riscv/picolibc/usr/lib/picolibc/riscv64-unknown-elf/include" \
  TEST_LIBS="-nostdlib -L$HOME/hackdac/hack_dac_26/tools/riscv/picolibc/usr/lib/picolibc/riscv64-unknown-elf/lib/release/rv32imac/ilp32 -L$HOME/hackdac/hack_dac_26/tools/riscv/picolibc/usr/lib/picolibc/riscv64-unknown-elf/lib/release -lc -lm -lgcc" \
  program.hex
```

Result:

```text
program.hex exists 300967 bytes
dccm.hex exists 359285 bytes
iccm.hex exists 0 bytes
mailbox.hex exists 0 bytes
iccm_lock.exe exists 634020 bytes

text    data     bss     dec     hex filename
79968   14272    192   94432   170e0 iccm_lock.exe
```

## 7. First Verilator Attempt with Host Verilator 5.028

Host Verilator:

```text
Verilator 5.028 2024-08-21 rev v5.028
```

Command:

```sh
make -C $HOME/hackdac/hack_dac_26/runs/verilator_iccm_lock \
  -f $HOME/hackdac/hack_dac_26/third_party/caliptra-rtl/tools/scripts/Makefile \
  TESTNAME=iccm_lock \
  BUILD_CFLAGS="-I$HOME/hackdac/hack_dac_26/tools/riscv/picolibc/usr/lib/picolibc/riscv64-unknown-elf/include" \
  TEST_LIBS="-nostdlib -L$HOME/hackdac/hack_dac_26/tools/riscv/picolibc/usr/lib/picolibc/riscv64-unknown-elf/lib/release/rv32imac/ilp32 -L$HOME/hackdac/hack_dac_26/tools/riscv/picolibc/usr/lib/picolibc/riscv64-unknown-elf/lib/release -lc -lm -lgcc" \
  verilator
```

Result:

```text
%Error: Verilator internal fault, sorry. Suggest trying --debug --gdbbt
make: *** [.../tools/scripts/Makefile:284: verilator-build] Error 255
```

## 8. Local Verilator 5.044 Attempt

The Caliptra RTL README says this revision was tested with Verilator 5.044, so
I tried to build it locally.

Clone:

```sh
cd $HOME/hackdac/hack_dac_26
git clone --depth 1 --branch v5.044 https://github.com/verilator/verilator \
  tools/verilator-src-v5.044
```

The `g++` build failed with an internal compiler error. Retrying with `clang++`
also failed while building the debug Verilator binary, but the optimized
Verilator binary was produced and usable:

```text
tools/verilator-src-v5.044/bin/verilator --version
Verilator 5.044 2026-01-01 rev v5.044
```

Build logs:

```text
logs/verilator_5_044_install.log
logs/verilator_5_044_install_j1.log
logs/verilator_5_044_install_clang.log
```

Retry environment:

```sh
export VERILATOR_ROOT=$HOME/hackdac/hack_dac_26/tools/verilator-src-v5.044
export PATH=$VERILATOR_ROOT/bin:$HOME/hackdac/hack_dac_26/tools/riscv/bin:$PATH
```

Retry command:

```sh
make -C $HOME/hackdac/hack_dac_26/runs/verilator_iccm_lock \
  -f $HOME/hackdac/hack_dac_26/third_party/caliptra-rtl/tools/scripts/Makefile \
  TESTNAME=iccm_lock \
  BUILD_CFLAGS="-I$HOME/hackdac/hack_dac_26/tools/riscv/picolibc/usr/lib/picolibc/riscv64-unknown-elf/include" \
  TEST_LIBS="-nostdlib -L$HOME/hackdac/hack_dac_26/tools/riscv/picolibc/usr/lib/picolibc/riscv64-unknown-elf/lib/release/rv32imac/ilp32 -L$HOME/hackdac/hack_dac_26/tools/riscv/picolibc/usr/lib/picolibc/riscv64-unknown-elf/lib/release -lc -lm -lgcc" \
  verilator-build
```

Result:

```text
%Error: Verilator internal fault, sorry. Suggest trying --debug --gdbbt
%Error: Command Failed ... tools/verilator-src-v5.044/bin/verilator_bin ...
make: *** [.../tools/scripts/Makefile:284: verilator-build] Error 255
```

## 9. Final Status

The Caliptra dummy/smoke memory image built successfully, but that was only a
prerequisite. The requested chip RTL simulation did not run. Both Verilator
versions tried here failed during Verilator elaboration, before
`obj_dir/Vcaliptra_top_tb` was generated.

Final answer to "did it work?": no, not as a complete Caliptra RTL simulation.
The setup gets through firmware image generation and then blocks on a Verilator
internal fault.

## 10. Follow-up Correction: Caliptra RTL v2.1 Tag

Because the requested starting point was the Caliptra 2.1 documentation, I also
tested the matching `caliptra-rtl` `v2.1` tag instead of treating `main` as the
only target.

Create a separate worktree:

```sh
cd $HOME/hackdac/hack_dac_26
git -C third_party/caliptra-rtl worktree add ../caliptra-rtl-v2.1 v2.1
git -C third_party/caliptra-rtl-v2.1 submodule update --init --recursive
```

Observed revision:

```text
caliptra-rtl-v2.1: 0381c00a
submodules/adams-bridge: 730902213ddb4eb4966e7bc9e542b7b21f5a9011
```

The v2.1 repo already contains prebuilt images for the `iccm_lock` smoke test,
so I used those directly instead of making firmware build part of the requested
result:

```sh
cd $HOME/hackdac/hack_dac_26
mkdir -p runs/verilator_iccm_lock_v2_1
cp third_party/caliptra-rtl-v2.1/src/integration/test_suites/iccm_lock/iccm_lock.hex \
  runs/verilator_iccm_lock_v2_1/program.hex
cp third_party/caliptra-rtl-v2.1/src/integration/test_suites/iccm_lock/dccm.hex \
  runs/verilator_iccm_lock_v2_1/dccm.hex
touch runs/verilator_iccm_lock_v2_1/iccm.hex
touch runs/verilator_iccm_lock_v2_1/mailbox.hex
```

Then I ran only the SoC Verilator build target:

```sh
export CALIPTRA_WORKSPACE=$HOME/hackdac/hack_dac_26
export CALIPTRA_ROOT=$HOME/hackdac/hack_dac_26/third_party/caliptra-rtl-v2.1
export CALIPTRA_AXI4PC_DIR=$CALIPTRA_ROOT/src/integration/tb
export CALIPTRA_PRIM_ROOT=$CALIPTRA_ROOT/src/caliptra_prim_generic
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export PATH=$HOME/hackdac/hack_dac_26/tools/riscv/bin:$PATH

make -C $HOME/hackdac/hack_dac_26/runs/verilator_iccm_lock_v2_1 \
  -f $CALIPTRA_ROOT/tools/scripts/Makefile \
  TESTNAME=iccm_lock \
  verilator-build
```

Result with host Verilator 5.028:

```text
%Error: Verilator internal fault, sorry. Suggest trying --debug --gdbbt
make: *** [.../tools/scripts/Makefile:270: verilator-build] Error 255
```

I also retried v2.1 using the locally built optimized Verilator 5.044 binary:

```text
%Error: Verilator internal fault, sorry. Suggest trying --debug --gdbbt
make: *** [.../tools/scripts/Makefile:270: verilator-build] Error 139
```

The v2.1 README lists Verilator 5.012 as the tested simulator version. I tried
to build Verilator 5.012 locally, optimized binary only, with both `g++` and
`clang++`. Both compiler toolchains crashed with compiler internal errors before
producing a usable `verilator_bin`.

Evidence logs:

```text
logs/caliptra_v2_1_host_verilator_build_only.log
logs/caliptra_v2_1_local_5044_verilator_build_only.log
logs/verilator_5_012_opt_build.log
logs/verilator_5_012_opt_build_clang.log
```

Corrected final answer: the requested Caliptra SoC Verilator dry run still did
not work. The v2.1 test did not get as far as simulator binary generation, even
when using the prebuilt `iccm_lock` memory images.

## 11. README `caliptra_top program.hex` Target

The README command:

```sh
make -f ${CALIPTRA_ROOT}/tools/scripts/Makefile TESTNAME=caliptra_top program.hex
```

initially failed with:

```text
fatal error: string.h: No such file or directory
```

The root cause was the host `riscv64-unknown-elf-gcc` package not exposing a
target C library/sysroot. I fixed this locally by replacing only the project
local `tools/riscv/bin/riscv64-unknown-elf-gcc` symlink with a wrapper that:

- uses the real `/usr/bin/riscv64-unknown-elf-gcc`;
- adds the locally extracted picolibc include path for compile steps;
- adds `-nostdlib` plus local picolibc `-lc -lm -lgcc` for link steps.

Wrapper path:

```text
tools/riscv/bin/riscv64-unknown-elf-gcc
```

With `PATH=$HOME/hackdac/hack_dac_26/tools/riscv/bin:$PATH`, the exact README
command now passes for the current `main` checkout:

```sh
cd $HOME/hackdac/hack_dac_26/runs/caliptra_top_programhex_main
export CALIPTRA_ROOT=$HOME/hackdac/hack_dac_26/third_party/caliptra-rtl
export PATH=$HOME/hackdac/hack_dac_26/tools/riscv/bin:$PATH
make -f ${CALIPTRA_ROOT}/tools/scripts/Makefile TESTNAME=caliptra_top program.hex
```

Result:

```text
Completed building caliptra_top
text    data    bss    dec    hex  filename
76112   14272   192  90576  161d0  caliptra_top.exe
```

Generated artifacts:

```text
runs/caliptra_top_programhex_main/program.hex
runs/caliptra_top_programhex_main/dccm.hex
runs/caliptra_top_programhex_main/iccm.hex
runs/caliptra_top_programhex_main/mailbox.hex
runs/caliptra_top_programhex_main/caliptra_top.exe
```

I also verified the same README target against the `v2.1` worktree:

```sh
cd $HOME/hackdac/hack_dac_26/runs/caliptra_top_programhex_v2_1
export CALIPTRA_ROOT=$HOME/hackdac/hack_dac_26/third_party/caliptra-rtl-v2.1
export PATH=$HOME/hackdac/hack_dac_26/tools/riscv/bin:$PATH
make -f ${CALIPTRA_ROOT}/tools/scripts/Makefile TESTNAME=caliptra_top program.hex
```

Result:

```text
Completed building caliptra_top
text    data    bss    dec    hex  filename
74416   13248   192  87856  15730  caliptra_top.exe
```

Generated artifacts:

```text
runs/caliptra_top_programhex_v2_1/program.hex
runs/caliptra_top_programhex_v2_1/dccm.hex
runs/caliptra_top_programhex_v2_1/iccm.hex
runs/caliptra_top_programhex_v2_1/mailbox.hex
runs/caliptra_top_programhex_v2_1/caliptra_top.exe
```
