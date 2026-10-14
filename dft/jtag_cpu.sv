module jtag_cpu (

    input logic tclk,
    input logic trst_n,
    input logic tms,
    input logic tdi,

    output logic tdo,

    // CPU reset
    input logic cpu_reset,

    // CPU memory interfaces
    output logic [31:0] imem_addr,
    input logic [31:0] imem_rdata,

    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic        dmem_read,
    output logic        dmem_write,
    input logic [31:0]  dmem_rdata

);


    // ============================================================
    // TAP CONTROLLER
    // ============================================================

    logic test_logic_reset;
    logic run_test_idle;

    logic capture_dr;
    logic shift_dr;
    logic update_dr;

    logic capture_ir;
    logic shift_ir;
    logic update_ir;

    logic scan_hold;
    

    jtag_tap tap (

        .tclk              (tclk),
        .trst_n            (trst_n),
        .tms               (tms),

        .test_logic_reset  (test_logic_reset),
        .run_test_idle     (run_test_idle),

        .capture_dr        (capture_dr),
        .shift_dr          (shift_dr),
        .update_dr         (update_dr),

        .capture_ir        (capture_ir),
        .shift_ir          (shift_ir),
        .update_ir         (update_ir)

    );


    // ============================================================
    // INSTRUCTION REGISTER
    // ============================================================

    logic [3:0] instruction;
    logic ir_tdo;


    jtag_ir ir (

        .tclk         (tclk),
        .trst_n       (trst_n),

        .capture_ir   (capture_ir),
        .shift_ir     (shift_ir),
        .update_ir    (update_ir),

        .tdi          (tdi),
        .tdo          (ir_tdo),

        .instruction  (instruction)

    );


    // ============================================================
    // IDCODE REGISTER
    // ============================================================

    logic idcode_tdo;
    logic [31:0] idcode_value;

    // DATA REGISTER MULTIPLEXER

    logic idcode_capture_dr;
    logic idcode_shift_dr;
    logic idcode_update_dr;

    logic bypass_capture_dr;
    logic bypass_shift_dr;
    logic bypass_update_dr;

    logic cpu_scan_capture_dr;
    logic cpu_scan_shift_dr;
    logic cpu_scan_update_dr;

    jtag_idcode idcode (

        .tclk          (tclk),
        .trst_n        (trst_n),

        .capture_dr    (idcode_capture_dr),
        .shift_dr      (idcode_shift_dr),
        .update_dr     (idcode_update_dr),

        .tdi           (tdi),
        .tdo           (idcode_tdo),

        .idcode_value  (idcode_value)

    );


    // ============================================================
    // BYPASS REGISTER
    // ============================================================

    logic bypass_tdo;
    logic bypass_value;


    jtag_bypass bypass (

        .tclk          (tclk),
        .trst_n        (trst_n),

        .capture_dr    (bypass_capture_dr),
        .shift_dr      (bypass_shift_dr),
        .update_dr     (bypass_update_dr),

        .tdi           (tdi),
        .tdo           (bypass_tdo),

        .bypass_value  (bypass_value)

    );


    // ============================================================
    // CPU SCAN INTERFACE
    // ============================================================

    logic cpu_scan_tdo;
    logic cpu_scan_en;
    logic cpu_scan_in;
    logic cpu_scan_out;


    jtag_cpu_scan cpu_scan (

        .tclk        (tclk),
        .trst_n      (trst_n),

        .capture_dr  (cpu_scan_capture_dr),
        .shift_dr    (cpu_scan_shift_dr),
        .update_dr   (cpu_scan_update_dr),

        .tdi         (tdi),
        .tdo         (cpu_scan_tdo),

        .scan_en     (cpu_scan_en),
        .scan_in     (cpu_scan_in),
        .scan_out    (cpu_scan_out)

    );


    // ============================================================
    // CPU
    // ============================================================

    // In this implementation tclk acts as the scan/test clock.
    // During CPU_SCAN, cpu_scan_en becomes active only in
    // SHIFT_DR.

    assign scan_hold = (instruction == 4'b0010) && !cpu_scan_shift_dr;
    
    capstone_cpu_pipe_jtag cpu (
        .clk        (tclk),
        .reset      (cpu_reset),

        .scan_en    (cpu_scan_en),
        .scan_in    (cpu_scan_in),
        .scan_hold  (scan_hold),
        .scan_out   (cpu_scan_out),

        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),

        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_read  (dmem_read),
        .dmem_write (dmem_write),
        .dmem_rdata (dmem_rdata)
    );


    // ============================================================
    // DATA REGISTER MULTIPLEXER
    // ============================================================

   


    jtag_dr_mux dr_mux (

        .instruction  (instruction),

        .capture_dr   (capture_dr),
        .shift_dr     (shift_dr),
        .update_dr    (update_dr),

        .idcode_tdo   (idcode_tdo),
        .bypass_tdo   (bypass_tdo),
        .cpu_scan_tdo (cpu_scan_tdo),

        .idcode_capture_dr   (idcode_capture_dr),
        .idcode_shift_dr     (idcode_shift_dr),
        .idcode_update_dr    (idcode_update_dr),

        .bypass_capture_dr   (bypass_capture_dr),
        .bypass_shift_dr     (bypass_shift_dr),
        .bypass_update_dr    (bypass_update_dr),

        .cpu_scan_capture_dr (cpu_scan_capture_dr),
        .cpu_scan_shift_dr   (cpu_scan_shift_dr),
        .cpu_scan_update_dr  (cpu_scan_update_dr),

        .tdo                 (tdo)

    );


endmodule