// top_level.v
`include "peak_detector.v"
`include "rr_interval_calculator.v"

module top_level(
    clk,
    rst,
    ecg_sample,
    peak_detected,
    rr_interval,
    rr_valid
);
    input clk;
    input rst;
    input [15:0] ecg_sample;
    output peak_detected;
    output [15:0] rr_interval;
    output rr_valid;

    wire peak_detected;

    peak_detector detector (
        .clk(clk),
        .rst(rst),
        .data_in(ecg_sample),
        .peak_detected(peak_detected)
    );
    
    rr_interval_calculator calculator (
        .clk(clk),
        .rst(rst),
        .peak_detected(peak_detected),
        .rr_interval(rr_interval),
        .rr_valid(rr_valid)
    );
endmodule