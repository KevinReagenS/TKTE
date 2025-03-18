module compare16_float
(
    input wire [15:0] data, 
    input wire [15:0] x0, x1, x2, x3, x4, x5, x6, x7, 
                       x8, x9, x10, x11, x12, x13, x14, x15,
    input wire [15:0] m0, m1, m2, m3, m4, m5, m6, m7, 
                       m8, m9, m10, m11, m12, m13, m14, m15, m16,
    input wire [15:0] c0, c1, c2, c3, c4, c5, c6, c7, 
                       c8, c9, c10, c11, c12, c13, c14, c15, c16,
    input wire clk,
    input wire reset,
    output reg [15:0] m_out, c_out
);

    reg [15:0] x [0:15]; 
    reg [15:0] m [0:16];
    reg [15:0] c [0:16];
    reg [15:0] flag;

    // Map inputs into array
    always @(*) begin
        x[0] = x0; x[1] = x1; x[2] = x2; x[3] = x3; x[4] = x4; x[5] = x5; x[6] = x6; x[7] = x7;
        x[8] = x8; x[9] = x9; x[10] = x10; x[11] = x11; x[12] = x12; x[13] = x13; x[14] = x14; x[15] = x15;

        m[0] = m0; m[1] = m1; m[2] = m2; m[3] = m3; m[4] = m4; m[5] = m5; m[6] = m6; m[7] = m7;
        m[8] = m8; m[9] = m9; m[10] = m10; m[11] = m11; m[12] = m12; m[13] = m13; m[14] = m14; m[15] = m15; m[16] = m16;

        c[0] = c0; c[1] = c1; c[2] = c2; c[3] = c3; c[4] = c4; c[5] = c5; c[6] = c6; c[7] = c7;
        c[8] = c8; c[9] = c9; c[10] = c10; c[11] = c11; c[12] = c12; c[13] = c13; c[14] = c14; c[15] = c15; c[16] = c16;
    end

    // Split data into sign and magnitude
    wire data_sign = data[15];
    wire [14:0] data_mag = data[14:0];

    reg x_sign [0:15];
    reg [14:0] x_mag [0:15];

    integer i;
    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            x_sign[i] = x[i][15];
            x_mag[i]  = x[i][14:0];
        end
    end

    // Sign-magnitude comparison function
    function compare_sign_mag;
        input sign_a, sign_b;
        input [14:0] mag_a, mag_b;
        begin
            if (sign_a != sign_b) begin
                compare_sign_mag = (sign_a > sign_b);
            end else begin
                if (sign_a == 1'b1) begin
                    compare_sign_mag = (mag_a > mag_b);
                end else begin
                    compare_sign_mag = (mag_a < mag_b);
                end
            end
        end
    endfunction

    // Generate flags
    integer j;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            flag <= 16'b0;
        end else begin
            for (j = 0; j < 16; j = j + 1) begin
                flag[j] <= compare_sign_mag(data_sign, x_sign[j], data_mag, x_mag[j]);
            end
        end
    end

    // Determine m and c based on flag
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            m_out <= 16'h0000;
            c_out <= 16'h0000;
        end else begin
            case (flag)
                16'b0000000000000001: begin m_out <= m[0]; c_out <= c[0]; end
                16'b0000000000000010: begin m_out <= m[1]; c_out <= c[1]; end
                16'b0000000000000100: begin m_out <= m[2]; c_out <= c[2]; end
                16'b0000000000001000: begin m_out <= m[3]; c_out <= c[3]; end
                16'b0000000000010000: begin m_out <= m[4]; c_out <= c[4]; end
                16'b0000000000100000: begin m_out <= m[5]; c_out <= c[5]; end
                16'b0000000001000000: begin m_out <= m[6]; c_out <= c[6]; end
                16'b0000000010000000: begin m_out <= m[7]; c_out <= c[7]; end
                16'b0000000100000000: begin m_out <= m[8]; c_out <= c[8]; end
                16'b0000001000000000: begin m_out <= m[9]; c_out <= c[9]; end
                16'b0000010000000000: begin m_out <= m[10]; c_out <= c[10]; end
                16'b0000100000000000: begin m_out <= m[11]; c_out <= c[11]; end
                16'b0001000000000000: begin m_out <= m[12]; c_out <= c[12]; end
                16'b0010000000000000: begin m_out <= m[13]; c_out <= c[13]; end
                16'b0100000000000000: begin m_out <= m[14]; c_out <= c[14]; end
                16'b1000000000000000: begin m_out <= m[15]; c_out <= c[15]; end
                default: begin m_out <= m[16]; c_out <= c[16]; end
            endcase
        end
    end

endmodule