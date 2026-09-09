module hazard_unit (
    input [4:0] if_id_rs1,
    input [4:0] if_id_rs2,
    input [4:0] id_ex_rd,
    input       id_ex_MemRead,
    output reg PCWrite,
    output reg if_id_write,
    output reg id_ex_flush
);

always @(*) begin
    if(id_ex_MemRead && id_ex_rd!=0 && ((id_ex_rd == if_id_rs1)||(id_ex_rd == if_id_rs2))) begin
        PCWrite = '0;
        if_id_write = '0;
        id_ex_flush = '1;
    end
    else begin
        PCWrite = '1;
        if_id_write = '1;
        id_ex_flush = '0;
    end
end
    
endmodule