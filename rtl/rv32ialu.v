module rv32ialu(a, b, alu_ctrl, zero, res);

    input [31:0] a, b;
    input [2:0] alu_ctrl;
    output zero;
    output reg [31:0] res;

    wire [31:0] add_sub_res;
    wire [31:0] and_or_res;
    wire [31:0] shift_res;
    wire [31:0] slt_res;
    wire [31:0] xor_res;

    wire pos_of, neg_of;

    // ADD for ctrl=0, SUB for ctrl=1
    aluaddsub inst1 (
        add_sub_res,
        a,
        b,
        alu_ctrl[0],
        pos_of,
        neg_of
    );

    // AND for ctrl=0, OR for ctrl=1
    alulogic inst2 (
        a,
        b,
        alu_ctrl[0],
        and_or_res
    );

    // SLL for ctrl=0, SRL for ctrl=1
    alushift inst3 (
        shift_res,
        a,
        b[4:0],
        alu_ctrl[0]
    );

    // SLT
    alucomp inst4 (
        slt_res,
        a,
        b
    );

    // XOR
    assign #1 xor_res = a ^ b;

    always @(*) begin
        case (alu_ctrl)
            3'b000: res = add_sub_res;  // ADD
            3'b001: res = add_sub_res;  // SUB
            3'b010: res = and_or_res;   // AND
            3'b011: res = and_or_res;   // OR
            3'b100: res = xor_res;      // XOR
            3'b101: res = shift_res;    // SLL
            3'b110: res = shift_res;    // SRL
            3'b111: res = slt_res;      // SLT
        endcase
    end

    assign zero = (res == 32'b0);

endmodule