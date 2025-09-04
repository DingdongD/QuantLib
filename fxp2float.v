// ��������汾�ʺ�Q8.8��ʽ�Ķ�����ת��
// // Qm.n ������ -> IEEE754 �����ȸ�����
// module fxp2float #(
//     parameter N = 16,       // ������λ��
//     parameter FRAC = 8      // С��λ��
// )(
//     input  wire [N-1:0] fxp,
//     output reg  [31:0] fp
// );

//     reg signed [N-1:0] s_int;
//     reg [N-1:0] abs_val;
//     reg [31:0] mantissa_long;
//     reg [7:0] exponent;
//     reg [22:0] mantissa;
//     reg sign;
//     integer i;

//     // �������λ1λ��
//     function integer highest_bit_pos;
//         input [N-1:0] val;
//         integer j;
//         begin
//             highest_bit_pos = -1;
//             for (j = N-1; j >= 0; j = j-1) begin
//                 if (val[j] == 1 && highest_bit_pos == -1)
//                     highest_bit_pos = j;
//             end
//         end
//     endfunction

//     always @(*) begin
//         s_int = fxp;
//         sign = (s_int < 0);
//         abs_val = sign ? -s_int : s_int;

//         if (abs_val == 0) begin
//             fp = 32'h00000000;
//         end else begin
//             // �ҵ����λ1��λ��
//             i = highest_bit_pos(abs_val);

//             // ָ�� = 127 + (���λλ��) - С��λ��
//             exponent = 127 + i - FRAC; // ���ﻹ��Ҫ��ȥ127 �Է���IEEE754ƫ���� ������������+

//             // ���β��: �����λ1���Ƶ�����λλ�ã�Ȼ��ȡ23λ
//             mantissa_long = abs_val << (23 - i);
//             mantissa = mantissa_long[22:0];

//             fp = {sign, exponent, mantissa};
//         end
//     end

// endmodule


// `timescale 1ns / 1ps
// // ͨ�� Qm.n ������ -> IEEE754 �����ȸ�����
// module fxp2float #(
//     parameter N = 16,       // ��λ�� = m + n
//     parameter FRAC = 8      // С��λ�� = n
// )(
//     input  wire [N-1:0] fxp,  // ��������
//     output reg  [31:0] fp     // �������
// );

//     reg signed [N-1:0] s_int;
//     reg [N-1:0] abs_val;
//     reg [31:0] mantissa_long;
//     reg [7:0] exponent;
//     reg [22:0] mantissa;
//     reg sign;
//     integer int_msb;  // �����������λλ��
//     integer shift;

//     // ���������������λ1��0-based��LSB=0��
//     function integer highest_int_bit;
//         input [N-1:0] val;
//         integer j;
//         begin
//             highest_int_bit = -1;
//             // �����������λ�����λ����
//             for (j = N-1; j >= 0; j = j-1) begin
//                 if (val[j] == 1 && highest_int_bit == -1)
//                     highest_int_bit = j;
//             end
//         end
//     endfunction

//     always @(*) begin
//         s_int = fxp;
//         sign = s_int[N-1];
//         abs_val = sign ? -s_int : s_int;

//         if (abs_val == 0) begin
//             fp = 32'h00000000;
//         end else begin
//             // �������Чλ
//             int_msb = highest_int_bit(abs_val);

//             // ָ�� = 127 + (���λλ�� - FRAC)
//             exponent = 127 + int_msb - FRAC;

//             // β����񻯣������λ�Ƶ�����λλ��
//             shift = 23 - int_msb;
//             mantissa_long = abs_val;
//             if (shift >= 0)
//                 mantissa_long = mantissa_long << shift;
//             else
//                 mantissa_long = mantissa_long >> (-shift);

//             mantissa = mantissa_long[22:0];

//             fp = {sign, exponent, mantissa};
//         end
//     end

// endmodule

module fxp2float_pipeline #(
    parameter N = 16,      // ������λ��
    parameter FRAC = 8     // С��λ
)(
    input  wire clk,
    input  wire rstn,
    input  wire [N-1:0] fxp_in,
    input  wire valid_in,
    output reg [31:0] fp_out,
    output reg valid_out
);

    // ===== Stage 1: ���Ŵ��� =====
    reg [N-1:0] abs_val_s1;
    reg sign_s1;
    reg valid_s1;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            abs_val_s1 <= 0;
            sign_s1 <= 0;
            valid_s1 <= 0;
        end else begin
            sign_s1 <= fxp_in[N-1];
            abs_val_s1 <= fxp_in[N-1] ? -fxp_in : fxp_in;
            valid_s1 <= valid_in;
        end
    end

    // ===== Stage 2: �������Чλ (MSB) =====
    reg [N-1:0] abs_val_s2;
    reg sign_s2;
    reg valid_s2;
    reg [4:0] msb_pos_s2;  // ֧�� N<=32
    integer i;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            abs_val_s2 <= 0;
            sign_s2 <= 0;
            valid_s2 <= 0;
            msb_pos_s2 <= 0;
        end else begin
            abs_val_s2 <= abs_val_s1;
            sign_s2 <= sign_s1;
            valid_s2 <= valid_s1;

            msb_pos_s2 = 0;
            for(i=N-1; i>=0; i=i-1) begin
                if(abs_val_s1[i] == 1 && msb_pos_s2 == 0) begin
                    msb_pos_s2 = i;
                end
            end
        end
    end

    // ===== Stage 3: ָ����β�� =====
    reg [7:0] exponent_s3;
    reg [22:0] mantissa_s3;
    reg sign_s3;
    reg valid_s3;
    reg [31:0] mantissa_long_s3;
    integer shift_s3;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            exponent_s3 <= 0;
            mantissa_s3 <= 0;
            sign_s3 <= 0;
            valid_s3 <= 0;
        end else begin
            sign_s3 <= sign_s2;
            valid_s3 <= valid_s2;

            if(abs_val_s2 == 0) begin
                exponent_s3 <= 0;
                mantissa_s3 <= 0;
            end else begin
                exponent_s3 <= 127 + msb_pos_s2 - FRAC;

                shift_s3 = 23 - msb_pos_s2;
                mantissa_long_s3 = shift_s3 >= 0 ? (abs_val_s2 << shift_s3) : (abs_val_s2 >> (-shift_s3));
                mantissa_s3 <= mantissa_long_s3[22:0];
            end
        end
    end

    // ===== Stage 4: ������ =====
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            fp_out <= 0;
            valid_out <= 0;
        end else begin
            fp_out <= {sign_s3, exponent_s3, mantissa_s3};
            valid_out <= valid_s3;
        end
    end

endmodule
