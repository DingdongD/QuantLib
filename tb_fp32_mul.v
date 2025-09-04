`timescale 1ns / 1ps
`include "fp32_mul.v"

module tb_fp32_mul;

  reg         clk;
  reg         rstn;
  reg         ena;
  reg  [31:0] a, b;
  reg  [1:0]  rm;
  wire [31:0] s;
  wire        valid;

  // DUT
  fp32_mul dut (
    .clk(clk),
    .rstn(rstn),
    .ena(ena),
    .a(a),
    .b(b),
    .rm(rm),
    .s(s),
    .valid(valid)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 100MHz clock

  // Reset and test stimulus
  initial begin
    $dumpfile("tb_fp32_mul.vcd");
    $dumpvars(0, tb_fp32_mul);

    // Initial values
    rstn = 0;
    ena = 0;
    a = 0;
    b = 0;
    rm = 2'b00;

    #20;
    rstn = 1;

    // Wait a cycle
    #10;

    // -------- Test 1: 2.0 * 3.0 ----------
    a = 32'h40000000; // 2.0
    b = 32'h40400000; // 3.0
    ena = 1;
    #10 ena = 0; // one cycle pulse

    // Wait for result valid
    wait(valid);
    $display("Test1: a=0x%08h b=0x%08h -> s=0x%08h", a, b, s);
    #5;

    // -------- Test 2: 1.5 * -2.5 ----------
    a = 32'h3fc00000; // 1.5
    b = 32'hc0200000; // -2.5
    ena = 1;
    #10 ena = 0;

    wait(valid);
    $display("Test2: a=0x%08h b=0x%08h -> s=0x%08h", a, b, s);
    #5;

    // -------- Test 3: 2.5 * 3.5 ----------
    a = 32'h40200000; // 0.0
    b = 32'h40600000; // 7.0
    ena = 1;
    #10 ena = 0;

    wait(valid);
    $display("Test3: a=0x%08h b=0x%08h -> s=0x%08h", a, b, s);
    #5;

    // -------- Test 4: Inf * 0 ----------
    a = 32'h7f800000; // +Inf
    b = 32'h00000000; // 0.0
    ena = 1;
    #10 ena = 0;

    wait(valid);
    $display("Test4: a=+Inf b=0x0 -> s=0x%08h", s);
    #5;

    // -------- Test 5: NaN * 5.0 ----------
    a = 32'h7fc12345; // NaN
    b = 32'h40a00000; // 5.0
    ena = 1;
    #10 ena = 0;

    wait(valid);
    $display("Test5: a=NaN b=5.0 -> s=0x%08h", s);
    #5;
    // Finish simulation
    #20 $finish;
  end

endmodule
