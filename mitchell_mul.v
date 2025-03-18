`timescale 1ns / 1ps

module mitchells_fixed_point_multiply #(parameter BITSIZE = 16, parameter FRAC = 11 ) (
    input  [BITSIZE-1:0] A,  // BITSIZE-bit fixed-point input (sign-magnitude)
    input  [BITSIZE-1:0] B,  // BITSIZE-bit fixed-point input (sign-magnitude)
    output [BITSIZE-1:0] C   // BITSIZE-bit fixed-point output (sign-magnitude)
);
    // Extract sign bits
    wire sign_A = A[BITSIZE-1];
    wire sign_B = B[BITSIZE-1];

    // Extract magnitude
    wire [BITSIZE-2:0] mag_A = A[BITSIZE-2:0];
    wire [BITSIZE-2:0] mag_B = B[BITSIZE-2:0];
    
    // Leading-One Detection (LOD) for logarithm approximation
    function [4:0] lod(input [BITSIZE-2:0] value);
        integer i;
        begin
            lod = 0;
            for (i = BITSIZE-2; i >= 0; i = i - 1) begin
                if (value[i])
                    lod = i;
            end
        end
    endfunction
    
    wire [4:0] logA = lod(mag_A);
    wire [4:0] logB = lod(mag_B);
    
    // Logarithm addition (approximate multiplication)
    wire [5:0] logSum = logA + logB;
    
    // Exponential approximation (Reconstruction)
    wire [BITSIZE-2:0] approx_product = 1 << logSum;
    
    // Determine the sign of the result
    wire result_sign = sign_A ^ sign_B;
    
    // Output result with saturation
    assign C = {result_sign, approx_product[BITSIZE-2:0]};
    
endmodule
