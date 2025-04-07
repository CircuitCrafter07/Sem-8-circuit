`timescale 1ns / 100ps 
module tb_deserializer; 
 
parameter CLOCK_PERIOD = 100; 
parameter MAX_JITTER = 10; 
parameter DELTA_JITTER = 17 ; 
 
wire       clk; 
reg    ref_clock; 
reg        a_rst; 
reg        a_rx; 
 
reg  [3:0] clocks_in; 
wire [9:0] c_parallel_out; 
reg disparity_in; 
wire disparity_out; 
wire clock_out; 
wire clock_4f; 
 
// Digital Rx 
wire [7:0] dataout; 
wire dispout; 
wire code_err; 
wire disp_err; 
wire data_valid_pipe; 
wire ko; 
 
reg[7:0] data_to_encode; 
 
wire [9:0] data_encoded; 
reg [7:0] test_values; 
reg [9:0] data_encoded_reg;
wire [3:0] clock_phases; 
 
integer clock_period; 
integer max_jitter; 
integer delta_jitter; 
integer noisy_clock; 
 
integer i,j; 
 
// clock signal generation (period = 20) 
initial 
begin 
 ref_clock = 0; 
 clock_period = 100; 
 max_jitter = 10; 
 delta_jitter = $random % max_jitter ; 
 noisy_clock = ($random % 2) ? clock_period + delta_jitter : clock_period - delta_jitter; 
 $display("The noisy clock value is %d ",noisy_clock); 
 $display("Delta jitter is %d",DELTA_JITTER); 
    clocks_in = 8'h0f; 
 disparity_in = 1'b0; 
    #50; 
    forever begin 
        for (i=0; i < 4; i=i+1) begin 
            #10 clocks_in[i] = ~clocks_in[i]; 
   ref_clock = ~ref_clock; 
            clocks_in[4+i] = ~clocks_in[4+i]; 
        end 
  //#10 ref_clock = ~ref_clock; 
    end 
end 
 
assign clk = clocks_in[0]; 
 
 
// serial input generation 
initial 
begin 
    // reset 
 test_values = 8'h00; 
    a_rst    = 1'b0; 
    a_rx = 1'b0; 
 data_to_encode = 0; 
    #100  a_rst = 1'b1; 
    #500 a_rst = 1'b0; 
 
    @(posedge clk); 
    // send comma 
 #327; 
    serial_mblb(10'h0f8); 
    // send test patterns 
serial_mblb(10'h365); // 5 
 serial_mblb(10'h366); // 6 
 serial_mblb(10'h347); // 7 
 serial_mblb(10'h0a7); // 8 
 serial_mblb(10'h369); // 9 
 //test_values = 8'hfd; 
 // 
 //consecutive_frame(5); 
  
    serial_mblb(10'h2aa); 
    serial_mblb(10'h155); 
    serial_mblb(10'h10f); 
    serial_mblb(10'h000); 
 #2000; 
 $finish; 
end     
 
always@(negedge clk) begin 
 test_values = test_values + 1 ; 
 
end 
 
 
task serial_mblb(input[9:0] data); 
begin   
    for (j=9; j >= 0; j=j-1) begin 
        #DELTA_JITTER; 
  //#17; 
  a_rx = data[j]; 
  //#10; 
        @(posedge clk); 
    end 
end 
endtask 
 
task consecutive_frame(input[7:0] init_value); 
begin 
 data_to_encode <= init_value; 
 @(posedge clk); 
 //data_encoded_reg = init_value; 
    for (j=10; j >= 0; j=j-1) begin 
  data_to_encode <= data_to_encode + 1; 
  #50; 
        @(posedge clk); 
    end 
end      
endtask 
 
//encode encode1( {1'b0 , data_to_encode} , 1'b0, data_encoded, dispout_aux); 
digitalRx superDut(a_rst, ref_clock, a_rx, ~a_rx, disparity_in, dataout, dispout, code_err, disp_err, data_valid_pipe, clock_4f, ko); 
deserializer dut(a_rst, clocks_in[3:0], a_rx, c_parallel_out, clock_out, disparity_in, disparity_out); 
clock_divider clock_divider_dut(a_rst, ref_clock, clock_phases); 
   
 
endmodule 