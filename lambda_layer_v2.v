// `include "delay3cc_v2.v"
// `include "squareroot_piped_v2.v"
// `include "PRNG.v"
// `include "softplus_8slice_piped_v2.v"

module lambda_layer_v2 (
    input  wire clk,                                  // Clock signal
    input  wire reset,                                // Reset signal
    input  wire [15:0] mean,                          // Mean (16-bit input)
    input  wire [15:0] vare,                           // Variance (16-bit input)
    output wire [15:0] lambda_out                     // Final output (16-bit)
);

    // Internal signals
    wire [15:0] sigma_sqrt;                           // Square root of variance
    wire [15:0] prng_out;                             // Output from PRNG
    wire [15:0] product_var;                          // Result of sigma_sqrt * prng_out
    wire [15:0] delayed_mean;                         // Delayed mean (3 clock cycles)
    wire [15:0] delayed_mean_2;                         // Delayed mean (3 clock cycles)
    wire [15:0] softplus_var;                         // Delayed mean (3 clock cycles)
    wire [15:0] lambda_result;                        // Result of delayed_mean + product
    reg [4:0] seedprng = 5'b11010;

    // Instantiate Delay (3 Clock Cycles)
    delay_3_cycle_v2 delay (
        .clk(clk),
        .in_data(mean),
        .out_data(delayed_mean)
    );
    
    delay_3_cycle_v2 delay2 (
        .clk(clk),
        .in_data(delayed_mean),
        .out_data(delayed_mean_2)
    );
    
    softplus_8slice_piped_v2 softplus_lambda (
        .clk(clk),
        .reset(reset),
        .data_in(vare),
        .data_out(softplus_var)
    );

    // Instantiate Square Root Module (sigma_sqrt = sqrt(var))
    squareroot_piped_v2 sqrt (
        .clk(clk),
        .reset(reset),
        .data_in(softplus_var),
        .data_out(sigma_sqrt)
    );

    // Instantiate PRNG Module (Generate Random Number)
    PRNG prng_instance (
        .clk(clk),
        .rst(reset),
        .seed(seedprng),
        .random_out(prng_out),
        .statee()
    );
    
    reg [15:0] prng_out_reg;
    reg [15:0] sigma_sqrt_reg;
    reg [15:0] delayed_mean_2ke3;
    
    always @(posedge clk) begin
        if (reset) begin
            prng_out_reg <= 16'b0;
            sigma_sqrt_reg <= 16'b0;
            delayed_mean_2ke3 <= 16'b0;
        end else begin
            prng_out_reg <= prng_out;
            sigma_sqrt_reg <= sigma_sqrt;
            delayed_mean_2ke3 <= delayed_mean_2;        
        end
    end

    // Instantiate Multiplier (sigma_sqrt * prng_out)
    fixed_point_multiply mult (
        .A(sigma_sqrt_reg),
        .B(prng_out_reg),
        .C(product_var)
    );
    
    reg [15:0] product_var_reg;
    reg [15:0] delayed_mean_3;
    
    always @(posedge clk) begin
        if (reset) begin
            product_var_reg <= 16'b0;
            delayed_mean_3 <= 16'b0;
        end else begin
            product_var_reg <= product_var;
            delayed_mean_3 <= delayed_mean_2ke3;
        end
    end

    // Instantiate Adder (delayed_mean + product)
    fixed_point_add add (
        .A(delayed_mean_3),
        .B(product_var_reg),
//        .A(delayed_mean_2),
//        .B(product_var),
        .C(lambda_result)
    );
    
    reg [15:0] output_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            output_reg <= 16'b0;
        end else begin
            output_reg <= lambda_result;
        end
    end

    // Assign final output
    assign lambda_out = output_reg;

endmodule
