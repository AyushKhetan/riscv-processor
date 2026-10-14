module reg32(d, q, clk, we, reset);

    input  [31:0] d;
    output reg [31:0] q;
    input clk, we, reset;

    always@(posedge clk)
        begin
            if(reset)
                q <= #1 32'b0;
            else if(we)
                q <= #1 d; //if (!we) case not included, holds to previous value by default
        end

endmodule
