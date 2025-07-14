`include "top_arrhythmia.v"

module top_arrhythmia_tb;

    // Parameters
    parameter BITSIZE = 16;

    // Inputs
    reg clk;
    reg reset;
    reg [BITSIZE*10-1:0] x;
    // reg valid;

    // Outputs
    wire [BITSIZE-1:0] y1;
    wire [BITSIZE-1:0] y2;
    wire [BITSIZE*2-1:0] y;
    wire done_flag;
    // wire [BITSIZE-1:0] y2;

    // Instantiate the Unit Under Test (UUT)
    top_arrhythmia #(BITSIZE) uut (
        .clk(clk),
        .reset(reset),
        .x(x),
        .y({y1,y2}),
        .done_flag_out(done_flag)
    );

/// for output ///
    localparam max_data = 25;
    integer i;
    integer sum;
    integer true;
    logic pred  [max_data-1:0];
    logic reall [max_data-1:0];

    function logic compare_sign_mag;
        input [15:0] val_a;
        input [15:0] val_b;  // Declare inputs as 16-bit
        logic sign_a;
        logic sign_b;
        logic [14:0] mag_a;
        logic [14:0] mag_b;

        begin
            // Extract sign and magnitude
            sign_a = val_a[15];
            sign_b = val_b[15];
            mag_a = val_a[14:0];
            mag_b = val_b[14:0];

            // Compare based on sign and magnitude
            if (sign_a != sign_b) begin
                // If signs differ, the negative number is smaller
                compare_sign_mag = (sign_a < sign_b);  // 1 if A > B
            end else begin
                // If signs are the same, compare magnitudes
                if (sign_a == 1'b1) begin
                    // Both negative: larger magnitude means smaller number
                    compare_sign_mag = (mag_a < mag_b);  // 1 if (-)A > (-)B
                end else begin
                    // Both positive: larger magnitude means larger number
                    compare_sign_mag = (mag_a > mag_b);  // 1 if A > B
                end
            end
        end
    endfunction

    function real b2f(input logic [15:0] binary_str);
        logic sign;
        logic [3:0] integer_part;
        logic [10:0] fractional_part;
        real frac_value;
        real float_value;
        int i;

        // Extract sign, integer, and fractional parts
        sign = binary_str[15];
        integer_part = binary_str[14:11];
        fractional_part = binary_str[10:0];

        // Calculate fractional value
        frac_value = 0.0;
        for (i = 0; i < 11; i = i + 1) begin
            if (fractional_part[i] == 1'b1) begin
                frac_value = frac_value + (1.0 / (2 ** (i + 1)));
            end
        end

        // Combine integer and fractional parts
        float_value = integer_part + frac_value;

        // Apply sign
        if (sign == 1'b1) begin
            float_value = -float_value;
        end

        return float_value;
    endfunction
/// for output ///

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 time units period
    end

    // Test sequence
    initial begin

    #600;
    reset = 1;
    x = 0;
    // Wait for global reset to finish
    #20;
    reset = 0;

    // Testcase 1 False
    x = {
    16'b0000010001110001,
    16'b0000001110110100,
    16'b0000001101001001,
    16'b0000001101101011,
    16'b0000001010101110,
    16'b0000010010011011,
    16'b0000001010100111,
    16'b0000010000110000,
    16'b0000001110011000,
    16'b0000001101101011
    };

    reall[0] = 0;
    pred[0] = compare_sign_mag(y1, y2);

    // #600;
    // reset = 1;
    // x = 0;
    // // Wait for global reset to finish
    // #20;
    // reset = 0;


        // $dumpfile("top_arrhythmia_tb.vcd");
        // $dumpvars(0, top_arrhythmia_tb);
        // Initialize Inputs
        reset = 1;
        x = 0;

        // Wait for global reset to finish
        #10;
        reset = 0;

        // Test case index 0 True (y1 > y2)
        x = {
        16'b0000010000101100,
        16'b0000000111111100,
        16'b0000011001011111,
        16'b0000010001100111,
        16'b0000010000110111,
        16'b0000000101001111,
        16'b0000000101010010,
        16'b0000010111101001,
        16'b0000001110110110,
        16'b0000001010111111
        };
        #600;
        reall[0] = 1;
        pred[0] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase index 2 False (y1 < y2)
        x = {
        16'b0000010111011011,
        16'b0000011000001101,
        16'b0000010111111001,
        16'b0000010111010001,
        16'b0000010110101110,
        16'b0000010110101001,
        16'b0000010110000101,
        16'b0000010110111000,
        16'b0000010111001100,
        16'b0000011000001000
        };
        #600;
        reall[2] = 0;
        pred [2] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase index 4 True (y1 > y2)
        x = {
        16'b0000001110111011,
        16'b0000011001011110,
        16'b0000001011101000,
        16'b0000010110111111,
        16'b0000001101011000,
        16'b0000001100001010,
        16'b0000001100001010,
        16'b0000010010111001,
        16'b0000010010010110,
        16'b0000010011010111
        };
        #600;
        reall[4] = 1;
        pred [4] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase 5 False (y1 < y2)
        x = {
        16'b0000010110011010,
        16'b0000010101001001,
        16'b0000010101011000,
        16'b0000010111110100,
        16'b0000011000000011,
        16'b0000010101111011,
        16'b0000010110010000,
        16'b0000010110011010,
        16'b0000010110101110,
        16'b0000010101000100
        };
        #600;
        reall[5] = 0;
        pred [5] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase 6 True (y1 > y2)
        x = {
        16'b0000010001100011,
        16'b0000001010111111,
        16'b0000100000000000,
        16'b0000010111101101,
        16'b0000010111001110,
        16'b0000001111000000,
        16'b0000011110010110,
        16'b0000010111101101,
        16'b0000010111011101,
        16'b0000001110110110
        };
        #600;
        reall[6] = 1;
        pred [6] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase 9 False (y1 < y2)
        x = {
        16'b0000011000001111,
        16'b0000010111101001,
        16'b0000010111000011,
        16'b0000011000101111,
        16'b0000011000011100,
        16'b0000010111111100,
        16'b0000010111010110,
        16'b0000010111111100,
        16'b0000010111100011,
        16'b0000011000001111
        };
        #600;
        reall[9] = 0;
        pred [9] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase 12 False
        x = {
        16'b0000010111111110,
        16'b0000010111111000,
        16'b0000010111101100,
        16'b0000010111110010,
        16'b0000011000101101,
        16'b0000010111101100,
        16'b0000011000000100,
        16'b0000010111011011,
        16'b0000010111010101,
        16'b0000010111101100
        };
        #600;
        reall[12] = 0;
        pred [12] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase 13 False
        x = {
        16'b0000010011101110,
        16'b0000010100000011,
        16'b0000010011110011,
        16'b0000010100000011,
        16'b0000010011111011,
        16'b0000010011111111,
        16'b0000010100110001,
        16'b0000010001110010,
        16'b0000010101101111,
        16'b0000010100111101
        };
        #600;
        reall[13] = 0;
        pred [13] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase 14 True
        x = {
        16'b0000001100000011,
        16'b0000010110000000,
        16'b0000001011110010,
        16'b0000010100011011,
        16'b0000001111001111,
        16'b0000001110000011,
        16'b0000001111010110,
        16'b0000010010110111,
        16'b0000010001100100,
        16'b0000010001110010
        };
        #600;
        reall[14] = 1;
        pred [14] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase 15 True
        x = {
        16'b0000010110111101,
        16'b0000010110100011,
        16'b0000010110110000,
        16'b0000010110001010,
        16'b0000010111000011,
        16'b0000010111001001,
        16'b0000010110110000,
        16'b0000010110001010,
        16'b0000010110100011,
        16'b0000010110101010
        };
        #600;
        reall[15] = 1;
        pred [15] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase 20 False
        x = {
        16'b0000010011100010,
        16'b0000010010111101,
        16'b0000010011101111,
        16'b0000010011110010,
        16'b0000010010101100,
        16'b0000010011101100,
        16'b0000010011010001,
        16'b0000011100110101,
        16'b0000001110110011,
        16'b0000010101101101
        };
        #600;
        reall[20] = 0;
        pred [20] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;

        // Testcase 23 False
        x = {
        16'b0000010111111100,
        16'b0000010111101000,
        16'b0000010101100100,
        16'b0000011001011111,
        16'b0000010110111010,
        16'b0000011000101010,
        16'b0000011001100110,
        16'b0000011001010010,
        16'b0000011000010000,
        16'b0000010111111100
        };
        #600;
        reall[23] = 0;
        pred [23] = compare_sign_mag(y1, y2);

        reset = 1;
        x = 0;
        // Wait for global reset to finish
        #10;
        reset = 0;



        // Initialize variables
        // sum = 0;
        // true = 0;

        // for (i = 0; i < max_data; i = i + 1) begin
        //     if (!(reall[i] === 1'bx || pred[i] === 1'bx)) begin
                // $display("testcase: %d, real: %b, pred: %b ------ y1_out: %b, y2_out: %b, in float: %f, %f", 0, reall[0], pred[0], y1, y2, b2f(y1), b2f(y2));
        //         sum = sum + 1;
        //         if (reall[i] == pred[i]) begin
        //             true = true + 1;
        //         end
        //     end
        // end

        // if (sum > 0) begin
        //     $display("accuracy = (%d / %d) = %.3f%%", true, sum, true * 100.0 / sum);
        // end else begin
        //     $display("No valid test cases to calculate accuracy.");
        // end

        // Finish simulation
        $finish;
    end

    initial begin
        // // Initialize variables
        // sum = 0;
        // true = 0;

        // for (i = 0; i < 25; i = i + 1) begin
        //     if (!(reall[i] === 1'bx || pred[i] === 1'bx)) begin
        //         $display("testcase: %d, real: %b, pred: %b", i, reall[i], pred[i]);
        //         sum = sum + 1;
        //         if (reall[i] == pred[i]) begin
        //             true = true + 1;
        //         end
        //     end
        // end

        // if (sum > 0) begin
        //     $display("accuracy = %4d / %4d = %4f", true, sum, true * 1.0 / sum);
        // end else begin
        //     $display("No valid test cases to calculate accuracy.");
        // end
    end

endmodule
