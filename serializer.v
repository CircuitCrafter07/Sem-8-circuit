module serializer(
    input wire clk,                // Clock signal
    input wire reset,              // Asynchronous reset signal
    input wire load,               // Load signal to load parallel data
    input wire [9:0] parallel_data,// Parallel input data (10-bit)
    output reg serial_out          // Serial output
);

    reg [9:0] shift_reg;           // Shift register to hold data
    reg [3:0] bit_counter;         // Counter to track bit position (0 to 9)
    reg busy;                      // Flag to indicate active serialization

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers
            shift_reg <= 10'b0;
            serial_out <= 1'b0;
            bit_counter <= 4'd0;
            busy <= 1'b0;          // Not busy after reset
        end else if (load) begin
            // Load parallel data into shift register
            shift_reg <= parallel_data;
            bit_counter <= 4'd9;   // Initialize bit counter to MSB
            busy <= 1'b1;          // Start serialization
        end else if (busy) begin
            // Perform serialization
            serial_out <= shift_reg[bit_counter]; // Output current bit
            if (bit_counter == 4'd0) begin
                busy <= 1'b0;      // Serialization complete
            end else begin
                bit_counter <= bit_counter - 1; // Decrement bit counter
            end
        end
    end
endmodule
