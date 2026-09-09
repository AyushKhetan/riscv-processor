`timescale 1ns/1ps

module bit32_32to1mux(reg_out, reg_num, reg_arr);

    input [4:0] reg_num;
    input [31:0] reg_arr [0:31];

    output [31:0] reg_out;

    assign reg_out = reg_arr[reg_num];

endmodule