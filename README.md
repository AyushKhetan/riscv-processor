# Pipelined RISC-V Processor

A modular **32-bit RISC-V (RV32I subset) processor** implemented in Verilog HDL and developed from a single-cycle baseline into a **five-stage pipelined architecture**.

The processor implements data forwarding, load-use hazard detection, pipeline stalls, branch handling, control-hazard flushing, and cycle-level performance counters.

## Architecture

The processor uses the classic five-stage pipeline:

**IF → ID → EX → MEM → WB**

The design is organized into modular datapath, control, pipeline-register, hazard-handling, and memory components.

### Core Components

- Program Counter and PC increment logic
- Instruction memory
- Data memory
- Register file
- Immediate generator
- ALU
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
|------|--------------|
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

1. Holds the PC
2. Holds the IF/ID pipeline register
3. Inserts a bubble into the ID/EX pipeline register

This introduces a one-cycle stall for the dependent instruction.

### Control Hazards

Branches are resolved in the **ID stage**.

For a taken branch:

- The PC is redirected to the branch target.
- The younger wrong-path instruction in IF is flushed.
- A one-cycle taken-branch penalty is incurred.

Both `BEQ` and `BNE` are supported.

## Verification

The design was verified using directed simulation tests covering:

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
- Taken `BEQ`
- Not-taken `BEQ`
- Taken `BNE`
- Not-taken `BNE`
- Branch target execution
- Pipeline flushing
- Benchmark execution

All directed functional tests and benchmark checks passed.

## Performance Characterization

The processor includes hardware performance counters for:

- Total cycles
- Instruction events
- Load-use stalls
- Branch instructions
- Taken branches
- Pipeline flushes

Final benchmark results:

| Metric | Result |
|--------|-------:|
| Cycles | 123 |
| Instructions | 95 |
| CPI | 1.29 |
| Load-use stalls | 11 |
| Branches | 10 |
| Taken branches | 9 |
| Pipeline flushes | 9 |

The measured CPI includes the overhead introduced by pipeline stalls and taken-branch penalties.

## Simulation

The project was developed and simulated using **Icarus Verilog** with the OSS CAD Suite.

Compile the final pipeline and testbench with:

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
