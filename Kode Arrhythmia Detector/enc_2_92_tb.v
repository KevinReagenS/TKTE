`timescale 1ns/1ps
`include "enc_2_92.v"

module tb_enc_2_92_batch32;
  parameter BITSIZE = 16, IN_SIZE = 92, OUT_SIZE = 4, BATCH = 32;

  reg clk, reset;
  reg [BITSIZE*IN_SIZE-1:0]        x;
  reg [BITSIZE*OUT_SIZE*IN_SIZE-1:0] w;
  reg [BITSIZE*OUT_SIZE-1:0]       b;
  wire [BITSIZE*OUT_SIZE-1:0]      y;
  wire                             done_all;

  // DUT
  enc_2_92_batch32 #(
    .BITSIZE(BITSIZE),
    .IN_SIZE(IN_SIZE),
    .OUT_SIZE(OUT_SIZE),
    .BATCH(BATCH)
  ) dut (
    .clk(clk), .reset(reset),
    .x(x), .w(w), .b(b),
    .y(y), .done_all(done_all)
  );

  integer i;
  initial clk = 0; always #5 clk = ~clk;

  initial begin
    $dumpfile("enc_2_92_tb.vcd");
    $dumpvars(0, tb_enc_2_92_batch32);

    // Set inputs BEFORE reset deasserts
    for (i = 0; i < IN_SIZE;         i = i + 1) x[i*BITSIZE +: BITSIZE] = 16'sd2048;   // 1.0
    for (i = 0; i < OUT_SIZE*IN_SIZE; i = i + 1) w[i*BITSIZE +: BITSIZE] = 16'sd205;   // 0.1
    for (i = 0; i < OUT_SIZE;        i = i + 1) b[i*BITSIZE +: BITSIZE] = 16'sd1024;   // 0.5

    reset = 1;
    #20;
    reset = 0;

    wait(done_all);
    #40;

    $display("=== Final y outputs ===");
    for (i = 0; i < OUT_SIZE; i = i + 1) begin
      $display("y[%0d] fixed = %0d, float = %f",
        i,
        y[i*BITSIZE +: BITSIZE],
        $itor(y[i*BITSIZE +: BITSIZE]) / 2048.0
      );
    end
    $finish;
  end
endmodule