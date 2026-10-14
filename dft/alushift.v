module alushift(outp, inp, b, ctrl);    //shifts

    output [31:0] outp;
    input [31:0] inp;
    input [4:0] b;
    input ctrl;

    assign #2 outp = ctrl ? (inp >> b) : (inp << b);


endmodule
