`include "fixed_point_add.v"
`include "fixed_point_multiply.v"

module enc_1 #(parameter BITSIZE = 16) (
    input wire  clk,
    input wire  reset,
    input wire  [BITSIZE*10-1:0]   x,  // Input vector (10 elements)
    input wire  [BITSIZE*6*10-1:0] w,  // Weight matrix (6x10)
    input wire  [BITSIZE*6-1:0]    b,  // Bias vector (6 elements)
    output wire [BITSIZE*6-1:0]    y   // Output vector (6 elements)
);

// Internal signals
wire [BITSIZE-1:0] in_mul_1    [5:0];
wire [BITSIZE-1:0] in_mul_2    [5:0];
wire [BITSIZE-1:0] out_mul     [5:0]; // Parallel multipliers output (6 elements per row)
reg  [BITSIZE-1:0] out_mul_reg [5:0];
wire [BITSIZE-1:0] in_add      [5:0]; // Input to adders (6 elements)
reg  [BITSIZE-1:0] in_add_reg  [5:0];
wire [BITSIZE-1:0] out_add     [5:0]; // Output from adders (6 elements)
reg  [3:0] j;                         // Counter for 10 iterations
reg  done;

// Sequential logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        j <= 0;
        done <= 0;
        out_mul_reg[0] <= 0; out_mul_reg[1] <= 0; out_mul_reg[2] <= 0; out_mul_reg[3] <= 0; out_mul_reg[4] <= 0; out_mul_reg[5] <= 0;  
        in_add_reg[0]  <= 0; in_add_reg[1]  <= 0; in_add_reg[2]  <= 0; in_add_reg[3]  <= 0; in_add_reg[4]  <= 0; in_add_reg[5]  <= 0;
    end else begin
        if (!done) begin
            // $display("j = %d, in mul 1 [3] = %b, in mul 2 [3] = %b, in add [3] = %b", j, in_mul_1[3], in_mul_2[3], out_mul[3]);
            out_mul_reg[0] <= out_mul[0];
            out_mul_reg[1] <= out_mul[1];
            out_mul_reg[2] <= out_mul[2];
            out_mul_reg[3] <= out_mul[3];
            out_mul_reg[4] <= out_mul[4];
            out_mul_reg[5] <= out_mul[5];

            in_add_reg[0] <= in_add[0];
            in_add_reg[1] <= in_add[1];
            in_add_reg[2] <= in_add[2];
            in_add_reg[3] <= in_add[3];
            in_add_reg[4] <= in_add[4];
            in_add_reg[5] <= in_add[5];

            if (j < 10) begin
                // Increment iteration
                j <= j + 1;
            end else begin
                done <= 1;
                // $display("done!");
            end
        end
    end

    // $display("time: %0t\t, clk: %b, reset: %b\t, j = %d, in_mul_1 = %h in_mul_2 = %h out_mul = %h, out_mul_reg = %h, in_add = %h out_add = %h output = %h",
    //          $time, clk, reset, j, in_mul_1[5], in_mul_2[5], out_mul[5], out_mul_reg[5], in_add_reg[5], out_add[5], y[BITSIZE*5 +: BITSIZE]);
end


// Parallel multiplication logic for 6 elements (1 row)
genvar idx;
generate
    for (idx = 0; idx < 6; idx = idx + 1) begin : multiplier
        assign in_mul_1 [idx] = (j == 0) ? x[(BITSIZE*0) +: BITSIZE] :
                                (j == 1) ? x[(BITSIZE*1) +: BITSIZE] :
                                (j == 2) ? x[(BITSIZE*2) +: BITSIZE] :
                                (j == 3) ? x[(BITSIZE*3) +: BITSIZE] :
                                (j == 4) ? x[(BITSIZE*4) +: BITSIZE] :
                                (j == 5) ? x[(BITSIZE*5) +: BITSIZE] :
                                (j == 6) ? x[(BITSIZE*6) +: BITSIZE] :
                                (j == 7) ? x[(BITSIZE*7) +: BITSIZE] :
                                (j == 8) ? x[(BITSIZE*8) +: BITSIZE] : x[(BITSIZE*9) +: BITSIZE];
        assign in_mul_2 [idx] = (j == 0) ? w[(BITSIZE*6*9) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 1) ? w[(BITSIZE*6*8) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 2) ? w[(BITSIZE*6*7) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 3) ? w[(BITSIZE*6*6) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 4) ? w[(BITSIZE*6*5) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 5) ? w[(BITSIZE*6*4) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 6) ? w[(BITSIZE*6*3) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 7) ? w[(BITSIZE*6*2) + (BITSIZE*idx) +: BITSIZE] :
                                (j == 8) ? w[(BITSIZE*6*1) + (BITSIZE*idx) +: BITSIZE] : w[(BITSIZE*6*0) + (BITSIZE*idx) +: BITSIZE];
        
        fixed_point_multiply mul (
            .A(in_mul_1[idx]), // Take x[j]
            .B(in_mul_2[idx]), // Row j, column idx
            .C(out_mul [idx])
        );
    end
endgenerate

// Parallel addition logic for 6 elements
generate
    for (idx = 0; idx < 6; idx = idx + 1) begin : adder
        assign in_add[idx] = (j == 0) ? b[BITSIZE*idx +: BITSIZE] : out_add[idx];

        fixed_point_add add (
            .A(out_mul_reg[idx]),
            .B(in_add_reg [idx]),
            .C(out_add    [idx])
        );

        assign y[BITSIZE*idx +: BITSIZE] = in_add_reg[idx];
    end
endgenerate

// // Assign final output
// always @(posedge clk) begin
//     // if(j < 10) begin
//         out_stage[0] <= out_add[0];
//         out_stage[1] <= out_add[1];
//         out_stage[2] <= out_add[2];
//         out_stage[3] <= out_add[3];
//         out_stage[4] <= out_add[4];
//         out_stage[5] <= out_add[5];
//     // end
// end

// // invert output only
// assign y[BITSIZE*0 +: BITSIZE] = out_stage[0];
// assign y[BITSIZE*1 +: BITSIZE] = out_stage[1];
// assign y[BITSIZE*2 +: BITSIZE] = out_stage[2];
// assign y[BITSIZE*3 +: BITSIZE] = out_stage[3];
// assign y[BITSIZE*4 +: BITSIZE] = out_stage[4];
// assign y[BITSIZE*5 +: BITSIZE] = out_stage[5];

// assign y[BITSIZE*0 +: BITSIZE] = out_stage[0];
// assign y[BITSIZE*1 +: BITSIZE] = out_stage[1];
// assign y[BITSIZE*2 +: BITSIZE] = out_stage[2];
// assign y[BITSIZE*3 +: BITSIZE] = out_stage[3];
// assign y[BITSIZE*4 +: BITSIZE] = out_stage[4];
// assign y[BITSIZE*5 +: BITSIZE] = out_stage[5];

// Update output stage (accumulate instead of overwrite)
// assign out_stage[0] = out_add[0];
// assign out_stage[1] = out_add[1];
// assign out_stage[2] = out_add[2];
// assign out_stage[3] = out_add[3];
// assign out_stage[4] = out_add[4];
// assign out_stage[5] = out_add[5];

endmodule
