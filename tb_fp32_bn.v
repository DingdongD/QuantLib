`timescale 1ns/1ps

module tb_fp32_batchnorm_pipeline;

    reg         clk;
    reg         rstn;
    reg         ena;
    reg  [31:0] x, mu, var, gamma, beta, eps;
    reg  [1:0]  rm;
    wire [31:0] y;
    wire        y_valid;

    // DUT
    fp32_batchnorm dut (
        .clk(clk), .rstn(rstn), .ena(ena),
        .x(x), .mu(mu), .var(var), .gamma(gamma), .beta(beta), .eps(eps),
        .rm(rm),
        .y(y), .y_valid(y_valid)
    );

    // Clock generator: 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset
    initial begin
        rstn = 0;
        ena  = 0;
        #20;
        rstn = 1;
    end

    // Test vectors
    integer i;
    reg [31:0] test_x[0:3];
    reg [31:0] test_mu[0:3];
    reg [31:0] test_var[0:3];
    reg [31:0] test_gamma[0:3];
    reg [31:0] test_beta[0:3];
    reg [31:0] test_eps[0:3];

    initial begin
        rm = 2'b00; // rounding mode nearest

        // Test vectors (IEEE-754 hex)
        test_x[0]     = 32'h40A00000; // 5.0
        test_mu[0]    = 32'h40000000; // 2.0
        test_var[0]   = 32'h40800000; // 4.0
        test_gamma[0] = 32'h3F800000; // 1.0
        test_beta[0]  = 32'h00000000; // 0.0
        test_eps[0]   = 32'h322BCC77; // 1e-8

        test_x[1]     = 32'hC1200000; // -10.0
        test_mu[1]    = 32'hC0000000; // -2.0
        test_var[1]   = 32'h40A00000; // 5.0
        test_gamma[1] = 32'h40000000; // 2.0
        test_beta[1]  = 32'h3F000000; // 0.5
        test_eps[1]   = 32'h322BCC77; // 1e-8

        test_x[2]     = 32'h40400000; // 3.0
        test_mu[2]    = 32'h3F800000; // 1.0
        test_var[2]   = 32'h40000000; // 2.0
        test_gamma[2] = 32'h3F800000; // 1.0
        test_beta[2]  = 32'h00000000; // 0.0
        test_eps[2]   = 32'h322BCC77; // 1e-8

        test_x[3]     = 32'hC0200000; // -2.5
        test_mu[3]    = 32'hC0000000; // -2.0
        test_var[3]   = 32'h3F800000; // 1.0
        test_gamma[3] = 32'h40000000; // 2.0
        test_beta[3]  = 32'h3F000000; // 0.5
        test_eps[3]   = 32'h322BCC77; // 1e-8

        // 输入流水线
        @(posedge rstn);  // 等 reset 释放
        
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            x     <= test_x[i];
            mu    <= test_mu[i];
            var   <= test_var[i];
            gamma <= test_gamma[i];
            beta  <= test_beta[i];
            eps   <= test_eps[i];
            ena <= 1;

            repeat(22)@(posedge clk);
            ena <= 0;

            repeat(33) @(posedge clk); 
        end

        // 等待流水线结果全部出来
        repeat (50) @(posedge clk);

        $finish;
    end

    // Monitor outputs and dump VCD
    initial begin
        $dumpfile("tb_fp32_batchnorm.vcd");
        $dumpvars(0, tb_fp32_batchnorm_pipeline);

        $display("time\tena\tx\ty\ty_valid");
        forever @(posedge clk) begin
            if (y_valid)
                $display("%0t\t%b\t%h\t%h\t%b", $time, ena, x, y, y_valid);
        end
    end

endmodule
