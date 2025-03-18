`include "fixed_point_add.v"
`include "mitchell_mul.v"
`include "compare16_float.v"

module softplus16_slice
#(parameter BITSIZE = 16)
(
    input wire [15:0] data, 
    input wire [15:0] x_0, x_1, x_2, x_3, x_4, x_5, x_6, x_7,
    input wire [15:0] x_8, x_9, x_10, x_11, x_12, x_13, x_14, x_15,
    input wire [15:0] m_0, m_1, m_2, m_3, m_4, m_5, m_6, m_7,
    input wire [15:0] m_8, m_9, m_10, m_11, m_12, m_13, m_14, m_15, m_16,
    input wire [15:0] c_0, c_1, c_2, c_3, c_4, c_5, c_6, c_7,
    input wire [15:0] c_8, c_9, c_10, c_11, c_12, c_13, c_14, c_15, c_16,
    input wire clk,
    input wire reset,
    output reg [15:0] m_out, c_out
);

    wire data_sign = data[15];
    wire [14:0] data_mag = data[14:0];

    wire x_sign [0:15];
    wire [14:0] x_mag [0:15];

    assign x_sign[0] = x_0[15]; assign x_mag[0] = x_0[14:0];
    assign x_sign[1] = x_1[15]; assign x_mag[1] = x_1[14:0];
    assign x_sign[2] = x_2[15]; assign x_mag[2] = x_2[14:0];
    assign x_sign[3] = x_3[15]; assign x_mag[3] = x_3[14:0];
    assign x_sign[4] = x_4[15]; assign x_mag[4] = x_4[14:0];
    assign x_sign[5] = x_5[15]; assign x_mag[5] = x_5[14:0];
    assign x_sign[6] = x_6[15]; assign x_mag[6] = x_6[14:0];
    assign x_sign[7] = x_7[15]; assign x_mag[7] = x_7[14:0];
    assign x_sign[8] = x_8[15]; assign x_mag[8] = x_8[14:0];
    assign x_sign[9] = x_9[15]; assign x_mag[9] = x_9[14:0];
    assign x_sign[10] = x_10[15]; assign x_mag[10] = x_10[14:0];
    assign x_sign[11] = x_11[15]; assign x_mag[11] = x_11[14:0];
    assign x_sign[12] = x_12[15]; assign x_mag[12] = x_12[14:0];
    assign x_sign[13] = x_13[15]; assign x_mag[13] = x_13[14:0];
    assign x_sign[14] = x_14[15]; assign x_mag[14] = x_14[14:0];
    assign x_sign[15] = x_15[15]; assign x_mag[15] = x_15[14:0];

    function compare_sign_mag(input sign_a, sign_b, input [14:0] mag_a, mag_b);
        begin
            if (sign_a != sign_b)
                compare_sign_mag = (sign_a > sign_b);
            else
                compare_sign_mag = (sign_a == 1'b1) ? (mag_a < mag_b) : (mag_a > mag_b);
        end
    endfunction

    reg [3:0] index;

    always @(posedge clk or posedge reset) begin
        if (reset)
            index <= 4'd15;
        else begin
            index <= 4'd15;
            if (compare_sign_mag(data_sign, x_sign[0], data_mag, x_mag[0])) index <= 4'd0;
            if (compare_sign_mag(data_sign, x_sign[1], data_mag, x_mag[1])) index <= 4'd1;
            if (compare_sign_mag(data_sign, x_sign[2], data_mag, x_mag[2])) index <= 4'd2;
            if (compare_sign_mag(data_sign, x_sign[3], data_mag, x_mag[3])) index <= 4'd3;
            if (compare_sign_mag(data_sign, x_sign[4], data_mag, x_mag[4])) index <= 4'd4;
            if (compare_sign_mag(data_sign, x_sign[5], data_mag, x_mag[5])) index <= 4'd5;
            if (compare_sign_mag(data_sign, x_sign[6], data_mag, x_mag[6])) index <= 4'd6;
            if (compare_sign_mag(data_sign, x_sign[7], data_mag, x_mag[7])) index <= 4'd7;
            if (compare_sign_mag(data_sign, x_sign[8], data_mag, x_mag[8])) index <= 4'd8;
            if (compare_sign_mag(data_sign, x_sign[9], data_mag, x_mag[9])) index <= 4'd9;
            if (compare_sign_mag(data_sign, x_sign[10], data_mag, x_mag[10])) index <= 4'd10;
            if (compare_sign_mag(data_sign, x_sign[11], data_mag, x_mag[11])) index <= 4'd11;
            if (compare_sign_mag(data_sign, x_sign[12], data_mag, x_mag[12])) index <= 4'd12;
            if (compare_sign_mag(data_sign, x_sign[13], data_mag, x_mag[13])) index <= 4'd13;
            if (compare_sign_mag(data_sign, x_sign[14], data_mag, x_mag[14])) index <= 4'd14;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            m_out <= 16'h0000;
            c_out <= 16'h0000;
        end else begin
            m_out <= m_0;
            c_out <= c_0;
        end
    end

    wire signed [BITSIZE-1:0] out_mul;
    mitchell_mul #(.BITSIZE(BITSIZE)) custom_mul (.A(data), .B(m_out), .C(out_mul));

    reg [BITSIZE-1:0] out_mul_reg, c_out_reg;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            out_mul_reg <= 0;
            c_out_reg   <= 0;
        end else begin
            out_mul_reg <= out_mul;
            c_out_reg   <= c_out;
        end
    end

    wire signed [BITSIZE-1:0] final_out;
    fixed_point_add #(.BITSIZE(BITSIZE)) custom_add (.A(out_mul_reg), .B(c_out_reg), .C(final_out));

    always @(posedge clk or posedge reset) begin
        if (reset)
            m_out <= 16'h0000;
        else
            m_out <= final_out;
    end

endmodule