// `timescale 1ns/1ps
// `include "float2fxp.v"

// module tb_float2fxp_pipe;

//     // ��������
//     parameter WOI  = 8;
//     parameter WOF  = 0;
//     parameter ROUND= 1;

//     reg         clk;
//     reg         rstn;
//     reg  [31:0] in;
//     wire [WOI+WOF-1:0] out;
//     wire        overflow;

//     // ʵ��������ģ��
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

//     // ʱ������
//     initial clk = 0;
//     always #5 clk = ~clk;  // 10ns ʱ������

//     // ������������
//     reg [31:0] test_vectors [0:9];
//     integer i;

//     // ����ת real ������ʾ
//     function real float32_to_real;
//         input [31:0] f;
//         real r;
//         begin
//             r = $bitstoreal({ {32{1'b0}}, f }); // ������ʾ��
//             float32_to_real = r;
//         end
//     endfunction

//     initial begin
//         $dumpfile("tb_float2fxp_pipe.vcd");  // ָ�������VCD�ļ���
//         $dumpvars(0, tb_float2fxp_pipe);     // ��¼ tb_float2fxp_pipe �������в�ε��ź�

        
//         // ��λ
//         rstn = 0;
//         in   = 0;
//         #20;
//         rstn = 1;

//         // ���ò��Ը�����
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
//             #10; // �� pipeline һ��ʱ�������ź�
//             // �ӳ����ֱ����ˮ����ɣ�������� pipeline ���=WOI+WOF+3
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

    // ��������
    parameter WOI  = 8;
    parameter WOF  = 0;
    parameter ROUND= 1;

    reg         clk;
    reg         rstn;
    reg  [31:0] in;
    reg         ena;             // ����������Ч�ź�
    wire [WOI+WOF-1:0] out;
    wire        overflow;
    wire        out_valid;       // ���������Ч�ź�

    // ʵ��������ģ��
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

    // ʱ������
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns ʱ������

    // ������������
    reg [31:0] test_vectors [0:9];
    integer i;

    initial begin
        $dumpfile("tb_float2fxp_pipe.vcd");
        $dumpvars(0, tb_float2fxp_pipe);

        // ��λ
        rstn = 0;
        ena  = 0;
        in   = 0;
        #20;
        rstn = 1;

        // ���ò��Ը�����
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
            ena = 1'b1;          // ��ǰ������Ч
            #10;                 // �� pipeline һ��ʱ��
            ena = 1'b0;          // ��һ������ȡ����Ч
            #10;
        end

        // �ȴ���ˮ��������
        #((4+1)*10); // pipeline ���=4�������ʵ�����
        $finish;
    end

    // ��ӡ�����ֻ����Чʱ�̴�ӡ
    always @(posedge clk) begin
        if(out_valid) begin
            $display("Time=%0t | in=0x%08h | out=0x%0h | overflow=%b | valid=%b",
                     $time, in, out, overflow, out_valid);
        end
    end

endmodule
