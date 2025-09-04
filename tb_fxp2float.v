`timescale 1ns/1ps
`include "fxp2float.v"
// module tb_fxp2float;

//     reg  [15:0] fxp;       // ���붨����
//     wire [31:0] fp;        // ���������

//     // ʵ���� DUT
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
//             #1;  // �ȴ�����߼��ȶ�
//             $display("time=%0t | fxp=0x%04h | fp=0x%08h", $time, fxp, fp);
//         end
//     endtask

//     initial begin
//         $display("=== Fixed-point to IEEE754 Float Conversion Test ===");

//         // �������ֵ (Q8.8 ��ʽ)
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

    // ===== �������� =====
    parameter N = 16;
    parameter FRAC = 8;

    reg clk;
    reg rstn;
    reg [N-1:0] fxp_in;
    reg valid_in;

    wire [31:0] fp_out;
    wire valid_out;

    // ===== �����Զ������� =====
    reg [N-1:0] test_values [0:6];
    integer i;

    // ===== ʱ������ =====
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns ʱ������

    // ===== ģ��ʵ���� =====
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

    // ===== �������ݳ�ʼ�� =====
    initial begin
        // Q4.12 ʾ��
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

        // ===== ι����ˮ�� =====
        for(i=0;i<7;i=i+1) begin
            @(posedge clk);
            fxp_in <= test_values[i];
            valid_in <= 1;
        end

        // ��������
        @(posedge clk);
        valid_in <= 0;

        // �ȴ���ˮ��������
        repeat(10) @(posedge clk);

        $finish;
    end

    // ===== �����ʾ =====
    always @(posedge clk) begin
        if(valid_out) begin
            $display("time=%0t | fxp=0x%04X | fp=0x%08X", $time, fxp_in, fp_out);
        end
    end

endmodule
