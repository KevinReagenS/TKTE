`timescale 1ns/1ps
`include "enc_3_92.v"

module enc_3_92_tb;

    parameter BITSIZE = 16;
    parameter IN_SIZE = 4;
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

    // Clock generation
    always #5 clk = ~clk;

    enc_3_92_batch32 #(
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
        clk = 0;
        reset = 1;
        #10 reset = 0;

        // === Fill x with 1.0 ===
        for (i = 0; i < IN_SIZE; i = i + 1)
            x[i*BITSIZE +: BITSIZE] = 16'sd2048; // 1.0 in 4.11 fixed-point

        // === Fill w with 0.1 ===
        for (i = 0; i < OUT_SIZE*IN_SIZE; i = i + 1)
            w[i*BITSIZE +: BITSIZE] = 16'sd205; // ~0.1 in 4.11 fixed-point

        // === Fill b with 0.5 ===
        for (i = 0; i < OUT_SIZE; i = i + 1)
            b[i*BITSIZE +: BITSIZE] = 16'sd1024; // 0.5 in 4.11 fixed-point

        // Wait until done
        wait (done_all);
        #20;

        $display("=== Output y ===");
        for (i = 0; i < OUT_SIZE; i = i + 1)
            $display("y[%0d] = %f", i, $itor($signed(y[i*BITSIZE +: BITSIZE])) / (1 << 11));

        $finish;
    end

endmodule