module fixed_point_add #(parameter BITSIZE = 16) (
    input [BITSIZE-1:0] A,  // Fixed-point input A
    input [BITSIZE-1:0] B,  // Fixed-point input B
    output [BITSIZE-1:0] C  // Result output
    // output overflow,
    // output [BITSIZE-2:0] result_value

);
    // Extract sign and value parts from both inputs
    wire sign_A = A[BITSIZE-1];         // Sign bit A
    wire sign_B = B[BITSIZE-1];         // Sign bit B
    wire [BITSIZE-2:0] value_A = A[BITSIZE-2:0]; // Value A
    wire [BITSIZE-2:0] value_B = B[BITSIZE-2:0]; // Value B

    // Result components
    wire [BITSIZE-1:0] sum;
    wire result_sign;
    wire [BITSIZE-2:0] result_value;

    // Perform addition or subtraction based on sign
    assign sum = (sign_A == sign_B) ? (value_A + value_B) : 
                 (value_A > value_B ? (value_A - value_B) : (value_B - value_A));

    // Determine the result sign
    assign result_sign = (sign_A == sign_B) ? sign_A : (value_A > value_B ? sign_A : sign_B);

    // Overflow detection
    // wire overflow = (sign_A == sign_B) && ((sum[BITSIZE-1] != sign_A) || (sum == {1'b1, {BITSIZE-1{1'b0}}}));
    // wire 
    // assign overflow = (sign_A == sign_B) && ((sum[BITSIZE]) || (sum == {1'b1, {BITSIZE-1{1'b0}}}));
    wire overflow = (sign_A == sign_B) && ((sum[BITSIZE-1]));

    // Handle overflow and underflow
    assign result_value = overflow ? {BITSIZE-1{1'b1}} : sum[BITSIZE-2:0];
    
    // $monitor("overflow = %b, result value = %b", overflow, result_value);

    // Combine sign and value for the final result
    assign C = {result_sign, result_value};

endmodule