/*
对称量化：qx=round(x/sx), qw=round(w/sw) 反量化恢复y=wx≈(qw*sw)*(qx*sx)=qw*qx*(sw*sx)
非对称量化：qx=round((x-zx)/sx), qw=round((w-zw)/sw) 反量化恢复y=wx≈(qw*sw+zw)*(qx*sx+zx)=qw*qx*(sw*sx)+qw*zx*sw+qx*zw*sx+zx*zw
*/


// =============================================================
// Dequantization pipeline (symmetric quantization)
// y = fxp_in * scale
// =============================================================
module dequantize_pipeline #(
    parameter N     = 16,  // 定点总位宽
    parameter FRAC  = 8    // 小数位
)(
    input  wire        clk,
    input  wire        rstn,
    input  wire [N-1:0] fxp_in,      // 定点输入
    input  wire        valid_in,     // 输入有效信号
    input  wire [31:0] scale,        // scale (浮点数)
    output wire [31:0] fp_out,       // 反量化后的浮点数
    output wire        valid_out     // 输出有效信号
);

    // Stage 1: fixed -> float
    wire [31:0] fp_val;
    wire fxp2f_valid;

    fxp2float_pipeline #(
        .N(N),
        .FRAC(FRAC)
    ) u_fxp2f (
        .clk      (clk),
        .rstn     (rstn),
        .fxp_in   (fxp_in),
        .valid_in (valid_in),
        .fp_out   (fp_val),
        .valid_out(fxp2f_valid)
    );

    // Stage 2: float multiply with scale
    fp32_mul u_fpmul (
        .clk   (clk),
        .rstn  (rstn),
        .ena   (fxp2f_valid),  // 由上一步的valid驱动
        .a     (fp_val),
        .b     (scale),
        .rm    (2'b00),        // 默认最近偶数舍入
        .s     (fp_out),
        .valid (valid_out)
    );

endmodule


