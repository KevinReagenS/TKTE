module delay_3_cycle (
    input  wire clk,                     // Clock signal
    input  wire [15:0] in_data,          // Input data (16-bit)
    output reg  [15:0] out_data          // Output data (16-bit)
);

    // Shift register to hold intermediate values
    reg [15:0] shift_reg [0:2];

    always @(posedge clk) begin
        // Shift data
        shift_reg[0] <= in_data;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];

        // Output delayed data
        out_data <= shift_reg[2];
    end

endmodule
