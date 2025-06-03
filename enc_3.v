// `include "fixed_point_add.v"
// `include "fixed_point_multiply.v"

module enc_3 #(parameter BITSIZE = 16) (
    input wire  clk,
    input wire  reset,
    input wire  [BITSIZE*1-1:0]    x,  // Input vector (1 elements)
    input wire  [BITSIZE*6*1-1:0]  w,  // Weight matrix (6x10)
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
reg  [3:0] j;
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

            if (j < 1) begin
                // Increment iteration
                j <= j + 1;
            end else begin
                done <= 1;
                // $display("done!");
            end
        end
    end
    // $display("time: %0t\t, clk: %b, reset: %b\t, j = %d, in_mul_1 = %h in_mul_2 = %h out_mul = %h, out_mul_reg = %h, in_add = %h out_add = %h output = %h",
    //          $time, clk, reset, j, in_mul_1[0], in_mul_2[0], out_mul[0], out_mul_reg[0], in_add_reg[0], out_add[0], y[BITSIZE*0 +: BITSIZE]);
end


// Parallel multiplication logic for 6 elements (1 row)
genvar idx;
generate
    for (idx = 0; idx < 6; idx = idx + 1) begin : multiplier
        assign in_mul_1 [idx] = x[(BITSIZE*0) +: BITSIZE];
        assign in_mul_2 [idx] = w[(BITSIZE*idx) +: BITSIZE];

        fixed_point_multiply mul (
            .A(in_mul_1[idx]),
            .B(in_mul_2[idx]),
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

endmodule
