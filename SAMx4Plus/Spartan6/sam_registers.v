`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    06:51:04 06/04/2024 
// Design Name: 
// Module Name:    sam_registers 
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
module sam_registers(
	input clk,
	input [15:0] A,
	input [7:0] D,
	input RESET,
	input RnW,
	output TY,
	output [7:0] F,
	output P,
	output [1:0] M,
	output [3:0] V,
	output [1:0] R,
	output C
	);
	
	reg [7:0] f;
	reg [1:0] m;
	reg [3:0] v;
	reg [1:0] r;
	reg ty;
	reg p;
	reg c;

	initial begin
		m = 2'b11;
		f = 8'b00000000;
		v = 4'b0000;
		r = 2'b00;
		p = 0;
		c = 0;
		ty = 0;
	end

	always @(negedge clk) begin
		if (!RESET) begin
			f = 8'b00000000;
			v = 4'b0000;
			r = 2'b00;
		end else if (A[15:8] == 8'b11111111) begin
			case (A[7:1])
				// Video mode register V
				7'b1100000: begin
					if (c && !RnW) begin
						v[3:0] = D[3:0];
					end else begin
						v[0] = A[0];
					end
				end
				7'b1100001: begin
					v[1] = A[0];
				end
				7'b1100010: begin
					v[2] = A[0];
				end
				// Video base address * 512
				7'b1100011: begin
					if (c && !RnW) begin
						f[7:0] = D[7:0];
					end else begin
						f[0] = A[0];
					end
				end
				7'b1100100: begin
					f[1] = A[0];
				end
				7'b1100101: begin
					f[2] = A[0];
				end
				7'b1100110: begin
					f[3] = A[0];
				end
				7'b1100111: begin
					f[4] = A[0];
				end
				7'b1101000: begin
					f[5] = A[0];
				end
				7'b1101001: begin
					f[6] = A[0];
				end
				// P
				7'b1101010: begin
					p = A[0];
				end
				// MPU Rate
				7'b1101011: begin
					r[0] = A[0];
				end
				7'b1101100: begin
					r[1] = A[0];
				end
				// Compatibility (was mem size 0)
				7'b1101101: begin
					c = A[0];
				end
				// reserved for enabling paging
				// 7'b1101110 begin
				// end
				// Map type
				7'b1101111: begin
					ty = A[0];
				end
			endcase
		end
	end
	
	assign V = v;
	assign M = m;
	assign F = f;
	assign R = r;
	assign P = p;
	assign TY = ty;
	assign C = c;

endmodule
