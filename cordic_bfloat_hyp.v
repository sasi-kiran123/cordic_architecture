

module atanh_LOOKUP_hypb(index, value);
    localparam EXP_SIZE = 8;
    localparam SIGN_SIZE = 1;
    localparam MANTISSA_SIZE = 7;

    input wire signed [7:0] index;
    output reg signed [SIGN_SIZE + EXP_SIZE-1:-MANTISSA_SIZE] value;

    always @(index)
    begin
        case (index)
            -5: value = 16'h4031;  //  atanh(1-2^(-7))=h02_c5481e
            -4: value = 16'h401b;  //  atanh(1-2^(-6))=h02_6c0b28
            -3: value = 16'h4004;  //  atanh(1-2^(-5))
            -2: value = 16'h3fdb;  //  atanh(1-2^(-4))
            -1: value = 16'h3fad;  //  atanh(1-2^(-3))
            0:  value = 16'h3f79;  //  atanh(1-2^(-2))
            1:  value = 16'h3f0c;  //  atanh(2^(-1))
            2:  value = 16'h3e82;  //  atanh(2^(-2))
            3:  value = 16'h3e00;  //  atanh(2^(-3))
            4:  value = 16'h3d80;  //  atanh(2^(-4))
            5:  value = 16'h3d00;  //  atanh(2^(-5))
            6:  value = 16'h3c80;  //  atanh(2^(-6))
            7:  value = 16'h3c00;  //  atanh(2^(-7))
            8:  value = 16'h3b80;  //  atanh(2^(-8))
            9:  value = 16'h3b00;  //  atanh(2^(-9))
            10: value = 16'h3a80;  //  atanh(2^(-10))
            11: value = 16'h39ff;  //  atanh(2^(-11))
            12: value = 16'h3980;  //  atanh(2^(-12))
            13: value = 16'h3900;  //  atanh(2^(-13))
            default: 
                value = 16'h00_00;
        endcase
    end
endmodule

module cordic_bfloat_hypb(
        input clk,
        input EN,
        input [8:-7] z,
        output [15:0] out
);

    parameter EXP_SIZE = 8;
    parameter SIGN_SIZE = 1; 
    parameter MANTISSA_SIZE = 7;
    parameter SIGN_BIT = 9;                          // 8 | 7 6 5 4 3 2 1 0 | -1 -2 -3 -4 -5 -6 -7
                                                     // S |   EXPONENT BIT  |        MANTISSA

    reg signed [SIGN_SIZE + EXP_SIZE-1:-MANTISSA_SIZE] x_;
    reg signed [SIGN_SIZE + EXP_SIZE-1:-MANTISSA_SIZE] y_;
    reg signed [SIGN_SIZE + EXP_SIZE-1:-MANTISSA_SIZE] z_;
    reg signed [7:0] i;
    wire signed [SIGN_SIZE + EXP_SIZE-1:-MANTISSA_SIZE] Z_UPDATE;
    // wire signed [SIGN_SIZE + EXP_SIZE-1:-MANTISSA_SIZE] shifted_out;
    reg IS_FIRST4;
    reg IS_FIRST13;
    wire [8:-7] mid_out;
    wire [15:0] x_shift_out,y_shift_out,x_out,y_out,z_out,x_neg_out,x_pos_out,y_pos_out,y_neg_out;

    atanh_LOOKUP_hypb LOOKUP(
        .index(i),
        .value(Z_UPDATE));

    fp_adder z1 (.mode(z_[SIGN_BIT-1]),.a(z_),.b(Z_UPDATE),.out(z_out));
    // rshift r11 (.a(x_),.shift_size(i),.pos_out(x_pos_out),.neg_out(x_neg_out));
    // rshift r12 (.a(y_),.shift_size(i),.pos_out(y_pos_out),.neg_out(y_neg_out));

    // assign x_shift_out = (i < 1) ? x_neg_out : x_pos_out;
    // assign y_shift_out = (i < 1) ? y_neg_out : y_pos_out;

    rshift r11 (.a(x_),.shift_size(i),.out(x_shift_out));
    rshift r12 (.a(y_),.shift_size(i),.out(y_shift_out));

    fp_adder x1 (.mode(~z_[SIGN_BIT-1]),.a(x_),.b(y_shift_out),.out(x_out));
    fp_adder y1 (.mode(~z_[SIGN_BIT-1]),.a(y_),.b(x_shift_out),.out(y_out));

    fp_adder o (.mode(1'b1),.a(x_out),.b(y_out),.out(mid_out));

    assign out = {mid_out[SIGN_BIT-1],(mid_out[EXP_SIZE-1:0] + 8'd11),mid_out[-1:-MANTISSA_SIZE]};



    always @(posedge clk)
    begin
        if (EN) //  Like Reset
        begin
            x_ <= 16'h3f80;
            y_ <= 16'h00_00;
            // z_ <= {4'h0,z,20'h00000};      // modify for decimal change
            z_ <= z;
            i <= -5;
            IS_FIRST4 <= 1'b1;
            IS_FIRST13 <= 1'b1;
        end
        else
        begin
            if(i<14)
            begin
                i <= i+1;
                x_ <= x_out;
                y_ <= y_out;
                z_ <= z_out;
            end
        end
    end
endmodule

module rshift(
    input [8:-7] a,
    input signed [7:0] shift_size,
    // output [15:0] pos_out,
    // output [15:0] neg_out
    output [15:0] out
);
parameter EXP_SIZE = 8;
parameter SIGN_BIT = 9; 
parameter MANTISSA_SIZE = 7;

wire [15:0] pos_out;
wire [15:0] neg_out;

assign pos_out = (a==16'd0) ? 16'd0 : ((shift_size < 1) ? {a[SIGN_BIT-1],(a[EXP_SIZE-1:0] + shift_size - 8'd2),a[-1:-MANTISSA_SIZE]} : {a[SIGN_BIT-1],a[EXP_SIZE-1:0] - shift_size,a[-1:-MANTISSA_SIZE]});

fp_adder z1 (.mode(1'b0),.a(a),.b(pos_out),.out(neg_out));

assign out = (a==16'd0) ? 16'd0 : ((shift_size < 1) ? neg_out : pos_out);

endmodule