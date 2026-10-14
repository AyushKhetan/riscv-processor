module forwarding_unit (
    input [4:0] id_ex_r1,
    input [4:0] id_ex_r2,
    input [4:0] ex_mem_rd,
    input [4:0] mem_wb_rd,

    input ex_mem_regWrite,
    input mem_wb_regWrite,
    input ex_mem_MemRead,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);


always @(*) begin
    ForwardA = 2'b0;
    ForwardB = 2'b0;

    if(ex_mem_regWrite && ex_mem_rd!='0 && (ex_mem_rd == id_ex_r1)) begin
        if (!ex_mem_MemRead) begin
            ForwardA = 2'b10;
        end
    end
    else if (mem_wb_regWrite && mem_wb_rd!='0 && (mem_wb_rd == id_ex_r1)) begin
        ForwardA = 2'b01;
    end

    if(ex_mem_regWrite && ex_mem_rd!='0 && (ex_mem_rd == id_ex_r2)) begin
        if (!ex_mem_MemRead) begin
            ForwardB = 2'b10;
        end
    end
    else if (mem_wb_regWrite && mem_wb_rd!='0 && (mem_wb_rd == id_ex_r2)) begin
        ForwardB = 2'b01;
    end
end
    
endmodule