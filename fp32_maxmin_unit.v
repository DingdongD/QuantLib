// ģ�� 2: �����Ƚϵ�Ԫ (������������ max/min)
// =====================================================
`include "fp32_key.v"
module fp32_maxmin_unit (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] max_v,
    output wire [31:0] min_v
);
    wire [31:0] ka, kb;
    wire a_nan, b_nan, a_zero, b_zero;

    // ӳ������ key
    fp32_key uA(.x(a), .key(ka), .is_nan(a_nan), .is_zero(a_zero));
    fp32_key uB(.x(b), .key(kb), .is_nan(b_nan), .is_zero(b_zero));

    // NaN ����: ��NaN������NaNĬ��ȡa
    wire a_gt_b =
        (b_nan && !a_nan) ? 1'b1 :
        (a_nan && !b_nan) ? 1'b0 :
        (a_nan && b_nan)  ? 1'b0 :
        (ka > kb); // �޷��űȽ� key

    // +0/-0 ����: max(+0,-0)=+0, min(+0,-0)=-0
    wire both_zero = a_zero & b_zero;
    wire a_pos0    = both_zero && (a[31]==1'b0) && (b[31]==1'b1); 
    wire equal_key = (ka == kb);

    wire take_a_as_max = a_pos0 | a_gt_b | equal_key;
    assign max_v = take_a_as_max ? a : b;
    assign min_v = take_a_as_max ? b : a;
endmodule
