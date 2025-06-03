// `include "fixed_point_add.v"
// `include "fixed_point_multiply.v"

module enc_2_92_batch32 #(
    parameter BITSIZE    = 16,
    parameter IN_SIZE    = 92,
    parameter OUT_SIZE   = 4,
    parameter BATCH      = 32
)(
    input  wire                       clk,
    input  wire                       reset,
    input  wire [BITSIZE*IN_SIZE-1:0]      x,
    input  wire [BITSIZE*OUT_SIZE*IN_SIZE-1:0] w,
    input  wire [BITSIZE*OUT_SIZE-1:0]     b,
    output reg  [BITSIZE*OUT_SIZE-1:0]     y,
    output reg                        done_all
);

    localparam BATCH_COUNT = (IN_SIZE + BATCH - 1) / BATCH;

    wire [BITSIZE-1:0] x_vec [0:IN_SIZE-1];
    genvar xi;
    generate
        for (xi = 0; xi < IN_SIZE; xi = xi + 1) begin : UNPACK_X
            assign x_vec[xi] = x[xi*BITSIZE +: BITSIZE];
        end
    endgenerate

    reg [$clog2(BATCH_COUNT)-1:0] batch_idx;
    reg                            done;
    reg                            started;

    reg [BITSIZE-1:0] acc_0, acc_1, acc_2, acc_3;
    reg [BITSIZE-1:0] temp_0, temp_1, temp_2, temp_3;

    integer k;

    reg  [BITSIZE-1:0] mul_reg [0:OUT_SIZE-1][0:BATCH-1];
    wire [BITSIZE-1:0] mul_out [0:OUT_SIZE-1][0:BATCH-1];

    genvar o_idx, i;
    generate
        for (o_idx = 0; o_idx < OUT_SIZE; o_idx = o_idx + 1) begin : MULTS
            for (i = 0; i < BATCH; i = i + 1) begin : LANE
                wire valid = (batch_idx*BATCH + i < IN_SIZE);
                wire [BITSIZE-1:0] x_e = valid ? x_vec[batch_idx*BATCH + i] : {BITSIZE{1'b0}};
                wire [BITSIZE-1:0] w_e = valid 
                    ? w[((o_idx*IN_SIZE) + (batch_idx*BATCH + i))*BITSIZE +: BITSIZE]
                    : {BITSIZE{1'b0}};

                fixed_point_multiply mulI(
                    .A(x_e),
                    .B(w_e),
                    .C(mul_out[o_idx][i])
                );
            end
        end
    endgenerate

    always @(posedge clk) begin
        for (k = 0; k < BATCH; k = k + 1) begin
            mul_reg[0][k] <= mul_out[0][k];
            mul_reg[1][k] <= mul_out[1][k];
            mul_reg[2][k] <= mul_out[2][k];
            mul_reg[3][k] <= mul_out[3][k];
        end
    end

    always @(posedge clk) begin
        // Default all outputs to avoid x
        y         <= {BITSIZE*OUT_SIZE{1'b0}};
        done_all  <= 0;

        if (reset) begin
            batch_idx <= 0;
            done      <= 0;
            started   <= 0;
            acc_0 <= 0; acc_1 <= 0; acc_2 <= 0; acc_3 <= 0;
        end else begin
            if (!started) begin
                acc_0 <= b[0*BITSIZE +: BITSIZE];
                acc_1 <= b[1*BITSIZE +: BITSIZE];
                acc_2 <= b[2*BITSIZE +: BITSIZE];
                acc_3 <= b[3*BITSIZE +: BITSIZE];
                started <= 1;
            end else if (!done) begin
                temp_0 = acc_0; temp_1 = acc_1; temp_2 = acc_2; temp_3 = acc_3;
                for (k = 0; k < BATCH; k = k + 1) begin
                    if (batch_idx*BATCH + k < IN_SIZE) begin
                        temp_0 = temp_0 + mul_reg[0][k];
                        temp_1 = temp_1 + mul_reg[1][k];
                        temp_2 = temp_2 + mul_reg[2][k];
                        temp_3 = temp_3 + mul_reg[3][k];
                    end
                end
                acc_0 <= temp_0; acc_1 <= temp_1; acc_2 <= temp_2; acc_3 <= temp_3;

                if (batch_idx < BATCH_COUNT - 1)
                    batch_idx <= batch_idx + 1;
                else begin
                    done <= 1;
                end
            end else begin
                // Write final output continuously after done
                y[0*BITSIZE +: BITSIZE] <= acc_0;
                y[1*BITSIZE +: BITSIZE] <= acc_1;
                y[2*BITSIZE +: BITSIZE] <= acc_2;
                y[3*BITSIZE +: BITSIZE] <= acc_3;
                done_all <= 1;
            end
        end
    end

endmodule