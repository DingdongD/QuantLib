// `include "wallace_tree_26x24.v"

module wallace_24x26 (
    input [23:0] a,
    input [25:0] b,
    output [49:8] x,
    output [49:8] y,
    output [7:0] z
);

    wallace_tree_26x24  umul(
    .a(b),
    .b(a),
    .x(x),  // sum high
    .y(y),  // carry high
    .z(z)         // sum low
);

endmodule
