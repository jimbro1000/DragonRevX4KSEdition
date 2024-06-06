`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:25:32 06/03/2024 
// Design Name: 
// Module Name:    samxvmode 
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
module samxvmode(
    input clk,
    input reset,
    input select,
	 input write,
	 input [3:0] wmode,
    output [3:0] rmode
    );
	 
	 reg [3:0] vmode;

	 always @(posedge clk) begin
		if (!reset)
			vmode <= 0;
		else begin
			if (select & write)
				vmode <= wmode;
			else
				vmode <= vmode;
		end
	 end
	 assign rmode = (select & ~write) ? vmode : 0;
endmodule
