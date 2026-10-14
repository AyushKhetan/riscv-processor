module if_id_dft(
    input logic clk,
    input logic reset,
    input logic hold,
    input logic writeEn,
    input logic flush,

    input logic scan_en,
    input logic scan_in,

    output logic scan_out,

    input logic [31:0] instr_in,
    input logic [31:0] pc_in,

    output logic [31:0] instr,// 64 bits
    output logic [31:0] pc
);

logic [63:0] scan_vector, scan_shifted;

assign scan_vector = {pc,instr};
assign scan_shifted = {scan_vector[62:0],scan_in};
assign scan_out = scan_vector[63];

always @(posedge clk) begin
    if(reset) begin
        instr <= '0;
        pc <= '0;
    end
    else if(scan_en) begin
        {pc,instr} <= scan_shifted;
    end
    else if (hold) begin
        instr <= instr;
        pc <= pc;
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