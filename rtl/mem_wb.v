module mem_wb(
    input clk,
    input reset,

    input [4:0] rd_in,
    input [31:0] pc_in,
    input [31:0] aluY_in,
    input [31:0] memReadData_in,
    input WBSel_in,
    input regWrite_in,

    output reg [4:0] rd,
    output reg [31:0] pc,
    output reg [31:0] aluY,
    output reg [31:0] memReadData,
    output reg WBSel,
    output reg regWrite
);

always @(posedge clk) begin
    if(reset) begin
        rd <= '0;
        pc <= '0;
        aluY <= '0;
        memReadData <= '0;
        WBSel <= '0;
        regWrite <= '0;
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
