// `include "wallace_tree_26x26.v"

module wallace_26x26 (
    input [25:0] a,
    input [25:0] b,
    output [51:0] z
);

    wire [51:8] x;
    wire [51:8] y;
    wire [51:8] z_high;
    wire [7:0]  z_low;


    wallace_tree_26x26  umul(
    .a(a),
    .b(b),
    .x(x),  // sum high
    .y(y),  // carry high
    .z(z_low)         // sum low
);

    assign z_high = x + y;
    assign z = {z_high, z_low};

endmodule