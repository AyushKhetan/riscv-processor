`timescale 1ns/1ps

module tb_jtag_idcode;

    logic tclk;
    logic trst_n;

    logic capture_dr;
    logic shift_dr;
    logic update_dr;

    logic tdi;
    logic tdo;

    logic [31:0] idcode_value;

    logic [31:0] shifted_out;

    integer i;


    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    jtag_idcode dut (
        .tclk          (tclk),
        .trst_n       (trst_n),

        .capture_dr   (capture_dr),
        .shift_dr     (shift_dr),
        .update_dr    (update_dr),

        .tdi          (tdi),
        .tdo          (tdo),

        .idcode_value (idcode_value)
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

        shifted_out = 32'b0;


        $display("");
        $display("==============================================");
        $display("          JTAG IDCODE REGISTER TEST");
        $display("==============================================");


        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        #12;

        trst_n = 1'b1;

        #1;

        if (idcode_value === 32'h1234_5678)

            $display("PASS: Reset IDCODE = %h", idcode_value);

        else begin

            $display(
                "FAIL: Reset IDCODE = %h",
                idcode_value
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


        if (dut.idcode_shift === 32'h1234_5678)

            $display(
                "PASS: CAPTURE_DR loaded %h",
                dut.idcode_shift
            );

        else begin

            $display(
                "FAIL: CAPTURE_DR = %h",
                dut.idcode_shift
            );

            $finish;

        end


        // --------------------------------------------------------
        // SHIFT_DR
        //
        // Shift out the complete IDCODE.
        //
        // TDO is sampled BEFORE the shift edge.
        // The current MSB is available combinationally at TDO.
        // The following posedge then shifts the register.// TDO is sampled AFTER the shift edge, consistent with
        // the scan timing convention we established earlier.
        // --------------------------------------------------------

        shift_dr = 1'b1;

        #1;

        $display("BEFORE FIRST SHIFT:");
        $display("  tclk         = %b", tclk);
        $display("  shift_dr     = %b", shift_dr);
        $display("  idcode_shift = %h", dut.idcode_shift);
        $display("  tdo          = %b", tdo);

        for (i = 0; i < 32; i = i + 1) begin

            tdi = 1'b0;

            shifted_out[31-i] = tdo;
            
            @(posedge tclk);
            #1;

            

        end

        shift_dr = 1'b0;


        // --------------------------------------------------------
        // Display
        // --------------------------------------------------------

        $display("");
        $display("Expected IDCODE = %h", 32'h1234_5678);
        $display("Shifted  IDCODE = %h", shifted_out);


        // --------------------------------------------------------
        // Check serial result
        // --------------------------------------------------------

        if (shifted_out === 32'h1234_5678)

            $display("PASS: IDCODE shifted out correctly");

        else begin

            $display("FAIL: IDCODE shifted out incorrectly");
            $finish;

        end


        // --------------------------------------------------------
        // UPDATE_DR
        // --------------------------------------------------------

        update_dr = 1'b1;

        @(posedge tclk);
        #1;

        update_dr = 1'b0;


        // After shifting zeros, the update register should
        // contain zeros.
        if (idcode_value === 32'b0)

            $display("PASS: UPDATE_DR transferred shifted data");

        else begin

            $display(
                "FAIL: UPDATE_DR = %h",
                idcode_value
            );

            $finish;

        end


        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("       ALL IDCODE TESTS PASSED");
        $display("==============================================");

        #20;

        $finish;

    end

endmodule