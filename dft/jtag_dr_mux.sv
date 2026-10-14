module jtag_dr_mux (

    input logic [3:0] instruction,

    input logic capture_dr,
    input logic shift_dr,
    input logic update_dr,

    input logic idcode_tdo,
    input logic bypass_tdo,
    input logic cpu_scan_tdo,

    output logic idcode_capture_dr,
    output logic idcode_shift_dr,
    output logic idcode_update_dr,

    output logic bypass_capture_dr,
    output logic bypass_shift_dr,
    output logic bypass_update_dr,

    output logic cpu_scan_capture_dr,
    output logic cpu_scan_shift_dr,
    output logic cpu_scan_update_dr,

    output logic tdo
);

    localparam logic [3:0] IDCODE   = 4'b0001;
    localparam logic [3:0] CPU_SCAN = 4'b0010;
    localparam logic [3:0] BYPASS   = 4'b1111;


    always_comb begin

        // Default: no DR selected
        idcode_capture_dr   = 1'b0;
        idcode_shift_dr     = 1'b0;
        idcode_update_dr    = 1'b0;

        bypass_capture_dr   = 1'b0;
        bypass_shift_dr     = 1'b0;
        bypass_update_dr    = 1'b0;

        cpu_scan_capture_dr = 1'b0;
        cpu_scan_shift_dr   = 1'b0;
        cpu_scan_update_dr  = 1'b0;

        tdo = 1'b0;


        case (instruction)

            IDCODE: begin

                idcode_capture_dr = capture_dr;
                idcode_shift_dr   = shift_dr;
                idcode_update_dr  = update_dr;

                if (shift_dr)
                    tdo = idcode_tdo;

            end


            CPU_SCAN: begin

                cpu_scan_capture_dr = capture_dr;
                cpu_scan_shift_dr   = shift_dr;
                cpu_scan_update_dr  = update_dr;

                if (shift_dr)
                    tdo = cpu_scan_tdo;

            end


            BYPASS: begin

                bypass_capture_dr = capture_dr;
                bypass_shift_dr   = shift_dr;
                bypass_update_dr  = update_dr;

                if (shift_dr)
                    tdo = bypass_tdo;

            end


            default: begin

                // Undefined instructions default to BYPASS

                bypass_capture_dr = capture_dr;
                bypass_shift_dr   = shift_dr;
                bypass_update_dr  = update_dr;

                if (shift_dr)
                    tdo = bypass_tdo;

            end

        endcase

    end

endmodule