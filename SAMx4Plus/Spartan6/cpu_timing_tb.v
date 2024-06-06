`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:41:51 06/03/2024
// Design Name:   cpu_timing
// Module Name:   /home/ise/ISE/mc6883test-spartan6/cpu_timing_tb.v
// Project Name:  mc6883test-spartan6
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: cpu_timing
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module cpu_timing_tb;

	// Inputs
	reg clk;
	reg rate_slow;
	reg rate_ad_slow;
	reg rate_ad_fast;
	reg rate_fast;
	reg isRAM;

	// Outputs
	wire E;
	wire Q;
	wire [3:0] T;
	wire Z_Source;

	// Instantiate the Unit Under Test (UUT)
	cpu_timing uut (
		.E(E), 
		.Q(Q), 
		.T(T), 
		.Z_Source(Z_Source), 
		.clk(clk), 
		.rate_slow(rate_slow), 
		.rate_ad_slow(rate_ad_slow), 
		.rate_ad_fast(rate_ad_fast), 
		.rate_fast(rate_fast), 
		.isRAM(isRAM)
	);

	initial begin
		// Initialize Inputs
		// clk = 0;
		rate_slow = 1;
		rate_ad_slow = 0;
		rate_ad_fast = 0;
		rate_fast = 0;
		isRAM = 0;

		// Wait 10 ns for global reset to finish
		#10;
        
		// Add stimulus here

	end
	
	always begin
		clk = 0;
		#4;
		clk = 1;
		#4;
	end
      
endmodule

