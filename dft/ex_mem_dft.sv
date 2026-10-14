module ex_mem_dft(
    input logic clk,
    input logic reset,
    input logic hold,

    input logic scan_en,
    input logic scan_in,

    output logic scan_out,

    input logic [4:0] rd_in,
    input logic [31:0] pc_in,
    input logic [31:0] aluY_in,
    input logic [31:0] storeData_in,
    input logic WBSel_in,
    input logic MemWrite_in,
    input logic MemRead_in,
    input logic regWrite_in,

    output logic [4:0] rd,      // 32*3 = 96+5+4 = 105 bits
    output logic [31:0] pc,
    output logic [31:0] aluY,
    output logic [31:0] storeData,
    output logic WBSel,
    output logic MemWrite,
    output logic MemRead,
    output logic regWrite
);

logic [104:0] scan_vector, scan_shifted;

assign scan_vector = {regWrite, MemRead, MemWrite, WBSel, storeData, aluY, pc, rd};
assign scan_shifted = {scan_vector[103:0],scan_in};
assign scan_out = scan_vector[104];

always @(posedge clk) begin
    if(reset) begin
        rd <= '0;
        pc <= '0;
        aluY <= '0;
        storeData <= '0;
        WBSel <= '0;
        MemWrite <= '0;
        MemRead <= '0;
        regWrite <= '0;
    end
    else if (scan_en) begin
        {regWrite, MemRead, MemWrite, WBSel, storeData, aluY, pc, rd} <= scan_shifted;
    end
    else if (hold) begin
        
    end
    else begin
        rd <= rd_in;
        pc <= pc_in;
        aluY <= aluY_in;
        storeData <= storeData_in;
        WBSel <= WBSel_in;
        MemWrite <= MemWrite_in;
        MemRead <= MemRead_in;
        regWrite <= regWrite_in;
    end
end

endmodule
