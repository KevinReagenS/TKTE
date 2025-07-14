// top_level_tb.v
`timescale 1ns/1ps
`include "top_level.v"

module testbench_top_level;

    // Sinyal input dan output
    reg clk;
    reg rst;
    reg [15:0] ecg_sample;
    wire peak_detected;
    wire [15:0] rr_interval;
    wire rr_valid;
    
    // Variabel untuk menghitung nilai RR dalam format desimal
    real rr_decimal;

    // Inisialisasi modul top level
    top_level uut (
        .clk(clk),
        .rst(rst),
        .ecg_sample(ecg_sample),
        .peak_detected(peak_detected),
        .rr_interval(rr_interval),
        .rr_valid(rr_valid)
    );

    // Clock generator
    always #5 clk = ~clk;  // 100 MHz clock (periode 10 ns)

    // Memuat data dari file
    reg [15:0] ecg_data [0:3599];  // 1800 sample
    integer i;
    
    // Fungsi untuk mengkonversi format kustom ke desimal
    function real decode_rr_interval;
        input [15:0] encoded_interval;
        reg sign;
        integer integer_part;
        real frac_part;
        begin
            sign = encoded_interval[15];
            integer_part = encoded_interval[14:11];
            frac_part = encoded_interval[10:0] / 2048.0; // 2^11 = 2048
            
            if (sign)
                decode_rr_interval = -1.0 * (integer_part + frac_part);
            else
                decode_rr_interval = integer_part + frac_part;
        end
    endfunction

    initial begin
        // Inisialisasi awal
        clk = 0;
        rst = 1;
        ecg_sample = 0;

        // Load file biner berisi data ECG
        $readmemb("11peaksnormal.txt", ecg_data);

        // Reset sebentar
        #20;
        rst = 0;

        // Kirim data satu per satu
        for (i = 0; i < 3600; i = i + 1) begin
            ecg_sample = ecg_data[i];
            #10;  // tunggu satu siklus clock
            if (peak_detected)
                $display("Peak detected at time %0t ns, sample index = %0d, value = %b", $time, i, ecg_sample);
            if (rr_valid) begin
                rr_decimal = decode_rr_interval(rr_interval);
                $display("R-R interval detected: %0b (binary format)", rr_interval);
                $display("  Sign bit: %b", rr_interval[15]);
                $display("  Integer part: %b (%0d)", rr_interval[14:11], rr_interval[14:11]);
                $display("  Mantissa part: %b", rr_interval[10:0]);
                $display("  Decoded value: %0.6f seconds", rr_decimal);
                $display("  Heart rate: %0.1f BPM", 60.0/rr_decimal);
            end
        end

        $finish;
    end

endmodule