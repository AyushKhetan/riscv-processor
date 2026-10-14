module jtag_tap (
    input logic tclk,
    input logic trst_n,
    input logic tms,

    output logic test_logic_reset,
    output logic run_test_idle,

    output logic capture_dr,
    output logic shift_dr,
    output logic update_dr,

    output logic capture_ir,
    output logic shift_ir,
    output logic update_ir
);

    typedef enum logic [3:0] {
        TEST_LOGIC_RESET = 4'd0,
        RUN_TEST_IDLE = 4'd1,

        SELECT_DR_SCAN = 4'd2,
        CAPTURE_DR     = 4'd3,
        SHIFT_DR       = 4'd4,
        EXIT1_DR       = 4'd5,
        PAUSE_DR       = 4'd6,
        EXIT2_DR       = 4'd7,
        UPDATE_DR      = 4'd8,

        SELECT_IR_SCAN = 4'd9,
        CAPTURE_IR     = 4'd10,
        SHIFT_IR       = 4'd11,
        EXIT1_IR       = 4'd12,
        PAUSE_IR       = 4'd13,
        EXIT2_IR       = 4'd14,
        UPDATE_IR      = 4'd15
    }  tap_state_t;

    tap_state_t state, next_state;

    // State Register
    always @(posedge tclk or negedge trst_n) begin
        if(!trst_n)
            state <= TEST_LOGIC_RESET;
        else
            state <= next_state;
    end

    always_comb begin
        case (state)
            TEST_LOGIC_RESET:
                if(tms)
                    next_state = TEST_LOGIC_RESET;
                else
                    next_state = RUN_TEST_IDLE;

            RUN_TEST_IDLE:
                if(tms)
                    next_state = SELECT_DR_SCAN;
                else
                    next_state = RUN_TEST_IDLE;

            SELECT_DR_SCAN:
                if (tms)
                    next_state = SELECT_IR_SCAN;
                else
                    next_state = CAPTURE_DR;

            CAPTURE_DR:
                if (tms)
                    next_state = EXIT1_DR;
                else
                    next_state = SHIFT_DR;

            SHIFT_DR:
                if (tms)
                    next_state = EXIT1_DR;
                else
                    next_state = SHIFT_DR;

            EXIT1_DR:
                if (tms)
                    next_state = UPDATE_DR;
                else
                    next_state = PAUSE_DR;

            PAUSE_DR:
                if (tms)
                    next_state = EXIT2_DR;
                else
                    next_state = PAUSE_DR;

            EXIT2_DR:
                if (tms)
                    next_state = UPDATE_DR;
                else
                    next_state = SHIFT_DR;

            UPDATE_DR:
                if (tms)
                    next_state = SELECT_DR_SCAN;
                else
                    next_state = RUN_TEST_IDLE;

            SELECT_IR_SCAN:
                if (tms)
                    next_state = TEST_LOGIC_RESET;
                else
                    next_state = CAPTURE_IR;

            CAPTURE_IR:
                if (tms)
                    next_state = EXIT1_IR;
                else
                    next_state = SHIFT_IR;

            SHIFT_IR:
                if (tms)
                    next_state = EXIT1_IR;
                else
                    next_state = SHIFT_IR;

            EXIT1_IR:
                if (tms)
                    next_state = UPDATE_IR;
                else
                    next_state = PAUSE_IR;

            PAUSE_IR:
                if (tms)
                    next_state = EXIT2_IR;
                else
                    next_state = PAUSE_IR;

            EXIT2_IR:
                if (tms)
                    next_state = UPDATE_IR;
                else
                    next_state = SHIFT_IR;

            UPDATE_IR:
                 if (tms)
                    next_state = SELECT_DR_SCAN;
                else
                    next_state = RUN_TEST_IDLE;

            default:
                next_state = TEST_LOGIC_RESET;
        
        endcase
    end

    always_comb begin
        
        test_logic_reset = (state == TEST_LOGIC_RESET);
        run_test_idle = (state == RUN_TEST_IDLE);

        capture_dr = (state == CAPTURE_DR);
        shift_dr   = (state == SHIFT_DR);
        update_dr  = (state == UPDATE_DR);

        capture_ir = (state == CAPTURE_IR);
        shift_ir   = (state == SHIFT_IR);
        update_ir  = (state == UPDATE_IR);
    end

endmodule

    

