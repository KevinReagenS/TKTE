// `include "fixed_point_add.v"
// `include "fixed_point_multiply.v"

module enc_4 #(parameter BITSIZE = 16) (
    input wire  clk,
    input wire  reset,
    input wire  [BITSIZE*6-1:0]   x,  // Input vector (6 elements)
    input wire  [BITSIZE*2*6-1:0] w,  // Weight matrix (2x6)
    input wire  [BITSIZE*2-1:0]    b,  // Bias vector (2 elements)
    output wire [BITSIZE*2-1:0]    y   // Output vector (2 elements)
);

// Internal signals
wire [BITSIZE-1:0] in_mul_1    [1:0];
wire [BITSIZE-1:0] in_mul_2    [1:0];
wire [BITSIZE-1:0] out_mul     [1:0]; // Parallel multipliers output (6 elements per row)
reg  [BITSIZE-1:0] out_mul_reg [1:0];
wire [BITSIZE-1:0] in_add      [1:0]; // Input to adders (6 elements)
reg  [BITSIZE-1:0] in_add_reg  [1:0];
wire [BITSIZE-1:0] out_add     [1:0]; // Output from adders (6 elements)
reg  [3:0] j;                         // Counter for 10 iterations
reg  done;

// Sequential logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        j <= 0;
        done <= 0;
        out_mul_reg[0] <= 0; out_mul_reg[1] <= 0;  
        in_add_reg[0]  <= 0; in_add_reg[1]  <= 0;
    end else begin
        if (!done) begin
            out_mul_reg[0] <= out_mul[0];
            out_mul_reg[1] <= out_mul[1];

            in_add_reg[0] <= in_add[0];
            in_add_reg[1] <= in_add[1];

            if (j < 6) begin
                // Increment iteration
                j <= j + 1;
            end else begin
                done <= 1;
            end
        end
    end

    // $display("time: %0t\t\t, clk: %b, reset: %b\t\t, j = %d, in1mul = %h in2mul = %h out_mul: %h\t\t\t, in_add = %h out_add: %h\t\t\t, output: %h\t\t\t",
    //           $time, clk, reset, j, x[BITSIZE*j +: BITSIZE], w[(BITSIZE*6*j) + (BITSIZE*0) +: BITSIZE], out_mul[0], in_add[0], out_add[0], out_stage[0]);
end


// Parallel multiplication logic for 6 elements (1 row)
genvar idx;
generate
    for (idx = 0; idx < 2; idx = idx + 1) begin : multiplier
        assign in_mul_1 [idx] = (j == 0) ? x[(BITSIZE*0) +: BITSIZE] :
                                (j == 1) ? x[(BITSIZE*1) +: BITSIZE] :
                                (j == 2) ? x[(BITSIZE*2) +: BITSIZE] :
                                (j == 3) ? x[(BITSIZE*3) +: BITSIZE] :
                                (j == 4) ? x[(BITSIZE*4) +: BITSIZE] : x[(BITSIZE*5) +: BITSIZE];
        assign in_mul_2 [idx] = (j == 0) ? w[(BITSIZE*2*5) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 1) ? w[(BITSIZE*2*4) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 2) ? w[(BITSIZE*2*3) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 3) ? w[(BITSIZE*2*2) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 4) ? w[(BITSIZE*2*1) + (BITSIZE*idx) +: BITSIZE] : w[(BITSIZE*2*0) + (BITSIZE*idx) +: BITSIZE];
                                
        fixed_point_multiply mul (
            .A(in_mul_1[idx]),
            .B(in_mul_2[idx]),
            .C(out_mul [idx])
        );
    end
endgenerate

// Parallel addition logic for 6 elements
generate
    for (idx = 0; idx < 2; idx = idx + 1) begin : adder
        assign in_add[idx] = (j == 0) ? b[BITSIZE*idx +: BITSIZE] : out_add[idx];

        fixed_point_add add (
            .A(out_mul_reg[idx]),
            .B(in_add_reg [idx]),
            .C(out_add    [idx])
        );

        assign y[BITSIZE*idx +: BITSIZE] = in_add_reg[idx];
    end
endgenerate

endmodule
