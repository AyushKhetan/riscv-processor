module perf_counter (
    input        clk,
    input        reset,

    input        fetch_event,
    input        stall_event,
    input        flush_event,
    input        branch_event,
    input        branch_taken_event,

    output reg [31:0] cycle_count,
    output reg [31:0] instr_count,
    output reg [31:0] stall_count,
    output reg [31:0] flush_count,
    output reg [31:0] branch_count,
    output reg [31:0] branch_taken_count
);

always @(posedge clk) begin
    if (reset) begin
        cycle_count        <= 32'd0;
        instr_count        <= 32'd0;
        stall_count        <= 32'd0;
        flush_count        <= 32'd0;
        branch_count       <= 32'd0;
        branch_taken_count <= 32'd0;
    end
    else begin
        cycle_count        <= cycle_count + 32'b1;
        if(fetch_event) begin
            instr_count        <= instr_count + fetch_event;
        end

        if(stall_event) begin
            stall_count        <= stall_count + stall_event;
        end
        
        if(flush_event) begin
            flush_count        <= flush_count + flush_event;
        end

        if(branch_event) begin
            branch_count       <= branch_count+ branch_event;
        end
        
        if(branch_taken_event) begin
            branch_taken_count <= branch_taken_count + branch_taken_event;
        end
        
    end
end

endmodule