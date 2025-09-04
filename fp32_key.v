/*
    Translate FP32 number to a key for comparison.

*/

module fp32_key (
    input wire [31:0] x,
    output wire [31:0] key,
    output wire is_nan,
    output wire is_zero
);

    wire sign = x[31];
    wire [7:0] exp = x[30:23];
    wire [22:0] frac = x[22:0];

    assign is_nan = (exp == 8'hff) && (frac != 0);
    assign is_zero = (exp == 8'h00) && (frac == 0);

    assign key = sign ? ~x : x^32'h80000000;

endmodule //fp32_key