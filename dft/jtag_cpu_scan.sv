module jtag_cpu_scan (

    input  logic tclk,
    input  logic trst_n,

    input  logic capture_dr,
    input  logic shift_dr,
    input  logic update_dr,

    input  logic tdi,
    output logic tdo,

    output logic scan_en,
    output logic scan_in,
    input  logic scan_out

);

    // CPU scan control

    assign scan_en = shift_dr;
    assign scan_in = tdi;
    assign tdo = scan_out;

endmodule