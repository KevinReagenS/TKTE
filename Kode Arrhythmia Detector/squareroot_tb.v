`timescale 1ns/1ps
`include "squareroot.v"       

module squareroot_piped_tb;
    // Parameters
    parameter BITSIZE = 16;
    parameter CLK_PERIOD = 10;

    // Signals
    reg clk;
    reg reset;
    reg [BITSIZE-1:0] data_in;
    wire [BITSIZE-1:0] data_out;

    // Device Under Test
    squareroot_piped #(
        .BITSIZE(BITSIZE)
    ) dut (
        .data_in(data_in),
        .data_out(data_out),
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    initial begin
        clk = 1;
        forever #5 clk = ~clk; // 10ns period clock
    end

    // Test stimulus
    initial begin
        $display("Starting sampling_VAE testbench...");
        $display("Testing different regions of the piecewise approximation");
        
        // Initialize
        data_in = 0;
        reset = 1;
        #CLK_PERIOD;

        reset = 0;
        #CLK_PERIOD;

        // Test Region 1 (below x1 = 0.00916727)
        data_in = 16'b0000000000001110; // 0.00716727
        #(CLK_PERIOD*3);
        $display("Output 1 in Binary: %b", data_out);
        
        // Test around x1-x2 boundary
        data_in = 16'b0000000000101000; // Around 0.02
        #(CLK_PERIOD*3);
        $display("Output 2 in Binary: %b", data_out);

        // Test around x2-x3 boundary
        data_in = 16'b0000000110011001; // Around 0.2
        #(CLK_PERIOD*3);
        $display("Output 3 in Binary: %b", data_out);

        // Test around x3-x4 boundary
        data_in = 16'b0000010000000000; // 0.5
        #(CLK_PERIOD*3);
        $display("Output 4 in Binary: %b", data_out);

        // Test around x4-x5 boundary
        data_in = 16'b0000100000000000; // 1
        #(CLK_PERIOD*3);
        $display("Output 5 in Binary: %b", data_out);

        // Test around x5-x6 boundary
        data_in = 16'b0001000000000000; // 2
        #(CLK_PERIOD*3);
        $display("Output 6 in Binary: %b", data_out);

        // Test around x6-x7 boundary
        data_in = 16'b0010000000000000; // 4
        #(CLK_PERIOD*3);
        $display("Output 7 in Binary: %b", data_out);

        // Test around x7-x8 boundary
        data_in = 16'b0010110000000000; // 5.5
        #(CLK_PERIOD*3);
        $display("Output 8 in Binary: %b", data_out);

        // Test above x8 (last region)
        data_in = 16'b0011100000000000; // 7
        #(CLK_PERIOD*3);
        $display("Output 9 in Binary: %b", data_out);

/*         // Test negative numbers (should handle sign properly)
        data_in = 16'h8400; // Negative number
        #CLK_PERIOD;
        $display("Output 10 in Binary: %b", data_out); */
        $display("Testbench completed");
        $finish;
    end

    // Optional: Generate VCD file for waveform viewing
    initial begin
        $dumpfile("squareroot_tb.vcd");
        $dumpvars(0, squareroot_piped_tb);
    end

endmodule