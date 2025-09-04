
`timescale 1ns/1ps
`include "fp32_maxmin_finder.v"

module tb_fp32_maxmin_valid;
    localparam N = 5;
    reg clk, rstn;
    reg in_valid;
    reg [N*32-1:0] in_flat;
    wire [31:0] max_v, min_v;
    wire out_valid;

    fp32_maxmin_finder_pipe #(
        .NUM_INPUTS(N),
        .PIPELINE(1)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .in_valid(in_valid),
        .inputs(in_flat),
        .max_value(max_v),
        .min_value(min_v),
        .out_valid(out_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rstn = 0;
        in_valid = 0;
        #12 rstn = 1;

        @(posedge clk);
        in_flat[31:0]      = 32'h3F800000; // 1.0
        in_flat[63:32]     = 32'hBF800000; // -1.0
        in_flat[95:64]     = 32'h40000000; // 2.0
        in_flat[127:96]    = 32'hC0000000; // -2.0
        in_flat[159:128]   = 32'h00000000; // 0.0
        in_valid = 1;

        @(posedge clk);
        in_valid = 0;

        wait(out_valid);
        $display("max = 0x%h  min = 0x%h", max_v, min_v);

        #20 $finish;
    end
endmodule
