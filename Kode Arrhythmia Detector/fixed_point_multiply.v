// `timescale 1ns / 1ps

module fixed_point_multiply #(parameter BITSIZE = 16, parameter FRAC = 11 ) (
    input  [BITSIZE-1:0] A,  // BITSIZE-bit fixed-point input (sign-magnitude)
    input  [BITSIZE-1:0] B,  // BITSIZE-bit fixed-point input (sign-magnitude)
    output [BITSIZE-1:0] C   // BITSIZE-bit fixed-point output (sign-magnitude)
);
    // Extract sign bits
    wire sign_A = A[BITSIZE-1];
    wire sign_B = B[BITSIZE-1];

    // Extract magnitude (mantissa + fraction)
    wire [BITSIZE-2:0] mag_A = A[BITSIZE-2:0];
    wire [BITSIZE-2:0] mag_B = B[BITSIZE-2:0];

    // Multiply magnitudes (unsigned multiplication)
    wire [(2*BITSIZE)-3:0] product_unsigned = mag_A * mag_B;

    // Normalize the result by right-shifting FRAC bits
    wire [BITSIZE-2:0] normalized_product = product_unsigned[25:11];

    // Determine the sign of the result
    wire result_sign = sign_A ^ sign_B; // XOR for determining sign

    // Determine if the result is out of bounds
    wire [6:0] overflow = 7'b1111111 & product_unsigned[(2*BITSIZE)-3:26];
    // wire underflow = (result_sign == 1) && (normalized_product[BITSIZE-1:0] < 16'hFFFF);

    // Combine sign and magnitude into final output with saturation
    assign C = overflow ? {result_sign, 15'b111_1111_1111_1111} : {result_sign, normalized_product[BITSIZE-2:0]}; // Concatenate sign and magnitude
    // assign C = overflow;
endmodule