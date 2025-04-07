module top_module_rx (
    input wire rst,
    input wire clk,
    input wire a_rx_serial,
    input wire disparity_d,
    output wire [7:0] dout, 
    output wire code_err, 
    output wire kout, 
    output wire disp, 
    output wire disp_err 
);
    // Instantiate inputBuffer module
    wire [9:0] dout_buffer_input;
    inputBuffer input_buffer_inst (
        .rst(rst),
        .clk(clk),
        .a_rx_serial(a_rx_serial),
        .dout(dout_buffer_input)
    );

    // Deserializer buffer
    wire [9:0] dout_buffer_deserializer;
    // Instantiate deserializer module (modify to use dout_buffer_deserializer)
    deserializer deserializer_inst (
        .rst(rst),
        .clk(clk),
        .a_rx(dout_buffer_input[0]), 
        .disparity_d(disparity_d),
        .c_parallel_out(dout_buffer_deserializer), // Use dout_buffer_deserializer
        .clk_out(clk_out),
        .disparity_q(disparity_q), 
        .c_data_valid(c_data_valid)
    );

    // Decoder buffer
    wire [9:0] dout_buffer_decoder;
    // Modify decoder instantiation to use dout_buffer_decoder
    decodePipe decoder_inst (
        .clk(clk),
        .rst(rst),
        .en(c_data_valid), 
        .din(dout_buffer_deserializer), // Use dout_buffer_deserializer
        .dout(dout), // Connect decoder output to module output
        .kout(kout),
        .code_err(code_err),
        .disp(disp),
        .disp_err(disp_err)
    );

endmodule
// ... (rest of the modules: deserializer, CDR, inputBuffer, decodePipe) 
// remain unchanged ...
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

    reg [9:0] shift_reg;      // Shift register for serial-to-parallel conversion
    reg [3:0] cycle_count;    // Cycle counter
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
            shift_reg <= {shift_reg[8:0], sampled_data};
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
            comma_detected <= (shift_reg == 10'b0011111100) || (shift_reg == 10'b1100000011);
        end
    end

    // Cycle counter and clk_out generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_count <= 4'd9;
            c_data_valid <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            if (comma_detected) begin
                cycle_count <= 4'd9;
                c_data_valid <= 1'b0;
            end else if (cycle_count == 4'd0) begin
                cycle_count <= 4'd9;
                c_data_valid <= 1'b1;
            end else begin
                cycle_count <= cycle_count - 1;
                c_data_valid <= 1'b0;
            end
            clk_out <= (cycle_count == 4'd5);
        end
    end

    // Parallel data output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_parallel_out <= 10'b0;
        end else if (c_data_valid) begin
            c_parallel_out <= shift_reg;
        end
    end
endmodule

// Updated CDR Module
module CDR (
    input wire rst,
    input wire [3:0] clks_in, // Multi-phase clock input
    input wire a_rx,          // Serial data input
    output reg bit_clock,     // Recovered clock output
    output reg samp_test      // Sampled data output
);

    reg [3:0] c_rx_upsampled;
    reg [1:0] best_samp;

    // Upsampling logic using 4-phase clock
    generate
        genvar i;
        for (i = 0; i < 4; i = i + 1) begin : upsample
            always @(posedge clks_in[i] or posedge rst) begin
                if (rst) begin
                    c_rx_upsampled[i] <= 1'b0;
                end else begin
                    c_rx_upsampled[i] <= a_rx;
                end
            end
        end
    endgenerate

    // Transition detection and phase selection logic
    always @(posedge clks_in[0] or posedge rst) begin
        if (rst) begin
            best_samp <= 2'b00;
        end else begin
            // Simple phase selection (placeholder logic)
            best_samp <= 2'b01;
        end
    end

    // Recovered clock and sampled data output
    always @(posedge clks_in[best_samp] or posedge rst) begin
        if (rst) begin
            bit_clock <= 1'b0;
            samp_test <= 1'b0;
        end else begin
            bit_clock <= clks_in[best_samp];
            samp_test <= c_rx_upsampled[best_samp];
        end
    end
endmodule

module inputBuffer (
    input wire rst,           // Reset signal
    input wire clk,           // Clock signal
    input wire a_rx_serial,   // Serial data input
    output reg [9:0] dout     // Parallel data output
);

    // Shift register to hold serial data
    reg [9:0] shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset the shift register and output
            shift_reg <= 10'b0;
            dout <= 10'b0;
        end else begin
            // Shift in new serial data and update the output
            shift_reg <= {shift_reg[8:0], a_rx_serial};
            dout <= shift_reg;
        end
    end

endmodule

module decodePipe (
	input wire clk,
	input wire rst,
	input wire en,
	input wire [9:0]din,
	output wire [7:0]dout,
	output wire kout,
	output wire code_err,
	output wire disp,
	output wire disp_err
);
   
reg [7:0]do;
reg k;
reg ce;
reg [2:0]e;
reg p;
reg [3:0]pe;
wire [9:0]d;

assign d = din;
assign disp_err = pe?1'b1:1'b0;
assign dout = do;
assign kout = k;
assign code_err = ce;
assign disp = p;

always @(posedge clk) begin
	if (rst) begin
		k <= 0;
		do <= 8'b0; 
	end else begin
		if (en == 1'b1) begin
			k <= (((d[7]&d[6]&d[5]&d[4])|(!d[7]&!d[6]&!d[5]&!d[4]))|(((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&(!d[5]&d[4]&d[2]&d[1]&d[0]))|(((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&(d[5]&!d[4]&!d[2]&!d[1]&!d[0])));
			do[7] <= ((d[0]^d[1])&!((!d[3]&d[2]&!d[1]&d[0]&!(!(d[7]|d[6]|d[5]|d[4])))|(!d[3]&d[2]&d[1]&!d[0]&(!(d[7]|d[6]|d[5]|d[4])))|(d[3]&!d[2]&!d[1]&d[0]&!(!(d[7]|d[6]|d[5]|d[4])))|(d[3]&!d[2]&d[1]&!d[0]&(!(d[7]|d[6]|d[5]|d[4])))))|(!d[3]&d[2]&d[1]&d[0])|(d[3]&!d[2]&!d[1]&!d[0]);
			do[6] <= (d[0]&!d[3]&(d[1]|!d[2]|!(!(d[7]|d[6]|d[5]|d[4]))))|(d[3]&!d[0]&(!d[1]|d[2]|(!(d[7]|d[6]|d[5]|d[4]))))|(!(!(d[7]|d[6]|d[5]|d[4]))&d[2]&d[1])|((!(d[7]|d[6]|d[5]|d[4]))&!d[2]&!d[1]);
			do[5] <= (d[0]&!d[3]&(d[1]|!d[2]|(!(d[7]|d[6]|d[5]|d[4]))))|(d[3]&!d[0]&(!d[1]|d[2]|!(!(d[7]|d[6]|d[5]|d[4]))))|((!(d[7]|d[6]|d[5]|d[4]))&d[2]&d[1])|(!(!(d[7]|d[6]|d[5]|d[4]))&!d[2]&!d[1]);
			do[4] <= d[5]^(((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!d[5])|(!d[7]&!d[6]&!d[5]&!d[4])|(!d[9]&!d[8]&!d[5]&!d[4]))|((((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[9]&!d[7]&(!(d[5]^d[4])))|(((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6])) & !d[9] & !d[8]))&!d[4]))|((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&d[6]&d[5]&d[4])|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[8]&!d[7]&(!(d[5]^d[4])))));
			do[3] <= d[6]^(((d[9]&d[8]&d[5]&d[4])|(!d[7]&!d[6]&!d[5]&!d[4])|(((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&d[4]))|((((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&d[9]&d[7]&(!(d[5]^d[4])))|(((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!d[5]))|((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&d[6]&d[5]&d[4])|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[8]&!d[7]&(!(d[5]^d[4])))));
			do[2] <= d[7]^(((((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[9]&!d[7]&(!(d[5]^d[4])))|(((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!d[5]))|((((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&d[4])|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&d[8]&d[7]&(!(d[5]^d[4])))|(((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&d[6]&d[5]&d[4]))|((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!d[5])|(!d[7]&!d[6]&!d[5]&!d[4])|(!d[9]&!d[8]&!d[5]&!d[4])));
			do[1] <= d[8]^(((d[9]&d[8]&d[5]&d[4])|(!d[7]&!d[6]&!d[5]&!d[4])|(((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&d[4]))|((((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&d[4])|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&d[8]&d[7]&(!(d[5]^d[4])))|(((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&d[6]&d[5]&d[4]))|((((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&d[9]&d[7]&(!(d[5]^d[4])))|(((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!d[5])));
			do[0] <= d[9]^(((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&d[6]&d[5]&d[4])|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[8]&!d[7]&(!(d[5]^d[4]))))|((((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[9]&!d[7]&(!(d[5]^d[4])))|(((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!d[5]))|((d[9]&d[8]&d[5]&d[4])|(!d[7]&!d[6]&!d[5]&!d[4])|(((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&d[4])));
		end
	end
end
   
always @(posedge clk) begin
	if (rst) begin
		p <= 1'b0;
		pe <= 4'hF;
		ce <= 1'b1;
		e <= 3'b000;
	end else begin
		if (en == 1'b1) begin
			p <= (((!((d[3]&d[2])|(!d[3]&!d[2])))&d[1]&d[0])|(!((d[1]&d[0])|(!d[1]&!d[0]))&d[3]&d[2]))|(((d[5]&d[4]&!(((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!p))|((((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&p))&(d[5]|d[4]))|(((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&p))&((d[3]&d[2]&!d[1]&!d[0])|(!d[3]&!d[2]&d[1]&d[0])|(!((d[3]&d[2])|(!d[3]&!d[2]))&!((d[1]&d[0])|(!d[1]&!d[0]))))) ;
			pe[0] <= ((p&((((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&(d[5]|d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&d[5]&d[4])))|(((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!(d[5]&d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[5]&!d[4]))&!p))|((p&!((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!(d[5]&d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[5]&!d[4]))&d[3]&d[2]));
			pe[1] <= ((p&d[9]&d[8]&d[7]))|((p&!((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!(d[5]&d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[5]&!d[4]))&(((!((d[3]&d[2])|(!d[3]&!d[2])))&d[1]&d[0])|(!((d[1]&d[0])|(!d[1]&!d[0]))&d[3]&d[2]))));
			pe[2] <= ((!p&!((((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&(d[5]|d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&d[5]&d[4]))&!d[3]&!d[2]))|((!p&!d[9]&!d[8]&!d[7]));
			pe[3] <= ((!p&!((((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&(d[5]|d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&d[5]&d[4]))&((!((d[3]&d[2])|(!d[3]&!d[2]))&!d[1]&!d[0])|(!((d[1]&d[0])|(!d[1]&!d[0]))&!d[3]&!d[2]))))|((((((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&(d[5]|d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&d[5]&d[4]))&(((!((d[3]&d[2])|(!d[3]&!d[2])))&d[1]&d[0])|(!((d[1]&d[0])|(!d[1]&!d[0]))&d[3]&d[2])))|(((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!(d[5]&d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[5]&!d[4]))&((!((d[3]&d[2])|(!d[3]&!d[2]))&!d[1]&!d[0])|(!((d[1]&d[0])|(!d[1]&!d[0]))&!d[3]&!d[2]))));
			e[0] <= ((d[9]&d[8]&d[7]&d[6])|(!d[9]&!d[8]&!d[7]&!d[6]))|((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!d[5]&!d[4]))|((((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&d[5]&d[4]))|((d[3]&d[2]&d[1]&d[0])|(!d[3]&!d[2]&!d[1]&!d[0]))|((d[5]&d[4]&d[3]&d[2]&d[1])|(!d[5]&!d[4]&!d[3]&!d[2]&!d[1]))|((d[5]&!d[4]&d[2]&d[1]&d[0])|(!d[5]&d[4]&!d[2]&!d[1]&!d[0]))|((((d[5]&d[4]&!d[2]&!d[1]&!d[0])|(!d[5]&!d[4]&d[2]&d[1]&d[0]))&!((d[7]&d[6]&d[5])|(!d[7]&!d[6]&!d[5]))))|((!((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&d[5]&!d[4]&!d[2]&!d[1]&!d[0]))|((!((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!d[5]&d[4]&d[2]&d[1]&d[0]));
			e[1] <= ((((((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&(d[5]|d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&d[5]&d[4]))&(((!((d[3]&d[2])|(!d[3]&!d[2])))&d[1]&d[0])|(!((d[1]&d[0])|(!d[1]&!d[0]))&d[3]&d[2])))|(((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!(d[5]&d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[5]&!d[4]))&((!((d[3]&d[2])|(!d[3]&!d[2]))&!d[1]&!d[0])|(!((d[1]&d[0])|(!d[1]&!d[0]))&!d[3]&!d[2]))))|((d[3]&d[2]&!d[1]&!d[0]&((((!((d[9]&d[8])|(!d[9]&!d[8]))&d[7]&d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&d[9]&d[8]))&(d[5]|d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&d[5]&d[4]))))|((!d[3]&!d[2]&d[1]&d[0]&((((!((d[9]&d[8])|(!d[9]&!d[8]))&!d[7]&!d[6])|(!((d[7]&d[6])|(!d[7]&!d[6]))&!d[9]&!d[8]))&!(d[5]&d[4]))|(((d[9]&d[8]&!d[7]&!d[6])|(d[7]&d[6]&!d[9]&!d[8])|(!((d[9]&d[8])|(!d[9]&!d[8]))&!((d[7]&d[6])|(!d[7]&!d[6]))))&!d[5]&!d[4]))));
			e[2] <= ((d[9]&d[8]&d[7]&!d[5]&!d[4]&((!d[3]&!d[2])|((!((d[3]&d[2])|(!d[3]&!d[2]))&!d[1]&!d[0])|(!((d[1]&d[0])|(!d[1]&!d[0]))&!d[3]&!d[2])))))|((!d[9]&!d[8]&!d[7]&d[5]&d[4]&((d[3]&d[2])|(((!((d[3]&d[2])|(!d[3]&!d[2])))&d[1]&d[0])|(!((d[1]&d[0])|(!d[1]&!d[0]))&d[3]&d[2])))))|((d[7]&d[6]&d[5]&d[4]&!d[3]&!d[2]&!d[1]))|((!d[7]&!d[6]&!d[5]&!d[4]&d[3]&d[2]&d[1]));
			ce <= e ? 1'b1 : 1'b0;
		end
	end
end

endmodule
