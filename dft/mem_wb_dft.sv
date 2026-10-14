module mem_wb_dft(
    input logic clk,
    input logic reset,
    input logic hold,

    input logic scan_en,
    input logic scan_in,

    output logic scan_out,

    input logic [4:0] rd_in,
    input logic [31:0] pc_in,
    input logic [31:0] aluY_in,
    input logic [31:0] memReadData_in,
    input logic WBSel_in,
    input logic regWrite_in,

    output logic[4:0] rd,       // 32*3 = 96+5+2 = 103 bits
    output logic[31:0] pc,
    output logic[31:0] aluY,
    output logic[31:0] memReadData,
    output logic WBSel,
    output logic regWrite
);

logic [102:0] scan_vector, scan_shifted;

assign scan_vector = {regWrite, WBSel, memReadData, aluY, pc, rd};
assign scan_shifted = {scan_vector[101:0],scan_in};
assign scan_out = scan_vector[102];

always @(posedge clk) begin
    if(reset) begin
        rd <= '0;
        pc <= '0;
        aluY <= '0;
        memReadData <= '0;
        WBSel <= '0;
        regWrite <= '0;
    end
    else if(scan_en) begin
        {regWrite, WBSel, memReadData, aluY, pc, rd} <= scan_shifted;
    end
    else if (hold) begin
        
    end
    else begin
        rd <= rd_in;
        pc <= pc_in;
        aluY <= aluY_in;
        memReadData <= memReadData_in;
        WBSel <= WBSel_in;
        regWrite <= regWrite_in;
    end
end

endmodule
