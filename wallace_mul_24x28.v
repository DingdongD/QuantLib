`timescale 1ns / 1ps

// Wallace tree multiplier for 24x28 bit product
module wallace_24x28 (
    input  wire [23:0] a,      // 24-bit multiplicand
    input  wire [27:0] b,      // 28-bit multiplier
    output wire [51:0] z       // 52-bit product
);
    // Internal signals for Wallace tree computation
    wire [51:8] x;             // Sum high bits (44 bits)
    wire [51:8] y;             // Carry high bits (44 bits)
    wire [51:8] z_high;        // Product high bits
    wire [7:0]  z_low;         // Product low bits

    // Instantiate Wallace tree partial product generator
    wallace_tree_24x28 wt_partial (
        .a(a),
        .b(b),
        .x(x),
        .y(y),
        .z(z_low)
    );

    // Compute high bits of product
    assign z_high = x + y;     // Add sum and carry
    assign z = {z_high, z_low}; // Concatenate high and low bits for final product
endmodule