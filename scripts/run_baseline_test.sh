#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
RTL_DIR="$REPO_ROOT/rtl"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/riscv-baseline.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

command -v iverilog >/dev/null 2>&1 || { echo "ERROR: iverilog not found. Load/install Icarus Verilog first." >&2; exit 127; }
command -v vvp >/dev/null 2>&1 || { echo "ERROR: vvp not found. Load/install Icarus Verilog first." >&2; exit 127; }

iverilog -g2012 -s tb_capstone_cpu_pipe_final -o "$BUILD_DIR/baseline_sim" \
  "$RTL_DIR/capstone_cpu_pipe.v" \
  "$RTL_DIR/if_id.v" "$RTL_DIR/id_ex.v" "$RTL_DIR/ex_mem.v" "$RTL_DIR/mem_wb.v" \
  "$RTL_DIR/hazard_unit.v" "$RTL_DIR/forwarding_unit.v" \
  "$RTL_DIR/ControlUnit.v" "$RTL_DIR/immgen.v" "$RTL_DIR/rv32ialu.v" \
  "$RTL_DIR/aluaddsub.v" "$RTL_DIR/alulogic.v" "$RTL_DIR/alushift.v" "$RTL_DIR/alucomp.v" \
  "$RTL_DIR/BankedMEM.v" "$RTL_DIR/bank8.v" "$RTL_DIR/regfile.v" "$RTL_DIR/reg32.v" \
  "$RTL_DIR/decoder5to32.v" "$RTL_DIR/PCInc.v" "$RTL_DIR/perf_counter.v" \
  "$RTL_DIR/tb_capstone_cpu_pipe.v"

# Run from the temporary directory so VCDs do not clutter the repository.
(cd "$BUILD_DIR" && vvp ./baseline_sim)
