module serializer_tb;

    // Inputs
    reg clk;
    reg reset;
    reg load;
    reg [9:0] parallel_data;

    // Outputs
    wire serial_out;

    // Instantiate the serializer module
    serializer uut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .parallel_data(parallel_data),
        .serial_out(serial_out)
    );

    // Clock generation
    always #5 clk = ~clk; // Clock with 10 ns period

    // Test sequence
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 0;
        load = 0;
        parallel_data = 10'b0;

        // Apply reset
        $display("Applying reset...");
        reset = 1;
        #10;
        reset = 0;
        #10;

        // Test Case 1: Load and serialize 10'b1010110001 
        $display("Loading and serializing 10'b1010110001...");
        parallel_data = 10'b1010110001 ;
        load = 1;
        #10;
        load = 0;

        // Observe serialization over 10 clock cycles
        #100;

        // Test Case 2: Load and serialize 10'b0101011010 
        $display("Loading and serializing 10'b0101011010 ...");
        parallel_data = 10'b0101011010;
        load = 1;
        #10;
        load = 0;

        // Observe serialization over 10 clock cycles
        #100;

        // Test Case 3: Apply reset mid-operation
        $display("Applying reset mid-operation...");
        parallel_data = 10'b1010100101;
        load = 1;
        #10;
        load = 0;

        // Wait for 5 clock cycles and then reset
        #50;
        reset = 1;
        #10;
        reset = 0;

        // Test Case 4: Idle state (no load, no reset)
        $display("Testing idle state...");
        #100;

        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %0t | reset: %b | load: %b | parallel_data: %b | serial_out: %b",
                 $time, reset, load, parallel_data, serial_out);
    end

endmodule
