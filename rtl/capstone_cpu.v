module capstone_cpu(clk, reset);
    input clk, reset;

    wire [31:0] PC;
    wire [31:0] next_pc;
    wire [31:0] instruction;
    wire [31:0] immOut;
    wire [31:0] rdata1, rdata2;
    wire [31:0] aluY;
    wire [31:0] memReadData;
    wire [31:0] writeBackData;
    wire [31:0] aluB;

    wire RegWrite, ALUSrc, MemWrite, MemRead;
    wire [2:0] ALUOp;
    wire [1:0] ImmSel;

    BankedMEM IMEM(
        .clk(clk),
        .writeEn(1'b0),
        .address(PC),
        .writeData(32'b0),
        .readData(instruction)
    );

    ControlUnit cu(
        .instruction(instruction),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .ALUOp(ALUOp),
        .ImmSel(ImmSel)
    );

    ImmGen immgen_inst(
        .ImmOut(immOut),
        .instruction(instruction),
        .ImmSel(ImmSel)
    );

    regfile rf(
        .clk(clk),
        .reset(reset),
        .we(RegWrite),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction[11:7]),
        .wd(writeBackData),
        .r1(rdata1),
        .r2(rdata2)
    );

    assign aluB = ALUSrc ? immOut : rdata2;
    
    rv32ialu alu(
        .a(rdata1),
        .b(aluB),
        .alu_ctrl(ALUOp),
        .zero(),
        .res(aluY)
    );

    BankedMEM DMEM(
        .clk(clk),
        .writeEn(MemWrite),
        .address(aluY),
        .writeData(rdata2),
        .readData(memReadData)
    );

    assign writeBackData = MemRead ? memReadData : aluY;

    PCInc pc_incrementer(
        .newPC(next_pc),
        .oldPC(PC)
    );

    reg [31:0] PC_reg;
    always @(posedge clk) begin
        if (reset)
            PC_reg <= 32'b0;
        else
            PC_reg <= next_pc;
    end
    assign PC = PC_reg;

endmodule