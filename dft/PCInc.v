`timescale 1ns/1ps

module PCInc(newPC, oldPC);
input [31:0] oldPC;
output [31:0] newPC;

wire ovf_pos_unused;
wire ovf_neg_unused;

aluaddsub u_adder (
    .outp(newPC),
    .a(oldPC),
    .b(32'd4),
    .ctrl(1'b0),
    .pos_of(ovf_pos_unused),
    .neg_of(ovf_neg_unused)
);

endmodule