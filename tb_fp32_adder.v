`timescale 1ns / 1ps
`include "fp32_adder.v"

`timescale 1ns / 1ps

module tb_fp32_adder;

  reg         clk;
  reg         rstn;
  reg         ena;
  reg  [31:0] a, b;
  reg  [1:0]  rm;
  reg         sel;       // 0 = add, 1 = subtract
  wire [31:0] s;
  wire        valid;

  // Instantiate DUT
  fp32_adder dut (
    .clk(clk),
    .rstn(rstn),
    .ena(ena),
    .a(a),
    .b(b),
    .rm(rm),
    .sel(sel),
    .s(s),
    .valid(valid)
  );

  // Clock generation: 10ns period
  initial clk = 0;
  always #5 clk = ~clk;
    
  // Test stimulus
  initial begin
    $dumpfile("tb_fp32_adder.vcd");
    $dumpvars(0, tb_fp32_adder);

    // Initialize
    rstn = 0;
    ena = 0;
    a = 0;
    b = 0;
    rm = 2'b00;
    sel = 0;

    #20;
    rstn = 1;

    // -------- Test 1: 2.0 + 3.0 ----------
    a = 32'h40000000; // 2.0
    b = 32'h40400000; // 3.0
    sel = 0;          // add
    ena = 1;
    #10 ena = 0;

    wait(valid);
    $display("Test1: 2.0 + 3.0 -> s=0x%08h", s);
    #5;
    
    // -------- Test 2: 5.5 - 1.5 ----------
    a = 32'h40b00000; // 5.5
    b = 32'h3fc00000; // 1.5
    sel = 1;          // subtract
    ena = 1;
    #10 ena = 0;

    wait(valid);
    $display("Test2: 5.5 - 1.5 -> s=0x%08h", s);
    #5;

    // -------- Test 3: 0 + -2.25 ----------
    a = 32'h40400000; // 3.0
    b = 32'hc0100000; // -2.25
    sel = 0;          // add
    ena = 1;
    #10 ena = 0;

    wait(valid);
    $display("Test3: 3 + -2.25 -> s=0x%08h", s);
    #5;

    // -------- Test 4: Inf + 1.0 ----------
    a = 32'h7f800000; // +Inf
    b = 32'h3f800000; // 1.0
    sel = 0;
    ena = 1;
    #10 ena = 0;

    wait(valid);
    $display("Test4: +Inf + 1.0 -> s=0x%08h", s);
    #5;

    // -------- Test 5: NaN - 2.0 ----------
    a = 32'h7fc12345; // NaN
    b = 32'h40000000; // 2.0
    sel = 1;          // subtract
    ena = 1;
    #10 ena = 0;

    wait(valid);
    $display("Test5: NaN - 2.0 -> s=0x%08h", s);
    #5;
    // Finish simulation
    #20 $finish;
  end

endmodule
