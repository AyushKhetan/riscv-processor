`timescale 1ns/1ps

// Demonstrates scan observability of one controlled stuck-at fault.
// The normal 423-bit pattern is shifted into the DFT-enabled processor.
// In the chosen pattern, test_pattern[0] = 1 and after the complete scan-in
// this bit is expected at the head of the serial scan chain (MEM/WB.regWrite).
// A simulator force models a stuck-at-0 fault on that scan-visible state bit.
// This is a single-fault observability demonstration, not a fault-coverage test.

module tb_fault_injection;

    logic clk;
    logic reset;
    logic scan_en;
    logic scan_in;
    logic scan_hold;
    logic scan_out;

    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic        dmem_read;
    logic        dmem_write;
    logic [31:0] dmem_rdata;

    logic [422:0] test_pattern;
    integer i;

    capstone_cpu_pipe_jtag dut (
        .clk        (clk),
        .reset      (reset),
        .scan_en    (scan_en),
        .scan_in    (scan_in),
        .scan_hold  (scan_hold),
        .scan_out   (scan_out),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_read  (dmem_read),
        .dmem_write (dmem_write),
        .dmem_rdata (dmem_rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk        = 1'b0;
        reset      = 1'b1;
        scan_en    = 1'b0;
        scan_in    = 1'b0;
        scan_hold  = 1'b1;
        imem_rdata = 32'b0;
        dmem_rdata = 32'b0;
        test_pattern = '0;

        // Hold the processor in reset, then release reset before scanning.
        repeat (3) @(posedge clk);
        #1 reset = 1'b0;

        // Use the same non-symmetric pattern as the integration test.
        for (i = 0; i < 423; i = i + 1)
            test_pattern[i] = (((i * 37 + 11) % 101) < 50);

        if (test_pattern[0] !== 1'b1) begin
            $display("FAIL: chosen pattern does not set test_pattern[0] to 1.");
            $fatal(1);
        end

        // Load all 423 bits through the CPU scan path.
        scan_en = 1'b1;
        for (i = 0; i < 423; i = i + 1) begin
            @(negedge clk);
            scan_in = test_pattern[i];
            @(posedge clk);
            #1;
        end

        // Stop shifting and keep functional pipeline state held stable.
        scan_en = 1'b0;
        scan_in = 1'b0;
        #1;

        // Confirm the fault-free expected bit is observable at scan-out.
        if (scan_out !== test_pattern[0]) begin
            $display("FAIL: baseline scan bit mismatch before fault injection.");
            $display("      Expected scan_out=%b, got=%b", test_pattern[0], scan_out);
            $fatal(1);
        end
        $display("PASS: fault-free scan bit observed at TDO (expected=%b).", test_pattern[0]);

        // Inject one controlled stuck-at-0 fault on a scan-visible state bit.
        // MEM/WB's scan vector is {regWrite, WBSel, ..., rd}; regWrite is its MSB.
        force dut.s4.regWrite = 1'b0;
        #1;

        if (scan_out !== test_pattern[0]) begin
            $display("PASS: stuck-at-0 fault on MEM/WB.regWrite detected at scan-out.");
            $display("      Expected=%b, faulty scan_out=%b", test_pattern[0], scan_out);
        end else begin
            $display("FAIL: injected stuck-at-0 fault was not observed at scan-out.");
            release dut.s4.regWrite;
            $fatal(1);
        end

        release dut.s4.regWrite;
        $display("FAULT-INJECTION OBSERVABILITY TEST PASSED");
        $finish;
    end

endmodule
