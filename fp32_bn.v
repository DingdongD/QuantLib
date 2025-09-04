// module fp32_batchnorm (
//     input  wire        clk,
//     input  wire        rstn,
//     input  wire        ena,        // pipeline enable
//     input  wire [31:0] x,          // 输入数据
//     input  wire [31:0] mu,         // 均值
//     input  wire [31:0] var,        // 方差
//     input  wire [31:0] gamma,      // scale
//     input  wire [31:0] beta,       // shift
//     input  wire [31:0] eps,        // epsilon
//     input  wire [1:0]  rm,         // rounding mode
//     output wire [31:0] y           // batchnorm结果
// );

//     // ---------------------------------------
//     // Step1: sub = x - mu
//     // ---------------------------------------
//     wire [31:0] sub;

//     fp32_adder u_sub (
//         .a(x),
//         .b(mu),
//         .rm(rm),
//         .sel(1'b1),   // subtract
//         .s(sub)
//     );

//     // ---------------------------------------
//     // Step2: var_eps = var + eps
//     // ---------------------------------------
//     wire [31:0] var_eps;

//     fp32_adder u_var_eps (
//         .a(var),
//         .b(eps),
//         .rm(rm),
//         .sel(1'b0),   // add
//         .s(var_eps)
//     );

//     // ---------------------------------------
//     // Step3: sqrt_val = sqrt(var + eps)  batchnorm 这部分可以完整存储 但是layernorm不行
//     // ---------------------------------------
//     wire [31:0] sqrt_val;

//     fsqrt_newton u_sqrt (
//         .clk(clk),
//         .rstn(rstn),
//         .ena(ena),
//         .d(var_eps),
//         .rm(rm),
//         .fsqrt(1'b1),
//         .s(sqrt_val),
//         .reg_x(),
//         .count(),
//         .busy(),
//         .stall()
//     );

//     // ---------------------------------------
//     // Step4: norm = (x - mu) / sqrt_val
//     // ---------------------------------------
//     wire [31:0] norm;

//     fdiv_newton u_div (
//         .a(sub),
//         .b(sqrt_val),
//         .rm(rm),
//         .fdiv(1'b1),
//         .ena(ena),
//         .clk(clk),
//         .clrn(rstn),
//         .s(norm),
//         .reg_x(),
//         .count(),
//         .busy(),
//         .stall()
//     );

//     // ---------------------------------------
//     // Step5: scaled = gamma * norm
//     // ---------------------------------------
//     wire [31:0] scaled;

//     fp32_mul u_mul (
//         .a(gamma),
//         .b(norm),
//         .rm(rm),
//         .s(scaled)
//     );

//     // ---------------------------------------
//     // Step6: y = scaled + beta
//     // ---------------------------------------
//     fp32_adder u_add_beta (
//         .a(scaled),
//         .b(beta),
//         .rm(rm),
//         .sel(1'b0),   // add
//         .s(y)
//     );

// endmodule

// Pipeline mode (used for layernorm and online batchnorm)
`timescale 1ns/1ps

module fp32_batchnorm (
    input  wire        clk,
    input  wire        rstn,
    input  wire        ena,        // Input data valid
    input  wire [31:0] x,
    input  wire [31:0] mu,
    input  wire [31:0] var,
    input  wire [31:0] gamma,
    input  wire [31:0] beta,
    input  wire [31:0] eps,
    input  wire [1:0]  rm,
    output reg  [31:0] y,
    output reg         y_valid
);

    // ---------------------------
    // Stage1: sub = x - mu, var_eps = var + eps
    // ---------------------------
    wire [31:0] sub, var_eps;
    wire        valid_s1_sub, valid_s1_var;

    fp32_adder u_sub (
        .clk(clk), .rstn(rstn), .ena(ena),
        .a(x), .b(mu), .rm(rm), .sel(1'b1),
        .s(sub), .valid(valid_s1_sub)  // when ena=1, valid after 1 cycle
    );

    fp32_adder u_var_eps (
        .clk(clk), .rstn(rstn), .ena(ena),
        .a(var), .b(eps), .rm(rm), .sel(1'b0),
        .s(var_eps), .valid(valid_s1_var)
    );

    reg [31:0] sub_r1, var_eps_r1;
    reg        ena_s1;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sub_r1 <= 0; var_eps_r1 <= 0; ena_s1 <= 0;
        end else begin
            sub_r1     <= sub;
            var_eps_r1 <= var_eps;
            ena_s1     <= valid_s1_sub & valid_s1_var; // Stage1 valid, This may cause some data missing
            // ena_s1 <= 1'b1;
        end
    end

    // ---------------------------
    // Stage2: sqrt_val = sqrt(var_eps)
    // ---------------------------
    wire [31:0] sqrt_val;
    wire        valid_s2;

    fsqrt_newton u_sqrt (
        .clk(clk), .rstn(rstn), .ena(ena_s1),
        .d(var_eps_r1), .rm(rm), .fsqrt(ena_s1),
        .s(sqrt_val), .reg_x(), .count(), .busy(), .stall(), .valid(valid_s2)
    );  // valid_s2 onlt 1 cycle for each data 


    reg [31:0] sub_r2, sqrt_val_r2;
    reg        ena_s2;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sub_r2 <= 0; sqrt_val_r2 <= 0; ena_s2 <= 0;
        end else begin
            sub_r2       <= sub_r1;
            sqrt_val_r2  <= sqrt_val;
            ena_s2       <= valid_s2;
        end
    end

    // ---------------------------
    // Stage3: norm = sub / sqrt_val
    // ---------------------------
    wire [31:0] norm;
    wire        valid_s3;

    fdiv_newton u_div (
        .clk(clk), .clrn(rstn), .ena(1'b1),
        .a(sub_r2), .b(sqrt_val_r2), .rm(rm), .fdiv(ena_s2), // when fractions are ready, start div
        .s(norm), .reg_x(), .count(), .busy(), .stall(), .valid(valid_s3)
    );


    reg [31:0] norm_r3;
    reg        ena_s3;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            norm_r3 <= 0; ena_s3 <= 0;
        end else begin
            norm_r3 <= norm;
            ena_s3  <= valid_s3;
        end
    end  // norm_r3 is zero? 

    // ---------------------------
    // Stage4: scaled = gamma * norm
    // ---------------------------
    wire [31:0] scaled;
    wire        valid_s4;

    fp32_mul u_mul (
        .clk(clk), .rstn(rstn), .ena(ena_s3),
        .a(gamma), .b(norm_r3), .rm(rm),
        .s(scaled), .valid(valid_s4)
    );

    // ---------------------------
    // Stage5: y = scaled + beta
    // ---------------------------
    wire [31:0] y_wire;
    wire        valid_s5;

    fp32_adder u_add_beta (
        .clk(clk), .rstn(rstn), .ena(valid_s4),
        .a(scaled), .b(beta), .rm(rm), .sel(1'b0),
        .s(y_wire), .valid(valid_s5)
    );

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            y       <= 0;
            y_valid <= 0;
        end else begin
            y       <= y_wire;
            y_valid <= valid_s5;
        end
    end

endmodule
