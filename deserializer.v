module deserializer (
    input wire rst,
    input wire clk,           // Single clock input
    input wire a_rx,          // Serial data input
    input wire disparity_d,   // Running disparity input
    output reg [9:0] c_parallel_out, // 10-bit parallel data output
    output reg clk_out,       // Recovered clock output
    output reg disparity_q,   // Running disparity output
    output reg c_data_valid   // Data valid flag
);

    reg [9:0] shift_reg;      // Shift register for serial-to-parallel conversion (10 bits)
    reg [3:0] cycle_count;    // Cycle counter for generating clk_out and c_data_valid
    wire sampled_data;        // Sampled data from CDR
    reg comma_detected;       // Comma detection flag

    // CDR instance for clock and data recovery
    wire bit_clock;
    CDR cdr_inst (
        .rst(rst),
        .clks_in({clk, clk, clk, clk}), // Replace with 4-phase clock signals
        .a_rx(a_rx),
        .bit_clock(bit_clock),
        .samp_test(sampled_data)
    );

    // Serial-to-parallel shift register logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 10'b0;
        end else begin
            shift_reg <= {shift_reg[8:0], sampled_data}; // Shift in sampled data
        end
    end

    // Running disparity logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            disparity_q <= 1'b0;
        end else begin
            disparity_q <= disparity_d;
        end
    end

    // Comma detection logic (for 10-bit comma patterns)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            comma_detected <= 1'b0;
        end else begin
            // Comma patterns for 10-bit (e.g., 8b/10b encoding)
            comma_detected <= (shift_reg == 10'b0011111100) || (shift_reg == 10'b1100000011);
        end
    end

    // Cycle counter and clk_out generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_count <= 4'd9; // Reset to 9
            c_data_valid <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            if (comma_detected) begin
                cycle_count <= 4'd9; // Reset on comma detection
                c_data_valid <= 1'b0;
            end else if (cycle_count == 4'd0) begin
                cycle_count <= 4'd9; // Reset the counter after 10 cycles
                c_data_valid <= 1'b1; // Data is valid after 10 bits
            end else begin
                cycle_count <= cycle_count - 1;
                c_data_valid <= 1'b0;
            end
            clk_out <= (cycle_count == 4'd5); // Generate recovered clock (half-cycle of 10)
        end
    end

    // Parallel data output logic (only valid when c_data_valid is high)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_parallel_out <= 10'b0;
        end else if (c_data_valid) begin
            c_parallel_out <= shift_reg;
        end
    end
endmodule

// Updated CDR Module for 10-bit recovery
module CDR (
    input wire rst,
    input wire [3:0] clks_in, // Multi-phase clock input
    input wire a_rx,          // Serial data input
    output reg bit_clock,     // Recovered clock output
    output reg samp_test      // Sampled data output (10 bits)
);

    reg [9:0] c_rx_upsampled [3:0];  // Upsampled data for each clock phase (10 bits for each clock)
    reg [1:0] best_samp;             // Phase selection logic (for simplicity, still 2 bits)

    // Upsampling logic using 4-phase clock (10-bit data)
    always @(posedge clks_in[0] or posedge rst) begin
        if (rst) begin
            c_rx_upsampled[0] <= 10'b0;
        end else begin
            c_rx_upsampled[0] <= {9'b0, a_rx};
        end
    end

    always @(posedge clks_in[1] or posedge rst) begin
        if (rst) begin
            c_rx_upsampled[1] <= 10'b0;
        end else begin
            c_rx_upsampled[1] <= {9'b0, a_rx};
        end
    end

    always @(posedge clks_in[2] or posedge rst) begin
        if (rst) begin
            c_rx_upsampled[2] <= 10'b0;
        end else begin
            c_rx_upsampled[2] <= {9'b0, a_rx};
        end
    end

    always @(posedge clks_in[3] or posedge rst) begin
        if (rst) begin
            c_rx_upsampled[3] <= 10'b0;
        end else begin
            c_rx_upsampled[3] <= {9'b0, a_rx};
        end
    end

    // Transition detection and phase selection logic
    always @(posedge clks_in[0] or posedge rst) begin
        if (rst) begin
            best_samp <= 2'b00;
        end else begin
            // Simple phase selection (placeholder logic for 10 bits)
            best_samp <= 2'b01;
        end
    end

    // Recovered clock and sampled data output (10 bits)
    always @(posedge clks_in[best_samp] or posedge rst) begin
        if (rst) begin
            bit_clock <= 1'b0;
            samp_test <= 10'b0;
        end else begin
            bit_clock <= clks_in[best_samp];
            samp_test <= c_rx_upsampled[best_samp];
        end
    end
endmodule
