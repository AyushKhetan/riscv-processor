`timescale 1ns/1ps

module tb_jtag_cpu;

    // ------------------------------------------------------------
    // JTAG and CPU interface signals
    // ------------------------------------------------------------
    logic tclk;
    logic trst_n;
    logic tms;
    logic tdi;
    logic tdo;

    logic cpu_reset;

    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic        dmem_read;
    logic        dmem_write;
    logic [31:0] dmem_rdata;

    // The first serial bit shifted in is test_pattern[0].
    logic [422:0] test_pattern;
    logic [422:0] shifted_out;
    logic [31:0]  idcode_read;

    integer i;
    integer first_mismatch;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    jtag_cpu dut (
        .tclk       (tclk),
        .trst_n     (trst_n),
        .tms        (tms),
        .tdi        (tdi),
        .tdo        (tdo),
        .cpu_reset  (cpu_reset),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_read  (dmem_read),
        .dmem_write (dmem_write),
        .dmem_rdata (dmem_rdata)
    );

    // ------------------------------------------------------------
    // Test clock
    // ------------------------------------------------------------
    initial tclk = 1'b0;
    always #5 tclk = ~tclk;

    // ------------------------------------------------------------
    // Apply one TMS value for one TCK rising edge.
    // The #1 delay lets nonblocking assignments and combinational
    // state decoding settle before the next stimulus is applied.
    // ------------------------------------------------------------
    task automatic tap_cycle(input logic tms_value);
        begin
            tms = tms_value;
            @(posedge tclk);
            #1;
        end
    endtask

    // ------------------------------------------------------------
    // Navigate from Run-Test/Idle to Shift-IR.
    // Expected starting state: Run-Test/Idle.
    // ------------------------------------------------------------
    task automatic goto_shift_ir;
        begin
            tap_cycle(1'b1); // IDLE       -> SELECT_DR_SCAN
            tap_cycle(1'b1); // SELECT_DR  -> SELECT_IR_SCAN
            tap_cycle(1'b0); // SELECT_IR  -> CAPTURE_IR
            tap_cycle(1'b0); // CAPTURE_IR -> SHIFT_IR
        end
    endtask

    // ------------------------------------------------------------
    // Navigate from Run-Test/Idle to Shift-DR.
    // Expected starting state: Run-Test/Idle.
    // ------------------------------------------------------------
    task automatic goto_shift_dr;
        begin
            tap_cycle(1'b1); // IDLE       -> SELECT_DR_SCAN
            tap_cycle(1'b0); // SELECT_DR  -> CAPTURE_DR
            tap_cycle(1'b0); // CAPTURE_DR -> SHIFT_DR
        end
    endtask

    // ------------------------------------------------------------
    // Load CPU_SCAN (4'b0010) into the instruction register.
    // With this IR's shift convention, TDI is applied LSB-first as
    // 0, 0, 1, 0. The last bit exits Shift-IR on the same edge.
    // Expected starting state: Run-Test/Idle.
    // ------------------------------------------------------------
    task automatic load_cpu_scan_instruction;
        begin
            goto_shift_ir();

            tdi = 1'b0; tms = 1'b0; @(posedge tclk); #1;
            tdi = 1'b0; tms = 1'b0; @(posedge tclk); #1;
            tdi = 1'b1; tms = 1'b0; @(posedge tclk); #1;
            tdi = 1'b0; tms = 1'b1; @(posedge tclk); #1;

            tap_cycle(1'b1); // EXIT1_IR -> UPDATE_IR
            tap_cycle(1'b0); // UPDATE_IR -> IDLE
        end
    endtask

    // ------------------------------------------------------------
    // Read the 32-bit IDCODE.
    // TDO is sampled before each shift edge; the implementation
    // shifts the current MSB toward TDO.
    // Expected starting state: Run-Test/Idle.
    // ------------------------------------------------------------
    task automatic read_idcode;
        integer k;
        begin
            idcode_read = 32'b0;
            goto_shift_dr();

            for (k = 0; k < 32; k = k + 1) begin
                tdi = 1'b0;
                tms = (k == 31) ? 1'b1 : 1'b0;
                idcode_read[31-k] = tdo;
                @(posedge tclk);
                #1;
            end

            tap_cycle(1'b1); // EXIT1_DR -> UPDATE_DR
            tap_cycle(1'b0); // UPDATE_DR -> IDLE
        end
    endtask

    // ------------------------------------------------------------
    // Shift the test pattern into the 423-bit CPU scan chain.
    // test_pattern[0] is the first bit presented at TDI.
    // Expected starting state: Run-Test/Idle.
    // ------------------------------------------------------------
    task automatic shift_cpu_pattern_in;
        integer k;
        begin
            goto_shift_dr();

            for (k = 0; k < 423; k = k + 1) begin
                tdi = test_pattern[k];
                tms = (k == 422) ? 1'b1 : 1'b0;
                @(posedge tclk);
                #1;
            end

            tap_cycle(1'b1); // EXIT1_DR -> UPDATE_DR
            tap_cycle(1'b0); // UPDATE_DR -> IDLE
        end
    endtask

    // ------------------------------------------------------------
    // Shift the scan chain out and collect TDO.
    // The first TDO sample corresponds to the first bit shifted in,
    // test_pattern[0], for this chain's wiring and shift direction.
    // Therefore, store sample k in shifted_out[k], not [422-k].
    // Expected starting state: Run-Test/Idle.
    // ------------------------------------------------------------
    task automatic shift_cpu_pattern_out;
        integer k;
        begin
            shifted_out = '0;
            goto_shift_dr();

            for (k = 0; k < 423; k = k + 1) begin
                tdi = 1'b0;
                tms = (k == 422) ? 1'b1 : 1'b0;

                // TDO is the current serial output before this edge
                // shifts the next bit into the chain.
                shifted_out[k] = tdo;

                @(posedge tclk);
                #1;
            end

            tap_cycle(1'b1); // EXIT1_DR -> UPDATE_DR
            tap_cycle(1'b0); // UPDATE_DR -> IDLE
        end
    endtask

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------
    initial begin
        trst_n     = 1'b0;
        tms        = 1'b0;
        tdi        = 1'b0;
        cpu_reset  = 1'b1;
        imem_rdata = 32'b0;
        dmem_rdata = 32'b0;
        test_pattern = '0;
        shifted_out  = '0;
        idcode_read  = '0;
        first_mismatch = -1;

        $display("");
        $display("==============================================");
        $display("       COMPLETE JTAG CPU INTEGRATION TEST");
        $display("==============================================");

        // Keep the synchronous CPU reset asserted for five clock edges.
        repeat (5) @(posedge tclk);
        #1;
        cpu_reset = 1'b0;

        // Release the active-low JTAG reset, then drive the TAP into
        // Test-Logic-Reset using five TMS-high clock edges.
        trst_n = 1'b1;
        repeat (5) begin
            tms = 1'b1;
            @(posedge tclk);
            #1;
        end

        // From Test-Logic-Reset, TMS=0 enters Run-Test/Idle.
        tap_cycle(1'b0);

        // --------------------------------------------------------
        // TEST 1: IDCODE
        // --------------------------------------------------------
        $display("");
        $display("--- IDCODE TEST ---");

        read_idcode();

        if (idcode_read === 32'h1234_5678) begin
            $display("PASS: JTAG IDCODE = %h", idcode_read);
        end
        else begin
            $display("FAIL: JTAG IDCODE = %h (expected 12345678)", idcode_read);
            $fatal(1, "IDCODE test failed");
        end

        // --------------------------------------------------------
        // TEST 2: Select CPU_SCAN
        // --------------------------------------------------------
        $display("");
        $display("--- CPU_SCAN INSTRUCTION TEST ---");

        load_cpu_scan_instruction();

        if (dut.instruction === 4'b0010) begin
            $display("PASS: Active instruction = CPU_SCAN");
        end
        else begin
            $display("FAIL: Active instruction = %b (expected 0010)", dut.instruction);
            $fatal(1, "CPU_SCAN instruction selection failed");
        end

        // --------------------------------------------------------
        // TEST 3: 423-bit CPU scan round trip
        // --------------------------------------------------------
        $display("");
        $display("--- 423-BIT CPU SCAN TEST ---");

        // Deterministic, non-symmetric pattern to expose bit-order errors.
        for (i = 0; i < 423; i = i + 1)
            test_pattern[i] = (((i * 37 + 11) % 101) < 50);

        shift_cpu_pattern_in();
        shift_cpu_pattern_out();

        if (shifted_out === test_pattern) begin
            $display("PASS: 423-bit CPU scan pattern recovered correctly");
        end
        else begin
            $display("FAIL: 423-bit CPU scan pattern mismatch");
            first_mismatch = -1;

            for (i = 0; i < 423; i = i + 1) begin
                if ((first_mismatch == -1) && (shifted_out[i] !== test_pattern[i])) begin
                    first_mismatch = i;
                end
            end

            if (first_mismatch >= 0) begin
                $display("First mismatch at bit %0d: expected=%b got=%b",
                         first_mismatch,
                         test_pattern[first_mismatch],
                         shifted_out[first_mismatch]);
            end

            $fatal(1, "CPU scan round-trip test failed");
        end

        $display("");
        $display("==============================================");
        $display("       ALL JTAG CPU TESTS PASSED");
        $display("==============================================");
        #20;
        $finish;
    end

endmodule
