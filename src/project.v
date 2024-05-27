/*
 * Copyright (c) 2024 Nicholas Alan West
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/*
* This file mostly contains the SPI interface and controlling logic
*/

module tt_um_28add11_QOAdecode (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

	// All output pins must be assigned. If not used, assign to 0.
	assign uo_out  = 0;
	assign uio_out [7:3] = 0;
	assign uio_out [1:0] = 0;
	assign uio_oe  = 8'b0100; // MISO is pin 2, thus we use it as output

	wire sclk;
	assign sclk = uio_in[3];
	wire chipsel;
	assign chipsel = uio_in[0];

	reg rst_n_sync;
	always @(posedge clk) begin
		rst_n_sync <= rst_n;
	end

	// Interface for the chip, modified SPI slave supporting mode 0
	reg [7:0] RX_temp_in;
	reg [7:0] RX_data;
	reg [7:0] RX_output_data; // For clock domain sync
	reg [2:0] RX_bit; // What bit of reciving we are on
	reg RX_done;
	reg data_rdy;
	reg RX_sync1, RX_sync2;
	
	reg [15:0] TX_data; // 15 because we only transmit 16 bit values
	reg [3:0] TX_bit;

	// RX, in the SPI clock domain
	always @(posedge sclk or negedge rst_n) begin
		if (~rst_n) begin // CS high (i.e. unselected) or chip reset
			// Set control signals to starting value
			RX_data <= 8'b0;
			RX_temp_in <= 8'b0;
			RX_bit <= 3'b0;
			RX_done <= 0;
		end else if (chipsel) begin
			// Set control signals to starting value
			RX_data <= 8'b0;
			RX_temp_in <= 8'b0;
			RX_bit <= 3'b0;
			RX_done <= 0;
		end
		else begin // CS low (i.e. selected)
			// Get our data, shifting up (highest first)
			RX_temp_in <= {RX_temp_in[6:0], uio_in[1]};

			RX_bit <= RX_bit + 1;

			if (RX_bit == 3'b111) begin // If we have entered a whole byte
				RX_done <= 1;
				RX_data <= {RX_temp_in[6:0], uio_in[1]}; // at this point rx_temp_in still has an unknown value at [7]
				// So we get rid of that
			end
			else if (RX_bit == 3'b001) begin // If we continue transmitting reset control
				RX_done <= 1'b0;
			end
		end
	end

	// Cross over into chip clock domain
	always @(posedge clk) begin
		if (~rst_n_sync) begin // If we have a reset
			// Set all signals to initial
			RX_sync1 <= 1'b0; 
			RX_sync2 <= 1'b0;
			RX_output_data <= 8'b0;
			data_rdy <= 1'b0;
		end
		else begin // No reset
			// Cross clock domains
			RX_sync1 <= RX_done;
			RX_sync2 <= RX_sync1;
		
			// Rising edge (TODO: look into why this works, I'm a noob!)
			if (RX_sync2 == 1'b0 && RX_sync1 == 1'b1) begin
				// Data is valid here
				RX_output_data <= RX_data;
				data_rdy <= 1'b1;
			end else data_rdy <= 1'b0;
		end
	end


	// Create our decoder
	wire [7:0] decoder_input_wire;
	assign decoder_input_wire = RX_output_data;
	qoa_decoder decode(
		.sys_rst_n(rst_n_sync),
		.sys_clk(clk),
		.data_rdy(data_rdy),
		.spi_in(decoder_input_wire),
		.spi_out(TX_data)
	);

	// Data TX, in SPI clock domain
	// Mode 0, so data is shifted out on the clock's negative edge
	always @(negedge sclk) begin
		if (chipsel || ~rst_n) begin // Reset values for cs or chip reset
			TX_bit <= 4'b1111; // MSB
		end
		else begin
			TX_bit <= TX_bit - 1;

		end
	end
	
	// Set actual TX value
	assign uio_out[2] = TX_data[TX_bit];

endmodule
