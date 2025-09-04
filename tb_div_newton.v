`timescale 1ns/1ps

module tb_fdiv_newton;

  // 信号定义
  reg         clk;
  reg         clrn;
  reg         ena;
  reg         fdiv;
  reg  [31:0] a;
  reg  [31:0] b;
  reg  [1:0]  rm;

  wire [31:0] s;
  wire [25:0] reg_x;
  wire [4:0]  count;
  wire        busy;
  wire        stall;
  wire        valid;

  // 实例化待测模块
  fdiv_newton uut (
    .a(a),
    .b(b),
    .rm(rm),
    .fdiv(fdiv),
    .ena(ena),
    .clk(clk),
    .clrn(clrn),
    .s(s),
    .reg_x(reg_x),
    .count(count),
    .busy(busy),
    .stall(stall),
    .valid(valid)
  );

  // 时钟生成
  initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 100MHz 时钟
  end

  // 仿真过程
  initial begin
    // VCD 转储
    $dumpfile("fdiv_newton_tb.vcd");
    $dumpvars(0, tb_fdiv_newton);

    // 初始化
    clrn = 0;
    ena  = 0;
    fdiv = 0;
    rm   = 2'b00;  // round to nearest
    a    = 32'b0;
    b    = 32'b0;

    #20;
    clrn = 1;
    ena  = 1;

    // ====== 测试用例 ======

    // 1) 6.0 / 3.0 = 2.0
    #10;
    a    = 32'h40400000;  // 3.0
    b    = 32'h40000000;  // 2.0
    fdiv = 1;
    #10 fdiv = 0;

    // 等待结果
    wait(valid);
    $display("6.0 / 3.0 = %h (expect 0x40000000)", s);

    // 2) 10.0 / 4.0 = 2.5
    #50;
    a    = 32'h41200000;  // 10.0
    b    = 32'h40800000;  // 4.0
    fdiv = 1;
    #10 fdiv = 0;

    wait(valid);
    $display("10.0 / 4.0 = %h (expect 0x40200000)", s);

    // 3) 1.0 / 0.0 = Inf
    #50;
    a    = 32'h42F6E979;  // 123.456
    b    = 32'h40FC7AE1;  // 7.89
    fdiv = 1;
    #10 fdiv = 0;

    wait(valid);
    $display("123.456 / 7.89 = %h (expect 417a5ab8)", s);

    // 4) 0.0 / 5.0 = 0.0
    #50;
    a    = 32'h00000000;  // 0.0
    b    = 32'h40a00000;  // 5.0
    fdiv = 1;
    #10 fdiv = 0;

    wait(valid);
    $display("0.0 / 5.0 = %h (expect 0x00000000)", s);

    // 5) NaN / 2.0
    #50;
    a    = 32'h7fc00000;  // NaN
    b    = 32'h40000000;  // 2.0
    fdiv = 1;
    #10 fdiv = 0;

    wait(valid);
    $display("NaN / 2.0 = %h (expect NaN)", s);

    // 仿真结束
    #100;
    $finish;
  end

endmodule
