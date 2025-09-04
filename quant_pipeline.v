module quantize_pipeline (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        ena,            // 输入数据有效

    input  wire [31:0] fp_in,          // 浮点输入
    input  wire [31:0] scale,          // 这里假设是 inv_scale = 1/scale
    input  wire [7:0]  zp,             // zero point
    input  wire        use_asym,       // 选择对称/非对称量化

    output reg  [7:0]  q_out,          // 量化结果
    output reg         sat,            // 饱和标志
    output reg         out_valid       // 输出有效
);

    // ===================================
    // Stage1: FP32 乘法
    // ===================================
    wire [31:0] mul_out;
    wire        mul_valid;

    fp32_mul u_mul (
        .clk   (clk),
        .rstn  (rst_n),
        .ena   (ena),
        .a     (fp_in),
        .b     (scale),
        .rm    (2'b00),
        .s     (mul_out),
        .valid (mul_valid)
    );

    // ===================================
    // Stage2: 浮点 -> 定点 (8-bit)
    // ===================================
    wire [7:0] fxp_out_8;
    wire       fxp_ovf;
    wire       fxp_valid;

    float2fxp_pipe #(
        .WOI (8),
        .WOF (0)
    ) u_f2fxp (
        .rstn      (rst_n),
        .clk       (clk),
        .ena       (mul_valid),
        .in        (mul_out),
        .out       (fxp_out_8),   // 8-bit
        .overflow  (fxp_ovf),
        .out_valid (fxp_valid)
    );

    // 符号扩展到 16-bit
    wire signed [15:0] fxp_out = {{8{fxp_out_8[7]}}, fxp_out_8};

    // ===================================
    // Stage3: 定点加法 (处理 zero point)
    // ===================================
    wire signed [15:0] zp_ext = use_asym ? {{8{zp[7]}}, zp} : 16'd0;

    wire signed [15:0] add_sum;
    wire               add_ovf;
    wire               add_valid;

    fixed_add_pipeline #(
        .WIDTH(16),
        .FRAC_BITS(0)
    ) u_add (
        .clk       (clk),
        .rst_n     (rst_n),
        .ena       (fxp_valid),
        .a         (fxp_out),
        .b         (zp_ext),
        .sum       (add_sum),
        .overflow  (add_ovf),
        .out_valid (add_valid)
    );

    // ===================================
    // Stage4: 裁剪到 8bit
    // ===================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_out     <= 8'd0;
            sat       <= 1'b0;
            out_valid <= 1'b0;
        end else begin
            out_valid <= add_valid;
            if (add_valid) begin
                if (add_sum > 127) begin
                    q_out <= 8'd127;
                    sat   <= 1'b1;
                end else if (add_sum < 0) begin
                    q_out <= 8'd0;   // clip to 0
                    sat   <= 1'b1;
                end else begin
                    q_out <= add_sum[7:0];
                    sat   <= 1'b0;
                end
            end
        end
    end

endmodule
