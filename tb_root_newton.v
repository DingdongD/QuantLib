`timescale 1ns/1ps
// `include "root_newton.v"

module tb_fsqrt_newton;

  reg         clk;
  reg         rstn;
  reg  [31:0] d;
  reg  [1:0]  rm;
  reg         fsqrt;
  reg         ena;
  wire [31:0] s;
  wire [25:0] reg_x;
  wire [4:0]  count;
  wire        busy;
  wire        stall;
  wire        valid;

  // DUT
  fsqrt_newton dut (
    .clk(clk),
    .rstn(rstn),
    .d(d),
    .rm(rm),
    .fsqrt(fsqrt),
    .ena(ena),
    .s(s),
    .reg_x(reg_x),
    .count(count),
    .busy(busy),
    .stall(stall),
    .valid(valid)
  );

  // clock
  initial clk = 0;
  always #5 clk = ~clk;

  // dump waveform
  initial begin
    $dumpfile("tb_fsqrt_newton.vcd");
    $dumpvars(0, tb_fsqrt_newton);
  end

  // task: apply input
  task run_sqrt(input [31:0] din, input [255*8:0] msg);
  begin
    @(posedge clk);
    d = din;
    fsqrt = 1;
    ena = 1;
    @(posedge clk);
    fsqrt = 0;
    // ena = 0;
    // wait for valid
    wait(valid);
    $display("%s: d=0x%08h sqrt=0x%08h", msg, din, s);
  end
  endtask

  // test sequence
  initial begin
    // init
    rstn = 0;
    d = 0;
    rm = 2'b00; // round to nearest
    fsqrt = 0;
    ena = 0;

    #20 rstn = 1;

    // test cases
    run_sqrt(32'h3f800000, "sqrt(1.0)");    // 1.0
    run_sqrt(32'h40800000, "sqrt(4.0)");    // 4.0
    run_sqrt(32'h40a00000, "sqrt(5.0)");    // 5.0
    run_sqrt(32'h00000000, "sqrt(0.0)");    // 0.0
    run_sqrt(32'h7f800000, "sqrt(+Inf)");   // +Inf
    run_sqrt(32'h7fc00000, "sqrt(NaN)");    // NaN
    run_sqrt(32'hbf800000, "sqrt(-1.0)");   // -1.0 (expect NaN)

    #50 $finish;
  end

endmodule
