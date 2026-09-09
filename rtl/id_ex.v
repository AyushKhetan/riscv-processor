module id_ex(
    input clk,
    input reset,

    input [31:0] r1_in,
    input [31:0] r2_in,
    input [4:0] rs1_in,
    input [4:0] rs2_in,
    input [4:0] rd_in,
    input [31:0] pc_in,
    input [31:0] imm_in,

    input WBSel_in,
    input regWrite_in,
    input ALUSrc_in,
    input MemWrite_in,
    input MemRead_in,
    input [2:0] ALUOp_in,

    output reg [31:0] r1,
    output reg [31:0] r2,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] rd,
    output reg [31:0] pc,
    output reg [31:0] imm,

    output reg WBSel,
    output reg regWrite,
    output reg ALUSrc,
    output reg MemWrite,
    output reg MemRead,
    output reg [2:0] ALUOp
);

always @(posedge clk) begin
    if(reset) begin
        r1 <= '0;
        r2 <= '0;
        rs1 <= '0;
        rs2 <= '0;
        rd <= '0;
        pc <= '0;
        imm <= '0;

        WBSel <= '0;
        regWrite <= '0;
        ALUSrc <= '0;
        MemWrite <= '0;
        MemRead <= '0;
        ALUOp <= '0;
    end
    else begin
        r1 <= r1_in;
        r2 <= r2_in;
        rs1 <= rs1_in;
        rs2 <= rs2_in;
        imm <= imm_in;
        rd <= rd_in;
        pc <= pc_in;

        WBSel <= WBSel_in;
        regWrite <= regWrite_in;
        ALUSrc <= ALUSrc_in;
        MemWrite <= MemWrite_in;
        MemRead <= MemRead_in;
        ALUOp <= ALUOp_in;
    end
end

endmodule
