`timescale 1ns/1ps


module alucomp(outp, a, b); //slt

    input  [31:0] a, b;
    output [31:0] outp;

    wire pos_of, neg_of;
    wire [31:0] res;
    wire slt;

    aluaddsub inst (res, a, b, 1'b1, pos_of, neg_of);

    assign slt = res[31] ^ pos_of ^ neg_of;
    assign #1 outp = {32{slt}};



endmodule