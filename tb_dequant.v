`timescale 1ns/1ps

module tb_dequantize_pipeline;

    reg         clk;
    reg         rstn;
    reg  [15:0] fxp_in;      // 测试定点输入
    reg         valid_in;
    reg  [31:0] scale;       // 浮点 scale

    wire [31:0] fp_out;
    wire        valid_out;

    // DUT 实例化
    dequantize_pipeline #(
        .N(16),
        .FRAC(8)   // 假设 Q7.8
    ) uut (
        .clk       (clk),
        .rstn      (rstn),
        .fxp_in    (fxp_in),
        .valid_in  (valid_in),
        .scale     (scale),
        .fp_out    (fp_out),
        .valid_out (valid_out)
    );

    // =========================================================
    // Clock generation
    // =========================================================
    initial clk = 0;
    always #5 clk = ~clk;  // 100MHz

    // =========================================================
    // Test stimulus
    // =========================================================
    initial begin
        $dumpfile("dequantize_pipeline.vcd");
        $dumpvars(0, tb_dequantize_pipeline);

        rstn = 0;
        fxp_in = 0;
        valid_in = 0;
        scale = 0;

        #20;
        rstn = 1;

        // -------------------------
        // Test case 1: fxp_in = 16 (Q7.8 -> 16/256 = 0.0625)
        // scale = 2.0
        // Expected float = 0.0625 * 2.0 = 0.125
        // -------------------------
        @(negedge clk);
        fxp_in    <= 16'd16;
        scale     <= 32'h40000000; // 2.0 in FP32
        valid_in  <= 1;

        @(negedge clk);
        valid_in <= 0;

        // -------------------------
        // Test case 2: fxp_in = -128 (Q7.8 -> -0.5)
        // scale = 1.5
        // Expected float = -0.5 * 1.5 = -0.75
        // -------------------------
        repeat(10) @(negedge clk);
        @(negedge clk);
        fxp_in   <= -16'sd128;
        scale    <= 32'h3fc00000; // 1.5 in FP32
        valid_in <= 1;

        @(negedge clk);
        valid_in <= 0;

        // -------------------------
        // Test case 3: fxp_in = 512 (Q7.8 -> 2.0)
        // scale = 0.25
        // Expected float = 2.0 * 0.25 = 0.5
        // -------------------------
        repeat(10) @(negedge clk);
        @(negedge clk);
        fxp_in   <= 16'd512;
        scale    <= 32'h3e800000; // 0.25 in FP32
        valid_in <= 1;

        @(negedge clk);
        valid_in <= 0;

        // Finish simulation after some cycles
        repeat(50) @(negedge clk);
        $finish;
    end

    // =========================================================
    // Monitor output when valid
    // =========================================================
    real fxp_real, scale_real, expected_real;
    always @(posedge clk) begin
        if (valid_out) begin
            // 将定点和 scale 转换为 real 用于显示
            fxp_real      = $itor(fxp_in)/256.0;  // Q7.8
            expected_real = fxp_real * scale_real;
          $display("time=%0t | fxp_in=%0d | scale=%h | fp_out=%h",
          $time, fxp_in, scale, fp_out);

        end
    end

endmodule
