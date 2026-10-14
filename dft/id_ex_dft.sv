module id_ex_dft(
    input logic clk,
    input logic flush,
    input logic reset,
    input logic hold,

    input logic scan_en,
    input logic scan_in,

    output logic scan_out,

    input logic [31:0] r1_in,
    input logic [31:0] r2_in,
    input logic [4:0] rs1_in,
    input logic [4:0] rs2_in,
    input logic [4:0] rd_in,
    input logic [31:0] pc_in,
    input logic [31:0] imm_in,

    input logic WBSel_in,
    input logic regWrite_in,
    input logic ALUSrc_in,
    input logic MemWrite_in,
    input logic MemRead_in,
    input logic [2:0] ALUOp_in,

    output logic [31:0] r1, // 32*4 + 5*3 = 143 bits
    output logic [31:0] r2,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [31:0] pc,
    output logic [31:0] imm,

    output logic WBSel,  //5+3 = 8, 143+8 = 151 bits
    output logic regWrite,
    output logic ALUSrc,
    output logic MemWrite,
    output logic MemRead,
    output logic [2:0] ALUOp
);

logic [150:0] scan_vector, scan_shifted;

assign scan_vector = {ALUOp, MemRead, MemWrite, ALUSrc, regWrite, WBSel, imm, pc, rd, rs2, rs1, r2, r1};
assign scan_shifted = {scan_vector[149:0],scan_in};
assign scan_out = scan_vector[150];

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
    else if (scan_en) begin
        {ALUOp, MemRead, MemWrite, ALUSrc, regWrite, WBSel, imm, pc, rd, rs2, rs1, r2, r1} <= scan_shifted;
    end
    else if (hold) begin
        
    end
    else if (flush) begin
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
