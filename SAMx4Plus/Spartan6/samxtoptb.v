`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:30:55 06/03/2024
// Design Name:   samxtop
// Module Name:   /home/ise/ISE/mc6883test-spartan6/samxtoptb.v
// Project Name:  mc6883test-spartan6
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: samxtop
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module samxtoptb;

	// Inputs
	reg [15:0] A;
	reg [7:0] D;
	reg [1:0] SZ;
	reg DA0;
	reg nRES;
	reg OSCOut;
	reg RnW;
	reg nHS;
	reg nNMIx;
	reg nIRQx;
	reg nFIRQx;

	// Outputs
	wire [21:0] Z;
	wire [2:0] S;
	wire VClk;
	wire Q;
	wire E;
	wire nWE;
	wire nRAS0;
	wire nNMI;
	wire nIRQ;
	wire nFIRQ;

	// Instantiate the Unit Under Test (UUT)
	samxtop uut (
		.Z(Z), 
		.S(S), 
		.A(A), 
		.D(D), 
		.SZ(SZ), 
		.DA0(DA0), 
		.nRES(nRES), 
		.VClk(VClk), 
		.OSCOut(OSCOut), 
		.Q(Q), 
		.E(E), 
		.RnW(RnW), 
		.nWE(nWE), 
		.nRAS0(nRAS0), 
		.nHS(nHS), 
		.nNMI(nNMI), 
		.nNMIx(nNMIx), 
		.nIRQ(nIRQ), 
		.nIRQx(nIRQx), 
		.nFIRQ(nFIRQ), 
		.nFIRQx(nFIRQx)
	);

	initial begin
		// Initialize Inputs
		A = 0;
		D = 0;
		SZ = 0;
		DA0 = 0;
		OSCOut = 0;
		RnW = 0;
		nHS = 0;
		nNMIx = 1;
		nIRQx = 1;
		nFIRQx = 1;

		// Wait 100 ns for global reset to finish
		nRES = 0;
		#100;
      nRES = 1;
		// Add stimulus here

	end
	
	always begin
		OSCOut = 0;
		#2;
		OSCOut = 1;
		#2;
	end
      
endmodule

