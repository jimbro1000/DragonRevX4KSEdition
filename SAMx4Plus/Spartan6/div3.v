`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:21:37 06/04/2024 
// Design Name: 
// Module Name:    div3 
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
module div3(
    input clk,
    output q,
    input rst
    );

	reg d0;
	reg q0;
	reg q1;
	reg q2;
	
	always @(posedge clk, rst) begin
		if (rst) begin
			q0 = 0;
			q1 = 0;
		end else begin
			q0 = d0;
			q1 = q0;
		end
	end
	
	always @(negedge clk, rst) begin
		if (rst) 
			q2 = 0;
		else begin
			q2 = q1;
		end
	end
	
	assign q = (q2 || q1);

endmodule
