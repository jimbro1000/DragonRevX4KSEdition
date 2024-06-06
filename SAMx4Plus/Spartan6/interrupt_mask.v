`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:37:35 06/03/2024 
// Design Name: 
// Module Name:    interrupt_mask 
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
module interrupt_mask(
    input nNMIx,
    input nIRQx,
    input nFIRQx,
    input mask,
    output nNMI,
    output nIRQ,
    output nFIRQ
    );
	 
	 reg NMI;
	 reg IRQ;
	 reg FIRQ;

	always @(mask, nNMIx, nIRQx, nFIRQx) begin
		if(!mask) begin
			NMI = nNMIx;
			IRQ = nIRQx;
			FIRQ = nFIRQx;
		end else begin
			NMI = 1;
			IRQ = 1;
			FIRQ = 1;
		end
	end
	
	assign nNMI = NMI;
	assign nIRQ = IRQ;
	assign nFIRQ = FIRQ;

endmodule
