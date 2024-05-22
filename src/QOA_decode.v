/*
 * Copyright (c) 2024 Nicholas Alan West
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/*
* This file is the core of the chip, the decode and processing logic for the QOA format
* Consists largely of a state machine for interpereting the SPI input data and doing stuff with it
*/

module qoa_decoder (
		input wire sys_rst_n,
		input wire sys_clk,
		input wire data_rdy,
		input wire [7:0] spi_in,
		input wire [3:0] spi_out_bit,
		output reg [15:0] spi_out
	);

	// LMS predictor history and weights, 2 * 4 16 bit registers
	reg signed [15:0] history [3:0];
	reg signed [15:0] weights [3:0];

	// Internal control signals
	parameter WAIT = 2'b0;
	parameter PARSE = 2'b01;
	parameter PROCESSING = 2'b10;
	parameter TXSAMPLE = 2'b11;

	reg [1:0] state;
	reg processing_stage;

	// Decoder control signals
	reg [1:0] mult_index;
	wire [15:0] delta;

	// Internal data
	reg [3:0] sf_index;
	reg [2:0] qr_index;
	reg [1:0] hw_index; // History/weights index
	reg hw_selector;
	reg high_low;
	reg signed [15:0] dequant;
	reg signed [31:0] accumulator;

	reg [15:0] sample;
	wire [15:0] temp_sample;

	wire signed [15:0] histTest;
	wire signed [15:0] weightTest;
	assign histTest = history[mult_index];
	assign weightTest = weights[mult_index];

	// QOA ROM
	wire [15:0] rom_data;
	QOA_ROM rom(
		.addr1(sf_index),
		.addr2(qr_index),
		.data(rom_data)
	);
	
	// Combinational components
	assign delta = dequant >>> 4;
	// data is valid when processing stage is 1
	assign temp_sample = (accumulator >>> 13) + dequant;

	always @(posedge sys_clk) begin
		if (~sys_rst_n) begin
			spi_out <= 16'b0;
			state <= WAIT;
			// Reset history and weights
			history[0] <= 16'b0;
			weights[0] <= 16'b0;
			history[1] <= 16'b0;
			weights[1] <= 16'b0;
			history[2] <= 16'b0;
			weights[2] <= 16'b0;
			history[3] <= 16'b0;
			weights[3] <= 16'b0;

			accumulator <= 32'b0;
			high_low <= 1'b1; // Start at high bit for MSB

			processing_stage <= 1'b0;
			mult_index <= 2'b0;
		end else begin
			case (state)
				WAIT: begin
					if (data_rdy) begin
						// Sample process
						if (spi_in[0]) begin 
							qr_index <= spi_in[3:1];
							sf_index <= spi_in[7:4];
							
							state <= PROCESSING; // Set state to process the values

						// Hist/Weights fill
						end else if (~spi_in[7]) begin// Ignore if instruction is for sample TX
							hw_selector <= spi_in[1];
							hw_index <= spi_in[3:2];

							state <= PARSE; // Parse the next two bytes for history/weights

						end else if (spi_in[7]) begin
							state <= TXSAMPLE; // Largely just so we ignore all other signals
							spi_out <= sample;
						end
					end
				end

				// Parse values into history/weights
				PARSE: begin
					if (data_rdy) begin
						if (hw_selector) begin

							// hw_selector being 1 = weights
							if (high_low) begin
								// High byte
								weights[hw_index] <= {spi_in, weights[hw_index][7:0]};
								high_low <= 1'b0;
								
							end else begin
								// Low byte
								weights[hw_index] <= {weights[hw_index][15:8], spi_in};
								high_low <= 1'b1; 
								state <= WAIT; // We are done putting things into the weights so return to waiting
							end
						end else begin
							// hw_selector 0 = history
							if (high_low) begin
								// High byte
								history[hw_index] <= {spi_in, history[hw_index][7:0]};
								high_low <= 1'b0;

							end else begin
								// Low byte
								history[hw_index] <= {history[hw_index][15:8], spi_in};
								high_low <= 1'b1; 
								state <= WAIT; // We are done putting things into the history so return to waiting
							end
						end
					end
				end

				// Get sample 
				PROCESSING: begin
					dequant <= rom_data;
					if (processing_stage == 1'b0) begin
						
						// Predict sample
						accumulator <= accumulator + (history[mult_index] * weights[mult_index]);
						mult_index <= mult_index + 1;

						if (mult_index == 2'd3) begin // Finish up prediction
							processing_stage = 1'b1;
							mult_index <= 2'b0;
						end

					end else begin
						// Save actual sample
						sample <= temp_sample;
						// Update LMS weights
						weights[0] <= weights[0] + (history[0] < 0 ? -delta : delta);
						weights[1] <= weights[1] + (history[1] < 0 ? -delta : delta);
						weights[2] <= weights[2] + (history[2] < 0 ? -delta : delta);
						weights[3] <= weights[3] + (history[3] < 0 ? -delta : delta);

						// Update LMS history, most recent last
						history[0] <= history[1];
						history[1] <= history[2];
						history[2] <= history[3];
						history[3] <= temp_sample;

						processing_stage <= 1'b0;

						accumulator <= 32'b0;

						state <= WAIT; // Complete execution	
					end 					
				end

				TXSAMPLE: begin
					if (data_rdy) begin // We need 16 spi clock cycles, i.e. two data_rdy pulses
						if (~processing_stage) begin
							processing_stage <= 1'b1;
						end else begin
							processing_stage <= 1'b0;
							state <= WAIT;
						end
						
					end
				end

				default: state <= WAIT;

			endcase
		end
	end
endmodule