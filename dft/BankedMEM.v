module BankedMEM (clk, writeEn, address, writeData, readData);
    input clk, writeEn;
    input [31:0] address, writeData;
    output [31:0] readData;

    wire [9:0] bankAddr;
    assign bankAddr = address[11:2];

    bank8 u_bank0 (
        .clk(clk),
        .writeEn(writeEn),
        .bankAddr(bankAddr),
        .dataIn(writeData[7:0]),
        .dataOut(readData[7:0])
    );

    bank8 u_bank1 (
        .clk(clk),
        .writeEn(writeEn),
        .bankAddr(bankAddr),
        .dataIn(writeData[15:8]),
        .dataOut(readData[15:8])
    );

    bank8 u_bank2 (
        .clk(clk),
        .writeEn(writeEn),
        .bankAddr(bankAddr),
        .dataIn(writeData[23:16]),
        .dataOut(readData[23:16])
    );

    bank8 u_bank3 (
        .clk(clk),
        .writeEn(writeEn),
        .bankAddr(bankAddr),
        .dataIn(writeData[31:24]),
        .dataOut(readData[31:24])
    );
endmodule