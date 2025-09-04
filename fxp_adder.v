// `include "csa.v"
// // Qm.n ����ӷ������� CSA����������ʹ���
// module fixed_add_csa #(
//     parameter WIDTH = 16  // ��λ��
// )(
//     input  signed [WIDTH-1:0] a,
//     input  signed [WIDTH-1:0] b,
//     output signed [WIDTH-1:0] sum
// );

//     wire [WIDTH-1:0] s_bits, c_bits;
//     wire [WIDTH-1:0] tmp_sum;
//     wire carry_out;

//     genvar i;

//     // ����λ CSA
//     generate
//         for (i=0; i<WIDTH; i=i+1) begin : bit_csa
//             csa bit_csa_inst (
//                 .a(a[i]),
//                 .b(b[i]),
//                 .ci(1'b0),   // �����ӷ���ci=0
//                 .s(s_bits[i]),
//                 .c(c_bits[i])
//             );
//         end
//     endgenerate

//     // �� sum �� carry �ϲ������ս����RCA ��ʽ��
//     assign {carry_out, tmp_sum} = s_bits + (c_bits << 1);

//     // ���/��Сֵ���ڱ���
//     localparam signed [WIDTH-1:0] MAX_VAL = {1'b0, {(WIDTH-1){1'b1}}};
//     localparam signed [WIDTH-1:0] MIN_VAL = {1'b1, {(WIDTH-1){1'b0}}};

//     assign sum = (tmp_sum > MAX_VAL) ? MAX_VAL :
//                  (tmp_sum < MIN_VAL) ? MIN_VAL :
//                  tmp_sum;

// endmodule

// module fixed_add_pipeline #(
//     parameter WIDTH = 16,    // ��λ��
//     parameter FRAC_BITS = 8  // С��λ�� (n)
// )(
//     input  clk,
//     input  rst_n,
//     input  signed [WIDTH-1:0] a,
//     input  signed [WIDTH-1:0] b,
//     output reg signed [WIDTH-1:0] sum,
//     output reg overflow
// );

//     // Pipeline stage 1: CSA����
//     reg signed [WIDTH-1:0] a_r1, b_r1;
//     reg [WIDTH-1:0] s_bits, c_bits;
    
//     // Pipeline stage 2: ��λ�����ӷ�
//     reg signed [WIDTH:0] tmp_sum_r2;  // ��һλ����������
    
//     // Pipeline stage 3: ���ʹ���
//     reg signed [WIDTH-1:0] final_sum_r3;
//     reg overflow_r3;
    
//     // ���/��Сֵ����
//     localparam signed [WIDTH-1:0] MAX_VAL = {1'b0, {(WIDTH-1){1'b1}}};  // 0111...1
//     localparam signed [WIDTH-1:0] MIN_VAL = {1'b1, {(WIDTH-1){1'b0}}};  // 1000...0
    
//     genvar i;
//     integer j;
//     // Stage 1: CSA���м���
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             a_r1 <= 0;
//             b_r1 <= 0;
//             s_bits <= 0;
//             c_bits <= 0;
//         end else begin
//             a_r1 <= a;
//             b_r1 <= b;
//             // ����CSA����
//             for (j = 0; j < WIDTH; j = j + 1) begin
//                 s_bits[j] <= a[j] ^ b[j];           // sumλ
//                 c_bits[j] <= a[j] & b[j];           // carryλ
//             end
//         end
//     end
    
//     // Stage 2: ��λ�����ӷ�
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             tmp_sum_r2 <= 0;
//         end else begin
//             // ��sum bits��carry bits��ӣ�carry bits����һλ
//             tmp_sum_r2 <= {1'b0, s_bits} + {c_bits, 1'b0};
//         end
//     end
    
//     // Stage 3: ������ͱ��ʹ���
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             final_sum_r3 <= 0;
//             overflow_r3 <= 0;
//         end else begin
//             // ������������λ��չ��Ľ����ԭ�����ͬ
//             if (tmp_sum_r2[WIDTH] != tmp_sum_r2[WIDTH-1]) begin
//                 // �������
//                 overflow_r3 <= 1;
//                 if (tmp_sum_r2[WIDTH]) begin
//                     // ����������͵���Сֵ
//                     final_sum_r3 <= MIN_VAL;
//                 end else begin
//                     // ����������͵����ֵ
//                     final_sum_r3 <= MAX_VAL;
//                 end
//             end else begin
//                 // �����
//                 overflow_r3 <= 0;
//                 final_sum_r3 <= tmp_sum_r2[WIDTH-1:0];
//             end
//         end
//     end
    
//     // �����ֵ
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             sum <= 0;
//             overflow <= 0;
//         end else begin
//             sum <= final_sum_r3;
//             overflow <= overflow_r3;
//         end
//     end

// endmodule

// // ��ena����
// module fixed_add_pipeline #(
//     parameter WIDTH = 16,    // ��λ��
//     parameter FRAC_BITS = 8  // С��λ�� (n)
// )(
//     input  clk,
//     input  rst_n,
//     input  signed [WIDTH-1:0] a,
//     input  signed [WIDTH-1:0] b,
//     output reg signed [WIDTH-1:0] sum,
//     output reg overflow
// );

//     // Pipeline stage 1: CSA����
//     reg signed [WIDTH-1:0] a_r1, b_r1;
//     reg [WIDTH-1:0] s_bits, c_bits;
    
//     // Pipeline stage 2: ��λ�����ӷ�
//     reg signed [WIDTH:0] tmp_sum_r2;  // ��һλ����������
    
//     // Pipeline stage 3: ���ʹ���
//     reg signed [WIDTH-1:0] final_sum_r3;
//     reg overflow_r3;
    
//     // ���/��Сֵ����
//     localparam signed [WIDTH-1:0] MAX_VAL = {1'b0, {(WIDTH-1){1'b1}}};  // 0111...1
//     localparam signed [WIDTH-1:0] MIN_VAL = {1'b1, {(WIDTH-1){1'b0}}};  // 1000...0
    
//     genvar i;
    
//     // Stage 1: ����Ĵ�
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             a_r1 <= 0;
//             b_r1 <= 0;
//         end else begin
//             a_r1 <= a;
//             b_r1 <= b;
//         end
//     end
    
//     // Stage 2: ��λ�����ӷ�
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             tmp_sum_r2 <= 0;
//         end else begin
//             // �з��żӷ������ַ�����չ
//             tmp_sum_r2 <= $signed({a_r1[WIDTH-1], a_r1}) + $signed({b_r1[WIDTH-1], b_r1});
//         end
//     end
    
//     // Stage 3: ������ͱ��ʹ���
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             final_sum_r3 <= 0;
//             overflow_r3 <= 0;
//         end else begin
//             // ������������λ��չ��Ľ����ԭ�����ͬ
//             if (tmp_sum_r2[WIDTH] != tmp_sum_r2[WIDTH-1]) begin
//                 // �������
//                 overflow_r3 <= 1;
//                 if (tmp_sum_r2[WIDTH]) begin
//                     // ����������͵���Сֵ
//                     final_sum_r3 <= MIN_VAL;
//                 end else begin
//                     // ����������͵����ֵ
//                     final_sum_r3 <= MAX_VAL;
//                 end
//             end else begin
//                 // �����
//                 overflow_r3 <= 0;
//                 final_sum_r3 <= tmp_sum_r2[WIDTH-1:0];
//             end
//         end
//     end
    
//     // �����ֵ
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             sum <= 0;
//             overflow <= 0;
//         end else begin
//             sum <= final_sum_r3;
//             overflow <= overflow_r3;
//         end
//     end

// endmodule




module fixed_add_pipeline #(
    parameter WIDTH = 16,    // ��λ��
    parameter FRAC_BITS = 8  // С��λ�� (n)
)(
    input  clk,
    input  rst_n,
    input  ena,                           // ����������Ч
    input  signed [WIDTH-1:0] a,
    input  signed [WIDTH-1:0] b,
    output reg signed [WIDTH-1:0] sum,
    output reg overflow,
    output reg out_valid                  // ���������Ч
);

    // Pipeline stage 1: CSA����
    reg signed [WIDTH-1:0] a_r1, b_r1;
    reg ena_r1;
    
    // Pipeline stage 2: ��λ�����ӷ�
    reg signed [WIDTH:0] tmp_sum_r2;  // ��һλ����������
    reg ena_r2;
    
    // Pipeline stage 3: ���ʹ���
    reg signed [WIDTH-1:0] final_sum_r3;
    reg overflow_r3;
    reg ena_r3;
    
    // ���/��Сֵ����
    localparam signed [WIDTH-1:0] MAX_VAL = {1'b0, {(WIDTH-1){1'b1}}};  // 0111...1
    localparam signed [WIDTH-1:0] MIN_VAL = {1'b1, {(WIDTH-1){1'b0}}};  // 1000...0
    
    // Stage 1: ����Ĵ�
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_r1 <= 0;
            b_r1 <= 0;
            ena_r1 <= 0;
        end else if (ena) begin
            a_r1 <= a;
            b_r1 <= b;
            ena_r1 <= 1'b1;
        end else begin
            ena_r1 <= 1'b0;
        end
    end
    
    // Stage 2: �ӷ�
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tmp_sum_r2 <= 0;
            ena_r2 <= 0;
        end else begin
            ena_r2 <= ena_r1;
            if (ena_r1) begin
                tmp_sum_r2 <= $signed({a_r1[WIDTH-1], a_r1}) + 
                               $signed({b_r1[WIDTH-1], b_r1});
            end
        end
    end
    
    // Stage 3: ������ͱ���
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_sum_r3 <= 0;
            overflow_r3 <= 0;
            ena_r3 <= 0;
        end else begin
            ena_r3 <= ena_r2;
            if (ena_r2) begin
                if (tmp_sum_r2[WIDTH] != tmp_sum_r2[WIDTH-1]) begin
                    overflow_r3 <= 1;
                    if (tmp_sum_r2[WIDTH])
                        final_sum_r3 <= MIN_VAL;
                    else
                        final_sum_r3 <= MAX_VAL;
                end else begin
                    overflow_r3 <= 0;
                    final_sum_r3 <= tmp_sum_r2[WIDTH-1:0];
                end
            end
        end
    end
    
    // �����ֵ
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 0;
            overflow <= 0;
            out_valid <= 0;
        end else begin
            sum <= final_sum_r3;
            overflow <= overflow_r3;
            out_valid <= ena_r3;
        end
    end

endmodule
