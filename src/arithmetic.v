/*
* Copyright (c) 2024 Nicholas Alan West
* SPDX-License-Identifier: Apache-2.0
*/

/*
Made by Nicholas West (28add11)

The arithmetic unit, consisting of the 32 bit adder, multiplier, and accompanying logic
This file also contains the multiplier module, as we are cheating a bit by using the adder to do part of our multiplication
*/

`default_nettype none

/*
* The 16 * 16 = 32 bit multiplier module
* using a sequential design
*/

module multiplier (
		input wire sys_clk,
		input wire sys_rst_n,
		input wire start,
		input wire signed [15:0] input1,
		input wire signed [15:0] input2,
		output reg signed [31:0] result,
		output wire finished
	);

	parameter WAIT = 1'b0;
	parameter MULTIPLY = 1'b1;

	wire [15:0] abs_input1;
	wire [15:0] abs_input2;
	assign abs_input1 = input1[15] ? -input1 : input1;
	assign abs_input2 = input2[15] ? -input2 : input2;

	reg signed [15:0] multiplier;
	reg signed [15:0] multiplicand;
	reg signed [31:0] partial_prod;
	reg signed [31:0] product;
	
	reg [4:0] count;
	reg state;

	reg pp_done;
	reg pp_done_prev; // Sync signal
	reg done;
	assign finished = done;

	always @(posedge sys_clk) begin
		if (~sys_rst_n) begin
			// Go to consistant state
			multiplier <= 16'b0;
			multiplicand <= 16'b0;
			partial_prod <= 32'b0;
			product <= 32'b0;

			count <= 5'b0;
			state <= WAIT;

			pp_done <= 1'b0;
		end else begin
			case (state)
				WAIT: begin
					if (start) begin // Reset values
						multiplier <= abs_input1;
						multiplicand <= abs_input2;
						partial_prod <= 32'b0;

						count <= 5'b0;
						state <= MULTIPLY;

						pp_done <= 1'b0;
					end
				end

				MULTIPLY: begin // Sequential multiplication algorithm
					if (count < 16) begin 
						if (multiplier[0]) begin
							partial_prod <= partial_prod + (multiplicand << count);
						end
						// Always shift and incrument counter
						multiplier <= multiplier >> 1;
						count <= count + 1;
					end else begin // Done multiplication
						product <= partial_prod;
						pp_done <= 1'b1;
						state <= WAIT;
					end
				end

				default: state <= WAIT;

			endcase
		end 
	end 

	// Sign correction
	
	always @(posedge sys_clk) begin
		if (~sys_rst_n) begin
			result <= 32'b0;
			pp_done_prev <= 1'b0;
			done <= 1'b0;
		end else begin
			pp_done_prev <= pp_done;
			if (pp_done && ~pp_done_prev) begin
				done <= 1'b1;
				if ((input1[15] ^ input2[15]) == 1'b1) begin // Negative result
					result <= -product;
				end else begin // Positive result
					result <= product;
				end
				
			end else begin
				done <= 1'b0;
			end
		end
	end
	
endmodule
