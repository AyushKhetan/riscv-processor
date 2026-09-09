module fragment_r_type(clk, reset, inst, rd_val);
    input clk, reset;
    input [31:0] inst;
    output [31:0] rd_val;

    wire [4:0] rs1 = inst[19:15];
    wire [4:0] rs2 = inst[24:20];
    wire [4:0] rd  = inst[11:7];
    wire [2:0] f3  = inst[14:12];
    wire f7_5      = inst[30];

    wire [31:0] rdata1, rdata2, alu_out;
    wire [2:0] alu_sel;

    regfile RF (
        .clk(clk),
        .reset(reset),
        .we(1'b1),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(alu_out),
        .r1(rdata1),
        .r2(rdata2)
    );

    alu_ctrl AC (
        .alu_ctrl(alu_sel),
        .funct3(f3),
        .funct7_5(f7_5)
    );

    alu_lab04 ALU (
        .out(alu_out),
        .a(rdata1),
        .b(rdata2),
        .sel(alu_sel)
    );

    assign rd_val = alu_out;
endmodule