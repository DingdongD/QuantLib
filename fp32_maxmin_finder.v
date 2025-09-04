// 模块 3: 递归比较树 (多输入 max/min, Verilog 版)
// 输入端口用一维 bus，而不是数组
// =====================================================
`include "fp32_maxmin_unit.v"

// 下面这个版本没有考虑pipeline优化
// module fp32_maxmin_finder #(
//     parameter NUM_INPUTS = 4
// )(
//     input  wire [NUM_INPUTS*32-1:0] inputs,  // 展平后的输入
//     output wire [31:0] max_value,
//     output wire [31:0] min_value
// );
//     localparam NUM_PAIRS      = (NUM_INPUTS >> 1);
//     localparam HAS_ODD        = (NUM_INPUTS % 2);
//     localparam NUM_NEXT_STAGE = NUM_PAIRS + HAS_ODD;

//     genvar i;
//     generate
//         if (NUM_INPUTS == 1) begin : base_case
//             assign max_value = inputs[31:0];
//             assign min_value = inputs[31:0];
//         end else begin : recurse_case
//             wire [NUM_NEXT_STAGE*32-1:0] max_values;
//             wire [NUM_NEXT_STAGE*32-1:0] min_values;

//             for (i = 0; i < NUM_PAIRS; i = i + 1) begin : cmp_pairs
//                 wire [31:0] a = inputs[32*(2*i+1)-1 : 32*(2*i)];
//                 wire [31:0] b = inputs[32*(2*i+2)-1 : 32*(2*i+1)];
//                 wire [31:0] mx, mn;

//                 fp32_maxmin_unit cmp_inst(.a(a), .b(b), .max_v(mx), .min_v(mn));

//                 assign max_values[32*(i+1)-1 : 32*i] = mx;
//                 assign min_values[32*(i+1)-1 : 32*i] = mn;
//             end

//             if (HAS_ODD) begin
//                 assign max_values[NUM_NEXT_STAGE*32-1 : (NUM_NEXT_STAGE-1)*32] =
//                        inputs[NUM_INPUTS*32-1 : (NUM_INPUTS-1)*32];
//                 assign min_values[NUM_NEXT_STAGE*32-1 : (NUM_NEXT_STAGE-1)*32] =
//                        inputs[NUM_INPUTS*32-1 : (NUM_INPUTS-1)*32];
//             end

//             if (NUM_INPUTS == 2) begin
//                 assign max_value = max_values[31:0];
//                 assign min_value = min_values[31:0];
//             end else begin
//                 wire [31:0] next_max, next_min;
//                 fp32_maxmin_finder #(.NUM_INPUTS(NUM_NEXT_STAGE)) recurse_max (
//                     .inputs(max_values),
//                     .max_value(next_max),
//                     .min_value()   // 忽略
//                 );
//                 fp32_maxmin_finder #(.NUM_INPUTS(NUM_NEXT_STAGE)) recurse_min (
//                     .inputs(min_values),
//                     .max_value(),  // 忽略
//                     .min_value(next_min)
//                 );
//                 assign max_value = next_max;
//                 assign min_value = next_min;
//             end
//         end
//     endgenerate
// endmodule


// 下面这个版本考虑pipeline优化
// =====================================================
// fp32_maxmin_finder_pipe
// - inputs: 扁平化的 NUM_INPUTS 个 32-bit 浮点，LSB 为 inputs[31:0] (input 0)
// - PIPELINE=1 在每一层插入寄存器，PIPELINE=0 无寄存器（组合）
// - 端口包含 clk, rstn（当 PIPELINE==0 时可接 0/1，不被使用）
// =====================================================

module fp32_maxmin_finder_pipe #(
    parameter NUM_INPUTS = 4,
    parameter PIPELINE   = 1
)(
    input  wire clk,
    input  wire rstn,                       // active low
    input  wire in_valid,                   // 输入有效
    input  wire [NUM_INPUTS*32-1:0] inputs,// 扁平化输入
    output wire [31:0] max_value,
    output wire [31:0] min_value,
    output reg  out_valid                   // 输出有效
);

    // -------------------------
    // log2函数
    // -------------------------
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value-1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    localparam NUM_STAGES = (PIPELINE==1) ? clog2(NUM_INPUTS) : 0;

    // -------------------------
    // 有效信号 shift register
    // -------------------------
    reg [NUM_STAGES:0] valid_pipe;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_pipe <= 0;
        end else begin
            valid_pipe[0] <= in_valid;
            valid_pipe[NUM_STAGES:1] <= valid_pipe[NUM_STAGES-1:0];
        end
    end
    always @(*) begin
        out_valid = valid_pipe[NUM_STAGES];
    end

    // -------------------------
    // 递归比较树
    // -------------------------
    generate
        if (NUM_INPUTS == 1) begin : gen_base
            assign max_value = inputs[31:0];
            assign min_value = inputs[31:0];
        end else begin : gen_recurse
            localparam NUM_PAIRS      = (NUM_INPUTS >> 1);
            localparam HAS_ODD        = (NUM_INPUTS % 2);
            localparam NUM_NEXT_STAGE = NUM_PAIRS + HAS_ODD;

            wire [NUM_NEXT_STAGE*32-1:0] max_values;
            wire [NUM_NEXT_STAGE*32-1:0] min_values;

            genvar i;
            for (i = 0; i < NUM_PAIRS; i = i + 1) begin : cmp_pairs
                wire [31:0] a, b, mx, mn;
                assign a = inputs[32*(2*i) + 31 : 32*(2*i)];
                assign b = inputs[32*(2*i+1) + 31 : 32*(2*i+1)];
                fp32_maxmin_unit cmp_inst(.a(a), .b(b), .max_v(mx), .min_v(mn));
                assign max_values[32*i + 31 : 32*i] = mx;
                assign min_values[32*i + 31 : 32*i] = mn;
            end

            if (HAS_ODD) begin : pass_tail
                assign max_values[NUM_NEXT_STAGE*32-1 : (NUM_NEXT_STAGE-1)*32] =
                       inputs[NUM_INPUTS*32-1 : (NUM_INPUTS-1)*32];
                assign min_values[NUM_NEXT_STAGE*32-1 : (NUM_NEXT_STAGE-1)*32] =
                       inputs[NUM_INPUTS*32-1 : (NUM_INPUTS-1)*32];
            end

            if (NUM_INPUTS == 2) begin : two_case
                if (PIPELINE) begin : two_pipe
                    reg [31:0] max_reg;
                    reg [31:0] min_reg;
                    always @(posedge clk or negedge rstn) begin
                        if (!rstn) begin
                            max_reg <= 0;
                            min_reg <= 0;
                        end else begin
                            max_reg <= max_values[31:0];
                            min_reg <= min_values[31:0];
                        end
                    end
                    assign max_value = max_reg;
                    assign min_value = min_reg;
                end else begin : two_comb
                    assign max_value = max_values[31:0];
                    assign min_value = min_values[31:0];
                end
            end else begin : more_than_two
                wire [31:0] next_max;
                wire [31:0] next_min;

                if (PIPELINE) begin : recurse_with_regs
                    reg [NUM_NEXT_STAGE*32-1:0] reg_max_values;
                    reg [NUM_NEXT_STAGE*32-1:0] reg_min_values;
                    always @(posedge clk or negedge rstn) begin
                        if (!rstn) begin
                            reg_max_values <= 0;
                            reg_min_values <= 0;
                        end else begin
                            reg_max_values <= max_values;
                            reg_min_values <= min_values;
                        end
                    end

                    fp32_maxmin_finder_pipe #(
                        .NUM_INPUTS(NUM_NEXT_STAGE),
                        .PIPELINE(PIPELINE)
                    ) recurse_max (
                        .clk(clk),
                        .rstn(rstn),
                        .in_valid(1'b1),   // always 1, pipeline valid handled outside
                        .inputs(reg_max_values),
                        .max_value(next_max),
                        .min_value()        // unused
                    );

                    fp32_maxmin_finder_pipe #(
                        .NUM_INPUTS(NUM_NEXT_STAGE),
                        .PIPELINE(PIPELINE)
                    ) recurse_min (
                        .clk(clk),
                        .rstn(rstn),
                        .in_valid(1'b1),
                        .inputs(reg_min_values),
                        .max_value(),       // unused
                        .min_value(next_min)
                    );

                    assign max_value = next_max;
                    assign min_value = next_min;

                end else begin : recurse_comb
                    fp32_maxmin_finder_pipe #(
                        .NUM_INPUTS(NUM_NEXT_STAGE),
                        .PIPELINE(PIPELINE)
                    ) recurse_max (
                        .clk(clk),
                        .rstn(rstn),
                        .in_valid(1'b1),
                        .inputs(max_values),
                        .max_value(next_max),
                        .min_value()
                    );

                    fp32_maxmin_finder_pipe #(
                        .NUM_INPUTS(NUM_NEXT_STAGE),
                        .PIPELINE(PIPELINE)
                    ) recurse_min (
                        .clk(clk),
                        .rstn(rstn),
                        .in_valid(1'b1),
                        .inputs(min_values),
                        .max_value(),
                        .min_value(next_min)
                    );

                    assign max_value = next_max;
                    assign min_value = next_min;
                end
            end
        end
    endgenerate
endmodule

