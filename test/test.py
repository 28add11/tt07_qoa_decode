# SPDX-FileCopyrightText: © 2024 Nicholas Alan West
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

def to_signed_16_bit(n):
    """Convert an unsigned 16-bit integer to a signed 16-bit integer."""
    if n >= 0x8000:  # If the number is greater than or equal to 32768
        return n - 0x10000  # Subtract 65536
    else:
        return n


@cocotb.test()
async def test_project(dut):
	dut._log.info("Start")
    
	# Open and read from the debug data file
	with open("qoaTestF SMALL.txt", "r") as debugDat:
		fileDat = debugDat.readlines()

	# Set the clock period to 20 ns (50 MHz)
	clock = Clock(dut.clk, 20, units="ns")
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

	sampleCount = 0
	# Read file, wait for processing, get internal signals
	for line in fileDat:
		# Determine operation
		if line[0] == 'h' or line[0] == 'w': # Fill history or weights
			instruction = (((int(line[2]) & 0x03) << 2) | (int(line[0] == 'w') << 1)) & 0x3E
			data = int(line[4:])

			# Send instruction
			for bit in range(0, 8):
				await ClockCycles(dut.clk, 3)
				dut.uio_in.value = (((instruction << bit) & 0x80) >> 6)
				await ClockCycles(dut.clk, 3)
				dut.uio_in.value = 0x08 | dut.uio_in.value
			
			# Send data
			for bit in range(0, 16):
				await ClockCycles(dut.clk, 3)
				dut.uio_in.value = (((data << bit) & 0x8000) >> 14)
				await ClockCycles(dut.clk, 3)
				dut.uio_in.value = 0x08 | dut.uio_in.value
			
			# Wait 3 clocks and zero values
			await ClockCycles(dut.clk, 3)
			dut.uio_in.value = 0

		else: # Sample
			splitted = line.split()
			sfQuant = int(splitted[0])
			qr = int(splitted[1])
			sample = int(splitted[2])

			# Send sample
			instruction = ((sfQuant << 4) | (qr << 1)) | 0x01
			for bit in range(0, 8):
				await ClockCycles(dut.clk, 3)
				dut.uio_in.value = (((instruction << bit) & 0x80) >> 6)
				await ClockCycles(dut.clk, 3)
				dut.uio_in.value = 0x08 | dut.uio_in.value
				
			await ClockCycles(dut.clk, 3)
			dut.uio_in.value = 0x01 # CS high
			await ClockCycles(dut.clk, 60) # Delay for processing
			# Get sample
			instruction = 0x80
			# Send instruction
			for bit in range(0, 8):
				dut.uio_in.value = (((instruction << bit) & 0x80) >> 6)
				await ClockCycles(dut.clk, 3)
				dut.uio_in.value = 0x08 | dut.uio_in.value
				await ClockCycles(dut.clk, 3)
				
			# Recive
			returned = 0
			for bit in range(0, 16):
				dut.uio_in.value = 0x00
				await ClockCycles(dut.clk, 3)
				dut.uio_in.value = 0x08
				returned = ((returned << 1) | ((dut.uio_out.value & 0x04) >> 2))
				await ClockCycles(dut.clk, 3)
			
			assert to_signed_16_bit(returned) == sample

			if sampleCount % 1000 == 0:
				print("Completed sample " + str(sampleCount))
			sampleCount += 1
			
'''
		for sf_quant in range(0, 16):
			send = ((sf_quant << 4) | (qr << 1)) | 0x01
			for bit in range(0, 8):
				dut.uio_in.value = (((send << bit) & 0x80) >> 6)
				await ClockCycles(dut.clk, 3)
				dut.uio_in.value = 0x08 | dut.uio_in.value
				await ClockCycles(dut.clk, 3)
			await ClockCycles(dut.clk, 3)
			assert dut.user_project.decode.rom_data.value.signed_integer == qoa_dequant_tab[sf_quant][qr]
'''
