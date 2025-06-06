module top_module_tx (
    input wire clk,
    input wire rst,
    input wire en,
    input wire kin,
    input wire [7:0] din,
    output wire serial_out
);

    wire [9:0] encoder_dout;
    wire disp;
    wire kin_err;

    encoder_8b10 encoder_inst (
        .clk(clk),
        .rst(rst),
        .en(en),
        .kin(kin),
        .din(din),
        .dout(encoder_dout),
        .disp(disp),
        .kin_err(kin_err)
    );

    serializer serializer_inst (
    .clk(clk),
    .reset(rst),
    .load(en),                // Map "en" to "load"
    .parallel_data(encoder_dout), // Map "encoder_dout" to "parallel_data"
    .serial_out(serial_out)
);


endmodule

module encoder_8b10
(
	input wire clk,
	input wire rst,
	input wire en,
	input wire kin,
	input wire [7:0]din,
	output wire [9:0]dout,
	output wire disp,
	output wire kin_err
);

reg p;
reg ke;
reg [18:0]t;
reg [9:0]do;
wire [7:0]d;
wire k;

assign d = din;
assign k = kin;

assign dout = do;
assign disp = p;
assign kin_err = ke;

always @(posedge clk) begin
	if (rst) begin
		p <= 1'b0;
		ke <= 1'b0;
		do <= 10'b0;
	end else begin
		if (en == 1'b1) begin
			p <= ((d[5]&d[6]&d[7])|(!d[5]&!d[6]))^(p^(((d[4]&d[3]&!d[2]&!d[1]&!d[0])|(!d[4]&!((d[0]&d[1]&!d[2]&!d[3])|(d[2]&d[3]&!d[0]&!d[1])|(!((d[0]&d[1])|(!d[0]&!d[1]))&!((d[2]&d[3])|(!d[2]&!d[3]))))&!((!((d[0]&d[1])|(!d[0]&!d[1]))&d[2]&d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&d[0]&d[1]))))|(k|(d[4]&!((d[0]&d[1]&!d[2]&!d[3])|(d[2]&d[3]&!d[0]&!d[1])|(!((d[0]&d[1])|(!d[0]&!d[1]))&!((d[2]&d[3])|(!d[2]&!d[3]))))&!((!((d[0]&d[1])|(!d[0]&!d[1]))&!d[2]&!d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&!d[0]&!d[1]))))));
			ke <= (k&(d[0]|d[1]|!d[2]|!d[3]|!d[4])&(!d[5]|!d[6]|!d[7]|!d[4]|!((!((d[0]&d[1])|(!d[0]&!d[1]))&d[2]&d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&d[0]&d[1])))); 
			do[9] <= t[12]^t[0];
			do[8] <= t[12]^(t[1]|t[2]);
			do[7] <= t[12]^(t[3]|t[4]);
			do[6] <= t[12]^t[5];
			do[5] <= t[12]^(t[6]&t[7]);
			do[4] <= t[12]^(t[8]|t[9]|t[10]|t[11]);
			do[3] <= t[13]^(t[15]&!t[14]);
			do[2] <= t[13]^t[16];
			do[1] <= t[13]^t[17];
			do[0] <= t[13]^(t[18]|t[14]);
		end
	end
end
  
always @(posedge clk) begin
	if(rst) begin
		t <= 0;
	end else begin
		if (en == 1'b1) begin
			t[0] <= d[0];
			t[1] <= d[1]&!(d[0]&d[1]&d[2]&d[3]);
			t[2] <= (!d[0]&!d[1]&!d[2]&!d[3]);
			t[3] <= (!d[0]&!d[1]&!d[2]&!d[3])|d[2];
			t[4] <= d[4]&d[3]&!d[2]&!d[1]&!d[0];
			t[5] <= d[3]&!(d[0]&d[1]&d[2]);
			t[6] <= d[4]|((!((d[0]&d[1])|(!d[0]&!d[1]))&!d[2]&!d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&!d[0]&!d[1]));
			t[7] <= !(d[4]&d[3]&!d[2]&!d[1]&!d[0]);
			t[8] <= (((d[0]&d[1]&!d[2]&!d[3])|(d[2]&d[3]&!d[0]&!d[1])|(!((d[0]&d[1])|(!d[0]&!d[1]))&!((d[2]&d[3])|(!d[2]&!d[3]))))&!d[4])|(d[4]&(d[0]&d[1]&d[2]&d[3]));
			t[9] <= d[4]&!d[3]&!d[2]&!(d[0]&d[1]);
			t[10] <= k&d[4]&d[3]&d[2]&!d[1]&!d[0];
			t[11] <= d[4]&!d[3]&d[2]&!d[1]&!d[0];
			t[12] <= (((d[4]&d[3]&!d[2]&!d[1]&!d[0])|(!d[4]&!((d[0]&d[1]&!d[2]&!d[3])|(d[2]&d[3]&!d[0]&!d[1])|(!((d[0]&d[1])|(!d[0]&!d[1]))&!((d[2]&d[3])|(!d[2]&!d[3]))))&!((!((d[0]&d[1])|(!d[0]&!d[1]))&d[2]&d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&d[0]&d[1]))))&!p)|((k|(d[4]&!((d[0]&d[1]&!d[2]&!d[3])|(d[2]&d[3]&!d[0]&!d[1])|(!((d[0]&d[1])|(!d[0]&!d[1]))&!((d[2]&d[3])|(!d[2]&!d[3]))))&!((!((d[0]&d[1])|(!d[0]&!d[1]))&!d[2]&!d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&!d[0]&!d[1])))|(!d[4]&!d[3]&d[2]&d[1]&d[0]))&p);
			t[13] <= (((!d[5]&!d[6])|(k&((d[5]&!d[6])|(!d[5]&d[6]))))&!(p^(((d[4]&d[3]&!d[2]&!d[1]&!d[0])|(!d[4]&!((d[0]&d[1]&!d[2]&!d[3])|(d[2]&d[3]&!d[0]&!d[1])|(!((d[0]&d[1])|(!d[0]&!d[1]))&!((d[2]&d[3])|(!d[2]&!d[3]))))&!((!((d[0]&d[1])|(!d[0]&!d[1]))&d[2]&d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&d[0]&d[1]))))|(k|(d[4]&!((d[0]&d[1]&!d[2]&!d[3])|(d[2]&d[3]&!d[0]&!d[1])|(!((d[0]&d[1])|(!d[0]&!d[1]))&!((d[2]&d[3])|(!d[2]&!d[3]))))&!((!((d[0]&d[1])|(!d[0]&!d[1]))&!d[2]&!d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&!d[0]&!d[1])))))))|((d[5]&d[6])&(p^(((d[4]&d[3]&!d[2]&!d[1]&!d[0])|(!d[4]&!((d[0]&d[1]&!d[2]&!d[3])|(d[2]&d[3]&!d[0]&!d[1])|(!((d[0]&d[1])|(!d[0]&!d[1]))&!((d[2]&d[3])|(!d[2]&!d[3]))))&!((!((d[0]&d[1])|(!d[0]&!d[1]))&d[2]&d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&d[0]&d[1]))))|(k|(d[4]&!((d[0]&d[1]&!d[2]&!d[3])|(d[2]&d[3]&!d[0]&!d[1])|(!((d[0]&d[1])|(!d[0]&!d[1]))&!((d[2]&d[3])|(!d[2]&!d[3]))))&!((!((d[0]&d[1])|(!d[0]&!d[1]))&!d[2]&!d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&!d[0]&!d[1])))))));
			t[14] <= d[5]&d[6]&d[7]&(k|(p?(!d[4]&d[3]&((!((d[0]&d[1])|(!d[0]&!d[1]))&d[2]&d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&d[0]&d[1]))):(d[4]&!d[3]&((!((d[0]&d[1])|(!d[0]&!d[1]))&!d[2]&!d[3])|(!((d[2]&d[3])|(!d[2]&!d[3]))&!d[0]&!d[1])))));
			t[15] <= d[5];
			t[16] <= d[6]|(!d[5]&!d[6]&!d[7]);
			t[17] <= d[7];
			t[18] <= !d[7]&(d[6]^d[5]);
		end
	end
end

endmodule
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
