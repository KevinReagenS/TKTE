// rr_interval_calculator.v
module rr_interval_calculator(
    input clk,
    input rst,
    input peak_detected,
    output reg [15:0] rr_interval,  // Format: 1 bit sign, 4 bit integer, 11 bit mantissa
    output reg rr_valid
);

reg [15:0] last_peak_pos;
reg [15:0] current_pos;
reg peak_detected_delayed;
reg [15:0] raw_interval;  // Untuk menyimpan interval mentah sebelum dibagi
reg [31:0] calculation_temp; // Untuk perhitungan sementara dengan presisi tinggi

always @(posedge clk or posedge rst) begin
    if(rst) begin
        last_peak_pos <= 0;
        current_pos <= 0;
        rr_interval <= 0;
        raw_interval <= 0;
        calculation_temp <= 0;
        rr_valid <= 0;
        peak_detected_delayed <= 0;
    end
    else begin
        current_pos <= current_pos + 1;
        peak_detected_delayed <= peak_detected;
        
        // Detect rising edge of peak_detected
        if(peak_detected && !peak_detected_delayed) begin
            if(last_peak_pos != 0) begin
                raw_interval <= current_pos - last_peak_pos;
                
                // Calculate RR interval in custom 16-bit floating point format:
                // 1 bit sign (bit 15), 4 bit integer (bits 14-11), 11 bit mantissa (bits 10-0)
                calculation_temp <= (current_pos - last_peak_pos) * (2**11); // Shift left by 11 bits for mantissa precision
                rr_interval[15] <= 0; // Sign bit (always positive for RR intervals)
                
                // Integer part (4 bits) - division by 360
                rr_interval[14:11] <= (current_pos - last_peak_pos) / 360;
                
                // Mantissa part (11 bits) - remainder after division, scaled
                rr_interval[10:0] <= ((current_pos - last_peak_pos) % 360) * (2**11) / 360;
                
                rr_valid <= 1;
            end
            else begin
                rr_valid <= 0;
            end
            last_peak_pos <= current_pos;
        end
        else begin
            rr_valid <= 0;
        end
    end
end

endmodule