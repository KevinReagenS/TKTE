module PRNG
(
    input wire clk,          // Clock signal
    input wire rst,          // Reset signal
    input wire [4:0] seed,  // -> 4 hex, 15 11 7 3
    output reg [15:0] random_out, // Random number output
    output reg [4:0] statee
);

reg [4:0] state;
reg initialize;


reg [32*16-1:0] epsilon_LUT;
initial begin
    initialize = 0;
    epsilon_LUT = {
        16'b0000000000000000, //1
        16'b0000000000000000, //2
        16'b0000000001110001, //3
        16'b0000000001110001, //4
        16'b0000000011100011, //5
        16'b0000000011100011, //6
        16'b0000000011100011, //7
        16'b0000000101010101, //8
        16'b0000000101010101, //9
        16'b0000000101010101, //10
        16'b0000000101010101, //11
        16'b0000000111000111, //12
        16'b0000000111000111, //13
        16'b0000000111000111, //14
        16'b0000000111000111, //15
        16'b0000000111000111, //16
        16'b0000001000111000, //17
        16'b0000001000111000, //18
        16'b0000001000111000, //19
        16'b0000001000111000, //20
        16'b0000001000111000, //21
        16'b0000001010101010, //22
        16'b0000001010101010, //23
        16'b0000001010101010, //24
        16'b0000001010101010, //25
        16'b0000001100011100, //26
        16'b0000001100011100, //27
        16'b0000001100011100, //28
        16'b0000001110001110, //29
        16'b0000001110001110, //30
        16'b0000010000000000, //31
        16'b0000010000000000  //32
    };
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        random_out <= 0;
    end else begin
        random_out = epsilon_LUT[state*16 +: 16];
    end
end

always @(posedge clk or posedge rst) begin
    if (!initialize) begin
        state <= seed; // Initialize state with seed on reset
        initialize = 1;
    end else if (rst) begin
        state <= seed; // Initialize state with seed on reset
    end else begin
        // random_out <= epsilon_LUT[state*16 +: 16]; // Corrected access
        state <= (state ^ (state << 4)) + 3;
    end
    statee = state;
end

endmodule