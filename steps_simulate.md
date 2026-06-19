# Caliptra Verilator Smoke-Test Flow

This file documents the README flow for building and running a Caliptra
top-level Verilator smoke test from this workspace:

```sh
$HOME/hackdac/hack_dac_26
```

The environment setup is centralized in:

```sh
source $HOME/hackdac/hack_dac_26/caliptra_env.sh [main|v2.1]
```

Use `main` for the current `third_party/caliptra-rtl` checkout, or `v2.1` for
the worktree matching the Caliptra 2.1 docs.

## 1. Source the Environment

For the current `main` checkout:

```sh
cd $HOME/hackdac/hack_dac_26
source ./caliptra_env.sh main
```

For the Caliptra RTL `v2.1` worktree:

```sh
cd $HOME/hackdac/hack_dac_26
source ./caliptra_env.sh v2.1
```

The source file exports:

```text
CALIPTRA_WORKSPACE
CALIPTRA_ROOT
CALIPTRA_AXI4PC_DIR
CALIPTRA_PRIM_ROOT
CALIPTRA_PRIM_MODULE_PREFIX
RISCV_TOOLCHAIN_ROOT
PICOLIBC_ROOT
VERILATOR_ROOT
PATH
TESTNAME
```

It also defines helper functions:

```text
caliptra_env_summary
caliptra_run_dir [testname]
caliptra_prepare_run_dir [testname]
caliptra_build_program_hex [testname]
caliptra_build_verilator [testname]
caliptra_run_verilator [testname]
caliptra_smoke_test [testname]
```

## 2. README Smoke-Test Target

The Caliptra RTL README recommends `iccm_lock` as the first Verilator smoke
test. The README one-shot command is:

```sh
RUN_DIR="$(caliptra_prepare_run_dir iccm_lock)"

make -C "$RUN_DIR" \
  -f "$CALIPTRA_ROOT/tools/scripts/Makefile" \
  TESTNAME=iccm_lock \
  verilator
```

Equivalent helper:

```sh
caliptra_smoke_test iccm_lock
```

This Makefile target does three things:

1. Builds the test memory images, including `program.hex`.
2. Builds the Verilator model as `obj_dir/Vcaliptra_top_tb`.
3. Runs `./obj_dir/Vcaliptra_top_tb`.

## 3. Split Build and Run Steps

If you want to inspect each step separately:

```sh
RUN_DIR="$(caliptra_prepare_run_dir iccm_lock)"

make -C "$RUN_DIR" \
  -f "$CALIPTRA_ROOT/tools/scripts/Makefile" \
  TESTNAME=iccm_lock \
  program.hex

make -C "$RUN_DIR" \
  -f "$CALIPTRA_ROOT/tools/scripts/Makefile" \
  TESTNAME=iccm_lock \
  verilator-build

cd "$RUN_DIR"
./obj_dir/Vcaliptra_top_tb
```

Equivalent helpers:

```sh
caliptra_build_program_hex iccm_lock
caliptra_build_verilator iccm_lock
caliptra_run_verilator iccm_lock
```

## 4. Optional Waveform Debug

The README says `debug=1` enables VCD waveform output, but in this workspace
that path currently fails because it expands to `--trace --trace-structs`.
Verilator 5.044 reports an internal error while elaborating Caliptra trace
state:

```text
%Error: Internal Error: src/soc_ifc/rtl/soc_ifc_top.sv:565:66:
../V3Number.cpp:1005: toUInt with 4-state 32'bz000000100111
```

Use `VERILATOR_DEBUG=--trace` instead. This keeps VCD waveform generation and
avoids `--trace-structs`:

```sh
RUN_DIR="$(caliptra_prepare_run_dir iccm_lock)"

make -C "$RUN_DIR" \
  -f "$CALIPTRA_ROOT/tools/scripts/Makefile" \
  TESTNAME=iccm_lock \
  VERILATOR="$VERILATOR_ROOT/bin/verilator" \
  VERILATOR_DEBUG=--trace \
  verilator
```

Equivalent helper flow:

```sh
export CALIPTRA_VERILATOR_DEBUG=--trace
caliptra_smoke_test iccm_lock
```

The waveform file is:

```text
sim.vcd
```

## 5. Optional L0 Regression Smoke Suite

The README also documents the wrapper script for the smoke-test suite:

```sh
python3 "$CALIPTRA_ROOT/tools/scripts/run_verilator_l0_regression.py"
```

The script creates timestamped run folders under:

```text
$CALIPTRA_WORKSPACE/scratch/$USER/verilator/<timestamp>/<testname>
```

and writes per-test logs with pass/fail status.

## 6. Known State in This Workspace

The README `program.hex` target is currently passing here:

```sh
source $HOME/hackdac/hack_dac_26/caliptra_env.sh main
RUN_DIR=$HOME/hackdac/hack_dac_26/runs/caliptra_top_programhex_main
mkdir -p "$RUN_DIR"
make -C "$RUN_DIR" \
  -f "$CALIPTRA_ROOT/tools/scripts/Makefile" \
  TESTNAME=caliptra_top \
  program.hex
```

Verified output:

```text
runs/caliptra_top_programhex_main/program.hex
runs/caliptra_top_programhex_main/dccm.hex
runs/caliptra_top_programhex_main/iccm.hex
runs/caliptra_top_programhex_main/mailbox.hex
```

The full Verilator SoC smoke simulation now passes for `iccm_lock` when using
the local optimized Verilator 5.044 and avoiding `debug=1`:

```text
logs/diag_local_nodebug_verilator_run.log
* TESTCASE PASSED
```

The VCD trace workaround also passes:

```text
logs/diag_local_trace_envroot_verilator_run.log
* TESTCASE PASSED
waveforms=sim.vcd
```

Do not use host Verilator 5.028 for the current main checkout. It still fails
RTL elaboration before `obj_dir/Vcaliptra_top_tb` is generated:

```text
logs/diag_host_nodebug_verilator_build.log
%Error: Verilator internal fault, sorry. Suggest trying --debug --gdbbt
```

The currently working smoke-test command is:

```sh
source $HOME/hackdac/hack_dac_26/caliptra_env.sh main
unset CALIPTRA_VERILATOR_DEBUG
caliptra_smoke_test iccm_lock
```

For a VCD:

```sh
source $HOME/hackdac/hack_dac_26/caliptra_env.sh main
export CALIPTRA_VERILATOR_DEBUG=--trace
caliptra_smoke_test iccm_lock
```
