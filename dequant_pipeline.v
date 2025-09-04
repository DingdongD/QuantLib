/*
�Գ�������qx=round(x/sx), qw=round(w/sw) �������ָ�y=wx��(qw*sw)*(qx*sx)=qw*qx*(sw*sx)
�ǶԳ�������qx=round((x-zx)/sx), qw=round((w-zw)/sw) �������ָ�y=wx��(qw*sw+zw)*(qx*sx+zx)=qw*qx*(sw*sx)+qw*zx*sw+qx*zw*sx+zx*zw
*/


// =============================================================
// Dequantization pipeline (symmetric quantization)
// y = fxp_in * scale
// =============================================================
module dequantize_pipeline #(
    parameter N     = 16,  // ������λ��
    parameter FRAC  = 8    // С��λ
)(
    input  wire        clk,
    input  wire        rstn,
    input  wire [N-1:0] fxp_in,      // ��������
    input  wire        valid_in,     // ������Ч�ź�
    input  wire [31:0] scale,        // scale (������)
    output wire [31:0] fp_out,       // ��������ĸ�����
    output wire        valid_out     // �����Ч�ź�
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
        .ena   (fxp2f_valid),  // ����һ����valid����
        .a     (fp_val),
        .b     (scale),
        .rm    (2'b00),        // Ĭ�����ż������
        .s     (fp_out),
        .valid (valid_out)
    );

endmodule


