`timescale 1ns/1ps

module tb_jtag_ir;

logic tclk;
    logic trst_n;

    logic capture_ir;
    logic shift_ir;
    logic update_ir;

    logic tdi;
    logic tdo;

    logic [3:0] instruction;

    jtag_ir dut (
        .tclk         (tclk),
        .trst_n      (trst_n),

        .capture_ir  (capture_ir),
        .shift_ir    (shift_ir),
        .update_ir   (update_ir),

        .tdi         (tdi),
        .tdo         (tdo),

        .instruction (instruction)
    );

    always #5 tclk = ~tclk;


    initial begin

        tclk = 1'b0;
        trst_n = 1'b0;

        capture_ir = 1'b0;
        shift_ir   = 1'b0;
        update_ir  = 1'b0;

        tdi = 1'b0;

        $display("");
        $display("==============================================");
        $display("       JTAG INSTRUCTION REGISTER TEST");
        $display("==============================================");


        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        #12;

        trst_n = 1'b1;

        #1;

        if (instruction === 4'b0001)
            $display("PASS: Reset instruction = IDCODE");
        else begin
            $display("FAIL: Reset instruction = %b", instruction);
            $finish;
        end


        // --------------------------------------------------------
        // CAPTURE_IR
        // --------------------------------------------------------

        capture_ir = 1'b1;

        @(posedge tclk);
        #1;

        capture_ir = 1'b0;

        if (dut.ir_shift === 4'b0001)
            $display("PASS: CAPTURE_IR loaded 0001");
        else begin
            $display("FAIL: CAPTURE_IR = %b", dut.ir_shift);
            $finish;
        end


        // --------------------------------------------------------
        // SHIFT_IR
        //
        // We want to load:
        //
        //     CPU_SCAN = 0010
        //
        // Serial order is LSB first:
        //
        //     0 -> 1 -> 0 -> 0
        // --------------------------------------------------------

        shift_ir = 1'b1;

        // Bit 0
        tdi = 1'b0;
        @(posedge tclk);
        
        #1

        // Bit 1
        tdi = 1'b0;
        @(posedge tclk);

        #1
        // Bit 2
        tdi = 1'b1;
        @(posedge tclk);

        #1        
        // Bit 3
        tdi = 1'b0;
        @(posedge tclk);

        #1;

        shift_ir = 1'b0;


        // --------------------------------------------------------
        // Check shift register
        // --------------------------------------------------------

        if (dut.ir_shift === 4'b0010)
            $display("PASS: SHIFT_IR loaded CPU_SCAN = 0010");
        else begin
            $display(
                "FAIL: IR_SHIFT = %b",
                dut.ir_shift
            );
            $finish;
        end


        // --------------------------------------------------------
        // UPDATE_IR
        // --------------------------------------------------------

        update_ir = 1'b1;

        @(posedge tclk);
        #1;

        update_ir = 1'b0;


        if (instruction === 4'b0010)
            $display("PASS: UPDATE_IR activated CPU_SCAN");
        else begin
            $display(
                "FAIL: Active instruction = %b",
                instruction
            );
            $finish;
        end


        // --------------------------------------------------------
        // Verify that active instruction remains stable
        // during another shift operation.
        // --------------------------------------------------------

        capture_ir = 1'b1;

        @(posedge tclk);
        #1;

        capture_ir = 1'b0;

        shift_ir = 1'b1;

        tdi = 1'b1;

        @(posedge tclk);
        #1;

        shift_ir = 1'b0;

        if (instruction === 4'b0010)
            $display(
                "PASS: Active instruction remains stable during SHIFT_IR"
            );
        else begin
            $display(
                "FAIL: Active instruction changed during SHIFT_IR"
            );
            $finish;
        end


        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("       ALL IR TESTS PASSED");
        $display("==============================================");

        #20;

        $finish;

    end

endmodule