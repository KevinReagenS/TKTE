// `include "fixed_point_add.v"
// `include "fixed_point_multiply.v"
// `include "compare_8float.v"

module softplus_8slice_piped
(
    input wire  [15:0] data_in,
    output wire [15:0] data_out,
    input clk,
    input reset
);

    reg [15:0] m1 = 16'b0000000000001010;
    reg [15:0] m2 = 16'b0000000001100011;
    reg [15:0] m3 = 16'b0000000100111000;
    reg [15:0] m4 = 16'b0000001001111110;
    reg [15:0] m5 = 16'b0000001111111111;
    reg [15:0] m6 = 16'b0000010110000001;
    reg [15:0] m7 = 16'b0000001110001110;
    reg [15:0] m8 = 16'b0000000110101001;
    reg [15:0] m9 = 16'b0000011111110101;

    reg [15:0] c1 = 16'b0000000001010000;
    reg [15:0] c2 = 16'b0000000110101010;
    reg [15:0] c3 = 16'b0000001110001111;
    reg [15:0] c4 = 16'b0000010100011100;
    reg [15:0] c5 = 16'b0000010110110001;
    reg [15:0] c6 = 16'b0000010100011100;
    reg [15:0] c7 = 16'b0000101010100111;
    reg [15:0] c8 = 16'b0000110001111011;
    reg [15:0] c9 = 16'b0000000001010001;

    reg [15:0] x1 = 16'b1001111100000000;
    reg [15:0] x2 = 16'b1001001000101001;
    reg [15:0] x3 = 16'b1000100110111111;
    reg [15:0] x4 = 16'b1000001100011011;
    reg [15:0] x5 = 16'b0000001100010100;
    reg [15:0] x6 = 16'b0000100111000101;
    reg [15:0] x7 = 16'b0001001000110101;
    reg [15:0] x8 = 16'b0001111011111000;

    // Pipeline registers
    reg [15:0] data_in_stage1, data_in_stage2;
    reg [15:0] m_out_stage1, c_out_stage1;
    reg [15:0] out_mul_stage2, c_out_stage2;

    // Stage 1: Compare
    wire [15:0] m_out, c_out;

    compare_8float custom_mux
    (
        .data  (data_in),
        .x1    (x1),
        .x2    (x2),
        .x3    (x3),
        .x4    (x4),
        .x5    (x5),
        .x6    (x6),
        .x7    (x7),
        .x8    (x8),
        .m1    (m1),
        .m2    (m2),
        .m3    (m3),
        .m4    (m4),
        .m5    (m5),
        .m6    (m6),
        .m7    (m7),
        .m8    (m8),
        .m9    (m9),
        .c1    (c1),
        .c2    (c2),
        .c3    (c3),
        .c4    (c4),
        .c5    (c5),
        .c6    (c6),
        .c7    (c7),
        .c8    (c8),
        .c9    (c9),
        .clk   (clk),
        .reset (reset),
        .m     (m_out),
        .c     (c_out)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_in_stage1 <= 16'b0;
            m_out_stage1 <= 16'b0;
            c_out_stage1 <= 16'b0;
        end else begin
            data_in_stage1 <= data_in;
            m_out_stage1 <= m_out;
            c_out_stage1 <= c_out;
        end
    end

    // Stage 2: Multiply
    wire [15:0] out_mul;

    fixed_point_multiply custom_mul
    (
        .A (data_in_stage1),
        .B (m_out_stage1),
        .C (out_mul)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_in_stage2 <= 16'b0;
            out_mul_stage2 <= 16'b0;
            c_out_stage2 <= 16'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            out_mul_stage2 <= out_mul;
            c_out_stage2 <= c_out_stage1;
        end
    end

    // Stage 3: Add
    fixed_point_add custom_add
    (
        .A (out_mul_stage2),
        .B (c_out_stage2),
        .C (data_out)
    );

endmodule