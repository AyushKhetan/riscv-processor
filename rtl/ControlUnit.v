module ControlUnit (
    instruction,
    RegWrite,
    ALUSrc,
    WBSel,
    MemWrite,
    MemRead,
    ALUOp,
    ImmSel,
    Branch,
    BranchNE
);

    input [31:0] instruction;
    output RegWrite, ALUSrc, WBSel, MemWrite, MemRead;
    output [2:0] ALUOp;
    output [1:0] ImmSel;
    output Branch, BranchNE;

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    // Opcodes
    wire is_rtype;
    wire is_ialu;
    wire is_iload;
    wire is_stype;
    wire is_btype;

    assign is_rtype = (opcode == 7'b0110011);
    assign is_ialu  = (opcode == 7'b0010011);
    assign is_iload = (opcode == 7'b0000011);
    assign is_stype = (opcode == 7'b0100011);
    assign is_btype = (opcode == 7'b1100011);

    // Main control
    assign RegWrite = is_rtype | is_ialu | is_iload;
    assign ALUSrc   = is_ialu | is_iload | is_stype;
    assign WBSel    = is_iload;
    assign MemWrite = is_stype;
    assign MemRead  = is_iload;

    assign ImmSel[0] = is_stype;
    assign ImmSel[1] = is_btype;

    assign Branch = is_btype;
    assign BranchNE = is_btype && (funct3 == 3'b001);
    
    // ALU control
    reg [2:0] alu_op_reg;

    always @(*) begin

        // Default: ADD
        alu_op_reg = 3'b000;

        if (is_rtype || is_ialu) begin

            case (funct3)

                3'b000: begin
                    // ADD / SUB
                    if (is_rtype && (funct7 == 7'b0100000))
                        alu_op_reg = 3'b001;
                    else
                        alu_op_reg = 3'b000;
                end

                3'b001:
                    alu_op_reg = 3'b101;     // SLL

                3'b010:
                    alu_op_reg = 3'b111;     // SLT

                3'b100:
                    alu_op_reg = 3'b100;     // XOR

                3'b101:
                    alu_op_reg = 3'b110;     // SRL

                3'b110:
                    alu_op_reg = 3'b011;     // OR

                3'b111:
                    alu_op_reg = 3'b010;     // AND

                default:
                    alu_op_reg = 3'b000;

            endcase

        end
        else if (is_btype) begin

            // Branch comparison = subtraction
            alu_op_reg = 3'b001;

        end
        else begin

            // LW/SW address calculation
            alu_op_reg = 3'b000;

        end
    end

    assign ALUOp = alu_op_reg;

endmodule