`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:08:55 06/03/2024 
// Design Name: 
// Module Name:    z_generator 
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
module z_generator(
    input [15:0] A,
    input [2:0] S,
    input Z_Source,
    input [15:0] B,
    output [21:0] Z
    );
	 
	reg [21:0] zz;
	 
	always @(A, Z_Source, B) begin
		if (Z_Source) begin // VDG
			zz = 6'b000000 & B[15:0];
		end else begin // MPU
			case (S)
				3'b100: //IO0
					zz = 18'b000000000000000000 & A[3:0];
				3'b101: //IO1
					zz = 18'b000000000000000000 & A[3:0];
				3'b110: //IO2
					zz = 18'b000000000000000000 & A[3:0];
				3'b001: //rom0+1
					zz = 9'b000000000 & A[12:0];
				3'b011: //rom2
					zz = 9'b000000000 & A[12:0];
				3'b000:
					zz = 6'b000000 & A[15:0];
			endcase
		end
	end

	assign Z = zz;

endmodule
