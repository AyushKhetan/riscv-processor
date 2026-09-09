module if_id(
    input clk,
    input reset,
    input writeEn,
    input flush,

    input [31:0] instr_in,
    input  [31:0] pc_in,

    output reg [31:0] instr,
    output reg [31:0] pc
);

always @(posedge clk) begin
    if(reset) begin
        instr <= '0;
        pc <= '0;
    end
    else if (flush) begin
        instr <= '0;
        pc <= '0;
    end
    else begin
        if(writeEn) begin
            instr <= instr_in;
            pc <= pc_in; 
        end
        else begin
            instr <= instr;
            pc <= pc;
        end
    end
end

endmodule