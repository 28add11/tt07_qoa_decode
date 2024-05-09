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

	reg signed [15:0] multiplier;
	reg signed [15:0] multiplicand;
	reg signed [31:0] product;


	always @ (posedge clk or posedge restart) begin
		// Set values to initial to begin multiplication
		if (restart) begin
			// Can all be done at once i think? Thus blocking assignments
			multiplier = input1;
			multiplicand = input2;
			product = 32'b0;
		end
		else begin
			
		end
		
	end
endmodule;