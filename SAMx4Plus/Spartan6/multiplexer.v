`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:02:19 06/03/2024 
// Design Name: 
// Module Name:    multiplexer 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 	 generate multiplexer control signal
//						 from address, RnW and maptype values
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module multiplexer(
    input [15:0] A,
    output [2:0] S,
	 output slowBlock,
	 output isRAM,
	 input mapType,
    input clk,
	 input RnW
    );

	reg is_FFxx;
	reg is_IO0;
	reg is_IO1;
	reg is_IO2;
	reg is_RAM;
	reg is_ROM;
	reg is_SAM_REG;
	reg is_CPU_VEC;
	reg is_8xxx;
	reg is_Axxx;
	reg is_Cxxx;
	reg is_Upper;
	
	reg [2:0] value;
	
	always @(posedge clk) begin
		is_FFxx = A[15:8] == 8'b11111111;
		is_8xxx = A[15:13] == 3'b111;
		is_Axxx = A[15:13] == 3'b101;
		is_Cxxx = A[15:14] == 2'b11 && !is_FFxx;
		is_Upper = is_8xxx || is_Axxx || is_Cxxx;
		is_ROM = is_8xxx || is_Axxx;
		is_RAM = A[15] == 0 || (mapType == 1 && !is_FFxx);
		is_IO0 = is_FFxx && A[7:5] == 3'b000;
		is_IO1 = is_FFxx && A[7:5] == 3'b001;
		is_IO2 = is_FFxx && A[7:5] == 3'b010;
		is_SAM_REG = is_FFxx && A[7:5] == 3'b110;
		is_CPU_VEC = is_FFxx && A[7:5] == 3'b111;
		
		if (is_IO0)
			value = 3'b100;
		else if (is_IO1)
			value = 3'b101;
		else if (is_IO2)
			value = 3'b110;
		else if (is_CPU_VEC)
			value = 3'b001;
		else if (is_FFxx)
			value = 3'b111;
		else if (is_Upper && mapType == 1 && RnW == 0)
			value = 3'b000;
		else if (is_ROM)
			value = 3'b001;
		else if (is_Cxxx)
			value = 3'b011;
		else if (RnW)
			value = 3'b000;
		else
			value = 3'b111;
	end
	
	assign S = value;
	assign isRAM = is_RAM;
	assign slowBlock = (is_RAM || is_IO0);
endmodule
