// `include "fixed_point_add.v"
// `include "fixed_point_multiply.v"

module enc_1_92_batch32 #(parameter BITSIZE = 16, parameter IN_SIZE = 10, 
    parameter OUT_SIZE = 92, parameter BATCH = 32)(

    input wire clk,
    input wire reset,
    input wire [BITSIZE*IN_SIZE-1:0] x,                    // input vector
    input wire [BITSIZE*OUT_SIZE*IN_SIZE-1:0] w,           // weight matrix (flattened)
    input wire [BITSIZE*OUT_SIZE-1:0] b,                   // bias vector
    output wire [BITSIZE*OUT_SIZE-1:0] y,                  // output vector
    output wire done_all
);

    localparam BATCH_COUNT = 4; //(OUT_SIZE + BATCH - 1) / BATCH;

    reg [BITSIZE-1:0] acc [0:OUT_SIZE-1];
    reg [$clog2(IN_SIZE):0] i;
    reg [$clog2(BATCH_COUNT):0] batch_idx;
    reg done;

    wire [BITSIZE-1:0] x_vec [0:IN_SIZE-1];
    wire [BITSIZE-1:0] w_batch [0:BATCH-1];
    wire [BITSIZE-1:0] mul_out [0:BATCH-1];
    wire [BITSIZE-1:0] add_out [0:BATCH-1];

    genvar j;
    generate
        for (j = 0; j < IN_SIZE; j = j + 1) begin : unpack_x
            assign x_vec[j] = x[j*BITSIZE +: BITSIZE];
        end
    endgenerate

    generate
        for (j = 0; j < BATCH; j = j + 1) begin : calc_batch
            wire [BITSIZE-1:0] in1 = x_vec[i];

            wire [BITSIZE-1:0] in2 = ((batch_idx*BATCH + j) < OUT_SIZE) ? 
                w[((batch_idx*BATCH + j)*IN_SIZE + i)*BITSIZE +: BITSIZE] : 0;

            fixed_point_multiply mul (
                .A(in1),
                .B(in2),
                .C(mul_out[j])
            );

            wire [BITSIZE-1:0] bias_or_acc = ((batch_idx*BATCH + j) < OUT_SIZE) ?
                ((i == 0) ? b[(batch_idx*BATCH + j)*BITSIZE +: BITSIZE] :
                            acc[batch_idx*BATCH + j])
                : 0;

            fixed_point_add add (
                .A(mul_out[j]),
                .B(bias_or_acc),
                .C(add_out[j])
            );

            always @(posedge clk) begin
                if (!reset && (batch_idx*BATCH + j) < OUT_SIZE) begin
                    acc[batch_idx*BATCH + j] <= add_out[j];
                end
            end
        end
    endgenerate

    // Control logic
    integer k;
    always @(posedge clk) begin
        if (reset) begin
            i <= 0;
            batch_idx <= 0;
            done <= 0;
            for (k = 0; k < OUT_SIZE; k = k + 1) begin
                acc[k] <= 0;
            end
        end else if (!done) begin
            if (i < IN_SIZE - 1) begin
                i <= i + 1;
            end else begin
                i <= 0;
                if (batch_idx < BATCH_COUNT - 1) begin
                    batch_idx <= batch_idx + 1;
                end else begin
                    done <= 1;
                end
            end
        end
    end

    generate
        for (j = 0; j < OUT_SIZE; j = j + 1) begin : output_y
            assign y[j*BITSIZE +: BITSIZE] = acc[j];
        end
    endgenerate

    assign done_all = done;

endmodule
