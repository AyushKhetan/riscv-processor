`timescale 1ns/1ps

module ImmGen(ImmOut, instruction, ImmSel);
input [1:0] ImmSel;
input [31:0] instruction;
output [31:0] ImmOut;

wire [31:0] imm_I;
wire [31:0] imm_S;
wire [31:0] imm_B;

assign imm_I = {{20{instruction[31]}}, instruction[31:20]};

assign imm_S = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

assign imm_B = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};

assign ImmOut = (ImmSel == 2'b00) ? imm_I :
                (ImmSel == 2'b01) ? imm_S :
                (ImmSel == 2'b10) ? imm_B : 32'b0;
endmodule