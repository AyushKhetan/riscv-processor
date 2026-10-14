`timescale 1ns/1ps

module tb_jtag_cpu_scan;

    logic tclk;
    logic trst_n;

    logic capture_dr;
    logic shift_dr;
    logic update_dr;

    logic tdi;
    logic tdo;

    logic scan_en;
    logic scan_in;
    logic scan_out;


    jtag_cpu_scan dut (

        .tclk        (tclk),
        .trst_n     (trst_n),

        .capture_dr (capture_dr),
        .shift_dr   (shift_dr),
        .update_dr  (update_dr),

        .tdi        (tdi),
        .tdo        (tdo),

        .scan_en    (scan_en),
        .scan_in    (scan_in),
        .scan_out   (scan_out)

    );


    always #5 tclk = ~tclk;


    initial begin

        tclk = 1'b0;
        trst_n = 1'b0;

        capture_dr = 1'b0;
        shift_dr   = 1'b0;
        update_dr  = 1'b0;

        tdi      = 1'b0;
        scan_out = 1'b0;


        $display("");
        $display("==============================================");
        $display("        JTAG CPU SCAN WRAPPER TEST");
        $display("==============================================");


        #12;

        trst_n = 1'b1;


        // --------------------------------------------------------
        // IDLE
        // --------------------------------------------------------

        #1;

        if (scan_en === 1'b0)
            $display("PASS: scan_en inactive in IDLE");

        else begin
            $display("FAIL: scan_en unexpectedly active");
            $finish;
        end


        // --------------------------------------------------------
        // SHIFT_DR
        // --------------------------------------------------------

        shift_dr = 1'b1;

        #1;

        if (scan_en === 1'b1)
            $display("PASS: SHIFT_DR activates scan_en");

        else begin
            $display("FAIL: SHIFT_DR did not activate scan_en");
            $finish;
        end


        // --------------------------------------------------------
        // TDI
        // --------------------------------------------------------

        tdi = 1'b1;

        #1;

        if (scan_in === 1'b1)
            $display("PASS: TDI connected to scan_in");

        else begin
            $display("FAIL: TDI not connected to scan_in");
            $finish;
        end


        // --------------------------------------------------------
        // TDO
        // --------------------------------------------------------

        scan_out = 1'b1;

        #1;

        if (tdo === 1'b1)
            $display("PASS: scan_out connected to TDO");

        else begin
            $display("FAIL: scan_out not connected to TDO");
            $finish;
        end


        // --------------------------------------------------------
        // End SHIFT_DR
        // --------------------------------------------------------

        shift_dr = 1'b0;

        #1;

        if (scan_en === 1'b0)
            $display("PASS: scan_en deactivated");

        else begin
            $display("FAIL: scan_en remains active");
            $finish;
        end


        // --------------------------------------------------------
        // Final
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("       ALL CPU SCAN WRAPPER TESTS PASSED");
        $display("==============================================");

        #20;

        $finish;

    end

endmodule