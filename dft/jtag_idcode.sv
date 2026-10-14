module jtag_idcode (
    input logic tclk,
    input logic trst_n,

    input logic capture_dr,
    input logic shift_dr,
    input logic update_dr,

    input logic tdi,
    output logic tdo,

    output logic [31:0] idcode_value
);

    localparam logic [31:0] IDCODE = 32'h1234_5678;

    logic [31:0] idcode_shift;
    logic [31:0] idcode_update;

    // IDCODE shift/capture/update

    always @(posedge tclk or negedge trst_n) begin

        if (!trst_n) begin

            idcode_shift  <= IDCODE;
            idcode_update <= IDCODE;

        end

        else begin

            if (capture_dr) begin
                idcode_shift <= IDCODE;
            end
            else if (shift_dr) begin
                idcode_shift <= {idcode_shift[30:0],tdi};
            end
            else if (update_dr) begin
                idcode_update <= idcode_shift;
            end
        end
    end

    // Serial output

    assign tdo = idcode_shift[31];

    // Updated value

    assign idcode_value = idcode_update;

endmodule