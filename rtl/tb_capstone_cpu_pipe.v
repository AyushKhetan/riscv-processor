`timescale 1ns/1ps

module tb_capstone_cpu_pipe_final;

    reg clk;
    reg reset;

    capstone_cpu_pipe dut (
        .clk(clk),
        .reset(reset)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // MEMORY INITIALIZATION TASKS
    // ============================================================

    task write_imem;
        input [9:0] index;
        input [31:0] data;
        begin
            dut.IMEM.u_bank0.mem[index] = data[7:0];
            dut.IMEM.u_bank1.mem[index] = data[15:8];
            dut.IMEM.u_bank2.mem[index] = data[23:16];
            dut.IMEM.u_bank3.mem[index] = data[31:24];
        end
    endtask

    task write_dmem;
        input [9:0] index;
        input [31:0] data;
        begin
            dut.DMEM.u_bank0.mem[index] = data[7:0];
            dut.DMEM.u_bank1.mem[index] = data[15:8];
            dut.DMEM.u_bank2.mem[index] = data[23:16];
            dut.DMEM.u_bank3.mem[index] = data[31:24];
        end
    endtask


    // ============================================================
    // INSTRUCTION ENCODERS
    // ============================================================

    // ADDI
    function [31:0] encode_addi;
        input [4:0] rd;
        input [4:0] rs1;
        input integer imm;
        begin
            encode_addi = {
                imm[11:0],
                rs1,
                3'b000,
                rd,
                7'b0010011
            };
        end
    endfunction


    // ADD
    function [31:0] encode_add;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            encode_add = {
                7'b0000000,
                rs2,
                rs1,
                3'b000,
                rd,
                7'b0110011
            };
        end
    endfunction


    // SUB
    function [31:0] encode_sub;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            encode_sub = {
                7'b0100000,
                rs2,
                rs1,
                3'b000,
                rd,
                7'b0110011
            };
        end
    endfunction


    // AND
    function [31:0] encode_and;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            encode_and = {
                7'b0000000,
                rs2,
                rs1,
                3'b111,
                rd,
                7'b0110011
            };
        end
    endfunction


    // OR
    function [31:0] encode_or;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            encode_or = {
                7'b0000000,
                rs2,
                rs1,
                3'b110,
                rd,
                7'b0110011
            };
        end
    endfunction


    // XOR
    function [31:0] encode_xor;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            encode_xor = {
                7'b0000000,
                rs2,
                rs1,
                3'b100,
                rd,
                7'b0110011
            };
        end
    endfunction


    // SLL
    function [31:0] encode_sll;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            encode_sll = {
                7'b0000000,
                rs2,
                rs1,
                3'b001,
                rd,
                7'b0110011
            };
        end
    endfunction


    // SRL
    function [31:0] encode_srl;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            encode_srl = {
                7'b0000000,
                rs2,
                rs1,
                3'b101,
                rd,
                7'b0110011
            };
        end
    endfunction


    // SLT
    function [31:0] encode_slt;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            encode_slt = {
                7'b0000000,
                rs2,
                rs1,
                3'b010,
                rd,
                7'b0110011
            };
        end
    endfunction


    // LW
    function [31:0] encode_lw;
        input [4:0] rd;
        input [4:0] rs1;
        input integer imm;
        begin
            encode_lw = {
                imm[11:0],
                rs1,
                3'b010,
                rd,
                7'b0000011
            };
        end
    endfunction


    // SW
    function [31:0] encode_sw;
        input [4:0] rs2;
        input [4:0] rs1;
        input integer imm;
        begin
            encode_sw = {
                imm[11:5],
                rs2,
                rs1,
                3'b010,
                imm[4:0],
                7'b0100011
            };
        end
    endfunction


    // BEQ
    function [31:0] encode_beq;
        input [4:0] rs1;
        input [4:0] rs2;
        input integer imm;
        begin
            encode_beq = {
                imm[12],
                imm[10:5],
                rs2,
                rs1,
                3'b000,
                imm[4:1],
                imm[11],
                7'b1100011
            };
        end
    endfunction


    // BNE
    function [31:0] encode_bne;
        input [4:0] rs1;
        input [4:0] rs2;
        input integer imm;
        begin
            encode_bne = {
                imm[12],
                imm[10:5],
                rs2,
                rs1,
                3'b001,
                imm[4:1],
                imm[11],
                7'b1100011
            };
        end
    endfunction


    // ============================================================
    // TEST PROGRAM
    // ============================================================

    initial begin

        $dumpfile("capstone_cpu_pipe_final.vcd");
        $dumpvars(0, tb_capstone_cpu_pipe_final);

        reset = 1'b1;


        // ========================================================
        // INITIAL DATA MEMORY
        // ========================================================

        // Address 4  -> bank index 1 -> 42
        // Address 8  -> bank index 2 -> initially 0
        // Address 12 -> bank index 3 -> 77

        write_dmem(10'd1, 32'd42);
        write_dmem(10'd2, 32'd0);
        write_dmem(10'd3, 32'd77);


        // ========================================================
        // BASIC ALU
        // ========================================================

        // x1 = 5
        write_imem(10'd0,
                   encode_addi(5'd1, 5'd0, 5));

        // x2 = 10
        write_imem(10'd1,
                   encode_addi(5'd2, 5'd0, 10));

        // x3 = 15
        write_imem(10'd2,
                   encode_add(5'd3, 5'd1, 5'd2));

        // x4 = 5
        write_imem(10'd3,
                   encode_sub(5'd4, 5'd3, 5'd2));

        // x5 = 5
        write_imem(10'd4,
                   encode_and(5'd5, 5'd3, 5'd4));

        // x6 = 15
        write_imem(10'd5,
                   encode_or(5'd6, 5'd3, 5'd4));

        // x7 = 10
        write_imem(10'd6,
                   encode_xor(5'd7, 5'd3, 5'd4));

        // x8 = 30
        write_imem(10'd7,
                   encode_sll(5'd8, 5'd1, 5'd2));

        // x9 = 2
        write_imem(10'd8,
                   encode_srl(5'd9, 5'd2, 5'd1));

        // x10 = 1
        write_imem(10'd9,
                   encode_slt(5'd10, 5'd1, 5'd2));


        // ========================================================
        // EX/MEM -> EX FORWARDING
        // ========================================================

        // x11 = 20
        write_imem(10'd10,
                   encode_addi(5'd11, 5'd0, 20));

        // x12 = x11 + 5 = 25
        write_imem(10'd11,
                   encode_addi(5'd12, 5'd11, 5));


        // ========================================================
        // DUAL FORWARDING
        // ========================================================

        // x13 = 30
        write_imem(10'd12,
                   encode_addi(5'd13, 5'd0, 30));

        // x14 = x12 + x13 = 55
        write_imem(10'd13,
                   encode_add(5'd14, 5'd12, 5'd13));


        // ========================================================
        // CHAINED RAW
        // ========================================================

        // x15 = x14 + x13 = 85
        write_imem(10'd14,
                   encode_add(5'd15, 5'd14, 5'd13));


        // ========================================================
        // LOAD
        // ========================================================

        // x16 = MEM[4] = 42
        write_imem(10'd15,
                   encode_lw(5'd16, 5'd0, 4));


        // ========================================================
        // LOAD-USE HAZARD
        // ========================================================

        // x17 = x16 + x1 = 47
        write_imem(10'd16,
                   encode_add(5'd17, 5'd16, 5'd1));


        // ========================================================
        // ALU -> SW STORE DATA FORWARDING
        // ========================================================

        // x18 = 99
        write_imem(10'd17,
                   encode_addi(5'd18, 5'd0, 99));

        // MEM[8] = x18
        write_imem(10'd18,
                   encode_sw(5'd18, 5'd0, 8));


        // ========================================================
        // ALU -> BRANCH
        // ========================================================

        // x19 = 50
        write_imem(10'd19,
                   encode_addi(5'd19, 5'd0, 50));

        // x19 != x1, so BEQ is NOT taken
        write_imem(10'd20,
                   encode_beq(5'd19, 5'd1, 8));

        // Must execute
        // x20 = 1
        write_imem(10'd21,
                   encode_addi(5'd20, 5'd0, 1));


        // ========================================================
        // MEM(ALU) -> ID BRANCH FORWARDING
        // ========================================================

        // x21 = 7
        write_imem(10'd22,
                   encode_addi(5'd21, 5'd0, 7));

        // Separation instruction
        // x22 = 1
        write_imem(10'd23,
                   encode_addi(5'd22, 5'd0, 1));

        // x21 == x21 -> taken
        // Target = instruction 26
        write_imem(10'd24,
                   encode_beq(5'd21, 5'd21, 8));

        // MUST be flushed
        write_imem(10'd25,
                   encode_addi(5'd23, 5'd0, 99));

        // Branch target
        // x24 = 24
        write_imem(10'd26,
                   encode_addi(5'd24, 5'd0, 24));


        // ========================================================
        // WB -> ID BRANCH FORWARDING
        // ========================================================

        // x25 = 12
        write_imem(10'd27,
                   encode_addi(5'd25, 5'd0, 12));

        // x26 = 1
        write_imem(10'd28,
                   encode_addi(5'd26, 5'd0, 1));

        // x27 = 1
        write_imem(10'd29,
                   encode_addi(5'd27, 5'd0, 1));

        // x25 == x25 -> taken
        // Target = instruction 32
        write_imem(10'd30,
                   encode_beq(5'd25, 5'd25, 8));

        // MUST be flushed
        write_imem(10'd31,
                   encode_addi(5'd28, 5'd0, 99));

        // Target
        // x29 = 29
        write_imem(10'd32,
                   encode_addi(5'd29, 5'd0, 29));


        // ========================================================
        // LW -> BRANCH
        //
        // This exercises:
        //
        //   LW -> load-use stall
        //   MEM(load) -> ID forwarding
        //   taken branch
        //   IF/ID flush
        // ========================================================

        // x30 = MEM[12] = 77
        write_imem(10'd33,
                   encode_lw(5'd30, 5'd0, 12));

        // Requires one load-use stall
        // x30 == x30 -> taken
        // Target = instruction 36
        write_imem(10'd34,
                   encode_beq(5'd30, 5'd30, 8));

        // MUST be flushed
        write_imem(10'd35,
                   encode_addi(5'd31, 5'd0, 99));

        // Target
        // x2 = 123
        write_imem(10'd36,
                   encode_addi(5'd2, 5'd0, 123));


        // ========================================================
        // BNE TAKEN
        // ========================================================

        // x3 = 1
        write_imem(10'd37,
                   encode_addi(5'd3, 5'd0, 1));

        // x4 = 2
        write_imem(10'd38,
                   encode_addi(5'd4, 5'd0, 2));

        // x3 != x4 -> taken
        // Target = instruction 41
        write_imem(10'd39,
                   encode_bne(5'd3, 5'd4, 8));

        // MUST be flushed
        // NOTE: x5 is already 5 from the earlier ALU test.
        write_imem(10'd40,
                   encode_addi(5'd5, 5'd0, 99));

        // Target
        // x6 = 66
        write_imem(10'd41,
                   encode_addi(5'd6, 5'd0, 66));


        // ========================================================
        // BNE NOT TAKEN
        // ========================================================

        // x7 remains 10
        write_imem(10'd42,
                   encode_addi(5'd7, 5'd7, 0));

        // x7 == x7 -> BNE NOT taken
        write_imem(10'd43,
                   encode_bne(5'd7, 5'd7, 8));

        // Must execute
        // x8 = 88
        write_imem(10'd44,
                   encode_addi(5'd8, 5'd0, 88));


        // ========================================================
        // NOP SPACE
        // ========================================================

        write_imem(10'd45, 32'b0);
        write_imem(10'd46, 32'b0);
        write_imem(10'd47, 32'b0);
        write_imem(10'd48, 32'b0);


        // ========================================================
        // RELEASE RESET
        // ========================================================

        #12;
        reset = 1'b0;


        // Allow complete program to execute
        #800;


        // ========================================================
        // RESULTS
        // ========================================================

        $display("");
        $display("==============================================");
        $display(" FINAL RISC-V PIPELINE VERIFICATION");
        $display("==============================================");


        // ========================================================
        // BASIC ALU
        // ========================================================

        if (dut.rf.x[1] !== 32'd5)
            $display("FAIL: ADDI x1 = %0d, expected 5",
                     dut.rf.x[1]);
        else
            $display("PASS: ADDI");

        if (dut.rf.x[3] !== 32'd1)
            $display("FAIL: basic ALU state x3 = %0d",
                     dut.rf.x[3]);
        else
            $display("PASS: basic ALU state");


        // ========================================================
        // FORWARDING
        // ========================================================

        if (dut.rf.x[12] !== 32'd25)
            $display("FAIL: EX/MEM -> EX forwarding: x12 = %0d, expected 25",
                     dut.rf.x[12]);
        else
            $display("PASS: EX/MEM -> EX forwarding");

        if (dut.rf.x[14] !== 32'd55)
            $display("FAIL: dual forwarding: x14 = %0d, expected 55",
                     dut.rf.x[14]);
        else
            $display("PASS: dual forwarding");

        if (dut.rf.x[15] !== 32'd85)
            $display("FAIL: chained RAW: x15 = %0d, expected 85",
                     dut.rf.x[15]);
        else
            $display("PASS: chained RAW forwarding");


        // ========================================================
        // LOAD
        // ========================================================

        if (dut.rf.x[16] !== 32'd42)
            $display("FAIL: LW x16 = %0d, expected 42",
                     dut.rf.x[16]);
        else
            $display("PASS: LW");


        // ========================================================
        // LOAD-USE
        // ========================================================

        if (dut.rf.x[17] !== 32'd47)
            $display("FAIL: load-use x17 = %0d, expected 47",
                     dut.rf.x[17]);
        else
            $display("PASS: load-use stall + forwarding");


        // ========================================================
        // STORE DATA FORWARDING
        // ========================================================

        if (dut.DMEM.u_bank0.mem[10'd2] !== 8'd99)
            $display("FAIL: MEM[8] low byte = %0d, expected 99",
                     dut.DMEM.u_bank0.mem[10'd2]);
        else
            $display("PASS: ALU -> SW store-data forwarding");


        // ========================================================
        // ALU -> BRANCH
        // ========================================================

        if (dut.rf.x[20] !== 32'd1)
            $display("FAIL: ALU -> branch / BEQ not-taken");
        else
            $display("PASS: ALU -> ID branch");


        // ========================================================
        // TAKEN BEQ + FLUSH
        // ========================================================

        if (dut.rf.x[23] !== 32'd0)
            $display("FAIL: BEQ flush: x23 = %0d, expected 0",
                     dut.rf.x[23]);
        else
            $display("PASS: taken BEQ flush");

        if (dut.rf.x[24] !== 32'd24)
            $display("FAIL: BEQ target: x24 = %0d, expected 24",
                     dut.rf.x[24]);
        else
            $display("PASS: BEQ target");


        // ========================================================
        // WB -> ID BRANCH
        // ========================================================

        if (dut.rf.x[28] !== 32'd0)
            $display("FAIL: WB -> ID branch flush: x28 = %0d, expected 0",
                     dut.rf.x[28]);
        else
            $display("PASS: WB -> ID branch forwarding");

        if (dut.rf.x[29] !== 32'd29)
            $display("FAIL: WB branch target: x29 = %0d, expected 29",
                     dut.rf.x[29]);
        else
            $display("PASS: WB -> branch + target");


        // ========================================================
        // LW -> ID BRANCH
        // ========================================================

        if (dut.rf.x[31] !== 32'd0)
            $display("FAIL: LW -> branch flush: x31 = %0d, expected 0",
                     dut.rf.x[31]);
        else
            $display("PASS: LW -> branch: stall + MEM -> ID forwarding");

        if (dut.rf.x[2] !== 32'd123)
            $display("FAIL: LW branch target: x2 = %0d, expected 123",
                     dut.rf.x[2]);
        else
            $display("PASS: LW -> branch target");


        // ========================================================
        // BNE TAKEN
        // ========================================================

        // x5 was originally 5.
        // The wrong-path instruction attempts to change it to 99.
        if (dut.rf.x[5] !== 32'd5)
            $display("FAIL: BNE taken flush: x5 = %0d, expected 5",
                     dut.rf.x[5]);
        else
            $display("PASS: BNE taken + flush");

        if (dut.rf.x[6] !== 32'd66)
            $display("FAIL: BNE target: x6 = %0d, expected 66",
                     dut.rf.x[6]);
        else
            $display("PASS: BNE taken target");


        // ========================================================
        // BNE NOT TAKEN
        // ========================================================

        if (dut.rf.x[8] !== 32'd88)
            $display("FAIL: BNE not-taken: x8 = %0d, expected 88",
                     dut.rf.x[8]);
        else
            $display("PASS: BNE not taken");


        // ========================================================
        // PHASE 2: PERFORMANCE BENCHMARK
        // ========================================================

        // Reset CPU and performance counters. Instruction/data memory
        // contents are retained across reset.
        reset = 1'b1;
        repeat (2) @(posedge clk);

        // --------------------------------------------------------
        // Deterministic benchmark
        // --------------------------------------------------------
        // x10 = loop counter (10 iterations)
        // x11 = accumulator; each iteration adds 42 + 1 = 43
        // The loop contains a load-use hazard and a taken BNE.
        // --------------------------------------------------------

        write_imem(10'd0,  encode_addi(5'd10, 5'd0, 10));
        write_imem(10'd1,  encode_addi(5'd11, 5'd0, 0));
        write_imem(10'd2,  encode_addi(5'd12, 5'd0, 1));
        write_imem(10'd3,  encode_addi(5'd13, 5'd0, 42));
        write_imem(10'd4,  encode_sw  (5'd13, 5'd0, 16));

        // Loop: 5 -> 11. BNE at 11 jumps back 24 bytes to 5.
        write_imem(10'd5,  encode_lw  (5'd14, 5'd0, 16));
        write_imem(10'd6,  encode_add (5'd11, 5'd11, 5'd14));
        write_imem(10'd7,  encode_add (5'd11, 5'd11, 5'd12));
        write_imem(10'd8,  encode_xor (5'd15, 5'd11, 5'd13));
        write_imem(10'd9,  encode_sll (5'd16, 5'd12, 5'd12));
        write_imem(10'd10, encode_sub (5'd10, 5'd10, 5'd12));
        write_imem(10'd11, encode_bne (5'd10, 5'd0, -24));

        // Post-loop ALU/memory workload.
        write_imem(10'd12, encode_addi(5'd20, 5'd0, 100));
        write_imem(10'd13, encode_add (5'd21, 5'd11, 5'd20));
        write_imem(10'd14, encode_sub (5'd22, 5'd21, 5'd20));
        write_imem(10'd15, encode_and (5'd23, 5'd22, 5'd11));
        write_imem(10'd16, encode_or  (5'd24, 5'd23, 5'd21));
        write_imem(10'd17, encode_xor (5'd25, 5'd24, 5'd22));
        write_imem(10'd18, encode_sll (5'd26, 5'd12, 5'd12));
        write_imem(10'd19, encode_srl (5'd27, 5'd26, 5'd12));
        write_imem(10'd20, encode_slt (5'd28, 5'd22, 5'd21));
        write_imem(10'd21, encode_sw  (5'd21, 5'd0, 20));
        write_imem(10'd22, encode_lw  (5'd29, 5'd0, 20));
        write_imem(10'd23, encode_add (5'd30, 5'd29, 5'd12));
        write_imem(10'd24, encode_addi(5'd18, 5'd30, 7));
        write_imem(10'd25, encode_sub (5'd19, 5'd18, 5'd12));
        write_imem(10'd26, encode_and (5'd20, 5'd19, 5'd18));
        write_imem(10'd27, encode_or  (5'd21, 5'd20, 5'd19));
        write_imem(10'd28, encode_xor (5'd22, 5'd21, 5'd20));
        write_imem(10'd29, encode_slt (5'd23, 5'd20, 5'd21));
        write_imem(10'd30, encode_add (5'd24, 5'd23, 5'd22));
        write_imem(10'd31, encode_addi(5'd31, 5'd0, 777));

        write_imem(10'd32, 32'b0);
        write_imem(10'd33, 32'b0);
        write_imem(10'd34, 32'b0);

        // Clear stale instructions from Phase 1.
        write_imem(10'd35, 32'b0);
        write_imem(10'd36, 32'b0);
        write_imem(10'd37, 32'b0);
        write_imem(10'd38, 32'b0);
        write_imem(10'd39, 32'b0);
        write_imem(10'd40, 32'b0);
        write_imem(10'd41, 32'b0);
        write_imem(10'd42, 32'b0);
        write_imem(10'd43, 32'b0);
        write_imem(10'd44, 32'b0);
        write_imem(10'd45, 32'b0);
        write_imem(10'd46, 32'b0);
        write_imem(10'd47, 32'b0);
        write_imem(10'd48, 32'b0);

        // Run until the completion marker is written, or stop after
        // 300 cycles if the processor fails to make progress.
        reset = 1'b0;
        fork
            begin
                wait (dut.rf.x[31] === 32'd777);
            end
            begin
                repeat (300) @(posedge clk);
                $display("");
                $display("FAIL: benchmark watchdog timeout");
                $finish;
            end
        join_any
        disable fork;

        // Drain the remaining pipeline stages.
        repeat (5) @(posedge clk);

        // --------------------------------------------------------
        // Benchmark functional checks
        // --------------------------------------------------------
        if (dut.rf.x[10] !== 32'd0)
            $display("FAIL: benchmark x10 = %0d, expected 0", dut.rf.x[10]);
        else
            $display("PASS: benchmark loop completion (x10 = 0)");

        if (dut.rf.x[11] !== 32'd430)
            $display("FAIL: benchmark x11 = %0d, expected 430", dut.rf.x[11]);
        else
            $display("PASS: benchmark accumulator (x11 = 430)");

        if (dut.rf.x[31] !== 32'd777)
            $display("FAIL: benchmark completion marker x31 = %0d", dut.rf.x[31]);
        else
            $display("PASS: benchmark completion marker");

        // --------------------------------------------------------
        // Performance counters
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display(" PERFORMANCE COUNTERS");
        $display("==============================================");
        $display("Cycles          : %0d", dut.cycle_count);
        $display("Instructions    : %0d", dut.instr_count);
        $display("Stalls          : %0d", dut.stall_count);
        $display("Branches        : %0d", dut.branch_count);
        $display("Taken branches  : %0d", dut.branch_taken_count);
        $display("Flushes         : %0d", dut.flush_count);

        if (dut.stall_count !== 32'd11)
            $display("FAIL: stall count = %0d, expected 11", dut.stall_count);
        else
            $display("PASS: load-use hazard accounting");

        if (dut.branch_count !== 32'd10)
            $display("FAIL: branch count = %0d, expected 10", dut.branch_count);
        else
            $display("PASS: branch accounting");

        if (dut.branch_taken_count !== 32'd9)
            $display("FAIL: taken branch count = %0d, expected 9", dut.branch_taken_count);
        else
            $display("PASS: taken-branch accounting");

        if (dut.flush_count !== 32'd9)
            $display("FAIL: flush count = %0d, expected 9", dut.flush_count);
        else
            $display("PASS: control-hazard accounting");

        if (dut.instr_count != 0)
            $display("CPI x100        : %0d", (dut.cycle_count * 100) / dut.instr_count);
        else
            $display("CPI x100        : N/A");

        if (dut.instr_count != 0)
            $display("Stall rate x100 : %0d", (dut.stall_count * 100) / dut.instr_count);
        else
            $display("Stall rate x100 : N/A");

        $display("==============================================");
        $display(" FINAL PIPELINE TEST COMPLETED");
        $display("==============================================");

        $finish;

    end


endmodule