module bank8 (clk, writeEn, bankAddr, dataIn, dataOut);
    input clk, writeEn;
    input [9:0] bankAddr;
    input [7:0] dataIn;
    output [7:0] dataOut;

    reg [7:0] mem [0:1023];

    assign dataOut = mem[bankAddr];

    always @(posedge clk) begin
        if (writeEn)
            mem[bankAddr] <= dataIn;
    end
endmodule