/*
 * Copyright (c) 2024 Nicholas Alan West
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/*
* Contains the lookup table for the dequantized result of sf_quant and QR
* Data is as follows: 
*	{   1,    -1,    3,    -3,    5,    -5,     7,     -7},
*	{   5,    -5,   18,   -18,   32,   -32,    49,    -49},
*	{  16,   -16,   53,   -53,   95,   -95,   147,   -147},
*	{  34,   -34,  113,  -113,  203,  -203,   315,   -315},
*	{  63,   -63,  210,  -210,  378,  -378,   588,   -588},
*	{ 104,  -104,  345,  -345,  621,  -621,   966,   -966},
*	{ 158,  -158,  528,  -528,  950,  -950,  1477,  -1477},
*	{ 228,  -228,  760,  -760, 1368, -1368,  2128,  -2128},
*	{ 316,  -316, 1053, -1053, 1895, -1895,  2947,  -2947},
*	{ 422,  -422, 1405, -1405, 2529, -2529,  3934,  -3934},
*	{ 548,  -548, 1828, -1828, 3290, -3290,  5117,  -5117},
*	{ 696,  -696, 2320, -2320, 4176, -4176,  6496,  -6496},
*	{ 868,  -868, 2893, -2893, 5207, -5207,  8099,  -8099},
*	{1064, -1064, 3548, -3548, 6386, -6386,  9933,  -9933},
*	{1286, -1286, 4288, -4288, 7718, -7718, 12005, -12005},
*	{1536, -1536, 5120, -5120, 9216, -9216, 14336, -14336}
*
* Luckily every other peice of data is just the negative of the one before it, so we can save some space
*/

module QOA_ROM (
		input wire [3:0] addr1,
		input wire [2:0] addr2,
		output wire [15:0] data
	);

	reg signed [13:0] ROM [0:15] [0:3]; // 14 bits because 14336 is max val, then sign bit is added later

	// Assign ROM values
	initial begin
		ROM[0][0] = 14'd1; ROM[0][1] = 14'd3; ROM[0][2] = 14'd5; ROM[0][3] = 14'd7;
		ROM[1][0] = 14'd5; ROM[1][1] = 14'd18; ROM[1][2] = 14'd32; ROM[1][3] = 14'd49;
		ROM[2][0] = 14'd16; ROM[2][1] = 14'd53; ROM[2][2] = 14'd95; ROM[2][3] = 14'd147;
		ROM[3][0] = 14'd34; ROM[3][1] = 14'd113; ROM[3][2] = 14'd203; ROM[3][3] = 14'd315;
		ROM[4][0] = 14'd63; ROM[4][1] = 14'd210; ROM[4][2] = 14'd378; ROM[4][3] = 14'd588;
		ROM[5][0] = 14'd104; ROM[5][1] = 14'd345; ROM[5][2] = 14'd621; ROM[5][3] = 14'd966;
		ROM[6][0] = 14'd158; ROM[6][1] = 14'd528; ROM[6][2] = 14'd950; ROM[6][3] = 14'd1477;
		ROM[7][0] = 14'd228; ROM[7][1] = 14'd760; ROM[7][2] = 14'd1368; ROM[7][3] = 14'd2128;
		ROM[8][0] = 14'd316; ROM[8][1] = 14'd1053; ROM[8][2] = 14'd1895; ROM[8][3] = 14'd2947;
		ROM[9][0] = 14'd422; ROM[9][1] = 14'd1405; ROM[9][2] = 14'd2529; ROM[9][3] = 14'd3934;
		ROM[10][0] = 14'd548; ROM[10][1] = 14'd1828; ROM[10][2] = 14'd3290; ROM[10][3] = 14'd5117;
		ROM[11][0] = 14'd696; ROM[11][1] = 14'd2320; ROM[11][2] = 14'd4176; ROM[11][3] = 14'd6496;
		ROM[12][0] = 14'd868; ROM[12][1] = 14'd2893; ROM[12][2] = 14'd5207; ROM[12][3] = 14'd8099;
		ROM[13][0] = 14'd1064; ROM[13][1] = 14'd3548; ROM[13][2] = 14'd6386; ROM[13][3] = 14'd9933;
		ROM[14][0] = 14'd1286; ROM[14][1] = 14'd4288; ROM[14][2] = 14'd7718; ROM[14][3] = 14'd12005;
		ROM[15][0] = 14'd1536; ROM[15][1] = 14'd5120; ROM[15][2] = 14'd9216; ROM[15][3] = 14'd14336;
	end
	
	// Every 2nd element in the table is the negative of the previous
	assign data = addr2[0] ? -ROM[addr1][addr2[2:1]] : ROM[addr1][addr2[2:1]];
	
endmodule
