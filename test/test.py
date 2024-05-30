# SPDX-FileCopyrightText: © 2024 Nicholas Alan West
# SPDX-License-Identifier: MIT

import time

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from cocotbext.spi import SpiBus, SpiConfig, SpiMaster

def to_signed_16_bit(n):
    """Convert an unsigned 16-bit integer to a signed 16-bit integer."""
    if n >= 0x8000:  # If the number is greater than or equal to 32768
        return n - 0x10000  # Subtract 65536
    else:
        return n


@cocotb.test()
async def test_project(dut):
	dut._log.info("Start")

	prevtime = time.time()
    
	spi_bus = SpiBus.from_entity(dut)
	spi_config = SpiConfig(
    	word_width = 8,
    	sclk_freq  = 8000000,
    	cpol       = False,
    	cpha       = False,
    	msb_first  = True,
    	cs_active_low = True,
		data_output_idle = 0
	)

	spi_master = SpiMaster(spi_bus, spi_config)

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
			await spi_master.write(instruction.to_bytes(1, "big"))

			# Send data
			databytes = data.to_bytes(2, "big", signed=True)
			await spi_master.write(databytes)

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
			await spi_master.write(instruction.to_bytes(1, "big"))

			await ClockCycles(dut.clk, 32) # Delay for processing
			# Get sample
			instruction = 0x80
			# Send instruction
			await spi_master.write(instruction.to_bytes(1, "big"))
			
			# Recive
			returned = 0
			spi_master.clear()
			await spi_master.write([0x00]) # Burner tx, just so spi clock keeps going
			returned = int.from_bytes(await spi_master.read(), byteorder='big')
			await spi_master.write([0x00])
			returned = int.from_bytes(await spi_master.read(), byteorder='big') | (returned << 8)
			
			assert to_signed_16_bit(returned) == sample

			if sampleCount % 1000 == 0:
				print("Completed sample " + str(sampleCount) + "\tSamples per second: " + str(1000 / (time.time() - prevtime)))
				prevtime = time.time()
			sampleCount += 1
