module jtag_ir (
    input logic tclk,
    input logic trst_n,

    input logic capture_ir,
    input logic shift_ir,
    input logic update_ir,

    input logic tdi,
    output logic tdo,

    output logic [3:0] instruction
);
    
    localparam logic [3:0] IDCODE = 4'b0001;
    localparam logic [3:0] CPU_SCAN = 4'b0010;
    localparam logic [3:0] BYPASS   = 4'b1111;

    logic [3:0] ir_shift;
    logic [3:0] ir_update;

    // IR shift/capture/update register

    always @(posedge tclk or negedge trst_n) begin

        if (!trst_n) begin
            ir_shift <= IDCODE;
            ir_update <= IDCODE;
        end

        else begin
            if (capture_ir) begin
                ir_shift <= 4'b0001;
            end

            else if (shift_ir) begin
                ir_shift <= {ir_shift[2:0],tdi};
            end

            else if (update_ir) begin
                ir_update <= ir_shift;
            end
        end
    end

    // Active instruction
    assign instruction = ir_update;

    // Serial output during SHIFT_IR
    assign tdo = ir_shift[3];


endmodule