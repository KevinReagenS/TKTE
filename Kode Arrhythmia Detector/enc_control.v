module enc_control (
    input  wire clk,
    input  wire reset,
    output wire [5:0] debug_cc,
    output reg  enc1_start,
    output reg  enc2_start,
    output reg  lambda_start,
    output reg  enc3_start,
    output reg  enc4_start,
    output reg  done_flag
);

    // Parameter untuk batasan waktu
    localparam offset    = 2;
    localparam enc1_cc   = 12;
    localparam softplus1 = 3;
    localparam enc2_cc   = 8;
    localparam softplus2 = 3;
    localparam lambda    = 8;
    localparam enc3_cc   = 3;
    localparam softplus3 = 3;
    localparam enc4_cc   = 8;
    localparam sigmoid   = 3;

    // Register untuk menghitung clock cycles
    reg [6:0] cc;

    // Debug output
    assign debug_cc = cc;

    // Logika sinkron (clock dan reset)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset semua register
            cc          <= 0;
            enc1_start  <= 1;
            enc2_start  <= 1;
            enc3_start  <= 1;
            enc4_start  <= 1;
            done_flag   <= 0;
        end else begin
            // Jika belum selesai, naikkan nilai cc
            if (!done_flag) begin
                cc <= cc + 1;

                // Update sinyal berdasarkan nilai cc
                case (cc)
                    offset: 
                        enc1_start <= 0;

                    offset + enc1_cc + softplus1:
                        enc2_start <= 0;

                    offset + enc1_cc + softplus1 + enc2_cc:
                        lambda_start <= 0;

                    offset + enc1_cc + softplus1 + enc2_cc + softplus2 + lambda:
                        enc3_start <= 0;

                    offset + enc1_cc + softplus1 + enc2_cc + softplus2 + lambda + enc3_cc + softplus3:
                        enc4_start <= 0;

                    offset + enc1_cc + softplus1 + enc2_cc + softplus2 + lambda + enc3_cc + softplus3 + enc4_cc + sigmoid:
                        done_flag <= 1;

                    default: begin
                        enc1_start   <= enc1_start;
                        enc2_start   <= enc2_start;
                        lambda_start <= lambda_start;
                        enc3_start   <= enc3_start;
                        enc4_start   <= enc4_start;
                        done_flag    <= done_flag;
                    end
                endcase
            end
        end
    end

endmodule
