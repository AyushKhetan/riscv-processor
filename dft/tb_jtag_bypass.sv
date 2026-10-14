`timescale 1ns/1ps

module tb_jtag_bypass;

    logic tclk;
    logic trst_n;

    logic capture_dr;
    logic shift_dr;
    logic update_dr;

    logic tdi;
    logic tdo;

    logic bypass_value;


    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    jtag_bypass dut (
        .tclk          (tclk),
        .trst_n       (trst_n),

        .capture_dr   (capture_dr),
        .shift_dr     (shift_dr),
        .update_dr    (update_dr),

        .tdi          (tdi),
        .tdo          (tdo),

        .bypass_value (bypass_value)
    );


    // ------------------------------------------------------------
    // tclk
    // ------------------------------------------------------------

    always #5 tclk = ~tclk;


    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    initial begin

        tclk = 1'b0;
        trst_n = 1'b0;

        capture_dr = 1'b0;
        shift_dr   = 1'b0;
        update_dr  = 1'b0;

        tdi = 1'b0;


        $display("");
        $display("==============================================");
        $display("          JTAG BYPASS REGISTER TEST");
        $display("==============================================");


        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        #12;

        trst_n = 1'b1;

        #1;

        if (dut.bypass_shift === 1'b0 &&
            bypass_value === 1'b0)

            $display("PASS: BYPASS reset");

        else begin

            $display(
                "FAIL: BYPASS reset: shift=%b update=%b",
                dut.bypass_shift,
                bypass_value
            );

            $finish;

        end


        // --------------------------------------------------------
        // CAPTURE_DR
        // --------------------------------------------------------

        capture_dr = 1'b1;

        @(posedge tclk);
        #1;

        capture_dr = 1'b0;


        if (dut.bypass_shift === 1'b0)

            $display("PASS: CAPTURE_DR loaded 0");

        else begin

            $display(
                "FAIL: CAPTURE_DR = %b",
                dut.bypass_shift
            );

            $finish;

        end


        // --------------------------------------------------------
        // SHIFT_DR
        //
        // Send a 1 into BYPASS.
        // --------------------------------------------------------

        shift_dr = 1'b1;

        tdi = 1'b1;

        @(posedge tclk);
        #1;

        shift_dr = 1'b0;


        if (dut.bypass_shift === 1'b1)

            $display("PASS: SHIFT_DR loaded TDI=1");

        else begin

            $display(
                "FAIL: SHIFT_DR = %b",
                dut.bypass_shift
            );

            $finish;

        end


        // --------------------------------------------------------
        // UPDATE_DR
        // --------------------------------------------------------

        update_dr = 1'b1;

        @(posedge tclk);
        #1;

        update_dr = 1'b0;


        if (bypass_value === 1'b1)

            $display("PASS: UPDATE_DR transferred 1");

        else begin

            $display(
                "FAIL: UPDATE_DR = %b",
                bypass_value
            );

            $finish;

        end


        // --------------------------------------------------------
        // Verify TDO
        //
        // Current shift register contains 1.
        // Therefore TDO must be 1.
        // --------------------------------------------------------

        if (tdo === 1'b1)

            $display("PASS: TDO = 1");

        else begin

            $display(
                "FAIL: TDO = %b",
                tdo
            );

            $finish;

        end


        // --------------------------------------------------------
        // Test another bit
        // --------------------------------------------------------

        shift_dr = 1'b1;

        tdi = 1'b0;

        @(posedge tclk);
        #1;

        shift_dr = 1'b0;


        if (dut.bypass_shift === 1'b0)

            $display("PASS: Second SHIFT_DR loaded 0");

        else begin

            $display(
                "FAIL: Second SHIFT_DR = %b",
                dut.bypass_shift
            );

            $finish;

        end


        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("       ALL BYPASS TESTS PASSED");
        $display("==============================================");

        #20;

        $finish;

    end

endmodule