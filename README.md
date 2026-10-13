# Pipelined RISC-V Processor with JTAG-Based Design-for-Testability

A modular **32-bit RISC-V-subset processor** implemented in Verilog, evolving from a single-cycle baseline to a five-stage pipeline with forwarding, hazard detection, pipeline stalls, branch flushing, and performance counters.

The project extends the processor with a **scan-based design-for-testability (DFT) architecture** using scan-enabled pipeline registers and a JTAG test-access interface. The DFT implementation includes a TAP controller, instruction register, IDCODE and BYPASS data registers, and a serial scan path intended to expose internal pipeline state for testing.

The repository contains the original processor implementation alongside the DFT extension, with dedicated RTL modules and testbenches for processor functionality, scan operations, and JTAG components.

## Table of Contents

- [Architecture](#architecture)
- [Supported Instruction Subset](#supported-instruction-subset)
- [Pipeline Hazard Handling](#pipeline-hazard-handling)
- [Verification](#verification)
- [Performance Characterization](#performance-characterization)
- [JTAG-Based Design-for-Testability](#jtag-based-design-for-testability)
- [Simulation](#simulation)
- [Repository Structure](#repository-structure)
- [Design Focus](#design-focus)
- [Tools](#tools)
- [Project Status](#project-status)

## Architecture

The processor uses the classic five-stage pipeline:

**IF → ID → EX → MEM → WB**

The design is organized into modular datapath, control, pipeline-register, hazard-handling, and memory components.

### Core Components

- Program counter and PC increment logic
- Instruction memory
- Data memory
- Register file
- Immediate generator
- Arithmetic logic unit (ALU)
- Main control unit
- IF/ID pipeline register
- ID/EX pipeline register
- EX/MEM pipeline register
- MEM/WB pipeline register
- Forwarding unit
- Load-use hazard detection unit
- Branch control and pipeline flushing
- Performance counters

## Supported Instruction Subset

| Type | Instructions |
|---|---|
| R-type | `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SLT` |
| I-type | `ADDI`, `LW` |
| S-type | `SW` |
| B-type | `BEQ`, `BNE` |

This project implements a **subset of RV32I** and does not claim full RISC-V ISA compliance.

## Pipeline Hazard Handling

### Data Hazards

The processor implements several forwarding paths to reduce unnecessary pipeline stalls:

- **EX/MEM → EX forwarding**
- **MEM/WB → EX forwarding**
- **WB → ID register-file bypass**
- **ALU → store-data forwarding**
- **Forwarding of branch operands into the ID stage**

These mechanisms allow dependent instructions to execute without waiting for the producing instruction to reach the write-back stage whenever the required value is already available.

### Load-Use Hazards

A load-use dependency cannot be resolved through normal EX-stage forwarding because the loaded data becomes available only after the memory stage.

The hazard detection unit therefore:

1. Holds the PC.
2. Holds the IF/ID pipeline register.
3. Inserts a bubble into the ID/EX pipeline register.

This introduces a one-cycle stall for the dependent instruction.

### Control Hazards

Branches are resolved in the **ID stage**.

For a taken branch:

- The PC is redirected to the branch target.
- The younger wrong-path instruction in IF is flushed.
- A one-cycle taken-branch penalty is incurred.

Both `BEQ` and `BNE` are supported.

## Verification

The original processor was verified using directed simulation tests covering:

- Basic arithmetic and ALU operations
- EX/MEM forwarding
- Dual-source forwarding
- Chained RAW dependencies
- Load instructions
- Load-use hazards and stalls
- ALU-to-store forwarding
- ALU-to-branch forwarding
- WB-to-branch forwarding
- Load-to-branch hazard handling
- Taken and not-taken `BEQ`
- Taken and not-taken `BNE`
- Branch target execution
- Pipeline flushing
- Benchmark execution

The recorded baseline results indicate that the directed functional tests and benchmark checks passed.

## Performance Characterization

The processor includes hardware performance counters for:

- Total cycles
- Instruction events
- Load-use stalls
- Branch instructions
- Taken branches
- Pipeline flushes

### Recorded Benchmark Results

| Metric | Result |
|---|---:|
| Cycles | 123 |
| Instructions | 95 |
| CPI | 1.29 |
| Load-use stalls | 11 |
| Branches | 10 |
| Taken branches | 9 |
| Pipeline flushes | 9 |

The measured CPI includes the overhead introduced by pipeline stalls and taken-branch penalties.

These results refer to the original processor benchmark and should not be interpreted as measurements of the JTAG/DFT extension.

## JTAG-Based Design-for-Testability

The DFT extension adds serial access to internal pipeline state through scan-enabled pipeline registers and a JTAG-style test-access interface.

### Scan Architecture

The scan path spans four pipeline registers:

| Pipeline register | Scan width |
|---|---:|
| IF/ID | 64 bits |
| ID/EX | 151 bits |
| EX/MEM | 105 bits |
| MEM/WB | 103 bits |
| **Total** | **423 bits** |

The four registers form a **423-bit serial scan chain** intended to support shifting internal pipeline state into and out of the processor for test and observability experiments.

The program counter is not included in this scan-chain total.

### JTAG Components

The DFT implementation includes:

- **TAP controller:** A 16-state finite-state machine for JTAG state transitions.
- **Instruction register (IR):** Selects the active data register.
- **IDCODE register:** Provides the configured 32-bit identification value `0x12345678`.
- **BYPASS register:** Provides a one-bit serial bypass path.
- **Data-register multiplexer:** Selects the data path associated with the active instruction.
- **CPU scan interface:** Connects the selected JTAG data path to the processor scan chain.
- **Scan-enabled pipeline registers:** Provide serial access to the four pipeline-register stages.

### JTAG Instruction Encodings

| Instruction | Encoding | Purpose |
|---|---|---|
| IDCODE | `0001` | Selects the identification register |
| CPU_SCAN | `0010` | Selects the processor scan path |
| BYPASS | `1111` | Selects the one-bit bypass register |

These are the encodings used by the current implementation; this project does not claim full IEEE 1149.1 compliance.

### DFT Verification Plan

The repository includes dedicated testbenches for the TAP controller, instruction register, IDCODE register, BYPASS register, standalone scan chain, and JTAG-to-CPU integration.

The following checks are important for completing validation of the integrated design:

1. Compile the complete DFT source set without errors.
2. Verify TAP state transitions and instruction selection.
3. Verify IDCODE and BYPASS data-register operation.
4. Perform an end-to-end 423-bit CPU scan-in/scan-out round trip using a nontrivial test pattern.
5. Confirm that scan operation does not unintentionally modify processor state or cause memory writes.
6. Re-run the baseline processor regression to ensure the extension has not broken normal operation.
7. Implement controlled fault injection and document detection results before making fault-coverage claims.

The existence of a testbench does not by itself establish that the corresponding test passes. End-to-end CPU scan verification and fault-injection evaluation remain explicit validation priorities until confirmed by reproducible simulation results.

## Simulation

The project uses **Icarus Verilog** for RTL simulation and **GTKWave** for waveform inspection.

### Baseline Processor

Compile the original five-stage processor and its testbench from the repository root:

```bash
iverilog -g2012 -o final_eval \
capstone_cpu_pipe.v \
if_id.v id_ex.v ex_mem.v mem_wb.v \
hazard_unit.v forwarding_unit.v \
ControlUnit.v ImmGen.v rv32ialu.v \
aluaddsub.v alulogic.v alushift.v alucomp.v \
BankedMEM.v bank8.v regfile.v reg32.v \
decoder5to32.v PCInc.v perf_counter.v \
tb_capstone_cpu_pipe.v
```

Run the simulation:

```bash
vvp final_eval
```

Use the actual source locations if the files reside in a subdirectory such as `rtl/`.

### DFT and JTAG Tests

The DFT extension has separate RTL modules and testbenches. Compile each testbench with its required dependencies and run it with `vvp`.

The exact source lists and commands should be documented alongside the testbenches once the current integration source has been repaired and the commands have been validated.

A VCD waveform can be generated by the testbench and inspected using GTKWave.

## Repository Structure

The repository contains the original processor RTL and a separate DFT extension. The following is the intended organization; file paths should be adjusted to match the checked-in layout.

```text
riscv-processor/
├── README.md
├── rtl/
│   ├── capstone_cpu.v
│   ├── capstone_cpu_pipe.v
│   ├── if_id.v
│   ├── id_ex.v
│   ├── ex_mem.v
│   ├── mem_wb.v
│   ├── forwarding_unit.v
│   ├── hazard_unit.v
│   ├── perf_counter.v
│   ├── ControlUnit.v
│   ├── ImmGen.v
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
│   └── tb_capstone_cpu_pipe.v
└── dft/
    ├── rtl/
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
    │   └── mem_wb_dft.sv
    └── tb/
        ├── tb_jtag_tap.sv
        ├── tb_jtag_ir.sv
        ├── tb_jtag_idcode.sv
        ├── tb_jtag_bypass.sv
        ├── tb_scan_chain.sv
        └── tb_jtag_cpu.sv
```

## Design Focus

The project focuses on practical RTL design, processor microarchitecture, and design-for-testability:

- Datapath and control design
- Five-stage pipelining
- Pipeline registers
- Data forwarding
- RAW hazard handling
- Load-use hazard detection
- Pipeline stalls
- Control hazards and branch resolution
- Pipeline flushing
- Cycle-level performance characterization
- Scan-enabled pipeline state
- JTAG TAP and data-register architecture
- RTL simulation and self-checking testbenches
- Internal-state observability and DFT validation

## Tools

- Verilog HDL
- SystemVerilog
- Icarus Verilog
- GTKWave
- Git and GitHub

## Project Status

### Original Processor

**Completed:** A functional five-stage RV32I-subset processor with forwarding, load-use hazard handling, branch flushing, directed verification, and performance counters.

### JTAG/DFT Extension

**Under integration and validation:** The scan-enabled pipeline registers, JTAG components, and testbenches have been developed. End-to-end CPU scan operation, regression testing of the integrated design, and fault-injection evaluation must be confirmed before the complete DFT extension can be considered verified.

The intended outcome is an integrated processor with JTAG-selected scan access to internal pipeline state, supported by reproducible simulation tests and documented DFT evaluation results.
