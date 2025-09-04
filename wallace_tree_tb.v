`timescale 1ns/1ps
// `include "wallace_tree_26x26.v"
// `include "wallace_mul_26x26.v"
`include "wallace_mul_26x24.v"
module tb_wallace_tree;
parameter M = 26;
parameter N = 24;
reg [M-1:0] a;
reg [N-1:0] b;
wire [M+N-1:0] result;
wire [2*N-1:0] ref;
// 实例化 Wallace Tree 模块  wallace_tree_26x26
wallace_26x24 uut (
    .a(a),
    .b(b),
    .z(result)
);

integer i;
integer errors;

assign ref = a * b;
initial begin
    errors = 0;
    // 随机测试 100 个样例
    for(i = 0; i < 100; i = i + 1) begin
        a = $random & ((1<<N)-1); // 保证只取 N 位
        b = $random & ((1<<N)-1);
        #1; // 等待组合逻辑稳定

        // 使用 Verilog $signed/$unsigned 强制类型匹配
        if(result !== (a * b)) begin
            $display("Mismatch! a=%0d b=%0d | Wallace result=%0d Expected=%0d",
                     a, b, result, a*b);
            errors = errors + 1;
        end else begin 
            $display("a=%0d b=%0d | Wallace result=%0d Expected=%0d",
                     a, b, result, ref);
        end
    end

    if(errors == 0)
        $display("All tests passed!");
    else
        $display("Total mismatches: %0d", errors);

    $finish;
end

endmodule
