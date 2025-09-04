`timescale 1ns/1ps

module tb_quantize_pipeline;

    reg         clk;
    reg         rst_n;
    reg         ena;

    reg  [31:0] fp_in;
    reg  [31:0] scale;
    reg  [7:0]  zp;
    reg         use_asym;

    wire [7:0]  q_out;
    wire        sat;
    wire        out_valid;

    // DUT
    quantize_pipeline uut (
        .clk       (clk),
        .rst_n     (rst_n),
        .ena       (ena),
        .fp_in     (fp_in),
        .scale     (scale),
        .zp        (zp),
        .use_asym  (use_asym),
        .q_out     (q_out),
        .sat       (sat),
        .out_valid (out_valid)
    );

    // clock
    always #5 clk = ~clk;  // 100MHz

    initial begin
        $dumpfile("quantize_pipeline.vcd");
        $dumpvars(0, tb_quantize_pipeline);

        clk = 0;
        rst_n = 0;
        ena = 0;
        fp_in = 0;
        scale = 0;
        zp = 0;
        use_asym = 0;

        #50;
        rst_n = 1;

        // ==============================
        //  Test case 1: fp_in=12.5, scale=0.5, zp=10, asym=1
        //  公式: (12.5/0.5) + 10 = 35
        //  注意：这里 scale 需要输入 inv_scale = 2.0
        // ==============================
        @(negedge clk);
        ena   <= 1;
        fp_in <= 32'h41480000; // 12.5
        scale <= 32'h40000000; // 2.0 (即 1/0.5)
        zp    <= 8'd10;
        use_asym <= 1;

        @(negedge clk);
        ena <= 0; // 只打一拍数据

        // ==============================
        //  Test case 2: fp_in=32768, scale=1.0, zp=0, sym
        //  公式: 32768 / 1.0 = 32768 → 裁剪到 127
        // ==============================
        repeat(20) @(negedge clk);
        ena   <= 1;
        fp_in <= 32'h47000000; // 32768.0
        scale <= 32'h3f800000; // 1.0
        zp    <= 8'd0;
        use_asym <= 0;

        @(negedge clk);
        ena <= 0;

        // ==============================
        //  Test case 3: fp_in=-20, scale=0.25, zp=5, asym=1
        //  公式: (-20 / 0.25) + 5 = -75 → clip到0
        // ==============================
        repeat(20) @(negedge clk);
        ena   <= 1;
        fp_in <= 32'hc1a00000; // -20.0
        scale <= 32'h40800000; // 4.0 (即 1/0.25)
        zp    <= 8'd5;
        use_asym <= 1;

        @(negedge clk);
        ena <= 0;

        // ==============================
        //  Finish
        // ==============================
        repeat(100) @(negedge clk);
        $finish;
    end

    // Monitor only when out_valid is high
    always @(posedge clk) begin
        if (out_valid) begin
            $display("time=%0t | fp_in=%h | scale=%h | zp=%0d | use_asym=%b | q_out=%0d | sat=%b",
                $time, fp_in, scale, zp, use_asym, q_out, sat);
        end
    end

endmodule
