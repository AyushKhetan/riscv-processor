module capstone_cpu_pipe_jtag(
    input logic clk,
    input logic reset,
    input logic scan_en,
    input logic scan_in,
    input logic  scan_hold,

    output logic scan_out,

    output logic [31:0] imem_addr,
    input logic [31:0] imem_rdata,

    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic        dmem_read,
    output logic       dmem_write,
    input logic [31:0]  dmem_rdata
    );
    

    logic [31:0] next_pc;
    logic [31:0] instr1;
    logic [31:0] instr2;
    
    logic [31:0] writeBackData;
    logic [31:0] aluA, alub;
    logic [31:0] aluB;

  
    logic [31:0] PC1;           
    logic if_id_write, PCWrite, taken_id;                     
    logic WBSel1, RegWrite1, ALUSrc1, MemWrite1, MemRead1; logic [2:0] ALUOp1;  logic [1:0] ImmSel; logic [31:0] immOut1, r1_1, r2_1, PC2; //Decode
    logic br_1, brne_1;
    logic [31:0] r1_id, r2_id;
    logic [4:0] rs1_2, rs2_2;
    logic id_ex_flush;
    logic WBSel2, RegWrite2, ALUSrc2, MemWrite2, MemRead2; logic [2:0] ALUOp2;  logic [31:0] immOut2, r1_2, r2_2, aluY_1, PC3;  logic [4:0] rd1; logic [1:0] ForwardA, ForwardB; //Execute
    logic WBSel3, RegWrite3, MemWrite3, MemRead3; logic [31:0] r2_3, aluY_2, PC4, memReadData1; logic [4:0] rd2;                                     //Mem
    logic WBSel4, RegWrite4; logic [31:0] aluY_3, memReadData2, PC5;  logic [4:0] rd3;                                                              //WB
    
    logic [31:0] pc_plus4;


    logic if_id_scan_out, id_ex_scan_out, ex_mem_scan_out;



    //counters

    logic [31:0] cycle_count;
    logic [31:0] instr_count;
    logic [31:0] stall_count;
    logic [31:0] flush_count;
    logic [31:0] branch_count;
    logic [31:0] branch_taken_count;
    

    BankedMEM IMEM(
        .clk(clk),
        .writeEn(1'b0),
        .address(PC1),
        .writeData(32'b0),
        .readData(instr1)
    );

    if_id_dft s1(
        .clk(clk),
        .reset(reset),
        .hold(scan_hold),
        .writeEn(if_id_write),
        .flush(taken_id),
        .scan_en(scan_en),
        .scan_in(scan_in),
        .scan_out(if_id_scan_out),
        .instr_in(instr1),
        .pc_in(PC1),
        .instr(instr2),
        .pc(PC2)
    );

    ControlUnit cu(
        .instruction(instr2),
        .RegWrite(RegWrite1),
        .ALUSrc(ALUSrc1),
        .WBSel(WBSel1),
        .MemWrite(MemWrite1),
        .MemRead(MemRead1),
        .ALUOp(ALUOp1),
        .ImmSel(ImmSel),
        .Branch(br_1),
        .BranchNE(brne_1)
    );

    ImmGen immgen_inst(
        .ImmOut(immOut1),
        .instruction(instr2),
        .ImmSel(ImmSel)
    );

    regfile rf(
        .clk(clk),
        .reset(reset),
        .we(!(scan_hold) && RegWrite4),
        .rs1(instr2[19:15]),
        .rs2(instr2[24:20]),
        .rd(rd3),
        .wd(writeBackData),
        .r1(r1_1),
        .r2(r2_1)
    );

    always @(*) begin
        if (RegWrite2 && (rd1 != 5'd0) && (rd1 == instr2[19:15])) begin //forward from Ex
            if(MemRead2) begin
                r1_id = r1_1;   //load data not available yet
            end
            else begin
                r1_id = aluY_1; //ALU
            end
        end
        else if (RegWrite3 && (rd2 != 5'd0) && (rd2 == instr2[19:15])) begin //forward from Mem
            if(MemRead3) begin
                r1_id = memReadData1; //load
            end
            else begin
                r1_id = aluY_2;         //ALU
            end
        end
        else if (RegWrite4 && (rd3 != 5'd0) && (rd3 == instr2[19:15])) begin //forward from WB
            r1_id = writeBackData; //WB
        end
        else begin
            r1_id = r1_1;
        end
    end

    always @(*) begin
        if (RegWrite2 && (rd1 != 5'd0) && (rd1 == instr2[24:20])) begin //forward from Ex
            if(MemRead2) begin
                r2_id = r2_1;   //load data not available yet
            end
            else begin
                r2_id = aluY_1; //ALU
            end
        end
        else if (RegWrite3 && (rd2 != 5'd0) && (rd2 == instr2[24:20])) begin  //forward from Mem
            if(MemRead3) begin
                r2_id = memReadData1; //load
            end
            else begin
                r2_id = aluY_2;        //ALU
            end
        end
        else if (RegWrite4 && (rd3 != 5'd0) && (rd3 == instr2[24:20])) begin  //forward from WB
            r2_id = writeBackData; //WB
        end
        else begin
            r2_id = r2_1;
        end
    end

    assign taken_id = (!id_ex_flush) && br_1 && (brne_1 ? (r1_id != r2_id): (r1_id == r2_id));
    assign next_pc = taken_id ? (PC2+immOut1) : pc_plus4;

    hazard_unit hu(
        .if_id_rs1     (instr2[19:15] ),
        .if_id_rs2     (instr2[24:20] ),
        .id_ex_rd      (rd1      ),
        .id_ex_MemRead (MemRead2 ),
        .PCWrite       (PCWrite       ),
        .if_id_write   (if_id_write   ),
        .id_ex_flush   (id_ex_flush   )
    );
    

    id_ex_dft s2(
        .clk         (clk         ),
        .reset       (reset       ),
        .hold        (scan_hold   ),

        .flush       (id_ex_flush),
        .scan_en     (scan_en),
        .scan_in     (if_id_scan_out),
        .scan_out    (id_ex_scan_out),

        .r1_in       (r1_id       ),
        .r2_in       (r2_id       ),
        .rs1_in      (instr2[19:15]),
        .rs2_in      (instr2[24:20]),
        .rd_in       (instr2[11:7]),
        .pc_in       (PC2         ),
        .imm_in      (immOut1      ),

        .WBSel_in    (WBSel1),
        .regWrite_in (RegWrite1 ),
        .ALUSrc_in   (ALUSrc1   ),
        .MemWrite_in (MemWrite1 ),
        .MemRead_in  (MemRead1 ),
        .ALUOp_in    (ALUOp1    ),

        .r1          (r1_2          ),
        .r2          (r2_2          ),
        .rs1         (rs1_2      ),
        .rs2         (rs2_2     ),
        .rd          (rd1          ),
        .pc          (PC3          ),
        .imm         (immOut2         ),
        .WBSel       (WBSel2),
        .regWrite    (RegWrite2   ),
        .ALUSrc      (ALUSrc2      ),
        .MemWrite    (MemWrite2    ),
        .MemRead     (MemRead2     ),
        .ALUOp       (ALUOp2       )
    );
    
    // 00 - ID_Ex, 01 - Mem_Wb, 10 - Ex_Mem
    forwarding_unit fu(
        .id_ex_r1       (rs1_2      ),
        .id_ex_r2       (rs2_2      ),
        .ex_mem_rd       (rd2       ),
        .mem_wb_rd       (rd3       ),
        .ex_mem_regWrite (RegWrite3),
        .mem_wb_regWrite (RegWrite4 ),
        .ex_mem_MemRead  (MemRead3  ),
        .ForwardA        (ForwardA        ),
        .ForwardB        (ForwardB        )
    );

    assign aluB = ALUSrc2 ? immOut2 : alub;

    always @(*) begin
        case (ForwardA)
            2'b00: aluA = r1_2;
            2'b01: aluA = writeBackData;
            2'b10: aluA = aluY_2;
        endcase

        case (ForwardB)
            2'b00: alub = r2_2;
            2'b01: alub = writeBackData;
            2'b10: alub = aluY_2;
        endcase
    end
    
    rv32ialu alu(
        .a(aluA),
        .b(aluB),
        .alu_ctrl(ALUOp2),
        .zero(),
        .res(aluY_1)
    );


    ex_mem_dft s3(
        .clk         (clk         ),
        .reset       (reset       ),
        .hold        (scan_hold   ),

        .scan_en     (scan_en),
        .scan_in     (id_ex_scan_out),
        .scan_out    (ex_mem_scan_out),

        .rd_in       (rd1       ),
        .pc_in       (PC3       ),
        .aluY_in     (aluY_1    ),
        .storeData_in(alub      ),

        .WBSel_in    (WBSel2),
        .MemWrite_in (MemWrite2 ),
        .MemRead_in  (MemRead2  ),
        .regWrite_in (RegWrite2 ),

        .rd          (rd2          ),
        .pc          (PC4          ),
        .aluY        (aluY_2        ),
        .storeData   (r2_3          ),

        .WBSel       (WBSel3        ),
        .MemWrite    (MemWrite3    ),
        .MemRead     (MemRead3     ),
        .regWrite    (RegWrite3    )
    );

    BankedMEM DMEM(
        .clk(clk),
        .writeEn(!(scan_hold) && MemWrite3),
        .address(aluY_2),
        .writeData(r2_3),
        .readData(memReadData1)
    );


    mem_wb_dft s4(
        .clk         (clk        ),
        .reset       (reset       ),
        .hold        (scan_hold   ),

        .scan_en     (scan_en),
        .scan_in     (ex_mem_scan_out),
        .scan_out    (scan_out),

        .rd_in       (rd2       ),
        .pc_in       (PC4       ),
        .aluY_in     (aluY_2     ),
        .memReadData_in (memReadData1),
        .WBSel_in    (WBSel3    ),
        .regWrite_in (RegWrite3 ),

        .rd          (rd3          ),
        .pc          (PC5          ),
        .aluY        (aluY_3      ),
        .memReadData (memReadData2),
        .WBSel       (WBSel4    ),
        .regWrite    (RegWrite4    )
    );
    
    assign writeBackData = WBSel4 ? memReadData2 : aluY_3;

    PCInc pc_incrementer(
        .newPC(pc_plus4),
        .oldPC(PC1)
    );

    logic [31:0] PC_reg;
    always @(posedge clk) begin
        if (reset)
            PC_reg <= 32'b0;
        else if(!scan_hold && PCWrite) begin
            PC_reg <= next_pc;
        end
        else begin
            PC_reg <= PC_reg;
        end
    end
    assign PC1 = PC_reg;


    perf_counter count(
        .clk                (clk                ),
        .reset              (reset              ),

        .fetch_event        (PCWrite && !taken_id && (instr1 != 32'b0)),
        .stall_event        (id_ex_flush        ),
        .flush_event        (taken_id           ),
        .branch_event       (br_1               ),
        .branch_taken_event (taken_id            ),

        .cycle_count        (cycle_count        ),
        .instr_count        (instr_count        ),
        .stall_count        (stall_count        ),
        .flush_count        (flush_count        ),
        .branch_count       (branch_count       ),
        .branch_taken_count (branch_taken_count )
    );
    

endmodule