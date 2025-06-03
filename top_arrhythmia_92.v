// imports 
    // `timescale 1ns/1ps
    // Basic needs
    `include "fixed_point_add.v"
    `include "fixed_point_multiply.v"
    `include "compare_8float_v2.v"

    // Big layer    
    `include "enc_1_92.v"
    `include "enc_2_92.v"

    // lambda layer
    `include "lambda_layer_v2.v"
    `include "delay3cc_v2.v"
    `include "squareroot_piped_v2.v"
    `include "PRNG.v"

    // Lanjut big layer
    `include "enc_3_92.v"
    `include "enc_4_92.v"

    // enc
    `include "enc_control.v"

    // Activation function
    `include "sigmoid8_piped.v"
    `include "softplus_8slice_piped_v2.v"
//

module top_arrhythmia #(parameter BITSIZE = 16) (
    input wire  clk,
    input wire  reset,
    input wire  [BITSIZE*10-1:0]   x,  // Input vector (10 elements)    

    //out layer 1 (24 node) (after acti func) 
    output wire [BITSIZE*92-1:0]    out_intermediate,

    //out zvar
    output wire [BITSIZE*2-1:0] out_zvar,       // The dimension of latent space is 2
    //out zmean
    output wire [BITSIZE*2-1:0] out_zmean,

    //out sampling layer (lambda)
    output wire [BITSIZE*2-1:0] out_sampling,

    //out decoder or out hidden classifier is a decoder (24 node) after acti func
    output wire [BITSIZE*92-1:0]    out_hidden_classifier,


    output wire [BITSIZE*2-1:0]    y,   // Output vector (2 elements)
    output wire done_flag_out
);
    // First Layer
    // reg signed[BITSIZE*10*92-1:0] w_enc_1;
    // reg signed[BITSIZE*92-1:0] b_enc_1;
    reg [15:0] w_enc_1 [0:92*10-1];
    wire [BITSIZE*10*92-1:0] w_enc_1_flat;
    reg [15:0] b_enc_1 [0:91];
    wire [BITSIZE*92-1:0] b_enc_1_flat;

    // Second Layer
    reg signed[BITSIZE*92*1-1:0] w_enc_2_mean1;
    reg signed[BITSIZE*1-1:0] b_enc_2_mean1;

    reg signed[BITSIZE*92*1-1:0] w_enc_2_var1;
    reg signed[BITSIZE*1-1:0] b_enc_2_var1;

    reg signed[BITSIZE*92*1-1:0] w_enc_2_mean2;
    reg signed[BITSIZE*1-1:0] b_enc_2_mean2;

    reg signed[BITSIZE*92*1-1:0] w_enc_2_var2;
    reg signed[BITSIZE*1-1:0] b_enc_2_var2;

    // Layer after lambda
    reg signed[BITSIZE*92*2-1:0] w_enc_3;
    reg signed[BITSIZE*92-1:0] b_enc_3;

    // Output layer
    reg signed[BITSIZE*2*92-1:0] w_enc_4;
    reg signed[BITSIZE*2-1:0] b_enc_4;

    initial begin

    $readmemb("intermediate_layer_weights.mem", w_enc_1);
    $readmemb("intermediate_layer_biases.mem", b_enc_1);

    // $readmemb("intermediate_layer_weights.mem", w_enc_2_mean1);
    // $readmemb("intermediate_layer_biases.mem", b_enc_2_mean1);



w_enc_2_mean1 = {
16'b1000101101001101,
16'b1001000101000010,
16'b1001010010010011,
16'b0000011111001111,
16'b1001000000000011,
16'b1000010000100000
};
b_enc_2_mean1 = {
16'b1000000001000101
};
w_enc_2_var1 = {
16'b0000000001100111,
16'b1000100101101101,
16'b1000001110001000,
16'b1001010101110010,
16'b1000110110110110,
16'b1010001101000001
};
b_enc_2_var1 = {
16'b1001100101001010
};
w_enc_3 = {
16'b1000011110110001,
16'b1000110000001011,
16'b0000001110011110,
16'b0000101111001101,
16'b0001001100000110,
16'b1000100110011001
};
b_enc_3 = {
16'b0000000101001100,
16'b0000001000000101,
16'b1000000111011001,
16'b0000001110110110,
16'b0000010100010001,
16'b0000000110011101
};
w_enc_4 = {
16'b0000011011101011,
16'b1000100001010010,
16'b0000000101101011,
16'b1000011100111010,
16'b1000000110001000,
16'b1000010000101101,
16'b1000011110001010,
16'b0000111000010011,
16'b1000001110110000,
16'b0000110111010000,
16'b0000011111001110,
16'b1000001110001010
};
b_enc_4 = {
16'b1000010011110011,
16'b0000010011110011
};


    end

    generate
        for (i = 0; i < 92*10; i = i + 1) begin : flatten_w_enc
            assign w_enc_1_flat[i*16 +: 16] = w_enc_1[i];
        end
    endgenerate

    generate
        for (i = 0; i < 92; i = i + 1) begin : flatten_b_enc
            assign b_enc_1_flat[i*16 +: 16] = b_enc_1[i];
        end
    endgenerate

    // Controller
    wire  enc1_start;
    wire  enc2_start;
    wire  lambda_start;
    wire  enc3_start;
    wire  enc4_start;
    wire  done_flag;
    wire done_all_1, done_all_2, done_all_3, done_all_4;
    assign done_flag_out = done_flag;

    enc_control enc_control_1(
    .clk(clk),
    .reset(reset),
    .debug_cc(),
    .enc1_start(enc1_start),
    .enc2_start(enc2_start),
    .lambda_start(lambda_start),
    .enc3_start(enc3_start),
    .enc4_start(enc4_start),
    .done_flag(done_flag)
    );

    // First layer
    wire [BITSIZE*92-1:0] enc_1_out;

    enc_1_92_batch32 #(.BITSIZE(BITSIZE)) 
    intermediate_layer(
        .clk(clk),
        .reset(enc1_start),
//        .reset(reset),
        .x(x),
        .w(w_enc_1_flat),
        .b(b_enc_1_flat),
        .y(enc_1_out),
        .done_all(done_all_1)
    );

    wire [BITSIZE*92-1:0] softplus_enc_1_out;

    // genvar i;
    // generate
    //     for (i = 0; i < 6; i = i + 1) begin : softplus_layer_enc_1
    //         softplus_8slice_piped_v2 softplus_enc_1 (
    //             .clk(clk),
    //             .reset(reset),
    //             .data_in(enc_1_out[BITSIZE*i +: BITSIZE]),
    //             .data_out(softplus_enc_1_out[BITSIZE*i +: BITSIZE])
    //         );
    //     end
    // endgenerate

    genvar i;
    generate
        for (i = 0; i < 92; i = i + 1) begin : relu_layer_enc_1
            assign softplus_enc_1_out[BITSIZE*i +: BITSIZE] = enc_1_out[BITSIZE*(i+1)-1] ? {BITSIZE{1'b0}} : enc_1_out[BITSIZE*i +: BITSIZE];
        end
    endgenerate
    
    assign out_intermediate = softplus_enc_1_out;                   // <<-- tambahan debugging
    
    reg [BITSIZE*92-1:0] softplus_enc_1_out_reg;
    
    always @(posedge clk or posedge reset) begin
     if (reset) begin
         softplus_enc_1_out_reg <= {BITSIZE*92{1'b0}};  // Reset the register to zero
     end else begin
         softplus_enc_1_out_reg <= softplus_enc_1_out;  // Reset the register to zero
     end
    end

    // enc_2 before lambda 
    wire [BITSIZE*1-1:0] enc_2_mean1_out;
    wire [BITSIZE*1-1:0] enc_2_var1_out;
    wire [BITSIZE*1-1:0] enc_2_mean2_out;
    wire [BITSIZE*1-1:0] enc_2_var2_out;

    enc_2_92_batch32 #(.BITSIZE(BITSIZE)) 
    mean (
        .clk(clk),
        .reset(enc2_start),
        .x(softplus_enc_1_out_reg),
        .w(w_enc_2_mean1),
        .b(b_enc_2_mean1),
        .y(enc_2_mean1_out)
    );

    assign out_zmean = enc_2_mean1_out;                              // <<-- tambahan debugging

    enc_2_92_batch32 #(.BITSIZE(BITSIZE)) 
    ivar (
        .clk(clk),
        .reset(enc2_start),
        .x(softplus_enc_1_out_reg),
        .w(w_enc_2_var1),
        .b(b_enc_2_var1),
        .y(enc_2_var1_out)
    );

    enc_2_92_batch32 #(.BITSIZE(BITSIZE)) 
    mean2 (
        .clk(clk),
        .reset(enc2_start),
        .x(softplus_enc_1_out_reg),
        .w(w_enc_2_mean2),
        .b(b_enc_2_mean2),
        .y(enc_2_mean2_out)
    );

    assign out_zmean = enc_2_mean1_out;                              // <<-- tambahan debugging

    enc_2_92_batch32 #(.BITSIZE(BITSIZE)) 
    ivar2 (
        .clk(clk),
        .reset(enc2_start),
        .x(softplus_enc_1_out_reg),
        .w(w_enc_2_var2),
        .b(b_enc_2_var2),
        .y(enc_2_var2_out)
    );

    assign out_zvar = enc_2_var1_out;                                // <<-- tambahan debugging

    // LAMBDA layer
    wire [BITSIZE*1-1:0] lambda_out1;
    wire [BITSIZE*1-1:0] lambda_out2;
    wire [BITSIZE*2-1:0] lambda_out;

    lambda_layer_v2
    lambda (
    .clk(clk),
    .reset(lambda_start),
    .mean(enc_2_mean1_out),
    .vare(enc_2_var1_out),
    .lambda_out(lambda_out1)
    );

    lambda_layer_v2
    lambda2 (
    .clk(clk),
    .reset(lambda_start),
    .mean(enc_2_mean2_out),
    .vare(enc_2_var2_out),
    .lambda_out(lambda_out2)
    );
    
    assign out_sampling = lambda_out1 & lambda_out2;
    assign out_sampling = lambda_out;                                // <<-- tambahan debugging

    
    // enc_3
    wire [BITSIZE*92-1:0] enc_3_out;

    enc_3_92_batch32 #(.BITSIZE(BITSIZE))
    hidden_classifier(
        .clk(clk),
        .reset(enc3_start),
        .x(lambda_out),
        .w(w_enc_3),
        .b(b_enc_3),
        .y(enc_3_out)
    );

    wire [BITSIZE*92-1:0] softplus_enc_3_out;

    // generate
    //     for (i = 0; i < 6; i = i + 1) begin : softplus_layer_enc_3
    //         softplus_8slice_piped_v2 softplus_enc_3 (
    //             .clk(clk),
    //             .reset(reset),
    //             .data_in(enc_3_out[BITSIZE*i +: BITSIZE]),
    //             .data_out(softplus_enc_3_out[BITSIZE*i +: BITSIZE])
    //         );
    //     end
    // endgenerate
    
    generate
        for (i = 0; i < 92; i = i + 1) begin : relu_layer_enc_3
            assign softplus_enc_3_out[BITSIZE*i +: BITSIZE] = enc_3_out[BITSIZE*(i+1)-1] ? {BITSIZE-1{1'b0}} : enc_3_out[BITSIZE*i +: BITSIZE];
        end
    endgenerate
    
    assign out_hidden_classifier = softplus_enc_3_out;                                // <<-- tambahan debugging
    
    reg [BITSIZE*92-1:0] softplus_enc_3_out_reg;
    
   // genvar i;
    generate
        for (i = 0; i < 92; i = i + 1) begin : reverse_enc_3_out
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    softplus_enc_3_out_reg[BITSIZE*i +: BITSIZE] <= {BITSIZE{1'b0}};
                end else begin
                    softplus_enc_3_out_reg[BITSIZE*i +: BITSIZE] <= softplus_enc_3_out[BITSIZE*(91 - i) +: BITSIZE];
                end
            end
        end
    endgenerate


    // enc_4
    wire [BITSIZE*2-1:0] enc_4_out;

    enc_4_92_batch32 #(.BITSIZE(BITSIZE))
    classifier_output (
        .clk(clk),
        .reset(enc4_start),
        .x(softplus_enc_3_out_reg),
        .w(w_enc_4),
        .b(b_enc_4),
        .y(enc_4_out)
    );
    wire [BITSIZE*2-1:0] enc_4_out_reverse; 
    assign enc_4_out_reverse[BITSIZE*0 +: BITSIZE] = enc_4_out[BITSIZE*1 +: BITSIZE];
    assign enc_4_out_reverse[BITSIZE*1 +: BITSIZE] = enc_4_out[BITSIZE*0 +: BITSIZE];

    wire [BITSIZE*2-1:0] sigmoid_enc_4_out;

    generate
        for (i = 0; i < 2; i = i + 1) begin : sigmoid_layer_enc_4
            sigmoid8_piped sigmoid_enc_4 (
                .clk(clk),
                .reset(reset),
                .data_in(enc_4_out[BITSIZE*i +: BITSIZE]),
                .data_out(sigmoid_enc_4_out[BITSIZE*i +: BITSIZE])
            );
        end
    endgenerate

    assign y = enc_4_out_reverse;

endmodule