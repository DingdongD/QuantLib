module shift_to_msb_equ_1 (  // ��������� �� ����ǰ��0�ּ�����С��������[1,2)��Χ
    input  [23:0] a,   // �����ź�
    output [23:0] b,   // ����źţ�MSB=1
    output [4:0] sa    // ����λ��
);

    // �����24λ�ź�a���� ֱ�������ЧλMSBΪ1  
    wire [23:0] a1, a2, a3, a4, a5;
    wire sa4, sa3, sa2, sa1, sa0;

    assign a5 = a;

    // ��һ�����жϸ�16λ�Ƿ�Ϊ0
    assign sa4 = ~|a5[23:8];
    assign a4  = sa4 ? {a5[7:0],16'b0} : a5;

    // �ڶ������жϸ�8λ�Ƿ�Ϊ0
    assign sa3 = ~|a4[23:16];
    assign a3  = sa3 ? {a4[15:0],8'b0} : a4;

    // ���������жϸ�4λ�Ƿ�Ϊ0
    assign sa2 = ~|a3[23:20];
    assign a2  = sa2 ? {a3[19:0],4'b0} : a3;

    // ���ļ����жϸ�2λ�Ƿ�Ϊ0
    assign sa1 = ~|a2[23:22];
    assign a1  = sa1 ? {a2[21:0],2'b0} : a2;

    // ���弶���жϸ�1λ�Ƿ�Ϊ0
    assign sa0 = ~a1[23];
    assign a0  = sa0 ? {a1[22:0],1'b0} : a1;

    // ������
    assign b = a0;

    // ������λ��
    assign sa = {sa4, sa3, sa2, sa1, sa0} & 5'b11111;  // ��֤5λ

endmodule
