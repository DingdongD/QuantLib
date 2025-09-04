// `include "wallace_tree_26x24.v"

module wallace_26x24 (
    input [25:0] a,
    input [23:0] b,
    output [49:0] z
);

    wire [49:8] x;
    wire [49:8] y;
    wire [49:8] z_high;
    wire [7:0]  z_low;

    wallace_tree_26x24  umul(
    .a(a),
    .b(b),
    .x(x),  // sum high
    .y(y),  // carry high
    .z(z_low)         // sum low
);

    assign z_high = x + y;
    assign z = {z_high, z_low};

endmodule