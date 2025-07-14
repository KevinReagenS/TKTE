// peak_detector.v
module peak_detector(
    input clk,
    input rst,
    input [15:0] data_in,
    output reg peak_detected,
    output [15:0] current_threshold // Optional: output current threshold for debugging
);

parameter WINDOW_SIZE = 25;
parameter MIN_DISTANCE = 50;
parameter ADAPTATION_WINDOW = 100; // Window size for threshold adaptation
parameter [15:0] THRESHOLD_MULTIPLIER = 16'b000010110011010;; // 1.0 in IEEE 754 half-precision
parameter [15:0] MIN_THRESHOLD = 16'b000000110011010; // Minimum threshold to avoid noise
parameter [15:0] MAX_THRESHOLD = 16'b000110110011010; // Maximum threshold cap

// Buffers
reg [15:0] window_buffer [0:WINDOW_SIZE-1];
reg [15:0] adaptation_buffer [0:ADAPTATION_WINDOW-1];

// Counters
reg [10:0] sample_counter;
reg [10:0] distance_counter;
reg [10:0] adaptation_counter;

// Threshold calculation variables
reg [15:0] adaptive_threshold;
reg [31:0] sum_accumulator; // For mean calculation
reg [15:0] mean_value;
reg [15:0] max_value;
reg [15:0] std_estimate; // Simplified standard deviation estimate

reg is_max;
integer i;

// Assign output
assign current_threshold = adaptive_threshold;

// Function to compare floating point numbers (same as original)
function is_greater;
    input [15:0] a, b;
    reg a_sign, b_sign;
    reg [3:0] a_int, b_int;
    reg [10:0] a_man, b_man;
    begin
        a_sign = a[15];
        b_sign = b[15];
        a_int = a[14:11];
        b_int = b[14:11];
        a_man = a[10:0];
        b_man = b[10:0];
        
        if(a_sign != b_sign) begin
            is_greater = (b_sign == 1);
        end
        else if(a_int != b_int) begin
            is_greater = (a_int > b_int) ^ a_sign;
        end
        else begin
            is_greater = (a_man > b_man) ^ a_sign;
        end
    end
endfunction

// Simplified floating point addition (for mean calculation)
function [15:0] fp_add;
    input [15:0] a, b;
    // Simplified implementation - in practice you'd want a proper FP adder
    reg [31:0] temp_sum;
    begin
        // Convert to fixed point for simple addition, then back to float
        // This is a simplified approach - real implementation would be more complex
        temp_sum = {16'h0, a} + {16'h0, b};
        fp_add = temp_sum[15:0]; // Simplified - not proper FP math
    end
endfunction

// Simplified floating point multiplication
function [15:0] fp_mult;
    input [15:0] a, b;
    reg [31:0] temp_mult;
    begin
        // Simplified implementation
        temp_mult = a * b;
        fp_mult = temp_mult[15:0]; // Simplified
    end
endfunction

always @(posedge clk or posedge rst) begin
    if(rst) begin
        // Initialize buffers
        for(i = 0; i < WINDOW_SIZE; i = i + 1)
            window_buffer[i] <= 16'b0;
        for(i = 0; i < ADAPTATION_WINDOW; i = i + 1)
            adaptation_buffer[i] <= 16'b0;
            
        // Initialize counters
        sample_counter <= 0;
        distance_counter <= 0;
        adaptation_counter <= 0;
        
        // Initialize threshold calculation variables
        adaptive_threshold <= MIN_THRESHOLD;
        sum_accumulator <= 32'b0;
        mean_value <= 16'b0;
        max_value <= 16'b0;
        std_estimate <= 16'b0;
        
        peak_detected <= 0;
    end
    else begin
        // Update window buffer (for peak detection)
        for(i = WINDOW_SIZE-1; i > 0; i = i - 1)
            window_buffer[i] <= window_buffer[i-1];
        window_buffer[0] <= data_in;
        
        // Update adaptation buffer (for threshold calculation)
        for(i = ADAPTATION_WINDOW-1; i > 0; i = i - 1)
            adaptation_buffer[i] <= adaptation_buffer[i-1];
        adaptation_buffer[0] <= data_in;
        
        // Adaptive threshold calculation
        if(adaptation_counter >= ADAPTATION_WINDOW) begin
            // Calculate statistics from adaptation buffer
            sum_accumulator = 32'b0;
            max_value = adaptation_buffer[0];
            
            // Find max and accumulate sum for mean
            for(i = 0; i < ADAPTATION_WINDOW; i = i + 1) begin
                sum_accumulator = sum_accumulator + {16'h0, adaptation_buffer[i]};
                if(is_greater(adaptation_buffer[i], max_value))
                    max_value = adaptation_buffer[i];
            end
            
            // Calculate mean (simplified)
            mean_value = sum_accumulator[15:0] >> 8; // Divide by 256 (approx for 200)
            
            // Estimate standard deviation as a fraction of (max - mean)
            if(is_greater(max_value, mean_value)) begin
                std_estimate = (max_value - mean_value) >> 2; // Divide by 4
            end else begin
                std_estimate = MIN_THRESHOLD;
            end
            
            // Calculate adaptive threshold: mean + k*std_dev
            // Using mean + 2*std_estimate as threshold
            adaptive_threshold = fp_add(mean_value, std_estimate << 1);
            
            // Apply bounds to threshold
            if(is_greater(MIN_THRESHOLD, adaptive_threshold))
                adaptive_threshold = MIN_THRESHOLD;
            else if(is_greater(adaptive_threshold, MAX_THRESHOLD))
                adaptive_threshold = MAX_THRESHOLD;
        end
        
        // Peak detection logic (using adaptive threshold)
        peak_detected <= 0;
        if(sample_counter >= WINDOW_SIZE && distance_counter >= MIN_DISTANCE) begin
            if(is_greater(data_in, adaptive_threshold)) begin
                is_max = 1;
                for(i = 1; i < WINDOW_SIZE; i = i + 1) begin
                    if(!is_greater(data_in, window_buffer[i])) begin
                        is_max = 0;
                        i = WINDOW_SIZE; // Exit loop
                    end
                end
                if(is_max) begin
                    peak_detected <= 1;
                    distance_counter <= 0;
                end
            end
        end
        
        // Update counters
        sample_counter <= sample_counter + 1;
        if(distance_counter < MIN_DISTANCE)
            distance_counter <= distance_counter + 1;
        if(adaptation_counter < ADAPTATION_WINDOW)
            adaptation_counter <= adaptation_counter + 1;
    end
end

endmodule
