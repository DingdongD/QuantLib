module shift_to_msb_equ_1 (  // 浮点数规格化 将 采用前导0分级查找小数调整到[1,2)范围
    input  [23:0] a,   // 输入信号
    output [23:0] b,   // 输出信号，MSB=1
    output [4:0] sa    // 左移位数
);

    // 输入的24位信号a左移 直到最高有效位MSB为1  
    wire [23:0] a1, a2, a3, a4, a5;
    wire sa4, sa3, sa2, sa1, sa0;

    assign a5 = a;

    // 第一级：判断高16位是否为0
    assign sa4 = ~|a5[23:8];
    assign a4  = sa4 ? {a5[7:0],16'b0} : a5;

    // 第二级：判断高8位是否为0
    assign sa3 = ~|a4[23:16];
    assign a3  = sa3 ? {a4[15:0],8'b0} : a4;

    // 第三级：判断高4位是否为0
    assign sa2 = ~|a3[23:20];
    assign a2  = sa2 ? {a3[19:0],4'b0} : a3;

    // 第四级：判断高2位是否为0
    assign sa1 = ~|a2[23:22];
    assign a1  = sa1 ? {a2[21:0],2'b0} : a2;

    // 第五级：判断高1位是否为0
    assign sa0 = ~a1[23];
    assign a0  = sa0 ? {a1[22:0],1'b0} : a1;

    // 输出结果
    assign b = a0;

    // 总左移位数
    assign sa = {sa4, sa3, sa2, sa1, sa0} & 5'b11111;  // 保证5位

endmodule
