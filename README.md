# Pipelined RISC-V Processor with JTAG-Based Design-for-Testability

A modular 32-bit RISC-V-subset processor implemented in Verilog, evolving from a single-cycle baseline to a five-stage pipeline with forwarding, hazard detection, pipeline stalls, branch flushing, and performance counters.

The project extends the processor with a scan-based design-for-testability (DFT) architecture using scan-enabled pipeline registers and a JTAG test-access interface. The DFT implementation includes a TAP controller, instruction register, IDCODE and BYPASS data registers, and a serial scan path for observing internal pipeline state.

This is an educational implementation of an RV32I subset. It does not claim full RISC-V ISA compliance or full IEEE 1149.1 compliance.

## Architecture

The processor uses the classic five-stage pipeline:

**IF → ID → EX → MEM → WB**

Core components include:

- Program counter and instruction/data memories
- Register file, immediate generator, ALU, and control unit
- IF/ID, ID/EX, EX/MEM, and MEM/WB pipeline registers
- Forwarding and load-use hazard detection units
- Branch control and pipeline flushing
- Performance counters

## Supported Instruction Subset

| Type | Instructions |
|---|---|
| R-type | `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SLT` |
| I-type | `ADDI`, `LW` |
| S-type | `SW` |
| B-type | `BEQ`, `BNE` |

## Pipeline Hazard Handling

### Data hazards

The processor implements:

- EX/MEM → EX forwarding
- MEM/WB → EX forwarding
- WB → ID register-file bypass
- ALU → store-data forwarding
- Branch operand forwarding into the ID stage

### Load-use hazards

When a dependent instruction requires load data that is not yet available, the hazard detection unit holds the PC and IF/ID register and inserts a bubble into ID/EX. This introduces a one-cycle stall.

### Control hazards

Branches are resolved in the ID stage. A taken branch redirects the PC to the branch target and flushes the younger wrong-path instruction in IF, incurring a one-cycle taken-branch penalty.

Both `BEQ` and `BNE` are supported.

## Performance Characterization

The baseline processor includes counters for total cycles, instruction events, load-use stalls, branches, taken branches, and pipeline flushes.

### Recorded benchmark results

| Metric | Result |
|---|---:|
| Cycles | 123 |
| Instructions | 95 |
| CPI | 1.29 |
| Load-use stalls | 11 |
| Branches | 10 |
| Taken branches | 9 |
| Pipeline flushes | 9 |

These results are from the original processor benchmark and are not measurements of the JTAG/DFT extension.

## JTAG-Based Scan DFT

The DFT extension connects four scan-enabled pipeline registers to a JTAG-style Test Access Port (TAP).

### Scan-chain composition

| Pipeline register | Width |
|---|---:|
| IF/ID | 64 bits |
| ID/EX | 151 bits |
| EX/MEM | 105 bits |
| MEM/WB | 103 bits |
| **Total** | **423 bits** |

The serial scan path is:

`TDI → IF/ID → ID/EX → EX/MEM → MEM/WB → TDO`

The program counter is not included in the 423-bit scan-chain total.

### JTAG instructions

The current implementation uses these project-specific instruction encodings:

| Instruction | Encoding | Function |
|---|---|---|
| IDCODE | `0001` | Selects the 32-bit identification register |
| CPU_SCAN | `0010` | Selects the processor scan path |
| BYPASS | `1111` | Selects a one-bit bypass register |

The configured IDCODE value is `32'h12345678`.

### DFT components

The `dft/` directory contains:

- TAP controller and instruction register
- IDCODE and BYPASS registers
- Data-register selection logic
- CPU scan interface and integration wrapper
- Scan-enabled pipeline-register implementations
- JTAG and scan testbenches
- Targeted fault-injection testbench

## Verification

The baseline processor regression and the DFT/JTAG regression have been run successfully using Icarus Verilog in the OSS CAD Suite environment.

The recorded checks include:

- Directed processor tests covering arithmetic, forwarding, load-use hazards, branches, stalls, and flushing
- Baseline benchmark completion and performance-counter checks
- TAP state-machine transitions
- Instruction-register operation
- IDCODE shifting and update
- BYPASS register operation
- A 423-bit scan-pattern round trip
- CPU scan-wrapper operation
- End-to-end JTAG-to-CPU integration, including IDCODE, CPU_SCAN selection, and scan-pattern recovery
- Targeted fault-injection observability

### Fault-injection experiment

A controlled stuck-at-0 fault was injected on the scan-visible `MEM/WB.regWrite` state bit. The fault-free value was observed at TDO, and the injected fault altered the observed scan-out value as expected.

This demonstrates observability for that specific injected fault. It is not a measurement of overall processor fault coverage.

## Running the Tests

Requirements: Icarus Verilog with SystemVerilog support (`iverilog -g2012`) and `vvp`. Run the commands from Bash, such as the OSS CAD Suite terminal or WSL.

### Baseline processor regression

From the repository root:

```bash
bash scripts/run_baseline_test.sh
```

### DFT/JTAG regression

From the repository root:

```bash
bash scripts/run_dft_tests.sh
```

The regression scripts compile each testbench with an explicitly selected top module. Simulation executables and generated waveforms are placed in temporary build directories and removed when the scripts finish.

## Repository Layout

```text
riscv-processor/
├── README.md
├── rtl/
│   ├── capstone_cpu_pipe.v
│   ├── if_id.v
│   ├── id_ex.v
│   ├── ex_mem.v
│   ├── mem_wb.v
│   ├── hazard_unit.v
│   ├── forwarding_unit.v
│   ├── ControlUnit.v
│   ├── immgen.v
│   ├── rv32ialu.v
│   ├── aluaddsub.v
│   ├── alulogic.v
│   ├── alushift.v
│   ├── alucomp.v
│   ├── BankedMEM.v
│   ├── bank8.v
│   ├── regfile.v
│   ├── reg32.v
│   ├── decoder5to32.v
│   ├── PCInc.v
│   ├── perf_counter.v
│   └── tb_capstone_cpu_pipe.v
├── dft/
│   ├── capstone_cpu_pipe_jtag.sv
│   ├── jtag_cpu.sv
│   ├── jtag_tap.sv
│   ├── jtag_ir.sv
│   ├── jtag_idcode.sv
│   ├── jtag_bypass.sv
│   ├── jtag_dr_mux.sv
│   ├── jtag_cpu_scan.sv
│   ├── if_id_dft.sv
│   ├── id_ex_dft.sv
│   ├── ex_mem_dft.sv
│   ├── mem_wb_dft.sv
│   ├── tb_jtag_tap.sv
│   ├── tb_jtag_ir.sv
│   ├── tb_jtag_idcode.sv
│   ├── tb_jtag_bypass.sv
│   ├── tb_scan.sv
│   ├── tb_jtag_cpu_scan.sv
│   ├── tb_jtag_cpu.sv
│   └── tb_fault_injection.sv
└── scripts/
    ├── run_baseline_test.sh
    └── run_dft_tests.sh
```

## Design Focus

The project demonstrates practical RTL design, processor microarchitecture, and DFT concepts:

- Five-stage pipelining and datapath/control design
- Data forwarding and RAW hazard handling
- Load-use stall insertion
- Branch resolution and pipeline flushing
- Cycle-level performance characterization
- Scan-enabled pipeline state and JTAG data-register architecture
- Self-checking RTL simulation and fault-observability experiments

## Tools

- Verilog HDL and SystemVerilog
- Icarus Verilog and `vvp`
- GTKWave
- Git and GitHub

## Project Status

**Original processor:** Directed functional verification and baseline benchmark checks passed.

**JTAG/DFT extension:** The TAP, instruction/data registers, scan chain, integrated JTAG-to-CPU path, baseline regression, and targeted fault-injection experiment passed the recorded simulations. These results establish the tested functionality but do not establish full ISA compliance, complete IEEE 1149.1 compliance, or comprehensive fault coverage.