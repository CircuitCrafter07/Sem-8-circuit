`timescale 1ns/1ps

module deserializer_tb;

    reg rst;
    reg clk;
    reg a_rx;
    reg disparity_d;
    wire [9:0] c_parallel_out;
    wire clk_out;
    wire disparity_q;
    wire c_data_valid;

    // Instantiate the deserializer
    deserializer uut (
        .rst(rst),
        .clk(clk),
        .a_rx(a_rx),
        .disparity_d(disparity_d),
        .c_parallel_out(c_parallel_out),
        .clk_out(clk_out),
        .disparity_q(disparity_q),
        .c_data_valid(c_data_valid)
    );

    // Clock generation: 100 MHz
    always #5 clk = ~clk;  // 10ns period

    // Stimulus
    initial begin
        $dumpfile("deserializer_tb.vcd");
        $dumpvars(0, deserializer_tb);

        // Initialize signals
        clk = 0;
        rst = 1;
        a_rx = 0;
        disparity_d = 0;

        // Hold reset for some cycles
        #20;
        rst = 0;
        
        // Send serial data (10-bit pattern: 1010110011)
        #10 a_rx = 1;
        #10 a_rx = 0;
        #10 a_rx = 1;
        #10 a_rx = 0;
        #10 a_rx = 1;
        #10 a_rx = 1;
        #10 a_rx = 0;
        #10 a_rx = 0;
        #10 a_rx = 1;
        #10 a_rx = 1;

        // Wait for output to stabilize
        #100;
        
        // Check results
        if (c_data_valid) begin
            $display("Parallel Output: %b", c_parallel_out);
        end else begin
            $display("No valid data yet.");
        end

        // End simulation
        #100;
        $finish;
    end

endmodule



