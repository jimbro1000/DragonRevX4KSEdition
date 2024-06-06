`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:19:31 06/04/2024 
// Design Name: 
// Module Name:    div2 
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
module div2(
    input clk,
    output q,
    input rst
    );
	 
	reg q0;

	always @(negedge clk, rst) begin
		if (rst)
			q0 = 0;
		else
			q0 = !q0;
	end
	
	assign q = q0;

endmodule
