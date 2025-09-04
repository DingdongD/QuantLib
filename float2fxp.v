// 1b+8b exponent 23b mantissa float to 16b fixed point(Qm.n,width=m+n+1)

// module float2fxp_pipe #(
//     parameter WOI  = 8,
//     parameter WOF  = 8,
//     parameter ROUND= 1
// )(
//     input  wire               rstn,
//     input  wire               clk,
//     input  wire        [31:0] in,
//     output reg  [WOI+WOF-1:0] out,
//     output reg                overflow
// );


// localparam [WOI+WOF-1:0] ONEO = 1;

// initial {out, overflow} = 0;

// // input comb
// wire        sign;
// wire [ 7:0] exp;
// wire [23:0] val;

// assign {sign,exp,val[22:0]} = in;
// assign val[23] = |exp;

// // pipeline stage1
// reg signinit=1'b0, roundinit=1'b0;
// reg signed [31:0] expinit = 0;
// reg [WOI+WOF-1:0] outinit = 0;

// generate if(WOI+WOF-1>=23) begin
//     always @ (posedge clk or negedge rstn)
//         if(~rstn) begin
//             outinit <= 0;
//             roundinit <= 1'b0;
//         end else begin
//             outinit <= 0;
//             outinit[WOI+WOF-1:WOI+WOF-1-23] <= val;
//             roundinit <= 1'b0;
//         end
// end else begin
//     always @ (posedge clk or negedge rstn)
//         if(~rstn) begin
//             outinit <= 0;
//             roundinit <= 1'b0;
//         end else begin
//             outinit <= val[23:23-(WOI+WOF-1)];
//             roundinit <= ( ROUND && val[23-(WOI+WOF-1)-1] );
//         end
// end endgenerate

// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         signinit <= 1'b0;
//         expinit  <= 0;
//     end else begin
//         signinit <= sign;
//         if( exp==8'd255 || {24'd0,exp}>WOI+126 )
//             expinit <= 0;
//         else
//             expinit <= {24'd0,exp} - (WOI-1) - 127;
//     end

// // next pipeline stages
// reg              signs [WOI+WOF :0];
// reg             rounds [WOI+WOF :0];
// reg [31:0]        exps [WOI+WOF :0];
// reg [WOI+WOF-1:0] outs [WOI+WOF :0];

// integer ii;

// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         for(ii=0; ii<WOI+WOF+1; ii=ii+1) begin
//             signs[ii]  <= 0;
//             rounds[ii] <= 0;
//             exps[ii]   <= 0;
//             outs[ii]   <= 0;
//         end
//     end else begin
//         for(ii=0; ii<WOI+WOF; ii=ii+1) begin
//             signs[ii] <= signs[ii+1];
//             if(exps[ii+1]!=0) begin
//                 {outs[ii], rounds[ii]} <= {       1'b0,   outs[ii+1] };
//                 exps[ii] <= exps[ii+1] + 1;
//             end else begin
//                 {outs[ii], rounds[ii]} <= { outs[ii+1], rounds[ii+1] };
//                 exps[ii] <= exps[ii+1];
//             end
//         end
//         signs[WOI+WOF] <= signinit;
//         rounds[WOI+WOF] <= roundinit;
//         exps[WOI+WOF] <= expinit;
//         outs[WOI+WOF] <= outinit;
//     end

// // last 2nd pipeline stage
// reg               signl = 1'b0;
// reg [WOI+WOF-1:0] outl = 0;
// reg [WOI+WOF-1:0] outt;
// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         outl <= 0;
//         signl <= 1'b0;
//     end else begin
//         outt = outs[0];
//         if(ROUND & rounds[0] & ~(&outt))
//             outt = outt + 1;
//         if(signs[0]) begin
//             signl <= (outt!=0);
//             outt  = (~outt) + ONEO;
//         end else
//             signl <= 1'b0;
//         outl <= outt;
//     end

// // last 1st pipeline stage: overflow control
// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         out <= 0;
//         overflow <= 1'b0;
//     end else begin
//         out <= outl;
//         overflow <= 1'b0;
//         if(signl) begin
//             if(~outl[WOI+WOF-1]) begin
//                 out[WOI+WOF-1] <= 1'b1;
//                 out[WOI+WOF-2:0] <= 0;
//                 overflow <= 1'b1;
//             end
//         end else begin
//             if(outl[WOI+WOF-1]) begin
//                 out[WOI+WOF-1] <= 1'b0;
//                 out[WOI+WOF-2:0] <= {(WOI+WOF){1'b1}};
//                 overflow <= 1'b1;
//             end
//         end
//     end

// endmodule


// module float2fxp_pipe #(
//     parameter WOI  = 8,
//     parameter WOF  = 8,
//     parameter ROUND= 1
// )(
//     input  wire               rstn,
//     input  wire               clk,
//     input  wire        [31:0] in,
//     output reg  [WOI+WOF-1:0] out,
//     output reg                overflow
// );


// localparam [WOI+WOF-1:0] ONEO = 1;

// initial {out, overflow} = 0;

// // input comb
// wire        sign;
// wire [ 7:0] exp;
// wire [23:0] val;

// assign {sign,exp,val[22:0]} = in;
// assign val[23] = |exp;

// // pipeline stage1
// reg signinit=1'b0, roundinit=1'b0;
// reg signed [31:0] expinit = 0;
// reg [WOI+WOF-1:0] outinit = 0;

// generate if(WOI+WOF-1>=23) begin
//     always @ (posedge clk or negedge rstn)
//         if(~rstn) begin
//             outinit <= 0;
//             roundinit <= 1'b0;
//         end else begin
//             outinit <= 0;
//             outinit[WOI+WOF-1:WOI+WOF-1-23] <= val;
//             roundinit <= 1'b0;
//         end
// end else begin
//     always @ (posedge clk or negedge rstn)
//         if(~rstn) begin
//             outinit <= 0;
//             roundinit <= 1'b0;
//         end else begin
//             outinit <= val[23:23-(WOI+WOF-1)];
//             roundinit <= ( ROUND && val[23-(WOI+WOF-1)-1] );
//         end
// end endgenerate

// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         signinit <= 1'b0;
//         expinit  <= 0;
//     end else begin
//         signinit <= sign;
//         if( exp==8'd255 || {24'd0,exp}>WOI+126 )
//             expinit <= 0;
//         else
//             expinit <= {24'd0,exp} - (WOI-1) - 127;
//     end

// // next pipeline stages
// reg              signs [WOI+WOF :0];
// reg             rounds [WOI+WOF :0];
// reg [31:0]        exps [WOI+WOF :0];
// reg [WOI+WOF-1:0] outs [WOI+WOF :0];

// integer ii;

// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         for(ii=0; ii<WOI+WOF+1; ii=ii+1) begin
//             signs[ii]  <= 0;
//             rounds[ii] <= 0;
//             exps[ii]   <= 0;
//             outs[ii]   <= 0;
//         end
//     end else begin
//         for(ii=0; ii<WOI+WOF; ii=ii+1) begin
//             signs[ii] <= signs[ii+1];
//             if(exps[ii+1]!=0) begin
//                 {outs[ii], rounds[ii]} <= {       1'b0,   outs[ii+1] };
//                 exps[ii] <= exps[ii+1] + 1;
//             end else begin
//                 {outs[ii], rounds[ii]} <= { outs[ii+1], rounds[ii+1] };
//                 exps[ii] <= exps[ii+1];
//             end
//         end
//         signs[WOI+WOF] <= signinit;
//         rounds[WOI+WOF] <= roundinit;
//         exps[WOI+WOF] <= expinit;
//         outs[WOI+WOF] <= outinit;
//     end

// // last 2nd pipeline stage
// reg               signl = 1'b0;
// reg [WOI+WOF-1:0] outl = 0;
// reg [WOI+WOF-1:0] outt;
// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         outl <= 0;
//         signl <= 1'b0;
//     end else begin
//         outt = outs[0];
//         if(ROUND & rounds[0] & ~(&outt))
//             outt = outt + 1;
//         if(signs[0]) begin
//             signl <= (outt!=0);
//             outt  = (~outt) + ONEO;
//         end else
//             signl <= 1'b0;
//         outl <= outt;
//     end

// // last 1st pipeline stage: overflow control
// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         out <= 0;
//         overflow <= 1'b0;
//     end else begin
//         out <= outl;
//         overflow <= 1'b0;
//         if(signl) begin
//             if(~outl[WOI+WOF-1]) begin
//                 out[WOI+WOF-1] <= 1'b1;
//                 out[WOI+WOF-2:0] <= 0;
//                 overflow <= 1'b1;
//             end
//         end else begin
//             if(outl[WOI+WOF-1]) begin
//                 out[WOI+WOF-1] <= 1'b0;
//                 out[WOI+WOF-2:0] <= {(WOI+WOF){1'b1}};
//                 overflow <= 1'b1;
//             end
//         end
//     end

// endmodule


// module float2fxp_pipe #(
//     parameter WOI  = 8,
//     parameter WOF  = 8,
//     parameter ROUND= 1
// )(
//     input  wire               rstn,
//     input  wire               clk,
//     input  wire        [31:0] in,
//     output reg  [WOI+WOF-1:0] out,
//     output reg                overflow
// );

// localparam [WOI+WOF-1:0] ONEO = 1;

// initial {out, overflow} = 0;

// // input comb
// wire        sign;
// wire [ 7:0] exp;
// wire [23:0] val;

// assign {sign,exp,val[22:0]} = in;  // get exp and mantissa
// assign val[23] = |exp; // 判断是否全为0

// // ---------------- stage1 ----------------
// reg signinit=1'b0, roundinit=1'b0;
// reg signed [31:0] expinit = 0;
// reg [WOI+WOF-1:0] outinit = 0;

// generate 
// if(WOI+WOF-1>=23) begin
//     always @ (posedge clk or negedge rstn)
//         if(~rstn) begin
//             outinit <= 0;
//             roundinit <= 1'b0;
//         end else begin
//             outinit <= 0;
//             outinit[WOI+WOF-1:WOI+WOF-1-23] <= val;
//             roundinit <= 1'b0;
//         end
// end else begin
//     always @ (posedge clk or negedge rstn)
//         if(~rstn) begin
//             outinit <= 0;
//             roundinit <= 1'b0;
//         end else begin
//             outinit <= val[23:23-(WOI+WOF-1)];
//             roundinit <= ( ROUND && val[23-(WOI+WOF-1)-1] );
//         end
// end 
// endgenerate

// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         signinit <= 1'b0;
//         expinit  <= 0;
//     end else begin
//         signinit <= sign;
//         if( exp==8'd255 || {24'd0,exp}>WOI+126 )
//             expinit <= 0;
//         else
//             expinit <= {24'd0,exp} - (WOI-1) - 127;
//     end

// // ---------------- stage2: barrel shift ----------------
// reg               sign_s2;
// reg [WOI+WOF-1:0] shifted_s2;
// reg               round_s2;
// integer sh;
// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         sign_s2    <= 1'b0;
//         shifted_s2 <= 0;
//         round_s2   <= 1'b0;
//     end else begin
//         sign_s2 <= signinit;

//         if(expinit > 0) begin
//             // left shift
//             if(expinit < WOI+WOF) begin
//                 shifted_s2 <= outinit << expinit; 
//                 round_s2   <= 1'b0; // 左移不用round
//             end else begin
//                 shifted_s2 <= {WOI+WOF{1'b1}}; // 溢出饱和
//                 round_s2   <= 1'b0;
//             end
//         end else if(expinit < 0) begin
//             // right shift
            
//             sh = -expinit;
//             if(sh < WOI+WOF) begin
//                 shifted_s2 <= outinit >> sh;
//                 round_s2   <= (ROUND && (sh > 0)) ? outinit[sh-1] : 1'b0;
//             end else begin
//                 shifted_s2 <= 0;
//                 round_s2   <= 1'b0;
//             end
//         end else begin
//             // expinit == 0
//             shifted_s2 <= outinit;
//             round_s2   <= roundinit;
//         end
//     end
// end

// // ---------------- stage3: rounding & sign ----------------
// reg               signl = 1'b0;
// reg [WOI+WOF-1:0] outl = 0;
// reg [WOI+WOF-1:0] outt;

// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         outl <= 0;
//         signl <= 1'b0;
//     end else begin
//         outt = shifted_s2;
//         if(ROUND & round_s2 & ~(&outt))
//             outt = outt + 1;
//         if(sign_s2) begin
//             signl <= (outt!=0);
//             outt  = (~outt) + ONEO;
//         end else
//             signl <= 1'b0;
//         outl <= outt;
//     end

// // ---------------- stage4: overflow control ----------------
// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         out <= 0;
//         overflow <= 1'b0;
//     end else begin
//         out <= outl;
//         overflow <= 1'b0;
//         if(signl) begin
//             if(~outl[WOI+WOF-1]) begin
//                 out[WOI+WOF-1] <= 1'b1;
//                 out[WOI+WOF-2:0] <= 0;
//                 overflow <= 1'b1;
//             end
//         end else begin
//             if(outl[WOI+WOF-1]) begin
//                 out[WOI+WOF-1] <= 1'b0;
//                 out[WOI+WOF-2:0] <= {(WOI+WOF){1'b1}};
//                 overflow <= 1'b1;
//             end
//         end
//     end

// endmodule


module float2fxp_pipe #(
    parameter WOI  = 8,
    parameter WOF  = 8,
    parameter ROUND= 1
)(
    input  wire               rstn,
    input  wire               clk,
    input  wire [31:0]        in,
    input  wire               ena,           // 新增输入有效信号
    output reg  [WOI+WOF-1:0] out,
    output reg                overflow,
    output reg                out_valid      // 输出有效信号
);

localparam [WOI+WOF-1:0] ONEO = 1;

initial {out, overflow, out_valid} = 0;

// input comb
wire        sign;
wire [ 7:0] exp;
wire [23:0] val;

assign {sign,exp,val[22:0]} = in;
assign val[23] = |exp; // 判断是否全为0

// ---------------- stage1 ----------------
reg signinit=1'b0, roundinit=1'b0;
reg signed [31:0] expinit = 0;
reg [WOI+WOF-1:0] outinit = 0;
reg valid_s1 = 1'b0;

generate 
if(WOI+WOF-1>=23) begin
    always @ (posedge clk or negedge rstn)
        if(~rstn) begin
            outinit <= 0;
            roundinit <= 1'b0;
            valid_s1 <= 1'b0;
        end else if(ena) begin
            outinit <= 0;
            outinit[WOI+WOF-1:WOI+WOF-1-23] <= val;
            roundinit <= 1'b0;
            valid_s1 <= 1'b1;
        end else
            valid_s1 <= 1'b0;
end else begin
    always @ (posedge clk or negedge rstn)
        if(~rstn) begin
            outinit <= 0;
            roundinit <= 1'b0;
            valid_s1 <= 1'b0;
        end else if(ena) begin
            outinit <= val[23:23-(WOI+WOF-1)];
            roundinit <= ( ROUND && val[23-(WOI+WOF-1)-1] );
            valid_s1 <= 1'b1;
        end else
            valid_s1 <= 1'b0;
end 
endgenerate

always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        signinit <= 1'b0;
        expinit  <= 0;
    end else if(ena) begin
        signinit <= sign;
        if( exp==8'd255 || {24'd0,exp}>WOI+126 )
            expinit <= 0;
        else
            expinit <= {24'd0,exp} - (WOI-1) - 127;
    end

// ---------------- stage2: barrel shift ----------------
reg               sign_s2;
reg [WOI+WOF-1:0] shifted_s2;
reg               round_s2;
reg               valid_s2;
integer sh;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        sign_s2    <= 1'b0;
        shifted_s2 <= 0;
        round_s2   <= 1'b0;
        valid_s2   <= 1'b0;
    end else begin
        sign_s2  <= signinit;
        valid_s2 <= valid_s1;

        if(valid_s1) begin
            if(expinit > 0) begin
                if(expinit < WOI+WOF) begin
                    shifted_s2 <= outinit << expinit;
                    round_s2   <= 1'b0;
                end else begin
                    shifted_s2 <= {WOI+WOF{1'b1}}; // 溢出饱和
                    round_s2   <= 1'b0;
                end
            end else if(expinit < 0) begin
                sh = -expinit;
                if(sh < WOI+WOF) begin
                    shifted_s2 <= outinit >> sh;
                    round_s2   <= (ROUND && (sh > 0)) ? outinit[sh-1] : 1'b0;
                end else begin
                    shifted_s2 <= 0;
                    round_s2   <= 1'b0;
                end
            end else begin
                shifted_s2 <= outinit;
                round_s2   <= roundinit;
            end
        end
    end
end

// ---------------- stage3: rounding & sign ----------------
reg               signl = 1'b0;
reg [WOI+WOF-1:0] outl = 0;
reg [WOI+WOF-1:0] outt;
reg               valid_s3;
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        outl <= 0;
        signl <= 1'b0;
        valid_s3 <= 1'b0;
    end else begin
        valid_s3 <= valid_s2;
        if(valid_s2) begin
            outt = shifted_s2;
            if(ROUND & round_s2 & ~(&outt))
                outt = outt + 1;
            if(sign_s2) begin
                signl <= (outt!=0);
                outt  = (~outt) + ONEO;
            end else
                signl <= 1'b0;
            outl <= outt;
        end
    end

// ---------------- stage4: overflow control ----------------
reg valid_s4;
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        out <= 0;
        overflow <= 1'b0;
        out_valid <= 1'b0;
        valid_s4 <= 1'b0;
    end else begin
        valid_s4 <= valid_s3;
        out_valid <= valid_s3;

        if(valid_s3) begin
            out <= outl;
            overflow <= 1'b0;
            if(signl) begin
                if(~outl[WOI+WOF-1]) begin
                    out[WOI+WOF-1] <= 1'b1;
                    out[WOI+WOF-2:0] <= 0;
                    overflow <= 1'b1;
                end
            end else begin
                if(outl[WOI+WOF-1]) begin
                    out[WOI+WOF-1] <= 1'b0;
                    out[WOI+WOF-2:0] <= {(WOI+WOF){1'b1}};
                    overflow <= 1'b1;
                end
            end
        end
    end

endmodule












// 下面这个版本是for循环版本，使用了WOI+WOF个pipeline stage
/*
for(ii=0;ii<WOI+WOF;ii=ii+1) begin
    if(expinit[ii]) begin
        if(expinit>0) outs[ii] <= outs[ii+1]<<ii;
        else outs[ii] <= outs[ii+1]>>ii;
    end else begin
        outs[ii] <= outs[ii+1];
    end
end

每次只处理 expinit 的某一位（像二进制移位累加器）结果是一个流水线，每一拍移一次，直到完成全部移位。
*/


// module float2fxp_pipe #(
//     parameter WOI  = 8,
//     parameter WOF  = 8,
//     parameter ROUND= 1
// )(
//     input  wire               rstn,
//     input  wire               clk,
//     input  wire        [31:0] in,
//     output reg  [WOI+WOF-1:0] out,
//     output reg                overflow
// );


// localparam [WOI+WOF-1:0] ONEO = 1;

// initial {out, overflow} = 0;

// // input comb
// wire        sign;
// wire [ 7:0] exp;
// wire [23:0] val;

// assign {sign,exp,val[22:0]} = in;  // get exp and matissa
// assign val[23] = |exp; // 判断是否全为0

// // pipeline stage1
// reg signinit=1'b0, roundinit=1'b0;
// reg signed [31:0] expinit = 0;
// reg [WOI+WOF-1:0] outinit = 0;

// generate if(WOI+WOF-1>=23) begin
//     always @ (posedge clk or negedge rstn)
//         if(~rstn) begin
//             outinit <= 0;
//             roundinit <= 1'b0;
//         end else begin
//             outinit <= 0;
//             outinit[WOI+WOF-1:WOI+WOF-1-23] <= val;
//             roundinit <= 1'b0;
//         end
// end else begin
//     always @ (posedge clk or negedge rstn)
//         if(~rstn) begin
//             outinit <= 0;
//             roundinit <= 1'b0;
//         end else begin
//             outinit <= val[23:23-(WOI+WOF-1)];
//             roundinit <= ( ROUND && val[23-(WOI+WOF-1)-1] );
//         end
// end endgenerate

// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         signinit <= 1'b0;
//         expinit  <= 0;
//     end else begin
//         signinit <= sign;
//         if( exp==8'd255 || {24'd0,exp}>WOI+126 )
//             expinit <= 0;
//         else
//             expinit <= {24'd0,exp} - (WOI-1) - 127;
//     end

    
// // next pipeline stages
// reg              signs [WOI+WOF :0];
// reg             rounds [WOI+WOF :0]; 
// reg [31:0]        exps [WOI+WOF :0];
// reg [WOI+WOF-1:0] outs [WOI+WOF :0];

// integer ii;

// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         for(ii=0; ii<WOI+WOF+1; ii=ii+1) begin
//             signs[ii]  <= 0;
//             rounds[ii] <= 0;
//             exps[ii]   <= 0;
//             outs[ii]   <= 0;
//         end
//     end else begin
//         for(ii=0; ii<WOI+WOF; ii=ii+1) begin 
//             signs[ii] <= signs[ii+1];
//             if(exps[ii+1]!=0) begin 
//                 {outs[ii], rounds[ii]} <= {       1'b0,   outs[ii+1] };
//                 exps[ii] <= exps[ii+1] + 1;
//             end else begin
//                 {outs[ii], rounds[ii]} <= { outs[ii+1], rounds[ii+1] };
//                 exps[ii] <= exps[ii+1]; 
//             end
//         end
//         signs[WOI+WOF] <= signinit;
//         rounds[WOI+WOF] <= roundinit;
//         exps[WOI+WOF] <= expinit;
//         outs[WOI+WOF] <= outinit;
//     end


// // last 2nd pipeline stage
// reg               signl = 1'b0;
// reg [WOI+WOF-1:0] outl = 0;
// reg [WOI+WOF-1:0] outt;
// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         outl <= 0;
//         signl <= 1'b0;
//     end else begin
//         outt = outs[0];
//         if(ROUND & rounds[0] & ~(&outt))
//             outt = outt + 1;
//         if(signs[0]) begin
//             signl <= (outt!=0);
//             outt  = (~outt) + ONEO;
//         end else
//             signl <= 1'b0;
//         outl <= outt;
//     end

// // last 1st pipeline stage: overflow control
// always @ (posedge clk or negedge rstn)
//     if(~rstn) begin
//         out <= 0;
//         overflow <= 1'b0;
//     end else begin
//         out <= outl;
//         overflow <= 1'b0;
//         if(signl) begin
//             if(~outl[WOI+WOF-1]) begin
//                 out[WOI+WOF-1] <= 1'b1;
//                 out[WOI+WOF-2:0] <= 0;
//                 overflow <= 1'b1;
//             end
//         end else begin
//             if(outl[WOI+WOF-1]) begin
//                 out[WOI+WOF-1] <= 1'b0;
//                 out[WOI+WOF-2:0] <= {(WOI+WOF){1'b1}};
//                 overflow <= 1'b1;
//             end
//         end
//     end

// endmodule

