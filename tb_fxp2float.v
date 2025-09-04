`timescale 1ns/1ps
`include "fxp2float.v"
// module tb_fxp2float;

//     reg  [15:0] fxp;       // 输入定点数
//     wire [31:0] fp;        // 输出浮点数

//     // 实例化 DUT
//     fxp2float #(
//         .N(16),
//         .FRAC(4)
//     ) uut (
//         .fxp(fxp),
//         .fp(fp)
//     );

//     task show_result;
//         input [15:0] fxp_val;
//         begin
//             fxp = fxp_val;
//             #1;  // 等待组合逻辑稳定
//             $display("time=%0t | fxp=0x%04h | fp=0x%08h", $time, fxp, fp);
//         end
//     endtask

//     initial begin
//         $display("=== Fixed-point to IEEE754 Float Conversion Test ===");

//         // 输入测试值 (Q8.8 格式)
//         show_result(16'h0100);  // 1.0
//         show_result(16'h02C1);  // 2.75
//         show_result(16'hFC80);  // -3.5
//         show_result(16'h0000);  // 0.0
//         show_result(16'hFF00);  // -1.0
//         show_result(16'h0340);  // 2.5
//         show_result(16'h7100);  // 113

//         $finish;
//     end

// endmodule


module tb_fxp2float_pipeline;

    // ===== 参数定义 =====
    parameter N = 16;
    parameter FRAC = 8;

    reg clk;
    reg rstn;
    reg [N-1:0] fxp_in;
    reg valid_in;

    wire [31:0] fp_out;
    wire valid_out;

    // ===== 待测试定点数据 =====
    reg [N-1:0] test_values [0:6];
    integer i;

    // ===== 时钟生成 =====
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns 时钟周期

    // ===== 模块实例化 =====
    fxp2float_pipeline #(
        .N(N),
        .FRAC(FRAC)
    ) uut (
        .clk(clk),
        .rstn(rstn),
        .fxp_in(fxp_in),
        .valid_in(valid_in),
        .fp_out(fp_out),
        .valid_out(valid_out)
    );

    // ===== 测试数据初始化 =====
    initial begin
        // Q4.12 示例
        test_values[0] = 16'h0100; // 0.0625
        test_values[1] = 16'h02C1; // 0.171875
        test_values[2] = 16'hFC80; // -0.0625
        test_values[3] = 16'h0000; // 0
        test_values[4] = 16'hFF00; // -0.0625
        test_values[5] = 16'h0340; // 0.203125
        test_values[6] = 16'h7100; // 28.0

        rstn = 0;
        fxp_in = 0;
        valid_in = 0;
        #20;
        rstn = 1;

        // ===== 喂入流水线 =====
        for(i=0;i<7;i=i+1) begin
            @(posedge clk);
            fxp_in <= test_values[i];
            valid_in <= 1;
        end

        // 结束输入
        @(posedge clk);
        valid_in <= 0;

        // 等待流水线输出完成
        repeat(10) @(posedge clk);

        $finish;
    end

    // ===== 输出显示 =====
    always @(posedge clk) begin
        if(valid_out) begin
            $display("time=%0t | fxp=0x%04X | fp=0x%08X", $time, fxp_in, fp_out);
        end
    end

endmodule
