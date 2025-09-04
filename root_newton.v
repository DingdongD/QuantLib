
// // `timescale 1ns / 1ps

// // Floating-point square root module using Newton-Raphson method
// module fsqrt_newton (
//     input  wire        clk,       // Clock signal
//     input  wire        rstn,      // Active-low reset signal
//     input  wire [31:0] d,         // Radicand (IEEE 754 single-precision)
//     input  wire [1:0]  rm,        // Rounding mode (00: nearest, 01: zero, 10: +inf, 11: -inf)
//     input  wire        fsqrt,     // Square root instruction signal (ID stage)
//     input  wire        ena,       // Enable signal for pipeline
//     output wire [31:0] s,         // Square root result (IEEE 754 single-precision)
//     output wire [25:0] reg_x,     // Current approximation (for simulation)
//     output wire [4:0]  count,     // Iteration counter for Newton-Raphson
//     output wire        busy,      // Busy signal for pipeline control
//     output wire        stall,      // Stall signal for pipeline
//     output reg         valid
// );
//     // IEEE 754 special value constants
//     parameter ZERO = 32'h00000000; // Zero
//     parameter INF  = 32'h7f800000; // Infinity
//     parameter NaN  = 32'h7fc00000; // Not-a-Number

//     // Input analysis for special cases
//     wire        d_expo_is_00 = ~|d[30:23]; // Exponent of d is all zeros (denormalized)
//     wire        d_expo_is_ff = &d[30:23];  // Exponent of d is all ones (Inf/NaN)
//     wire        d_frac_is_00 = ~|d[22:0];  // Fraction of d is zero
//     wire        sign = d[31];              // Sign bit of input

//     // Exponent calculation: e_q = (e_d >> 1) + 63 + (e_d % 2)
//     wire [7:0]  exp_8 = {1'b0, d[30:24]} + 8'd63 + d[23]; // Normalized exponent

//     // Fraction normalization
//     wire [23:0] d_f24 = d_expo_is_00 ? {d[22:0], 1'b0} : {1'b1, d[22:0]}; // Denormalized: .f_d,0; Normalized: .1,f_d
//     wire [23:0] d_temp24 = d[23] ? {1'b0, d_f24[23:1]} : d_f24; // Shift one more bit if exponent is odd
//     wire [23:0] d_frac24; // Normalized fraction: .1xx...x or .01x...x
//     wire [4:0]  shamt_d;  // Shift amount (even number)

//     // Normalize fraction to have MSB = 1x or 01
//     shift_even_bits shift_d (.a(d_temp24), .b(d_frac24), .sa(shamt_d));

//     // Final exponent: denormalized = 63 - shamt_d/2; normalized = exp_8
//     wire [7:0]  exp0 = exp_8 - {4'h0, shamt_d[4:1]};

//     // Pipeline registers for three stages (e1, e2, e3)
//     reg         e1_sign, e2_sign, e3_sign;     // Sign bit
//     reg [1:0]   e1_rm, e2_rm, e3_rm;           // Rounding mode
//     reg [7:0]   e1_exp, e2_exp, e3_exp;        // Exponent
//     reg         e1_e00, e2_e00, e3_e00;       // d exponent = 00
//     reg         e1_eff, e2_eff, e3_eff;       // d exponent = ff
//     reg         e1_f00, e2_f00, e3_f00;       // d fraction = 00

//     // Pipeline register update logic
//     always @(negedge rstn or posedge clk) begin
//         if (!rstn) begin
//             // Reset all pipeline registers
//             e1_sign <= 1'b0; e2_sign <= 1'b0; e3_sign <= 1'b0;
//             e1_rm <= 2'b0; e2_rm <= 2'b0; e3_rm <= 2'b0;
//             e1_exp <= 8'b0; e2_exp <= 8'b0; e3_exp <= 8'b0;
//             e1_e00 <= 1'b0; e2_e00 <= 1'b0; e3_e00 <= 1'b0;
//             e1_eff <= 1'b0; e2_eff <= 1'b0; e3_eff <= 1'b0;
//             e1_f00 <= 1'b0; e2_f00 <= 1'b0; e3_f00 <= 1'b0;
//         end else if (ena) begin
//             // Propagate signals through pipeline stages
//             e1_sign <= sign; e2_sign <= e1_sign; e3_sign <= e2_sign;
//             e1_rm <= rm; e2_rm <= e1_rm; e3_rm <= e2_rm;
//             e1_exp <= exp0; e2_exp <= e1_exp; e3_exp <= e2_exp;
//             e1_e00 <= d_expo_is_00; e2_e00 <= e1_e00; e3_e00 <= e2_e00;
//             e1_eff <= d_expo_is_ff; e2_eff <= e1_eff; e3_eff <= e2_eff;
//             e1_f00 <= d_frac_is_00; e2_f00 <= e1_f00; e3_f00 <= e2_f00;
//         end
//     end


//     // Newton-Raphson square root for fraction
//     wire [31:0] frac0; // Square root result: 1.xxxx...x
//     root_newton24 frac_newton (
//         .d(d_frac24), .fsqrt(fsqrt), .ena(ena), .clk(clk), .rstn(rstn),
//         .q(frac0), .busy(busy), .count(count), .reg_x(reg_x), .stall(stall)
//     );

//     // Rounding logic
//     wire [26:0] frac = {frac0[31:6], |frac0[5:0]}; // Include sticky bit
//     wire        frac_plus_1 = // Rounding decision based on mode
//         (~e3_rm[1] & ~e3_rm[0] & frac[3] & frac[2] & ~frac[1] & ~frac[0]) |
//         (~e3_rm[1] & ~e3_rm[0] & frac[2] & (frac[1] | frac[0])) |
//         (~e3_rm[1] & e3_rm[0] & (frac[2] | frac[1] | frac[0]) & e3_sign) |
//         (e3_rm[1] & ~e3_rm[0] & (frac[2] | frac[1] | frac[0]) & ~e3_sign);
//     wire [24:0] frac_rnd = {1'b0, frac[26:3]} + frac_plus_1;
//     wire [7:0]  expo_new = frac_rnd[24] ? e3_exp + 8'h1 : e3_exp;
//     wire [22:0] frac_new = frac_rnd[24] ? frac_rnd[23:1] : frac_rnd[22:0];

//     // Final result assembly
//     assign s = final_result(e3_sign, e3_e00, e3_eff, e3_f00, {e3_sign, expo_new, frac_new});

//     // Function to handle special cases and compute final result
//     function [31:0] final_result;
//         input        d_sign, d_e00, d_eff, d_f00;
//         input [31:0] calc;
//         casex ({d_sign, d_e00, d_eff, d_f00})
//             4'b1xxx : final_result = NaN;  // Negative input: NaN
//             4'b000x : final_result = calc; // Normalized number
//             4'b0100 : final_result = calc; // Denormalized number
//             4'b0010 : final_result = NaN;  // NaN input
//             4'b0011 : final_result = INF;  // Infinity input
//             default : final_result = ZERO; // Zero or default
//         endcase
//     endfunction


//     always @(posedge clk or negedge rstn) begin
//         if (!rstn)
//             valid <= 1'b0;
//         else begin
//             if (fsqrt & (count==5'b0))
//                 valid <= 1'b0;          // 新输入清除 valid
//             else if (!busy && (count != 5'b0)) 
//                 valid <= 1'b1;          // 迭代完成输出有效
//             else
//                 valid <= 1'b0;          // 计算中或 stall
//         end
//     end

// endmodule

// // Module to shift input by even bits until MSB is 1x or 01
// module shift_even_bits (
//     input  wire [23:0] a,   // Input fraction
//     output wire [23:0] b,   // Normalized fraction (1xx...x or 01x...x)
//     output wire [4:0]  sa   // Shift amount (even number)
// );
//     wire [23:0] a5, a4, a3, a2, a1;

//     assign a5 = a;
//     assign sa[4] = ~|a5[23:8];  // Check for 16-bit zero
//     assign a4 = sa[4] ? {a5[7:0], 16'b0} : a5;
//     assign sa[3] = ~|a4[23:16]; // Check for 8-bit zero
//     assign a3 = sa[3] ? {a4[15:0], 8'b0} : a4;
//     assign sa[2] = ~|a3[23:20]; // Check for 4-bit zero
//     assign a2 = sa[2] ? {a3[19:0], 4'b0} : a3;
//     assign sa[1] = ~|a2[23:22]; // Check for 2-bit zero
//     assign a1 = sa[1] ? {a2[21:0], 2'b0} : a2;
//     assign sa[0] = 1'b0;        // Ensure even shift
//     assign b = a1;
// endmodule

// // Newton-Raphson square root for 24-bit fraction
// module root_newton24 (
//     input  wire [23:0] d,      // Radicand (.1xx...x or .01x...x)
//     input  wire        fsqrt,  // Square root instruction
//     input  wire        ena,    // Enable signal
//     input  wire        clk,    // Clock signal
//     input  wire        rstn,   // Active-low reset
//     output reg  [31:0] q,      // Square root result (.1xxx...x)
//     output reg         busy,   // Busy signal
//     output reg  [4:0]  count, // Iteration counter
//     output reg  [25:0] reg_x, // Current approximation (01.xx...x)
//     output wire        stall   // Pipeline stall signal
// );
//     // Internal registers
//     reg [23:0] reg_d;         // Radicand register
//     reg [25:0] reg_de_x;      // Pipeline register for x (ID to E1)
//     reg [23:0] reg_de_d;      // Pipeline register for d (ID to E1)
//     reg [49:0] a_s;           // Sum register (E1 to E2)
//     reg [49:8] a_c;           // Carry register (E1 to E2)

//     // ROM for initial approximation (1/sqrt(d))
//     function [7:0] rom;
//         input [4:0] d;
//         case (d)
//             5'h08: rom = 8'hff; 5'h09: rom = 8'he1;
//             5'h0a: rom = 8'hc7; 5'h0b: rom = 8'hb1;
//             5'h0c: rom = 8'h9e; 5'h0d: rom = 8'h9e;
//             5'h0e: rom = 8'h7f; 5'h0f: rom = 8'h72;
//             5'h10: rom = 8'h66; 5'h11: rom = 8'h5b;
//             5'h12: rom = 8'h51; 5'h13: rom = 8'h48;
//             5'h14: rom = 8'h3f; 5'h15: rom = 8'h37;
//             5'h16: rom = 8'h30; 5'h17: rom = 8'h29;
//             5'h18: rom = 8'h23; 5'h19: rom = 8'h1d;
//             5'h1a: rom = 8'h17; 5'h1b: rom = 8'h12;
//             5'h1c: rom = 8'h0d; 5'h1d: rom = 8'h08;
//             5'h1e: rom = 8'h04; 5'h1f: rom = 8'h00;
//             default: rom = 8'hff; // 0-7: not accessed
//         endcase
//     endfunction

//     // Newton-Raphson iteration signals
//     wire [7:0]  x0 = rom(d[23:19]); // Initial approximation from ROM
//     wire [51:0] x_2;                // xi * xi
//     wire [51:0] x2d;                // (xi * xi) * d
//     wire [51:0] x52;                // xi * (3 - (xi * xi * d)) / 2
//     wire [49:0] m_s;                // Wallace tree sum
//     wire [49:8] m_c;                // Wallace tree carry
//     wire [7:0]  m_s_low;            // Wallace tree low bits
//     wire [49:0] d_x;                // Final product
//     wire [31:0] e2p;                // Result with sticky bit

//     // Wallace tree multiplications
//     wallace_26x26 x2 (.a(reg_x), .b(reg_x), .z(x_2)); // xi * xi
//     wallace_24x28 xd (.a(reg_d), .b(x_2[51:24]), .z(x2d)); // (xi * xi) * d
//     wire [25:0] b26 = 26'h3000000 - x2d[49:24]; // 3 - (xi * xi * d)
//     wallace_26x26 xip1 (.a(reg_x), .b(b26), .z(x52)); // xi * (3 - (xi * xi * d))
//     wallace_24x26 wt (.a(reg_de_d), .b(reg_de_x), .x(m_s[49:8]), .y(m_c), .z(m_s[7:0])); // d * x

//     // Final result calculation
//     assign d_x = {1'b0, a_s} + {a_c, 8'b0}; // Sum and carry addition
//     assign e2p = {d_x[47:17], |d_x[16:0]}; // Include sticky bit
//     assign stall = fsqrt & (count == 5'b0) | busy;

//     // Newton-Raphson state machine
//     always @(posedge clk or negedge rstn) begin
//         if (!rstn) begin
//             count <= 5'b0;         // Reset counter
//             busy <= 1'b0;          // Clear busy
//             reg_x <= 26'b0;        // Reset approximation
//             reg_d <= 24'b0;        // Reset radicand
//             reg_de_x <= 26'b0;     // Reset pipeline x
//             reg_de_d <= 24'b0;     // Reset pipeline d
//             a_s <= 50'b0;          // Reset sum
//             a_c <= 42'b0;          // Reset carry
//             q <= 32'b0;            // Reset result
//         end else begin
//             if (fsqrt & (count == 5'b0)) begin
//                 count <= 5'b1;     // Start iteration
//                 busy <= 1'b1;      // Set busy
//             end else begin
//                 if (count == 5'h01) begin
//                     reg_x <= {2'b1, x0, 16'b0}; // Initialize x0
//                     reg_d <= d;                 // Store radicand
//                 end
//                 if (count != 5'b0) count <= count + 5'b1; // Increment counter
//                 if (count == 5'h15) busy <= 1'b0;        // Clear busy
//                 if (count == 5'h16) count <= 5'b0;       // Reset counter
//                 if (count == 5'h08 || count == 5'h0f || count == 5'h16)
//                     reg_x <= x52[50:25]; // Update approximation
//             end
//             if (ena) begin
//                 reg_de_x <= x52[50:25]; // Pipeline x
//                 reg_de_d <= reg_d;      // Pipeline d
//                 a_s <= m_s;             // Pipeline sum
//                 a_c <= m_c;             // Pipeline carry
//                 q <= e2p;               // Store result
//             end
//         end
//     end
// endmodule


`timescale 1ns/1ps

// =========================
// fsqrt_newton (pipelined)
// =========================
module fsqrt_newton (
    input  wire        clk,       // Clock signal
    input  wire        rstn,      // Active-low reset signal
    input  wire [31:0] d,         // Radicand (IEEE 754 single-precision)
    input  wire [1:0]  rm,        // Rounding mode (00: nearest, 01: zero, 10: +inf, 11: -inf)
    input  wire        fsqrt,     // Square root instruction signal (ID stage)
    input  wire        ena,       // Enable signal for pipeline
    output wire [31:0] s,         // Square root result (IEEE 754 single-precision)
    output wire [25:0] reg_x,     // Current approximation (for simulation)
    output wire [4:0]  count,     // Iteration counter for Newton-Raphson
    output wire        busy,      // Busy signal for pipeline control
    output wire        stall,     // Stall signal for pipeline
    output reg         valid
);
    // IEEE 754 special value constants
    localparam [31:0] ZERO32 = 32'h00000000; // Zero
    localparam [31:0] INF32  = 32'h7f800000; // Infinity
    localparam [31:0] NaN32  = 32'h7fc00000; // Not-a-Number

    // Input analysis for special cases
    wire        d_expo_is_00 = ~|d[30:23]; // Exponent all zeros (denormalized)
    wire        d_expo_is_ff =  &d[30:23]; // Exponent all ones (Inf/NaN)
    wire        d_frac_is_00 = ~|d[22:0];  // Fraction is zero
    wire        sign         =  d[31];     // Input sign

    // Exponent pre-calc: e_q = floor(e_d/2) + 63  (已在规范化中考虑奇偶)
    wire [7:0]  exp_8 = {1'b0, d[30:24]} + 8'd63 + d[23]; // 若 e_d 为奇数，多加 1

    // Fraction normalization (.1xx...x 或 .01x...x)
    wire [23:0] d_f24    = d_expo_is_00 ? {d[22:0], 1'b0} : {1'b1, d[22:0]}; // 非规约数：.f,0；规约数：1.f
    wire [23:0] d_temp24 = d[23] ? {1'b0, d_f24[23:1]}    : d_f24;           // 若指数为奇数再右移 1
    wire [23:0] d_frac24;
    wire [4:0]  shamt_d;

    // 将输入移动到 1x/01 形式，且仅进行偶数位移动
    shift_even_bits shift_d (.a(d_temp24), .b(d_frac24), .sa(shamt_d));

    // 最终指数：exp0 = exp_8 - (shamt_d/2)
    wire [7:0]  exp0 = exp_8 - {4'h0, shamt_d[4:1]};

    // ---------------------
    // 流水线寄存 (E1/E2/E3)
    // ---------------------
    reg         e1_sign, e2_sign, e3_sign;
    reg  [1:0]  e1_rm,   e2_rm,   e3_rm;
    reg  [7:0]  e1_exp,  e2_exp,  e3_exp;
    reg         e1_e00,  e2_e00,  e3_e00;
    reg         e1_eff,  e2_eff,  e3_eff;
    reg         e1_f00,  e2_f00,  e3_f00;

    // 采样根模块输出 q 进入本模块流水线
    reg [31:0]  e1_q, e2_q, e3_q;

    // 供 special-case 阶段使用的紧凑打包 {exp[7:0], frac[22:0]}
    reg [30:0]  e1_calc, e2_calc, e3_calc;

    // 在 E3 时钟沿寄存的最终字段
    reg [7:0]   e3_exponent;
    reg [22:0]  e3_fraction;

    // 纯寄存的最终输出
    reg [31:0]  s_reg;
    assign s = s_reg;

    // Newton-Raphson sqrt（分数部分），输出 q 为 .1xxx... 形态 + 粘滞位
    wire [31:0] q_raw;
    root_newton24 frac_newton (
        .d(d_frac24), .fsqrt(fsqrt), .ena(ena), .clk(clk), .rstn(rstn),
        .q(q_raw), .busy(busy), .count(count), .reg_x(reg_x), .stall(stall)
    );

    // --------------------------
    // E1 组合计算：calc_next
    // --------------------------
    // 组合中仅做很小的逻辑：将 q(.1xxx.. + sticky) 经舍入拼成 {exp, frac}
    reg [30:0] calc_next;
    // 临时量（模块级声明，避免过程内声明 wire/reg）
    reg [26:0] frac_for_round;
    reg        frac_plus_1_local;
    reg [24:0] frac_rnd_local;
    reg [7:0]  exp1_local;

    always @(*) begin
        // 默认
        calc_next        = 31'b0;
        frac_for_round   = {q_raw[31:6], |q_raw[5:0]};   // 引入 sticky
        // 舍入决策使用当前阶段的 rm/sign（E1）
        frac_plus_1_local =
            (~rm[1] & ~rm[0] & frac_for_round[3] & frac_for_round[2] & ~frac_for_round[1] & ~frac_for_round[0]) |
            (~rm[1] & ~rm[0] & frac_for_round[2] & (frac_for_round[1] | frac_for_round[0])) |
            (~rm[1] &  rm[0] & (|frac_for_round[2:0]) &  sign) |
            ( rm[1] & ~rm[0] & (|frac_for_round[2:0]) & ~sign);

        // 24+1 位加 1 舍入
        frac_rnd_local = {1'b0, frac_for_round[26:3]} + frac_plus_1_local;

        // 舍入进位影响指数（使用 E1 的 exp0）
        exp1_local  = frac_rnd_local[24] ? (exp0 + 8'h1) : exp0;

        // 打包 {exp, frac}（若进位，frac 取右移 1 后高位）
        calc_next = {exp1_local[7:0],
                     (frac_rnd_local[24] ? frac_rnd_local[23:1] : frac_rnd_local[22:0])};
    end

    // --------------------------
    // 流水线寄存与最终结果寄存
    // --------------------------
    always @(negedge rstn or posedge clk) begin
        if (!rstn) begin
            e1_sign <= 1'b0; e2_sign <= 1'b0; e3_sign <= 1'b0;
            e1_rm   <= 2'b0; e2_rm   <= 2'b0; e3_rm   <= 2'b0;
            e1_exp  <= 8'b0; e2_exp  <= 8'b0; e3_exp  <= 8'b0;
            e1_e00  <= 1'b0; e2_e00  <= 1'b0; e3_e00  <= 1'b0;
            e1_eff  <= 1'b0; e2_eff  <= 1'b0; e3_eff  <= 1'b0;
            e1_f00  <= 1'b0; e2_f00  <= 1'b0; e3_f00  <= 1'b0;
            e1_q    <= 32'b0; e2_q   <= 32'b0; e3_q   <= 32'b0;
            e1_calc <= 31'b0; e2_calc<= 31'b0; e3_calc<= 31'b0;
            e3_exponent <= 8'b0; e3_fraction <= 23'b0;
            s_reg <= 32'b0;
        end else if (ena) begin
            // 标志/控制流水
            e1_sign <= sign;     e2_sign <= e1_sign;     e3_sign <= e2_sign;
            e1_rm   <= rm;       e2_rm   <= e1_rm;       e3_rm   <= e2_rm;
            e1_exp  <= exp0;     e2_exp  <= e1_exp;      e3_exp  <= e2_exp;
            e1_e00  <= d_expo_is_00; e2_e00 <= e1_e00;   e3_e00  <= e2_e00;
            e1_eff  <= d_expo_is_ff; e2_eff <= e1_eff;   e3_eff  <= e2_eff;
            e1_f00  <= d_frac_is_00; e2_f00 <= e1_f00;   e3_f00  <= e2_f00;

            // 采样 q、calc 进入流水
            e1_q    <= q_raw;    e2_q    <= e1_q;        e3_q    <= e2_q;
            e1_calc <= calc_next; e2_calc<= e1_calc;     e3_calc <= e2_calc;

            // 在 E3：用 E2 的寄存量做 special-case 判定，并在同一沿寄存结果
            {e3_exponent, e3_fraction} <= final_result_reg(
                e2_sign, e2_e00, e2_eff, e2_f00, e2_calc
            );

            
        end
    end

    // special-case 处理：返回 {exp, frac}
    function [30:0] final_result_reg;
        input        d_sign, d_e00, d_eff, d_f00;
        input [30:0] calc_in; // {exp[7:0], frac[22:0]}
        begin
            casex ({d_sign, d_e00, d_eff, d_f00})
                4'b1xxx: final_result_reg = NaN32[30:0];   // 负数开根 -> NaN
                4'b000x: final_result_reg = calc_in;       // 规约数
                4'b0100: final_result_reg = calc_in;       // 非规约数
                4'b0010: final_result_reg = NaN32[30:0];   // 输入 NaN
                4'b0011: final_result_reg = INF32[30:0];   // 输入 Inf
                default: final_result_reg = ZERO32[30:0];  // 零或默认
            endcase
        end
    endfunction

    // valid 与 busy/count 的时序关系保持不变
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s_reg <= 32'b0;
            valid <= 1'b0;
        end
        else begin
            if (fsqrt & (count==5'b0))

                valid <= 1'b0;          // 新输入清除 valid
            else if (!busy && (count != 5'b0)) begin
            // 纯寄存输出
            s_reg <= {e3_sign, e3_exponent, e3_fraction};
            valid <= 1'b1;          // 迭代完成输出有效
            end
                
            else
                valid <= 1'b0;          // 计算中或 stall
        end
    end
endmodule

// =========================================
// Module to shift input by even bits until
// MSB is 1x or 01 (normalization helper)
// =========================================
module shift_even_bits (
    input  wire [23:0] a,   // Input fraction
    output wire [23:0] b,   // Normalized fraction (1xx...x or 01x...x)
    output wire [4:0]  sa   // Shift amount (even number)
);
    wire [23:0] a5, a4, a3, a2, a1;

    assign a5 = a;
    assign sa[4] = ~|a5[23:8];          // 需要 16 位移？
    assign a4   = sa[4] ? {a5[7:0], 16'b0} : a5;

    assign sa[3] = ~|a4[23:16];         // 需要 8 位移？
    assign a3   = sa[3] ? {a4[15:0], 8'b0} : a4;

    assign sa[2] = ~|a3[23:20];         // 需要 4 位移？
    assign a2   = sa[2] ? {a3[19:0], 4'b0} : a3;

    assign sa[1] = ~|a2[23:22];         // 需要 2 位移？
    assign a1   = sa[1] ? {a2[21:0], 2'b0} : a2;

    assign sa[0] = 1'b0;                // 仅偶数位移
    assign b = a1;
endmodule

// ==========================================
// root_newton24 (pipelined, registered out)
// ==========================================
module root_newton24 (
    input  wire [23:0] d,      // Radicand (.1xx...x or .01x...x)
    input  wire        fsqrt,  // Square root instruction
    input  wire        ena,    // Enable signal
    input  wire        clk,    // Clock signal
    input  wire        rstn,   // Active-low reset
    output reg  [31:0] q,      // Square root result (.1xxx...x with sticky) - registered
    output reg         busy,   // Busy signal - registered
    output reg  [4:0]  count,  // Iteration counter - registered
    output reg  [25:0] reg_x,  // Current approximation (01.xx...x) - registered
    output reg         stall   // Pipeline stall signal - registered
);
    // Internal registers
    reg [23:0] reg_d;         // Radicand register
    reg [25:0] reg_de_x;      // Pipeline register for x (ID to E1)
    reg [23:0] reg_de_d;      // Pipeline register for d (ID to E1)
    reg [49:0] a_s;           // Sum register (E1 to E2)
    reg [49:8] a_c;           // Carry register (E1 to E2)

    // ROM for initial approximation (1/sqrt(d))
    function [7:0] rom;
        input [4:0] dsel;
        case (dsel)
            5'h08: rom = 8'hff; 5'h09: rom = 8'he1;
            5'h0a: rom = 8'hc7; 5'h0b: rom = 8'hb1;
            5'h0c: rom = 8'h9e; 5'h0d: rom = 8'h9e;
            5'h0e: rom = 8'h7f; 5'h0f: rom = 8'h72;
            5'h10: rom = 8'h66; 5'h11: rom = 8'h5b;
            5'h12: rom = 8'h51; 5'h13: rom = 8'h48;
            5'h14: rom = 8'h3f; 5'h15: rom = 8'h37;
            5'h16: rom = 8'h30; 5'h17: rom = 8'h29;
            5'h18: rom = 8'h23; 5'h19: rom = 8'h1d;
            5'h1a: rom = 8'h17; 5'h1b: rom = 8'h12;
            5'h1c: rom = 8'h0d; 5'h1d: rom = 8'h08;
            5'h1e: rom = 8'h04; 5'h1f: rom = 8'h00;
            default: rom = 8'hff; // 0-7: not accessed
        endcase
    endfunction

    // Newton-Raphson iteration signals
    wire [7:0]  x0   = rom(d[23:19]);   // Initial approximation from ROM
    wire [51:0] x_2;                    // xi * xi
    wire [51:0] x2d;                    // (xi * xi) * d
    wire [51:0] x52;                    // xi * (3 - (xi * xi * d))
    wire [49:0] m_s;                    // Wallace tree sum
    wire [49:8] m_c;                    // Wallace tree carry
    wire [49:0] d_x_sum_next;           // Final product sum (carry+sum)
    wire [31:0] e2p_next;               // Result with sticky bit (next)

    // Wallace tree multiplications (外部模块需提供)
    wallace_26x26 x2   (.a(reg_x),  .b(reg_x),     .z(x_2));         // xi * xi
    wallace_24x28 xd   (.a(reg_d),  .b(x_2[51:24]), .z(x2d));        // (xi * xi) * d
    wire [25:0] b26 = 26'h3000000 - x2d[49:24];                      // 3 - (xi * xi * d)
    wallace_26x26 xip1 (.a(reg_x),  .b(b26),       .z(x52));         // xi * (3 - (xi * xi * d))
    wallace_24x26 wt   (.a(reg_de_d), .b(reg_de_x), .x(m_s[49:8]), .y(m_c), .z(m_s[7:0])); // d * x

    // 将 Wallace tree 的 sum/carry 合成，并加入 sticky
    assign d_x_sum_next = {1'b0, a_s} + {a_c, 8'b0};            // 50 + 50 → 50
    assign e2p_next     = {d_x_sum_next[47:17], |d_x_sum_next[16:0]}; // 31+1（粘滞位）

    // 时序控制与流水寄存
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count   <= 5'b0;
            busy    <= 1'b0;
            reg_x   <= 26'b0;
            reg_d   <= 24'b0;
            reg_de_x<= 26'b0;
            reg_de_d<= 24'b0;
            a_s     <= 50'b0;
            a_c     <= 42'b0;
            q       <= 32'b0;
            stall   <= 1'b0;
        end else begin
            // 启动/停止条件
            if (fsqrt & (count == 5'b0)) begin
                count <= 5'b1;
                busy  <= 1'b1;
            end else begin
                if (count == 5'h01) begin
                    reg_x <= {2'b01, x0, 16'b0}; // 初始化 x0（01.xx... 形态）
                    reg_d <= d;                  // 缓存被开方数
                end
                if (count != 5'b0) count <= count + 5'b1;
                if (count == 5'h15) busy <= 1'b0;
                if (count == 5'h16) count <= 5'b0;

                // 在若干迭代点更新逼近（与原实现一致）
                if (count == 5'h08 || count == 5'h0f || count == 5'h16)
                    reg_x <= x52[50:25];
            end

            // 流水寄存（仅在 ena 时推进）
            if (ena) begin
                reg_de_x <= x52[50:25];
                reg_de_d <= reg_d;
                a_s      <= m_s;
                a_c      <= m_c;
                q        <= e2p_next;   // 把合并并带 sticky 的结果寄存到 q
            end

            // stall 采用寄存输出，避免组合跨模块
            stall <= (fsqrt & (count == 5'b0)) | busy;
        end
    end
endmodule
