module alulogic(a, b, ctrl, outp);  //and, or

    input [31:0] a, b;
    input ctrl;
    output [31:0] outp;

    assign #1 outp = ctrl ? (a | b) : (a & b);

endmodule
