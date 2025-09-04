// `timescale 1ns/1ps
// `include "float2fxp.v"

// module tb_float2fxp_pipe;

//     // 参数定义
//     parameter WOI  = 8;
//     parameter WOF  = 0;
//     parameter ROUND= 1;

//     reg         clk;
//     reg         rstn;
//     reg  [31:0] in;
//     wire [WOI+WOF-1:0] out;
//     wire        overflow;

//     // 实例化待测模块
//     float2fxp_pipe #(
//         .WOI(WOI),
//         .WOF(WOF),
//         .ROUND(ROUND)
//     ) u_float2fxp (
//         .clk(clk),
//         .rstn(rstn),
//         .in(in),
//         .out(out),
//         .overflow(overflow)
//     );

//     // 时钟生成
//     initial clk = 0;
//     always #5 clk = ~clk;  // 10ns 时钟周期

//     // 测试输入数组
//     reg [31:0] test_vectors [0:9];
//     integer i;

//     // 浮点转 real 用于显示
//     function real float32_to_real;
//         input [31:0] f;
//         real r;
//         begin
//             r = $bitstoreal({ {32{1'b0}}, f }); // 仿真显示用
//             float32_to_real = r;
//         end
//     endfunction

//     initial begin
//         $dumpfile("tb_float2fxp_pipe.vcd");  // 指定输出的VCD文件名
//         $dumpvars(0, tb_float2fxp_pipe);     // 记录 tb_float2fxp_pipe 及其所有层次的信号

        
//         // 复位
//         rstn = 0;
//         in   = 0;
//         #20;
//         rstn = 1;

//         // 设置测试浮点数
//         test_vectors[0] = 32'h3f800000; // 1.0
//         test_vectors[1] = 32'h40000000; // 2.0
//         test_vectors[2] = 32'h40200000; // 3.0  
//         test_vectors[3] = 32'hbf800000; // -1.0
//         test_vectors[4] = 32'hc0000000; // -2.0
//         test_vectors[5] = 32'h00000000; // 0.0
//         test_vectors[6] = 32'h7f800000; // +Inf
//         test_vectors[7] = 32'hff800000; // -Inf
//         test_vectors[8] = 32'h7fc00000; // NaN
//         test_vectors[9] = 32'h41200000; // 10.0

//         for(i=0; i<10; i=i+1) begin
//             in = test_vectors[i];
//             #10; // 给 pipeline 一个时钟启动信号
//             // 延迟输出直到流水线完成，这里假设 pipeline 深度=WOI+WOF+3
//             #((WOI+WOF+3)*10);
//             $display("Time=%0t | in=0x%08h | out=0x%0h | overflow=%b", 
//                      $time, in, out, overflow);
//         end

//         #50;
//         $finish;
//     end

// endmodule


`timescale 1ns/1ps
`include "float2fxp.v"

module tb_float2fxp_pipe;

    // 参数定义
    parameter WOI  = 8;
    parameter WOF  = 0;
    parameter ROUND= 1;

    reg         clk;
    reg         rstn;
    reg  [31:0] in;
    reg         ena;             // 新增输入有效信号
    wire [WOI+WOF-1:0] out;
    wire        overflow;
    wire        out_valid;       // 新增输出有效信号

    // 实例化待测模块
    float2fxp_pipe #(
        .WOI(WOI),
        .WOF(WOF),
        .ROUND(ROUND)
    ) u_float2fxp (
        .clk(clk),
        .rstn(rstn),
        .in(in),
        .ena(ena),
        .out(out),
        .overflow(overflow),
        .out_valid(out_valid)
    );

    // 时钟生成
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns 时钟周期

    // 测试输入数组
    reg [31:0] test_vectors [0:9];
    integer i;

    initial begin
        $dumpfile("tb_float2fxp_pipe.vcd");
        $dumpvars(0, tb_float2fxp_pipe);

        // 复位
        rstn = 0;
        ena  = 0;
        in   = 0;
        #20;
        rstn = 1;

        // 设置测试浮点数
        test_vectors[0] = 32'h3f800000; // 1.0
        test_vectors[1] = 32'h40000000; // 2.0
        test_vectors[2] = 32'h40200000; // 3.0  
        test_vectors[3] = 32'hbf800000; // -1.0
        test_vectors[4] = 32'hc0000000; // -2.0
        test_vectors[5] = 32'h00000000; // 0.0
        test_vectors[6] = 32'h7f800000; // +Inf
        test_vectors[7] = 32'hff800000; // -Inf
        test_vectors[8] = 32'h7fc00000; // NaN
        test_vectors[9] = 32'h41200000; // 10.0

        for(i=0; i<10; i=i+1) begin
            in  = test_vectors[i];
            ena = 1'b1;          // 当前输入有效
            #10;                 // 给 pipeline 一个时钟
            ena = 1'b0;          // 下一个周期取消有效
            #10;
        end

        // 等待流水线输出完毕
        #((4+1)*10); // pipeline 深度=4级，可适当调整
        $finish;
    end

    // 打印输出，只有有效时刻打印
    always @(posedge clk) begin
        if(out_valid) begin
            $display("Time=%0t | in=0x%08h | out=0x%0h | overflow=%b | valid=%b",
                     $time, in, out, overflow, out_valid);
        end
    end

endmodule
