`timescale 1ns/1ps
`include "enc_1_92.v"

module enc_1_92_tb;

    parameter BITSIZE = 16;
    parameter IN_SIZE = 10;
    parameter OUT_SIZE = 92;
    parameter BATCH = 32;

    reg clk;
    reg reset;
    reg [BITSIZE*IN_SIZE-1:0] x;
    reg [BITSIZE*OUT_SIZE*IN_SIZE-1:0] w;
    reg [BITSIZE*OUT_SIZE-1:0] b;
    wire [BITSIZE*OUT_SIZE-1:0] y;
    wire done_all;

    integer i;
    integer cycle_count;

    // Clock generation
    always #5 clk = ~clk;

    enc_1_92_batch32 #(
        .BITSIZE(BITSIZE),
        .IN_SIZE(IN_SIZE),
        .OUT_SIZE(OUT_SIZE),
        .BATCH(BATCH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .x(x),
        .w(w),
        .b(b),
        .y(y),
        .done_all(done_all)
    );

    initial begin
        $dumpfile("enc_1_92_tb.vcd");
        $dumpvars(0, enc_1_92_tb);
        
        clk = 0;
        reset = 1;
        cycle_count = 0;
        #10 reset = 0;

        // === Fill x with 1.0 ===
        x[0*BITSIZE +: BITSIZE] = 16'sd2048;
        x[1*BITSIZE +: BITSIZE] = 16'sd1024;
        for (i = 2; i < IN_SIZE; i = i + 1)
            x[i*BITSIZE +: BITSIZE] = 16'sd2048; // 1.0 in 4.11 fixed-point

        // === Fill w with 0.1 ===
        for (i = 0; i < OUT_SIZE*IN_SIZE; i = i + 1)
            w[i*BITSIZE +: BITSIZE] = 16'sd205; // ~0.1 in 4.11 fixed-point

        // === Fill b with 0.5 ===
        for (i = 0; i < OUT_SIZE; i = i + 1)
            b[i*BITSIZE +: BITSIZE] = 16'sd1024; // 0.5 in 4.11 fixed-point

        // Count cycles until done
        while (!done_all) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        #20;

        // Print the output
        $display("=== Output y ===");
        for (i = 0; i < OUT_SIZE; i = i + 1) begin
            $display("y[%0d] = %f", i, $itor($signed(y[i*BITSIZE +: BITSIZE])) / (1 << 11));
        end
        
        $display("Total Clock Cycles: %0d", cycle_count);
        $finish;
    end

endmodule
