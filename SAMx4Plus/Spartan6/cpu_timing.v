`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:50:22 06/03/2024 
// Design Name: 
// Module Name:    cpu_timing 
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
module cpu_timing(
    output E,
    output Q,
    output wire [3:0] T,
    output Z_Source,
    input clk,
    input rate_slow,
    input rate_ad_slow,
    input rate_ad_fast,
    input rate_fast,
	 input isRAM
    );

	reg qi;
	reg ei;
	reg [3:0] t;
	reg fast_cycle;
	reg z;
	
	initial begin
		fast_cycle = 0;
	end

	always @(negedge clk) begin
		case (t)
			4'b1111: begin
				t = 4'b0000;
				if (fast_cycle)
					if (rate_slow || rate_ad_slow)
						fast_cycle = 0;
					else begin
						qi = 1;
						if (rate_fast && isRAM)
							z = 0;
					end
			end
			4'b0000: t = 4'b0001;
			4'b0001: begin
				t = 4'b0010;
				if (!fast_cycle) begin
					if (rate_fast || rate_ad_fast)
						fast_cycle = 1;
				end else
					ei = 1;
			end
			4'b0010: begin
				t = 4'b0011;
				if (!fast_cycle)
					qi = 1;
			end
			4'b0011: begin
				t = 4'b0100;
				if (fast_cycle)
					qi = 0;
			end
			4'b0100: t = 4'b0101;
			4'b0101: begin
				t = 4'b0110;
				if (fast_cycle)
					ei = 0;
			end
			4'b0110: begin
				t = 4'b0111;
				if (!fast_cycle)
					ei = 1;
			end
			4'b0111: begin
				t = 4'b1000;
				z = 0;
				if (fast_cycle)
					if (rate_slow || rate_ad_slow)
						fast_cycle = 0;
					else
						qi = 1;
			end
			4'b1000: t = 4'b1001;
			4'b1001: begin
				t = 4'b1010;
				if (!fast_cycle)
					if (rate_fast)
						fast_cycle = 1;
				else
					ei = 1;
			end
			4'b1010: begin
				t = 4'b1011;
				if (!fast_cycle)
					qi = 0;
			end
			4'b1011: begin
				t = 4'b1100;
				if (fast_cycle)
					qi = 0;
			end
			4'b1100: t = 4'b1101;
			4'b1101: begin
				t = 4'b1110;
				if (fast_cycle)
					ei = 0;
			end
			default: begin
				t = 4'b1111;
				if (!fast_cycle)
					ei = 0;
				z = 1;
			end
		endcase
	end
	
	assign Q = qi;
	assign E = ei;
	assign T = t;

	assign Z_Source = z;
	
endmodule
