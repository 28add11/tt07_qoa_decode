# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
	dut._log.info("Start")
    
	# Open and read from the debug data file
	#with open("qoaTestF.txt", "r") as debugDat:
	#	fileDat = debugDat.readlines()

    # Set the clock period to 10 us (100 KHz)
	clock = Clock(dut.clk, 10, units="us")
	cocotb.start_soon(clock.start())

	# Reset
	dut._log.info("Reset")
	dut.ena.value = 1
	dut.ui_in.value = 0
	dut.uio_in.value = 0
	dut.rst_n.value = 0
	await ClockCycles(dut.clk, 10)
	dut.rst_n.value = 1

	dut._log.info("Test project behavior")

	# QOA dequant values
	qoa_dequant_tab = [[   1,    -1,    3,    -3,    5,    -5,     7,     -7],
	[   5,    -5,   18,   -18,   32,   -32,    49,    -49],
	[  16,   -16,   53,   -53,   95,   -95,   147,   -147],
	[  34,   -34,  113,  -113,  203,  -203,   315,   -315],
	[  63,   -63,  210,  -210,  378,  -378,   588,   -588],
	[ 104,  -104,  345,  -345,  621,  -621,   966,   -966],
	[ 158,  -158,  528,  -528,  950,  -950,  1477,  -1477],
	[ 228,  -228,  760,  -760, 1368, -1368,  2128,  -2128],
	[ 316,  -316, 1053, -1053, 1895, -1895,  2947,  -2947],
	[ 422,  -422, 1405, -1405, 2529, -2529,  3934,  -3934],
	[ 548,  -548, 1828, -1828, 3290, -3290,  5117,  -5117],
	[ 696,  -696, 2320, -2320, 4176, -4176,  6496,  -6496],
	[ 868,  -868, 2893, -2893, 5207, -5207,  8099,  -8099],
	[1064, -1064, 3548, -3548, 6386, -6386,  9933,  -9933],
	[1286, -1286, 4288, -4288, 7718, -7718, 12005, -12005],
	[1536, -1536, 5120, -5120, 9216, -9216, 14336, -14336]]

	# start with chipsel high and pulse clock
	dut.uio_in.value = 0b00000001
	await ClockCycles(dut.clk, 3)
	dut.uio_in.value = 0b00001001
	await ClockCycles(dut.clk, 3)
	dut.uio_in.value = 0b00000001
	await ClockCycles(dut.clk, 3)
    
	# pull everything low
	dut.uio_in.value = 0
	await ClockCycles(dut.clk, 3)
    
	# Read file, get outputs
	for qr in range(0, 8):
		for sf_quant in range(0, 16):
			send = ((sf_quant << 4) | (qr << 1)) | 0x01
			for bit in range(0, 8):
				dut.uio_in.value = (((send << bit) & 0x80) >> 6)
				await ClockCycles(dut.clk, 3)
				dut.uio_in.value = 0x08 | dut.uio_in.value
				await ClockCycles(dut.clk, 3)
			await ClockCycles(dut.clk, 3)
			assert dut.user_project.decode.rom_data.value.signed_integer == qoa_dequant_tab[sf_quant][qr]


    # Wait for one clock cycle to see the output values
    

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
