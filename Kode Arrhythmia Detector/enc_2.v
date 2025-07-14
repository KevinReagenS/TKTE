// `include "fixed_point_add.v"
// `include "fixed_point_multiply.v"

module enc_2 #(parameter BITSIZE = 16) (
    input wire  clk,
    input wire  reset,
    input wire  [BITSIZE*6-1:0]   x,  // Input vector (6 elements)
    input wire  [BITSIZE*1*6-1:0] w,  // Weight matrix (1x6)
    input wire  [BITSIZE*1-1:0]    b,  // Bias vector (1 element)
    output wire [BITSIZE*1-1:0]    y   // Output vector (1 element)
);

// Internal 
wire [BITSIZE-1:0] in_mul_1;
wire [BITSIZE-1:0] in_mul_2;
wire [BITSIZE-1:0] out_mul;   // Output of multiplier
reg  [BITSIZE-1:0] out_mul_reg;
wire [BITSIZE-1:0] in_add;    // Input to adder
reg  [BITSIZE-1:0] in_add_reg;
wire [BITSIZE-1:0] out_add;   // Output from adder
reg  [2:0] j;                 // Counter for iterations
reg  done;                    // Completion flag

assign  in_add =   (j == 0) ? b : out_add;
assign  in_mul_1 = (j == 0) ? x[(BITSIZE*1*0) +: BITSIZE] :
                   (j == 1) ? x[(BITSIZE*1*1) +: BITSIZE] :
                   (j == 2) ? x[(BITSIZE*1*2) +: BITSIZE] :
                   (j == 3) ? x[(BITSIZE*1*3) +: BITSIZE] :
                   (j == 4) ? x[(BITSIZE*1*4) +: BITSIZE] : x[(BITSIZE*1*5) +: BITSIZE];
assign  in_mul_2 = (j == 0) ? w[(BITSIZE*1*0) +: BITSIZE] :
                   (j == 1) ? w[(BITSIZE*1*1) +: BITSIZE] :
                   (j == 2) ? w[(BITSIZE*1*2) +: BITSIZE] :
                   (j == 3) ? w[(BITSIZE*1*3) +: BITSIZE] :
                   (j == 4) ? w[(BITSIZE*1*4) +: BITSIZE] : w[(BITSIZE*1*5) +: BITSIZE];

always @(posedge clk or posedge reset) begin
    if (reset) begin
        j <= 0;
        done <= 0;
        in_add_reg <= 0;
        out_mul_reg <= 0;
    end else begin
        if (!done) begin
            // Update the output stage
            out_mul_reg <= out_mul;
            in_add_reg <= in_add;
            
            // Increment the counter
            if (j < 6) begin
                j <= j + 1;
            end else begin
                done <= 1;
            end
        end
    end
    // $display("time: %0t\t, clk: %b, reset: %b\t, j = %d, in_mul_1 = %h in_mul_2 = %h out_mul = %h, out_mul_reg = %h, in_add = %h out_add = %h output = %h",
    //          $time, clk, reset, j, in_mul_1, in_mul_2, out_mul, out_mul_reg, in_add_reg, out_add, y);

end


// Parallel multiplication logic for 6 elements (1 row)
fixed_point_multiply mul (
    .A(in_mul_1), // Take x[j]
    .B(in_mul_2), // Row j, column idx
    .C(out_mul)
);

// Parallel addition logic
fixed_point_add add (
    .A(out_mul_reg),
    .B(in_add_reg),
    .C(out_add)
);

// Assign output
assign y = in_add_reg;

endmodule