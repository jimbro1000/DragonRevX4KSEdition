`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:36:22 06/03/2024 
// Design Name: 
// Module Name:    mpu_rate 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mpu_rate(
	 input clk,
    input [1:0] R,
    input isSlowBlock,
    output rate_slow,
    output rate_ad_slow,
    output rate_ad_fast,
    output rate_fast
    );
	 
	 reg mpu_rate_slow;
	 reg mpu_rate_ad_slow;
	 reg mpu_rate_ad_fast;
	 reg mpu_rate_fast;

	always @(posedge clk) begin
		mpu_rate_slow = R == 2'b00;
		mpu_rate_ad_slow = R == 2'b01 && isSlowBlock;
		mpu_rate_ad_fast = R == 2'b01 && !isSlowBlock;
		mpu_rate_fast = R[1] == 1;
	end
	
	assign rate_slow = mpu_rate_slow;
	assign rate_ad_slow = mpu_rate_ad_slow;
	assign rate_ad_fast = mpu_rate_ad_fast;
	assign rate_fast = mpu_rate_fast;

endmodule
