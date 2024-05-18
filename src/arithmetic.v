/*
* Copyright (c) 2024 Nicholas Alan West
* SPDX-License-Identifier: Apache-2.0
*/

/*
Made by Nicholas West (28add11)

The arithmetic unit, consisting of the 32 bit adder, multiplier, and accompanying logic
This file also contains the multiplier module, as we are cheating a bit by using the adder to do part of our multiplication
*/

/*
* The 16 * 16 = 32 bit multiplier module
* using a sequential design
* 3 i/o things are for interface with adder
*/
/*
module multiplication (
		input wire clk,
		input wire restart,
		input wire signed [15:0] input1,
		input wire signed [15:0] input2,
		output wire signed [31:0] result,
		output wire signed [31:0] term1,
		output wire signed [31:0] term2,
		input wire signed [31:0] sum
	);

	

	always @ (posedge clk or posedge restart) begin
		// Set values to initial to begin multiplication
		if (restart) begin
			// Can all be done at once i think? Thus blocking assignments
			multiplier = input1;
			multiplicand = input2;
			product = 32'b0;
		end
		else begin
			multipicand <= multipicand >> 1;
			
		end 
		
	end 
endmodule; */

module arithmetic(
		input wire signed operation,
		input wire signed [31:0] input1,
		input wire signed [31:0] input2
		output wire signed [31:0] result
	);

	assign result = operation ? input1 * input2 : input1 + input2;

endmodule