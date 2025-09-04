`timescale 1ns / 1ps
`include "fxp_adder.v"
// module tb_fixed_add_csa;

//     parameter WIDTH = 16;
//     parameter FRAC  = 8;

//     reg  signed [WIDTH-1:0] a, b;
//     wire signed [WIDTH-1:0] sum;

//     // 实例化基于 CSA 的定点加法器
//     fixed_add_csa #(.WIDTH(WIDTH)) uut (
//         .a(a),
//         .b(b),
//         .sum(sum)
//     );

//     initial begin
//         // Test 1: 0.5 + 0.5
//         a = 16'h4000;  // 0.5
//         b = 16'h4000;  // 0.5
//         #10;
//         $display("Test1: a=0x%h, b=0x%h, sum=0x%h", a, b, sum);

//         // Test 2: 最大值 + 0.5 (溢出)
//         a = 16'h7FFF;  // 最大接近 1
//         b = 16'h4000;  // 0.5
//         #10;
//         $display("Test2: a=0x%h, b=0x%h, sum=0x%h", a, b, sum);

//         // Test 3: -0.5 + -0.5
//         a = -16'sh4000; // -0.5
//         b = 16'sh4000; // -0.5
//         #10;
//         $display("Test3: a=0x%h, b=0x%h, sum=0x%h", a, b, sum);

//         // Test 4: 正负混合
//         a = 16'h2000; // 0.25
//         b = -16'sh1000; // -0.125
//         #10;
//         $display("Test4: a=0x%h, b=0x%h, sum=0x%h", a, b, sum);

//         $finish;
//     end

// endmodule


// Testbench
module tb_fixed_add_pipeline;
    parameter WIDTH = 16;
    parameter FRAC_BITS = 8;  // Q7.8 format
    
    reg clk;
    reg rst_n;
    reg signed [WIDTH-1:0] a, b;
    wire signed [WIDTH-1:0] sum;
    wire overflow;
    
    // Instantiate the DUT (Device Under Test)
    fixed_add_pipeline #(
        .WIDTH(WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum),
        .overflow(overflow)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Fixed-point to real conversion
    function real fixed_to_real;
        input signed [WIDTH-1:0] fixed_val;
        begin
            fixed_to_real = $itor(fixed_val) / (1 << FRAC_BITS);
        end
    endfunction
    
    // Real to fixed-point conversion
    function signed [WIDTH-1:0] real_to_fixed;
        input real real_val;
        begin
            real_to_fixed = $rtoi(real_val * (1 << FRAC_BITS));
        end
    endfunction
    
    initial begin
        // Initialization
        clk = 0;
        rst_n = 0;
        a = 0;
        b = 0;
        
        // Reset
        #10 rst_n = 1;
        #10;
        
        $display("=== Q7.8 Fixed-Point Adder Test ===");
        $display("Time\t\tA(decimal)\tA(hex)\t\tB(decimal)\tB(hex)\t\tSum(decimal)\tSum(hex)\tOverflow");
        
        // Test case 1: Positive + Positive
        a = real_to_fixed(25.5);   // 25.5
        b = real_to_fixed(10.25);  // 10.25
        #10;
        #30; // Wait for pipeline latency
        $display("%0t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%b", 
                 $time, fixed_to_real(a), a, fixed_to_real(b), b, 
                 fixed_to_real(sum), sum, overflow);
        
        // Test case 2: Negative + Negative  
        a = real_to_fixed(-15.75); // -15.75
        b = real_to_fixed(-8.5);   // -8.5
        #10;
        #30;
        $display("%0t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%b", 
                 $time, fixed_to_real(a), a, fixed_to_real(b), b, 
                 fixed_to_real(sum), sum, overflow);
        
        // Test case 3: Positive + Negative
        a = real_to_fixed(30.0);   // 30.0
        b = real_to_fixed(-12.25); // -12.25*2^8=-12.25*256=-3136 3136正数C40 0x10000-0x0C40=0xF3C0
        #10;
        #30;
        $display("%0t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%b", 
                 $time, fixed_to_real(a), a, fixed_to_real(b), b, 
                 fixed_to_real(sum), sum, overflow);
        
        // Test case 4: Positive overflow
        a = real_to_fixed(100.0);  // Near max value
        b = real_to_fixed(50.0);   // Will cause overflow
        #10;
        #30;
        $display("%0t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%b", 
                 $time, fixed_to_real(a), a, fixed_to_real(b), b, 
                 fixed_to_real(sum), sum, overflow);
        
        // Test case 5: Negative overflow
        a = real_to_fixed(-100.0); // Near min value
        b = real_to_fixed(-50.0);  // Will cause negative overflow
        #10;
        #30;
        $display("%0t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%b", 
                 $time, fixed_to_real(a), a, fixed_to_real(b), b, 
                 fixed_to_real(sum), sum, overflow);
        
        // Test case 6: Fraction precision check
        a = real_to_fixed(0.125);  // 0.125 (1/8)
        b = real_to_fixed(0.375);  // 0.375 (3/8)
        #10;
        #30;
        $display("%0t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%.3f\t\t0x%04h\t\t%b", 
                 $time, fixed_to_real(a), a, fixed_to_real(b), b, 
                 fixed_to_real(sum), sum, overflow);
        
        $display("\n=== Format Information ===");
        $display("Q7.8 format: 1 sign bit + 7 integer bits + 8 fractional bits");
        $display("Value range: %.3f to %.3f", fixed_to_real(16'h8000), fixed_to_real(16'h7FFF));
        $display("Precision: %.6f", 1.0/(1<<FRAC_BITS));
        
        #50;
        $finish;
    end
    
    // Optional signal monitor
    // always @(posedge clk) begin
    //     if (rst_n && (a !== 0 || b !== 0)) begin
    //         $monitor("Clock %0d: a=%.3f(0x%04h), b=%.3f(0x%04h) -> sum=%.3f(0x%04h), overflow=%b",
    //                 $time/10, fixed_to_real(a), a, fixed_to_real(b), b, 
    //                 fixed_to_real(sum), sum, overflow);
    //     end
    // end

endmodule
