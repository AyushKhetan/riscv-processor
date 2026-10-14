`timescale 1ns/1ps

module tb_scan;

    logic        clk;
    logic        reset;

    logic        scan_en;
    logic        scan_in;
    logic        scan_out;

    // Memory interface
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic        dmem_read;
    logic        dmem_write;
    logic [31:0] dmem_rdata;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    capstone_cpu_pipe_jtag dut (
        .clk        (clk),
        .reset      (reset),

        .scan_en    (scan_en),
        .scan_in    (scan_in),
        .scan_out   (scan_out),

        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),

        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_read  (dmem_read),
        .dmem_write (dmem_write),
        .dmem_rdata (dmem_rdata)
    );

    // ------------------------------------------------------------
    // Clock: 10 ns period
    // ------------------------------------------------------------

    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // 423-bit scan patterns
    // ------------------------------------------------------------

    logic [422:0] test_pattern;
    logic [422:0] shifted_out;

    integer i;

    initial begin

        clk        = 1'b0;
        reset      = 1'b1;
        scan_en    = 1'b0;
        scan_in    = 1'b0;

        // Memory inputs
        imem_rdata = 32'b0;
        dmem_rdata = 32'b0;

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat (2) @(posedge clk);
        #1;

        reset = 1'b0;

        // --------------------------------------------------------
        // Construct recognizable scan pattern
        //
        // The vector is arranged according to the COMPLETE chain:
        //
        // IF/ID  : instr[31:0], pc[31:0]
        // ID/EX  : r1, r2, rs1, rs2, rd, pc, imm,
        //           WBSel, regWrite, ALUSrc, MemWrite,
        //           MemRead, ALUOp
        // EX/MEM : rd, pc, aluY, storeData,
        //           WBSel, MemWrite, MemRead, regWrite
        // MEM/WB : rd, pc, aluY, memReadData,
        //           WBSel, regWrite
        //
        // --------------------------------------------------------

        test_pattern = '0;

        // We'll initially use an alternating pattern.
        for (i = 0; i < 423; i = i + 1)
            test_pattern[i] = i % 2;

        // --------------------------------------------------------
        // SHIFT IN
        // --------------------------------------------------------

        scan_en = 1'b1;

        for (i = 0; i < 423; i = i + 1) begin
            scan_in = test_pattern[i];
            @(posedge clk);
        end

        #1;

        // --------------------------------------------------------
        // Display internal state after SHIFT IN
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("        AFTER 423-BIT SHIFT IN");
        $display("==============================================");

        $display("IF/ID:");
        $display("  instr = %h", dut.s1.instr);
        $display("  pc    = %h", dut.s1.pc);

        $display("");
        $display("ID/EX:");
        $display("  r1       = %h", dut.s2.r1);
        $display("  r2       = %h", dut.s2.r2);
        $display("  rs1      = %h", dut.s2.rs1);
        $display("  rs2      = %h", dut.s2.rs2);
        $display("  rd       = %h", dut.s2.rd);
        $display("  pc       = %h", dut.s2.pc);
        $display("  imm      = %h", dut.s2.imm);
        $display("  WBSel    = %b", dut.s2.WBSel);
        $display("  regWrite = %b", dut.s2.regWrite);
        $display("  ALUSrc   = %b", dut.s2.ALUSrc);
        $display("  MemWrite = %b", dut.s2.MemWrite);
        $display("  MemRead  = %b", dut.s2.MemRead);
        $display("  ALUOp    = %b", dut.s2.ALUOp);

        $display("");
        $display("EX/MEM:");
        $display("  rd          = %h", dut.s3.rd);
        $display("  pc          = %h", dut.s3.pc);
        $display("  aluY        = %h", dut.s3.aluY);
        $display("  storeData   = %h", dut.s3.storeData);
        $display("  WBSel       = %b", dut.s3.WBSel);
        $display("  MemWrite    = %b", dut.s3.MemWrite);
        $display("  MemRead     = %b", dut.s3.MemRead);
        $display("  regWrite    = %b", dut.s3.regWrite);

        $display("");
        $display("MEM/WB:");
        $display("  rd          = %h", dut.s4.rd);
        $display("  pc          = %h", dut.s4.pc);
        $display("  aluY        = %h", dut.s4.aluY);
        $display("  memReadData = %h", dut.s4.memReadData);
        $display("  WBSel       = %b", dut.s4.WBSel);
        $display("  regWrite    = %b", dut.s4.regWrite);

        // --------------------------------------------------------
        // SHIFT OUT
        // --------------------------------------------------------

        shifted_out = '0;

        for (i = 0; i < 423; i = i + 1) begin
            scan_in = 1'b0;

            @(posedge clk);

            // scan_out represents the bit currently at the end
            // of the chain, BEFORE this shift clock.
            shifted_out[i] = scan_out;

            
        end

        scan_en = 1'b0;

        // --------------------------------------------------------
        // Compare shifted-out sequence
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("             SHIFT-OUT CHECK");
        $display("==============================================");

        if (shifted_out === test_pattern)
            $display("PASS: 423-bit scan pattern shifted out correctly.");
        else
            $display("FAIL: Shifted-out pattern does not match.");

        $display("==============================================");
        $display("");

        #20;
        $finish;
    end

endmodule