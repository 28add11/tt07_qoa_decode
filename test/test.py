# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

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

    # Set the input values you want to test

	# start with chipsel high and pulse clock
    dut.uio_in.value = 0b00000001
    await ClockCycles(dut.clk, 4)
    dut.uio_in.value = 0b00001001
    await ClockCycles(dut.clk, 4)
    dut.uio_in.value = 0b00000001
    await ClockCycles(dut.clk, 4)
    
	# pull everything low
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 4)
    
	# Ocillate clock and send data
    for i in range(0, 255):
        recived = 0
        for bit in range(0, 8):
            dut.uio_in.value = (((i << bit) & 0x80) >> 6)
            await ClockCycles(dut.clk, 4)
            dut.uio_in.value = 0x08 | dut.uio_in.value
            await ClockCycles(dut.clk, 4)
        # test transmit functionality
        for bit in range(0, 8):
            dut.uio_in.value = 0
            await ClockCycles(dut.clk, 4)
            dut.uio_in.value = 0x08 
            # Sample data on rising edge
            recived = ((recived << 1) | ((dut.uio_out.value & 0x04) >> 2))
            await ClockCycles(dut.clk, 4)
        assert recived == i
        
    """
	# Test all 8 bit values
    for i in range(0, 255):
        bit = 0
        response = 0
        # pull everything low
        dut.uio_in.value = 0
        print(dut.uio_in.value)
        # Send the val
        for bit in range(0, 8):
             
            dut.uio_in.value = (dut.uio_in.value | (((i << bit) & 0x80) >> 1))
            await ClockCycles(dut.clk, 4)
            # set spi clk high
            dut.uio_in.value = (dut.uio_in.value | 0x08)
            await ClockCycles(dut.clk, 4)
            # set low again
            dut.uio_in.value = (dut.uio_in.value & 0xF7)
            
		# read the val
        
        for bit in range(0, 16):
            await ClockCycles(dut.clk, 4)
            # set spi clk high
            dut.uio_in.value = (dut.uio_in.value | 0x08)
            # read
            response = ((response << bit) | (dut.uio_out.value >> 2))
            await ClockCycles(dut.clk, 4)
            # set low again
            dut.uio_in.value = (dut.uio_in.value & 0xF7)
        assert response == ((i << 8) | i)
            """

    # Wait for one clock cycle to see the output values
    

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
