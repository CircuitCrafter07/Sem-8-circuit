module top_module_rx_tb;

    // Inputs
    reg rst;
    reg clk;
    reg a_rx_serial;
    reg disparity_d;

    // Outputs
    wire [7:0] dout;
    wire disparity_q;
    wire code_err;
    wire kout;
    wire disp;
    wire disp_err;

    // Instantiate the DUT
    top_module_rx dut (
        .rst(rst),
        .clk(clk),
        .a_rx_serial(a_rx_serial),
        .disparity_d(disparity_d),
        .dout(dout),
        .code_err(code_err),
        .kout(kout),
        .disp(disp),
        .disp_err(disp_err)
    );

    // Clock generation
    always begin
        clk = 0;
        #5;
        clk = 1;
        #5;
    end

    // Declare lfsr outside the always block
    reg [3:0] lfsr; 

    initial begin
        // Reset
        rst = 1;
        #10;
        rst = 0;

        // Initial value for a_rx_serial
        a_rx_serial = 1'b0; 

        // Initialize lfsr
        lfsr = 4'b1111; 

        // Monitor and display results
        $monitor("Time: %t, a_rx_serial: %b, dout: %b, code_err: %b, kout: %b, disp: %b, disp_err: %b", $time, a_rx_serial, dout, code_err, kout, disp, disp_err);

        #500; // Run for some time
        $finish;
    end

    // Generate random data on the rising edge of the clock
    always @(posedge clk) begin
        if (~rst) begin 
            lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[1]}; 
            a_rx_serial <= lfsr[0]; 
        end
    end

endmodule
