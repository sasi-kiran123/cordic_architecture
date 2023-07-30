module fp_adder(
    a,
    b,
    out,
    mode
);
parameter EXP_SIZE = 8;
parameter SIGN_SIZE = 1; 
parameter MANTISSA_SIZE = 7;
parameter SIGN_BIT = 9;                             
integer i;
input [SIGN_SIZE + EXP_SIZE-1:-MANTISSA_SIZE] a;
input [SIGN_SIZE + EXP_SIZE-1:-MANTISSA_SIZE] b;

input mode;
output [SIGN_SIZE + EXP_SIZE-1:-MANTISSA_SIZE] out;

wire a_sign,b_sign,b_sign1,borrow,carry;
wire [MANTISSA_SIZE-1:0] a_mantissa,b_mantissa,m1_out,m2_out,out_mantissa;
wire [EXP_SIZE-1:0] a_exp,b_exp,sub_exp_out,m3_out,out_exp;
wire [MANTISSA_SIZE:0] p1_out,r1_out,p2_out,r2_out,a1_out;
wire outSignBit,condition;


assign {a_sign,a_exp,a_mantissa} = a;
assign {b_sign1,b_exp,b_mantissa} = b;
assign b_sign = mode ? b_sign1 : (~b_sign1); 

assign condition= (a_sign == b_sign) ? 1:0;
//assign b_sign = mode ? b_sign1 : (~b_sign1); 




sub #(.INPUT_SIZE(8)) s1 (a_exp,b_exp,sub_exp_out,borrow);


mux_2_1 #(.INPUT_SIZE(7)) m1 (b_mantissa,a_mantissa,borrow,m1_out);
mux_2_1 #(.INPUT_SIZE(7)) m2 (a_mantissa,b_mantissa,borrow,m2_out);

prepend #(.INPUT_SIZE(7)) p1 (m1_out,p1_out);
right_shift  #(.INPUT_SIZE(8),.SHIFT_SIZE(EXP_SIZE)) r1 (p1_out,sub_exp_out,r1_out,1'b1);
prepend #(.INPUT_SIZE(7)) p2 (m2_out,p2_out);

wire [7:0] sub_man_out;
wire man_borrow;
sub #(.INPUT_SIZE(8)) s2 (r1_out,p2_out,sub_man_out,man_borrow);
wire [7:0]man3_out,man4_out;
mux_2_1 #(.INPUT_SIZE(8)) m5 (r1_out,p2_out,man_borrow,man3_out);
mux_2_1 #(.INPUT_SIZE(8)) m4 (p2_out,r1_out,man_borrow,man4_out);

mux_2_1 #(.INPUT_SIZE(EXP_SIZE)) m3 (a_exp,b_exp,borrow,m3_out);

adder_sub_8_bit a1 (.a(man3_out),.b(man4_out),.out(a1_out),.condition(condition),.exp(m3_out),.exp_out(out_exp));

//exp_shifter e1(m3_out,carry,out_exp,condition);
//right_shift #(.INPUT_SIZE(8),.SHIFT_SIZE(1)) r2 (a1_out,carry,r2_out,condition);

assign out_mantissa = a1_out[MANTISSA_SIZE-1:0];


assign outSignBit = ((a_exp>b_exp)||((a_exp==b_exp)&&(a_mantissa>b_mantissa))) ? a_sign : b_sign;
assign out = {outSignBit,out_exp,out_mantissa};

endmodule

module mux_2_1 #(parameter INPUT_SIZE = 8)(
    i1,
    i2,
    select,
    out
);
input [INPUT_SIZE-1: 0] i1;
input [INPUT_SIZE-1: 0] i2;
input select;
output [INPUT_SIZE-1: 0] out;

assign out = select ? i2 : i1;

endmodule

module sub #(parameter INPUT_SIZE = 7)(
    a,
    b,
    out,
    borrow
);
input [INPUT_SIZE-1: 0] a;
input [INPUT_SIZE-1: 0] b;
output [INPUT_SIZE-1: 0] out;
output borrow;

wire [INPUT_SIZE-1: 0]par_out;

assign par_out = a-b;
assign borrow = par_out[INPUT_SIZE-1];
assign out = borrow ? -par_out : par_out;

endmodule

module adder_sub_8_bit(
    a,
    b,
    out,
    condition,
    exp,
    exp_out
);
input [7:0] a;
input [7:0] b,exp;
input condition;
output reg [7:0] out;
output reg [7:0]exp_out;
 reg carry;
 integer i;

always @(a,b) begin
    if(condition) {carry,out}=a+b;
    else {carry,out}=a-b;
     exp_out=exp;

    if(condition) begin
        out=out>>carry;
        exp_out=exp_out+carry;
    end
//    else begin
//        for(i=0;i<8;i=i+1)
//       // while(out[7]!=1'b1)
//        begin
//            out=out<<1'b1;
//            exp_out=exp_out-1'b1;
//        end
//    end
end




endmodule

// module right_shift #(parameter INPUT_SIZE = 8,parameter SHIFT_SIZE = 1)(
//     in,
//     shift_amount,
//     out,
//     condition
// );
// input [INPUT_SIZE-1:0] in;
// input [SHIFT_SIZE-1:0] shift_amount;
// output [INPUT_SIZE-1:0] out;
// input condition;
// assign out =condition? in >>> shift_amount : in << shift_amount;

// endmodule

module prepend #(parameter INPUT_SIZE = 7)(
    in,
    out
);
input [INPUT_SIZE-1:0] in;
output [INPUT_SIZE:0] out;

assign out = {1'b1,in};

endmodule

module exp_shifter(
    in,
    c_add,
    out,condition
);
input [7:0] in;
input c_add;
output [7:0] out;
input condition;
assign out = condition ? in + c_add :in;

endmodule
