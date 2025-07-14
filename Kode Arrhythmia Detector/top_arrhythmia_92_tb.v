// Testbench for top_arrhythmia_92
`include "top_arrhythmia_92.v"
`timescale 1ns/1ps

module tb_top_arrhythmia;

  // Parameter
  parameter BITSIZE = 16;

  // Testbench signals
  reg clk;
  reg reset;
  reg [BITSIZE*10-1:0] x;

  wire [BITSIZE*92-1:0] out_intermediate;
  wire [BITSIZE*2-1:0] out_zvar;
  wire [BITSIZE*2-1:0] out_zmean;
  wire [BITSIZE*2-1:0] out_sampling;
  wire [BITSIZE*92-1:0] out_hidden_classifier;
  wire [BITSIZE*2-1:0] y;
  wire done_flag_out;

  // Instantiate the design under test (DUT)
  top_arrhythmia #(BITSIZE) dut (
    .clk(clk),
    .reset(reset),
    .x(x),
    .out_intermediate(out_intermediate),
    .out_zvar(out_zvar),
    .out_zmean(out_zmean),
    .out_sampling(out_sampling),
    .out_hidden_classifier(out_hidden_classifier),
    .y(y),
    .done_flag_out(done_flag_out)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
  end

  // Test sequence
  initial begin
    $dumpfile("top_arrhythmia_92_tb.vcd");
    $dumpvars(0, tb_top_arrhythmia);

    $display("Starting simulation...");

    // Initialize
    reset = 1;
    x = 0;

    #20;
    reset = 0;

    // Give input after reset
    #10;
    x = {
      16'h0100, 16'h0200, 16'h0300, 16'h0400, 16'h0500,
      16'h0600, 16'h0700, 16'h0800, 16'h0900, 16'h0A00
    };

    // Wait for done_flag
    wait (done_flag_out == 1);
    $display("Computation done at time %t", $time);

    // Optionally display outputs
    $display("Output y = %h", y);
    $display("out_intermediate = %h", out_intermediate);
    $display("out_zvar = %h", out_zvar);
    $display("out_zmean = %h", out_zmean);
    $display("out_sampling = %h", out_sampling);
    $display("out_hidden_classifier = %h", out_hidden_classifier);

    #20;
    $finish;
  end

endmodule
