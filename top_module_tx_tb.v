module top_module_tx_tb;

    // Inputs
    reg clk;
    reg rst;
    reg en;
    reg kin;
    reg [7:0] din;

    // Outputs
    wire serial_out;

    // Internal signals
    wire [9:0] encoder_dout;
    wire disp;
    wire kin_err;

    // Instantiate the DUT
    top_module_tx dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .kin(kin),
        .din(din),
        .serial_out(serial_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Testbench logic
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        en = 0;
        kin = 0;
        din = 8'h00;

        // Apply reset
        #10 rst = 0;

        // Test case 1: Normal operation
        #20 en = 1;
        din = 8'hAA;
        kin = 0;
        #20 en = 0;

        // Test case 2: With kin input
        #20 en = 1;
        din = 8'h55;
        kin = 1;
        #20 en = 0;

        // Test case 3: With kin error
        #20 en = 1;
        din = 8'h00;
        kin = 1; 
        #20 en = 0;

        // Finish simulation
        #100 $finish;
    end

    // Monitor signals
    always @(posedge clk) begin
        if (en) begin
            $display("Time: %t, din: %h, encoder_dout: %h, serial_out: %b", $time, din, encoder_dout, serial_out);
        end
    end

endmodule
