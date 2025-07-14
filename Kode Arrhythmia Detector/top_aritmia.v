`include "enc_control.v"
`include "enc_1_92.v"
`include "enc_2_92.v"
`include "lambda_layer_v2.v"

module top_aritmia #(parameter BITSIZE = 16)(
    input clk,
    input reset,
    input [BITSIZE*10-1:0] x,
    output [BITSIZE*92-1:0] out_intermediate,
    output [BITSIZE*92-1:0] out_zmean,
    output [BITSIZE*92-1:0] out_zvar,
    output [BITSIZE*92-1:0] out_sampling,
    output done_flag
);

    wire enc1_start, enc2_start, lambda_start, dec1_start, dec2_start;
    wire [BITSIZE*92-1:0] enc_1_out;
    wire [BITSIZE*92-1:0] softplus_enc_1_out;
    wire [BITSIZE*92-1:0] z_mean_out, z_logvar_out;
    wire [BITSIZE*92-1:0] sampling_out;

    // Internal register for ReLU activation output
    reg [BITSIZE*92-1:0] softplus_enc_1_out_reg;

    // Bias for encoder 1 (completed to 92 elements)
    wire [BITSIZE*92-1:0] b_enc_1 = {
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, // Fill up to 92 bias values
        {BITSIZE{1'b0}} , {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}},
        {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}, {BITSIZE{1'b0}}
    };

    // Assume w_enc_1 is properly initialized (not shown for brevity)
    wire [BITSIZE*10*92-1:0] w_enc_1;

    // ReLU activation from enc_1_out
    genvar i;
    generate
        for (i = 0; i < 92; i = i + 1) begin
            assign softplus_enc_1_out[BITSIZE*i +: BITSIZE] = enc_1_out[BITSIZE*(i+1)-1] ? {BITSIZE{1'b0}} : enc_1_out[BITSIZE*i +: BITSIZE];
        end
    endgenerate

    always @(posedge clk) begin
        softplus_enc_1_out_reg <= softplus_enc_1_out;
    end

    enc_control control(
        .clk(clk),
        .reset(reset),
        .enc1_start(enc1_start),
        .enc2_start(enc2_start),
        .lambda_start(lambda_start),
        .dec1_start(dec1_start),
        .dec2_start(dec2_start),
        .done_all(done_flag)
    );

    enc_1_92 enc1(
        .clk(clk),
        .reset(enc1_start),
        .x(x),
        .w(w_enc_1),
        .b(b_enc_1),
        .out(enc_1_out)
    );

    enc_2_92 enc2_mean(
        .clk(clk),
        .reset(enc2_start),
        .x(softplus_enc_1_out_reg),
        .out(z_mean_out)
    );

    enc_2_92 enc2_logvar(
        .clk(clk),
        .reset(enc2_start),
        .x(softplus_enc_1_out_reg),
        .out(z_logvar_out)
    );

    lambda_layer_v2 lambda(
        .clk(clk),
        .reset(lambda_start),
        .z_mean(z_mean_out),
        .z_logvar(z_logvar_out),
        .out(sampling_out)
    );

    assign out_intermediate = enc_1_out;
    assign out_zmean = z_mean_out;
    assign out_zvar = z_logvar_out;
    assign out_sampling = sampling_out;

endmodule