module jtag_bypass (
    input logic tclk,
    input logic trst_n,

    input logic capture_dr,
    input logic shift_dr,
    input  logic update_dr,

    input  logic tdi,
    output logic tdo,

    output logic bypass_value
);

    logic bypass_shift;
    logic bypass_update;

    // BYPASS register

    always @(posedge tclk or negedge trst_n) begin

        if (!trst_n) begin

            bypass_shift  <= 1'b0;
            bypass_update <= 1'b0;

        end

        else begin
            if (capture_dr) begin

                // Capture a known value
                bypass_shift <= 1'b0;

            end

            else if (shift_dr) begin

                // TDI -> BYPASS -> TDO
                bypass_shift <= tdi;

            end

            else if (update_dr) begin

                bypass_update <= bypass_shift;

            end
        end
    end
        // Serial output
        assign tdo = bypass_shift;

        // Updated BYPASS value
        assign bypass_value = bypass_update;
    
endmodule