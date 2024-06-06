`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:20:34 06/03/2024 
// Design Name: 
// Module Name:    samxtop 
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
module samxtop(
    output [21:0] Z,
    output [2:0] S,
    input [15:0] A,
    input [7:0] D,
    input [1:0] SZ,
	 input DA0,
    input nRES,
    output VClk,
    input OSCOut,
    output Q,
    output E,
    input RnW,
    output nWE,
    output nRAS0,
    input nHS,
    output nNMI,
    input nNMIx,
    output nIRQ,
    input nIRQx,
    output nFIRQ,
    input nFIRQx
    );
	 
	 wire	TY;
	 wire	[7:0] F;
	 wire [3:0] V;
	 wire P;
	 wire [1:0] R;
	 wire [1:0] M;
	 reg [16:0] B;
	 reg  mask;
	 reg	rw;
	 wire COMPATIBILITY;

	 wire Z_Source;
	 wire [3:0] T;
	 wire	isRAM;
	 wire	slowBlock;
	 wire rate_slow;
	 wire rate_ad_slow;
	 wire rate_ad_fast;
	 wire rate_fast;
	 wire BOSC;
	 
	 wire xdiv3_out;
	 wire xdiv2_out;
	 wire ydiv12_out;
	 wire ydiv8_out;
	 wire ydiv3_out;
	 wire ydiv2_out;
	 
	 wire use_xgnd;
	 wire use_xdiv3;
	 wire use_xdiv2;
	 wire use_xdiv1;
	 
	 wire use_ygnd;
	 wire use_ydiv12;
	 wire use_ydiv8;
	 wire use_ydiv3;
	 wire use_ydiv2;
	 wire use_ydiv1;
	 
	 wire IERuVP;
	 wire is_DMA;
	 
	 multiplexer address_multiplexer
	 (
		A, S, slowBlock, isRAM, TY, OSCOut, RnW
	 );
	 
	 mpu_rate mpu_rate_control
	 (
		OSCOut, R, slowBlock, rate_slow, rate_ad_slow, rate_ad_fast, rate_fast
	 );
	 
	 cpu_timing timer
	 (
		E, Q, T, Z_Source, BOSC, rate_slow, rate_ad_slow, rate_ad_fast, rate_fast, isRAM
	 );
	 
	 interrupt_mask irq_mask
	 (
		nNMIx, nIRQx, nFIRQx, mask, nNMI, nIRQ, nFIRQ
	 );
	 
	 z_generator address_mapper
	 (
		A, S, Z_Source, B, Z
	 );
	 
	 sam_registers registers
	 (
		BOSC, A, D, nRES, RnW, TY, F, P, M, V, R, COMPATIBILITY
	 );
	 
	 div3 xdiv3
	 (
		B[3], xdiv3_out, IERuVP
	 );
	 
	 div2 xdiv2
	 (
		B[3], xdiv2_out, IERuVP
	 );
	 
	 div4 ydiv12
	 (
		ydiv3_out, ydiv12_out, IERuVP
	 );
	 
	 div4 ydiv8
	 (
		ydiv2_out, ydiv8_out, IERuVP
	 );
	 
	 div3 ydiv3
	 (
		B[4], ydiv3_out, IERuVP
	 );
	 
	 div2 ydiv2
	 (
		B[4], ydiv2_out, IERuVP
	 );
	 
	 initial begin
		B = 17'b00000000000000000;
		mask = 0;
	 end
	 
	 assign BOSC = OSCOut;
	 
	 always @(RnW, E, isRAM) begin
		rw = (E && isRAM) ? RnW : 1;
	 end
	 
	 assign nWE = rw;
	 assign nRAS0 = 0;
	 assign VClk = 0;
	 
	 assign IERuVP = !nRES || !( HR || DA0nq);
	 
	 always @(negedge HR) begin
		DA0nq = !DA0;
	 end
	 
	 assign VP = !nRES || !nHS;
	 assign use_ygnd = (!V[3] && !V[2] && !V[0] && !(Vprev[1] == V[1]));
	 assign use_yb4 = (!V[3] && !V[1] && !V[0] && !(Vprev[2] == V[2]));
	 assign use_xgnd = (!V[3] && !V[2] && !V[0] && !(Vprev[1] == V[1]));
	 
	 assign use_ydiv12 = (V[2:0] == 3'b000 && !use_ygnd && !use_yb4);
	 assign use_ydiv8 = (V[3:2] == 2'b10 && V[0] && !use_ygnd && !use_yb4);
	 assign use_ydiv3 = (V == 3'b0010 && !use_ygnd);
	 assign use_ydiv2 = (V == 3'b0100 && !use_yb4);
	 assign use_ydiv1 = !(use_ydiv12 || use_ydiv8 || use_ydiv3 || use_ydiv2);
	 
	 assign use_xdiv3 = (!use_xgnd && V == 4'b0001);
	 assign use_xdiv2 = (!use_xgnd && V == 4'b0011);
	 assign use_xdiv1 = !(use_xdiv3 || use_xdiv2);
	 
	 assign is_DMA = (V[2:0] == 3'b111);

endmodule
