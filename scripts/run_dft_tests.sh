#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DFT_DIR="$REPO_ROOT/dft"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/riscv-dft.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

command -v iverilog >/dev/null 2>&1 || { echo "ERROR: iverilog not found. Load/install Icarus Verilog first." >&2; exit 127; }
command -v vvp >/dev/null 2>&1 || { echo "ERROR: vvp not found. Load/install Icarus Verilog first." >&2; exit 127; }

# Compile each top separately. Other testbench modules are present in the source
# set but are not elaborated as additional roots because -s selects one top.
TESTS=(
  tb_jtag_tap
  tb_jtag_ir
  tb_jtag_idcode
  tb_jtag_bypass
  tb_scan
  tb_jtag_cpu_scan
  tb_jtag_cpu
  tb_fault_injection
)

for tb in "${TESTS[@]}"; do
  echo
  echo "============================================================"
  echo "Running $tb"
  echo "============================================================"
  iverilog -g2012 -s "$tb" -o "$BUILD_DIR/$tb.vvp" "$DFT_DIR"/*.v "$DFT_DIR"/*.sv
  (cd "$BUILD_DIR" && vvp "./$tb.vvp")
done

echo
echo "ALL DFT/JTAG TESTBENCHES COMPLETED"
