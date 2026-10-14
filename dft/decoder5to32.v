`timescale 1ns/1ps

module decoder5to32(dec_out, rd, reg_write_en);

    input [4:0] rd;
    input reg_write_en;
    output [31:0] dec_out;

    assign #1 dec_out = reg_write_en ?  (32'b1 << rd) : 32'b0;

endmodule