`timescale 1ns/1ps

module tb_capstone_cpu;

    reg clk;
    reg reset;

    capstone_cpu dut (
        .clk(clk),
        .reset(reset)
    );

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Write a 32-bit instruction into instruction memory.
    // Memory is little-endian.
    // ------------------------------------------------------------
    task write_instruction;
        input [31:0] addr;
        input [31:0] instr;
        reg [9:0] index;
        begin
            index = addr[11:2];

            dut.IMEM.u_bank0.mem[index] = instr[7:0];
            dut.IMEM.u_bank1.mem[index] = instr[15:8];
            dut.IMEM.u_bank2.mem[index] = instr[23:16];
            dut.IMEM.u_bank3.mem[index] = instr[31:24];
        end
    endtask

    // ------------------------------------------------------------
    // Test program
    //
    // x1 = 5
    // x2 = 10
    // x3 = x1 + x2       = 15
    // x4 = x2 - x1       = 5
    // x5 = x1 & x2       = 0
    // x6 = x1 | x2       = 15
    // x7 = x1 ^ x2       = 15
    // x8 = x3 + 1        = 16
    //
    // Then:
    // mem[0] = x3
    // x9    = mem[0]     = 15
    // ------------------------------------------------------------

    initial begin

        // Reset
        reset = 1'b1;

        // Clear instruction memory
        // NOP = addi x0,x0,0
        write_instruction(32'd0,  32'h00000013);
        write_instruction(32'd4,  32'h00500093);  // addi x1,x0,5
        write_instruction(32'd8,  32'h00A00113);  // addi x2,x0,10
        write_instruction(32'd12, 32'h002081B3);  // add  x3,x1,x2
        write_instruction(32'd16, 32'h40110233);  // sub  x4,x2,x1
        write_instruction(32'd20, 32'h0020F2B3);  // and  x5,x1,x2
        write_instruction(32'd24, 32'h0020E333);  // or   x6,x1,x2
        write_instruction(32'd28, 32'h0020C3B3);  // xor  x7,x1,x2
        write_instruction(32'd32, 32'h00118413);  // addi x8,x3,1
        write_instruction(32'd36, 32'h00302023);  // sw   x3,0(x0)
        write_instruction(32'd40, 32'h00002483);  // lw   x9,0(x0)

        // Hold reset for one clock
        #12;
        reset = 1'b0;

        // Run enough cycles for the program
        #120;

        // --------------------------------------------------------
        // Checks
        // --------------------------------------------------------

        if (dut.rf.x[1] !== 32'd5)
            $display("ERROR: x1 = %0d, expected 5", dut.rf.x[1]);
        else
            $display("PASS: x1 = 5");

        if (dut.rf.x[2] !== 32'd10)
            $display("ERROR: x2 = %0d, expected 10", dut.rf.x[2]);
        else
            $display("PASS: x2 = 10");

        if (dut.rf.x[3] !== 32'd15)
            $display("ERROR: x3 = %0d, expected 15", dut.rf.x[3]);
        else
            $display("PASS: x3 = 15");

        if (dut.rf.x[4] !== 32'd5)
            $display("ERROR: x4 = %0d, expected 5", dut.rf.x[4]);
        else
            $display("PASS: x4 = 5");

        if (dut.rf.x[5] !== 32'd0)
            $display("ERROR: x5 = %0d, expected 0", dut.rf.x[5]);
        else
            $display("PASS: x5 = 0");

        if (dut.rf.x[6] !== 32'd15)
            $display("ERROR: x6 = %0d, expected 15", dut.rf.x[6]);
        else
            $display("PASS: x6 = 15");

        if (dut.rf.x[7] !== 32'd15)
            $display("ERROR: x7 = %0d, expected 15", dut.rf.x[7]);
        else
            $display("PASS: x7 = 15");

        if (dut.rf.x[8] !== 32'd16)
            $display("ERROR: x8 = %0d, expected 16", dut.rf.x[8]);
        else
            $display("PASS: x8 = 16");

        if (dut.rf.x[9] !== 32'd15)
            $display("ERROR: x9 = %0d, expected 15", dut.rf.x[9]);
        else
            $display("PASS: x9 = 15");

        $display("--------------------------------");
        $display("Baseline CPU test complete");
        $display("--------------------------------");

        $finish;
    end

endmodule