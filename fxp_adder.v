// `include "csa.v"
// // Qm.n 定点加法器基于 CSA，带溢出饱和处理
// module fixed_add_csa #(
//     parameter WIDTH = 16  // 总位宽
// )(
//     input  signed [WIDTH-1:0] a,
//     input  signed [WIDTH-1:0] b,
//     output signed [WIDTH-1:0] sum
// );

//     wire [WIDTH-1:0] s_bits, c_bits;
//     wire [WIDTH-1:0] tmp_sum;
//     wire carry_out;

//     genvar i;

//     // 单个位 CSA
//     generate
//         for (i=0; i<WIDTH; i=i+1) begin : bit_csa
//             csa bit_csa_inst (
//                 .a(a[i]),
//                 .b(b[i]),
//                 .ci(1'b0),   // 两数加法，ci=0
//                 .s(s_bits[i]),
//                 .c(c_bits[i])
//             );
//         end
//     endgenerate

//     // 将 sum 和 carry 合并成最终结果（RCA 方式）
//     assign {carry_out, tmp_sum} = s_bits + (c_bits << 1);

//     // 最大/最小值用于饱和
//     localparam signed [WIDTH-1:0] MAX_VAL = {1'b0, {(WIDTH-1){1'b1}}};
//     localparam signed [WIDTH-1:0] MIN_VAL = {1'b1, {(WIDTH-1){1'b0}}};

//     assign sum = (tmp_sum > MAX_VAL) ? MAX_VAL :
//                  (tmp_sum < MIN_VAL) ? MIN_VAL :
//                  tmp_sum;

// endmodule

// module fixed_add_pipeline #(
//     parameter WIDTH = 16,    // 总位宽
//     parameter FRAC_BITS = 8  // 小数位数 (n)
// )(
//     input  clk,
//     input  rst_n,
//     input  signed [WIDTH-1:0] a,
//     input  signed [WIDTH-1:0] b,
//     output reg signed [WIDTH-1:0] sum,
//     output reg overflow
// );

//     // Pipeline stage 1: CSA计算
//     reg signed [WIDTH-1:0] a_r1, b_r1;
//     reg [WIDTH-1:0] s_bits, c_bits;
    
//     // Pipeline stage 2: 进位传播加法
//     reg signed [WIDTH:0] tmp_sum_r2;  // 多一位用于溢出检测
    
//     // Pipeline stage 3: 饱和处理
//     reg signed [WIDTH-1:0] final_sum_r3;
//     reg overflow_r3;
    
//     // 最大/最小值定义
//     localparam signed [WIDTH-1:0] MAX_VAL = {1'b0, {(WIDTH-1){1'b1}}};  // 0111...1
//     localparam signed [WIDTH-1:0] MIN_VAL = {1'b1, {(WIDTH-1){1'b0}}};  // 1000...0
    
//     genvar i;
//     integer j;
//     // Stage 1: CSA并行计算
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             a_r1 <= 0;
//             b_r1 <= 0;
//             s_bits <= 0;
//             c_bits <= 0;
//         end else begin
//             a_r1 <= a;
//             b_r1 <= b;
//             // 并行CSA计算
//             for (j = 0; j < WIDTH; j = j + 1) begin
//                 s_bits[j] <= a[j] ^ b[j];           // sum位
//                 c_bits[j] <= a[j] & b[j];           // carry位
//             end
//         end
//     end
    
//     // Stage 2: 进位传播加法
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             tmp_sum_r2 <= 0;
//         end else begin
//             // 将sum bits和carry bits相加，carry bits左移一位
//             tmp_sum_r2 <= {1'b0, s_bits} + {c_bits, 1'b0};
//         end
//     end
    
//     // Stage 3: 溢出检测和饱和处理
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             final_sum_r3 <= 0;
//             overflow_r3 <= 0;
//         end else begin
//             // 检测溢出：符号位扩展后的结果与原结果不同
//             if (tmp_sum_r2[WIDTH] != tmp_sum_r2[WIDTH-1]) begin
//                 // 发生溢出
//                 overflow_r3 <= 1;
//                 if (tmp_sum_r2[WIDTH]) begin
//                     // 负溢出，饱和到最小值
//                     final_sum_r3 <= MIN_VAL;
//                 end else begin
//                     // 正溢出，饱和到最大值
//                     final_sum_r3 <= MAX_VAL;
//                 end
//             end else begin
//                 // 无溢出
//                 overflow_r3 <= 0;
//                 final_sum_r3 <= tmp_sum_r2[WIDTH-1:0];
//             end
//         end
//     end
    
//     // 输出赋值
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

// // 无ena控制
// module fixed_add_pipeline #(
//     parameter WIDTH = 16,    // 总位宽
//     parameter FRAC_BITS = 8  // 小数位数 (n)
// )(
//     input  clk,
//     input  rst_n,
//     input  signed [WIDTH-1:0] a,
//     input  signed [WIDTH-1:0] b,
//     output reg signed [WIDTH-1:0] sum,
//     output reg overflow
// );

//     // Pipeline stage 1: CSA计算
//     reg signed [WIDTH-1:0] a_r1, b_r1;
//     reg [WIDTH-1:0] s_bits, c_bits;
    
//     // Pipeline stage 2: 进位传播加法
//     reg signed [WIDTH:0] tmp_sum_r2;  // 多一位用于溢出检测
    
//     // Pipeline stage 3: 饱和处理
//     reg signed [WIDTH-1:0] final_sum_r3;
//     reg overflow_r3;
    
//     // 最大/最小值定义
//     localparam signed [WIDTH-1:0] MAX_VAL = {1'b0, {(WIDTH-1){1'b1}}};  // 0111...1
//     localparam signed [WIDTH-1:0] MIN_VAL = {1'b1, {(WIDTH-1){1'b0}}};  // 1000...0
    
//     genvar i;
    
//     // Stage 1: 输入寄存
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             a_r1 <= 0;
//             b_r1 <= 0;
//         end else begin
//             a_r1 <= a;
//             b_r1 <= b;
//         end
//     end
    
//     // Stage 2: 进位传播加法
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             tmp_sum_r2 <= 0;
//         end else begin
//             // 有符号加法，保持符号扩展
//             tmp_sum_r2 <= $signed({a_r1[WIDTH-1], a_r1}) + $signed({b_r1[WIDTH-1], b_r1});
//         end
//     end
    
//     // Stage 3: 溢出检测和饱和处理
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             final_sum_r3 <= 0;
//             overflow_r3 <= 0;
//         end else begin
//             // 检测溢出：符号位扩展后的结果与原结果不同
//             if (tmp_sum_r2[WIDTH] != tmp_sum_r2[WIDTH-1]) begin
//                 // 发生溢出
//                 overflow_r3 <= 1;
//                 if (tmp_sum_r2[WIDTH]) begin
//                     // 负溢出，饱和到最小值
//                     final_sum_r3 <= MIN_VAL;
//                 end else begin
//                     // 正溢出，饱和到最大值
//                     final_sum_r3 <= MAX_VAL;
//                 end
//             end else begin
//                 // 无溢出
//                 overflow_r3 <= 0;
//                 final_sum_r3 <= tmp_sum_r2[WIDTH-1:0];
//             end
//         end
//     end
    
//     // 输出赋值
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
    parameter WIDTH = 16,    // 总位宽
    parameter FRAC_BITS = 8  // 小数位数 (n)
)(
    input  clk,
    input  rst_n,
    input  ena,                           // 输入数据有效
    input  signed [WIDTH-1:0] a,
    input  signed [WIDTH-1:0] b,
    output reg signed [WIDTH-1:0] sum,
    output reg overflow,
    output reg out_valid                  // 输出数据有效
);

    // Pipeline stage 1: CSA计算
    reg signed [WIDTH-1:0] a_r1, b_r1;
    reg ena_r1;
    
    // Pipeline stage 2: 进位传播加法
    reg signed [WIDTH:0] tmp_sum_r2;  // 多一位用于溢出检测
    reg ena_r2;
    
    // Pipeline stage 3: 饱和处理
    reg signed [WIDTH-1:0] final_sum_r3;
    reg overflow_r3;
    reg ena_r3;
    
    // 最大/最小值定义
    localparam signed [WIDTH-1:0] MAX_VAL = {1'b0, {(WIDTH-1){1'b1}}};  // 0111...1
    localparam signed [WIDTH-1:0] MIN_VAL = {1'b1, {(WIDTH-1){1'b0}}};  // 1000...0
    
    // Stage 1: 输入寄存
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
    
    // Stage 2: 加法
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
    
    // Stage 3: 溢出检测和饱和
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
    
    // 输出赋值
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
