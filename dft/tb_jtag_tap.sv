`timescale 1ns/1ps

module tb_jtag_tap;

    logic tclk;
    logic trst_n;
    logic tms;

    logic test_logic_reset;
    logic run_test_idle;

    logic capture_dr;
    logic shift_dr;
    logic update_dr;

    logic capture_ir;
    logic shift_ir;
    logic update_ir;


    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    jtag_tap dut (
        .tclk              (tclk),
        .trst_n           (trst_n),
        .tms              (tms),

        .test_logic_reset (test_logic_reset),
        .run_test_idle    (run_test_idle),

        .capture_dr       (capture_dr),
        .shift_dr         (shift_dr),
        .update_dr        (update_dr),

        .capture_ir       (capture_ir),
        .shift_ir         (shift_ir),
        .update_ir        (update_ir)
    );


    // ------------------------------------------------------------
    // tclk
    // ------------------------------------------------------------

    always #5 tclk = ~tclk;


    // ------------------------------------------------------------
    // State-name decoder for readable output
    // ------------------------------------------------------------

    task display_state;

        begin

            case (dut.state)

                4'd0: $display("STATE = TEST_LOGIC_RESET");
                4'd1: $display("STATE = RUN_TEST_IDLE");

                4'd2: $display("STATE = SELECT_DR_SCAN");
                4'd3: $display("STATE = CAPTURE_DR");
                4'd4: $display("STATE = SHIFT_DR");
                4'd5: $display("STATE = EXIT1_DR");
                4'd6: $display("STATE = PAUSE_DR");
                4'd7: $display("STATE = EXIT2_DR");
                4'd8: $display("STATE = UPDATE_DR");

                4'd9:  $display("STATE = SELECT_IR_SCAN");
                4'd10: $display("STATE = CAPTURE_IR");
                4'd11: $display("STATE = SHIFT_IR");
                4'd12: $display("STATE = EXIT1_IR");
                4'd13: $display("STATE = PAUSE_IR");
                4'd14: $display("STATE = EXIT2_IR");
                4'd15: $display("STATE = UPDATE_IR");

                default:
                    $display("STATE = UNKNOWN");

            endcase

        end

    endtask


    // ------------------------------------------------------------
    // Apply one TMS value for one tclk cycle
    // ------------------------------------------------------------

    task tap_cycle(input logic tms_value);

        begin

            tms = tms_value;

            @(posedge tclk);
            #1;

            display_state();

        end

    endtask


    // ------------------------------------------------------------
    // Check expected state
    // ------------------------------------------------------------

    task check_state(
        input [3:0] expected_state,
        input [255:0] expected_name
    );

        begin

            if (dut.state !== expected_state) begin

                $display(
                    "FAIL: Expected %0s but got state code %0d",
                    expected_name,
                    dut.state
                );

                $finish;

            end
            else begin

                $display("PASS: Reached %0s", expected_name);

            end

        end

    endtask


    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    initial begin

        tclk   = 1'b0;
        trst_n = 1'b0;
        tms   = 1'b0;


        $display("");
        $display("==============================================");
        $display("        JTAG TAP CONTROLLER TEST");
        $display("==============================================");


        // --------------------------------------------------------
        // Reset TAP
        // --------------------------------------------------------

        #12;

        trst_n = 1'b1;

        #1;

        check_state(
            4'd0,
            "TEST_LOGIC_RESET"
        );


        // --------------------------------------------------------
        // RESET -> IDLE
        // TMS = 0
        // --------------------------------------------------------

        $display("");
        $display("--- RESET -> IDLE ---");

        tap_cycle(1'b0);

        check_state(
            4'd1,
            "RUN_TEST_IDLE"
        );


        // --------------------------------------------------------
        // IDLE -> SELECT_DR -> CAPTURE_DR -> SHIFT_DR
        // --------------------------------------------------------

        $display("");
        $display("--- DR PATH ---");

        // IDLE -> SELECT_DR_SCAN
        tap_cycle(1'b1);

        check_state(
            4'd2,
            "SELECT_DR_SCAN"
        );

        // SELECT_DR_SCAN -> CAPTURE_DR
        tap_cycle(1'b0);

        check_state(
            4'd3,
            "CAPTURE_DR"
        );

        // CAPTURE_DR -> SHIFT_DR
        tap_cycle(1'b0);

        check_state(
            4'd4,
            "SHIFT_DR"
        );


        // --------------------------------------------------------
        // Remain in SHIFT_DR
        // --------------------------------------------------------

        $display("");
        $display("--- SHIFT DR ---");

        tap_cycle(1'b0);

        check_state(
            4'd4,
            "SHIFT_DR"
        );

        tap_cycle(1'b0);

        check_state(
            4'd4,
            "SHIFT_DR"
        );


        // --------------------------------------------------------
        // SHIFT_DR -> EXIT1_DR
        // --------------------------------------------------------

        $display("");
        $display("--- EXIT DR ---");

        tap_cycle(1'b1);

        check_state(
            4'd5,
            "EXIT1_DR"
        );


        // --------------------------------------------------------
        // EXIT1_DR -> UPDATE_DR
        // --------------------------------------------------------

        tap_cycle(1'b1);

        check_state(
            4'd8,
            "UPDATE_DR"
        );


        // --------------------------------------------------------
        // UPDATE_DR -> IDLE
        // --------------------------------------------------------

        tap_cycle(1'b0);

        check_state(
            4'd1,
            "RUN_TEST_IDLE"
        );


        // --------------------------------------------------------
        // IR PATH
        // --------------------------------------------------------

        $display("");
        $display("--- IR PATH ---");


        // IDLE -> SELECT_DR_SCAN
        tap_cycle(1'b1);

        check_state(
            4'd2,
            "SELECT_DR_SCAN"
        );


        // SELECT_DR_SCAN -> SELECT_IR_SCAN
        tap_cycle(1'b1);

        check_state(
            4'd9,
            "SELECT_IR_SCAN"
        );


        // SELECT_IR_SCAN -> CAPTURE_IR
        tap_cycle(1'b0);

        check_state(
            4'd10,
            "CAPTURE_IR"
        );


        // CAPTURE_IR -> SHIFT_IR
        tap_cycle(1'b0);

        check_state(
            4'd11,
            "SHIFT_IR"
        );


        // Remain in SHIFT_IR
        tap_cycle(1'b0);

        check_state(
            4'd11,
            "SHIFT_IR"
        );


        // SHIFT_IR -> EXIT1_IR
        tap_cycle(1'b1);

        check_state(
            4'd12,
            "EXIT1_IR"
        );


        // EXIT1_IR -> UPDATE_IR
        tap_cycle(1'b1);

        check_state(
            4'd15,
            "UPDATE_IR"
        );


        // UPDATE_IR -> IDLE
        tap_cycle(1'b0);

        check_state(
            4'd1,
            "RUN_TEST_IDLE"
        );


        // --------------------------------------------------------
        // Test PAUSE paths
        // --------------------------------------------------------

        $display("");
        $display("--- DR PAUSE PATH ---");


        // IDLE -> SELECT_DR -> CAPTURE_DR -> SHIFT_DR
        tap_cycle(1'b1);
        tap_cycle(1'b0);
        tap_cycle(1'b0);

        check_state(
            4'd4,
            "SHIFT_DR"
        );


        // SHIFT_DR -> EXIT1_DR
        tap_cycle(1'b1);

        check_state(
            4'd5,
            "EXIT1_DR"
        );


        // EXIT1_DR -> PAUSE_DR
        tap_cycle(1'b0);

        check_state(
            4'd6,
            "PAUSE_DR"
        );


        // Remain in PAUSE_DR
        tap_cycle(1'b0);

        check_state(
            4'd6,
            "PAUSE_DR"
        );


        // PAUSE_DR -> EXIT2_DR
        tap_cycle(1'b1);

        check_state(
            4'd7,
            "EXIT2_DR"
        );


        // EXIT2_DR -> SHIFT_DR
        tap_cycle(1'b0);

        check_state(
            4'd4,
            "SHIFT_DR"
        );


        // SHIFT_DR -> EXIT1_DR -> UPDATE_DR -> IDLE
        tap_cycle(1'b1);
        tap_cycle(1'b1);
        tap_cycle(1'b0);

        check_state(
            4'd1,
            "RUN_TEST_IDLE"
        );


        // --------------------------------------------------------
        // Test TAP reset through TMS
        // Five consecutive TMS=1 cycles
        // --------------------------------------------------------

        $display("");
        $display("--- TAP RESET THROUGH TMS ---");

        tap_cycle(1'b1);   // SELECT_DR
        tap_cycle(1'b1);   // SELECT_IR
        tap_cycle(1'b1);   // RESET
        tap_cycle(1'b1);   // RESET
        tap_cycle(1'b1);   // RESET

        check_state(
            4'd0,
            "TEST_LOGIC_RESET"
        );


        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("       ALL TAP FSM TESTS PASSED");
        $display("==============================================");

        #20;

        $finish;

    end

endmodule