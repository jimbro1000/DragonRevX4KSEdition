`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:24:46 06/04/2024 
// Design Name: 
// Module Name:    div4 
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
module div4(
    input clk,
    output q,
    input rst
    );

	reg q0;
	
	div2 div2_0 (
		clk, q0, rst
	);
	
	div2 div2_1 (
		q0, q, rst
	);

endmodule
