// `include "delay3cc.v"
// `include "squareroot.v"
// `include "PRNG.v"

module lambda_layer (
    input  wire clk,                                  // Clock signal
    input  wire reset,                                // Reset signal
    input  wire [15:0] mean,                          // Mean (16-bit input)
    input  wire [15:0] var,                           // Variance (16-bit input)
    output wire [15:0] lambda_out                     // Final output (16-bit)
);

    // Internal signals
    wire [15:0] sigma_sqrt;                           // Square root of variance
    wire [15:0] prng_out;                             // Output from PRNG
    wire [15:0] product_var;                          // Result of sigma_sqrt * prng_out
    wire [15:0] delayed_mean;                         // Delayed mean (3 clock cycles)
    wire [15:0] lambda_result;                        // Result of delayed_mean + product
    reg [4:0] seedprng = 5'b11010;

    // Instantiate Delay (3 Clock Cycles)
    delay_3_cycle delay (
        .clk(clk),
        .in_data(mean),
        .out_data(delayed_mean)
    );

    // Instantiate Square Root Module (sigma_sqrt = sqrt(var))
    squareroot_piped sqrt (
        .clk(clk),
        .reset(reset),
        .data_in(var),
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

    // Instantiate Multiplier (sigma_sqrt * prng_out)
    fixed_point_multiply mult (
        .A(sigma_sqrt),
        .B(prng_out),
        .C(product_var)
    );

    // Instantiate Adder (delayed_mean + product)
    fixed_point_add add (
        .A(delayed_mean),
        .B(product_var),
        .C(lambda_result)
    );

    // Assign final output
    assign lambda_out = lambda_result;

endmodule
