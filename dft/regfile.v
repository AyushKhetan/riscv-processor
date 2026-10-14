`timescale 1ns/1ps

module regfile(clk, reset, we, rs1, rs2, rd, wd, r1, r2);

    input clk, reset, we;
    input [4:0] rs1, rs2, rd;
    input [31:0] wd;
    output [31:0] r1, r2;

    wire [31:0] x [0:31];
    wire [31:0] ctrl;

    decoder5to32 d1(ctrl, rd, we);

    assign x[0] = 32'b0;

    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin: reg_gen
            reg32 r_inst(wd, x[i], clk, ctrl[i], reset);
        end
    endgenerate

    assign r1 = x[rs1];
    assign r2 = x[rs2];

endmodule