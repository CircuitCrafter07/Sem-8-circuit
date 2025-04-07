module Des(
    input wire clk,           // Clock signal
    input wire reset,         // Asynchronous reset signal
    input wire serial_in,     // Serial input
    input wire load,          // Load signal to start deserialization
    output reg [7:0] parallel_out // Parallel output data (8-bit)
);

    reg [7:0] shift_reg;     // Shift register to hold data
    reg [2:0] bit_counter;   // Counter to track bit position (0 to 7)
    reg busy;                // Flag to indicate active deserialization

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers
            shift_reg <= 8'b0;
            parallel_out <= 8'b0;
            bit_counter <= 3'd0;
            busy <= 1'b0; // Not busy after reset
        end else if (load) begin
            // Start deserialization
            bit_counter <= 3'd0; // Initialize bit counter to LSB
            busy <= 1'b1; 
        end else if (busy) begin
            // Perform deserialization
            shift_reg[bit_counter] <= serial_in; 
            if (bit_counter == 3'd7) begin
                parallel_out <= shift_reg; // Output parallel data
                busy <= 1'b0; // Deserialization complete
            end else begin
                bit_counter <= bit_counter + 1; // Increment bit counter
            end
        end
    end

endmodule
