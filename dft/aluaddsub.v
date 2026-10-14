`timescale 1ns/1ps

module aluaddsub(outp, a, b, ctrl, pos_of, neg_of); //add/sub

    input signed [31:0] a, b;
    input ctrl;
    output signed [31:0] outp;
    output pos_of, neg_of;

    wire [31:0] bop;
    assign bop = ctrl ? ~b : b;

    wire [32:0] full_outp;

    assign full_outp = a + bop + ctrl;
    assign #3 outp = full_outp[31:0];

    wire cin_msb;
    wire [31:0] sum_withoutmsb;

    assign sum_withoutmsb = a[30:0] + bop[30:0] + ctrl;

    assign #3 pos_of = sum_withoutmsb[31] & ~full_outp[32];
    assign #3 neg_of = ~sum_withoutmsb[31] & full_outp[32];
    // pos_of = #3 (~a[31] & ~bop[31] & outp[31]);
    // neg_of = #3 (a[31] & bop[31] & ~outp[31]);


endmodule