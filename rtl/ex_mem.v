module ex_mem(
    input clk,
    input reset,

    input [4:0] rd_in,
    input [31:0] pc_in,
    input [31:0] aluY_in,
    input [31:0] storeData_in,
    input WBSel_in,
    input MemWrite_in,
    input MemRead_in,
    input regWrite_in,

    output reg [4:0] rd,
    output reg [31:0] pc,
    output reg [31:0] aluY,
    output reg [31:0] storeData,
    output reg WBSel,
    output reg MemWrite,
    output reg MemRead,
    output reg regWrite
);

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
