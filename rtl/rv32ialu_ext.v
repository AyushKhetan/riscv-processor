`timescale 1ns/1ps

module rv32ialu_ext(a, b, alu_ctrl, zero, res);

    input [31:0] a, b;
    input [3:0] alu_ctrl;
    output zero;
    output reg [31:0] res;

    wire [31:0] add_sub_res, and_or_res, shift_res, slt_res, sltu_res;
    wire pos_of, neg_of;
    wire carry_out;
    wire [32:0] full_sum;

    assign full_sum = a + (~b) + 1'b1; 
    assign carry_out = full_sum[32];
    assign #1 sltu_res = {31'b0, ~carry_out};

    aluaddsub inst1 (add_sub_res, a, b, ~alu_ctrl[0], pos_of, neg_of);
    alulogic inst2 (a, b, alu_ctrl[0], and_or_res);
    alushift inst3 (shift_res, a, b[4:0], alu_ctrl[0]);
    alucomp inst4 (slt_res, a, b);

    always @(*)
    begin
        case(alu_ctrl)
            4'b0000 : #1 res = add_sub_res;
            4'b0001 : #1 res = add_sub_res;
            4'b0010 : #1 res = and_or_res;
            4'b0011 : #1 res = and_or_res;
            4'b0100 : #1 res = shift_res;
            4'b0101 : #1 res = shift_res;
            4'b0110 : #1 res = slt_res;
            4'b1000 : #1 res = sltu_res;
            default : #1 res = 32'b0;
        endcase
    end

    assign zero = (res == 32'b0);

endmodule