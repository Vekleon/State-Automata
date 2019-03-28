/*
*	KEY[0] load initial state
*  KEY[1] load rule set
*  KEY[2] low synchrounous reset
*	KEY[3] GO!
*  SW[8:0] determine display initial state
*  Sw[...] determine rule set
*/
module top(SW, KEY, CLOCK_50, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);
	input [3:0] KEY;
	input [9:0] SW;
	input CLOCK_50;
	
	vga visual(
		.CLOCK_50(CLOCK_50),
		.KEY(KEY[3:0]),
		.SW(SW[9:0]),
		.VGA_CLK(VGA_CLK),
		.VGA_SYNC_N(VGA_SYNC_N),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B)
	);
	
endmodule

// Module which handles writing to the VGA based on given inputs.
// For now, only SW[9:8] function as inputs, and control which
// ring of the 8x8 pixel board are active and red.
module vga
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs heres
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(plot),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	wire [63:0] cells;
	wire ld_x, ld_y, ld_c, plot;
	
	// Handles the state of the cells on the board
	// This is done using the same mechanics that will
	// be used to display the rows of the automata.
	ring_writer r0(	.clk(CLOCK_50),
					.reset_n(resetn),
					.enable(1'b1),
					.s(SW[9:8]),
					.cells(cells));
	
	// Takes the output from ring_writer and puts
	// it to the screen by controlling the vga_adapter
	// inputs x,y,colour.
	vga_c v0(	.clk(CLOCK_50),
				.reset_n(resetn),
				.cells(cells),
				.ld_x(ld_x),
				.ld_y(ld_y),
				.ld_c(ld_c),
				.plot(plot),
				.c_out(colour),
				.x_out(x),
				.y_out(y));
    
endmodule

// Given an input of cells, rapidly updates the
// pixels in the output to display the cells. These
// outputs should go to the VGA adapter module.
module vga_c(
	input clk, reset_n,
	input [63:0] cells,
	
	output ld_x, ld_y, ld_c, plot,
	output [2:0] c_out,
	output [7:0] x_out,
	output [6:0] y_out);
	
	reg [2:0] cur_x, cur_y;
	reg [3:0] offset;
	
	wire [2:0] next_x, next_y;
	wire [3:0] next_off;
	
	// Assigning internal values
	assign next_off[3:0] = offset[3:0] + 1'b1;
	assign next_x[2:0] = (& offset) ? cur_x[2:0] + 1'b1 : cur_x[2:0];
	assign next_y[2:0] = ((& offset) & !(| next_x)) ? cur_y[2:0] + 1'b1 : cur_y[2:0];
	
	// Setting the important output values
	assign c_out = cells[{cur_y, cur_x}] ? 3'b100 : 3'b111;
	assign y_out[6:5] = 0;
	assign y_out[4:0] = {cur_y[2:0], offset[3:2]};
	assign x_out[7:5] = 0;
	assign x_out[4:0] = {cur_x[2:0], offset[1:0]};
	
	// Duh
	assign ld_x = 1;
	assign ld_y = 1;
	assign ld_c = 1;
	assign plot = 1;
	
	// Handling controls
	always @(posedge clk, negedge reset_n) begin
		if (!reset_n) begin
			cur_x <= 0;
			cur_y <= 0;
			offset <= 0;
		end
		else begin
			cur_x <= next_x;
			cur_y <= next_y;
			offset <= next_off;
		end
	end

endmodule

// Given inputs for selecting the state of the rings,
// writes to a board of cells and outputs the current state.
module ring_writer(
	input clk, reset_n, enable,
	input [1:0] s,
	output [63:0] cells);
	
	wire write;
	wire [2:0] row_select;
	wire [7:0] row_val;
	
	ring_control rc0 (clk,
						reset_n,
						enable,
						s,
						write,
						row_select,
						row_val);
						
	board b0 (write,
				clk,
				reset_n,
				row_select,
				row_val,
				cells);
endmodule

// Used to control the state of the board in the
// ring_writer module. This is an FSA.
module ring_control(

	input clk, reset_n, enable,
	input [1:0] s,
	output reg write,
	output reg [2:0] row_select,
	output reg [7:0] row_val);
	
	reg [1:0] prev_input;
	reg [2:0] curr, next;
	
	localparam 	S_WAIT = 0,
				S_RING_1 = 1,
				S_RING_2 = 2,
				S_RING_3 = 3,
				S_RING_4 = 4;

	// Handling the "next" state
	always @(*) begin
		case(curr)
			S_WAIT:
				if (prev_input != s) begin // Only proceeding if the input has changed
					case(s)
						2'b00: next <= S_RING_1;
						2'b01: next <= S_RING_2;
						2'b10: next <= S_RING_3;
						2'b11: next <= S_RING_4;
					endcase
				end
			default: begin
				if (curr != S_RING_1 &
					curr != S_RING_2 &
					curr != S_RING_3 &
					curr != S_RING_4)
					next <= S_WAIT;
				else if (row_select == 3'b111)
					next <= S_WAIT;
				end
		endcase
	end
	
	// Controls for the current state
	always @(*) begin
	
		// Default controls
		write = 1;
		row_val = 0;
		
		case(curr)
			S_WAIT:
				write <= 0;
				row_select <= 0;
			S_RING_1:
				case (row_select)
					3'b000: row_val <= 8'b11111111;
					3'b111: row_val <= 8'b11111111;
					default: row_val <= 8'b10000001;
				endcase
			S_RING_2:
				case (row_select)
					3'b000: row_val <= 8'b00000000;
					3'b001: row_val <= 8'b01111110;
					3'b110: row_val <= 8'b01111110;
					3'b111: row_val <= 8'b00000000;
					default: row_val <= 8'b01000010;
				endcase
			S_RING_3:
				case (row_select)
					3'b000: row_val <= 8'b00000000;
					3'b001: row_val <= 8'b00000000;
					3'b010: row_val <= 8'b00111100;
					3'b101: row_val <= 8'b00111100;
					3'b110: row_val <= 8'b00000000;
					3'b111: row_val <= 8'b00000000;
					default: row_val <= 8'b00100100;
				endcase
			S_RING_4:
				case (row_select)
					3'b011: row_val <= 8'b00011000;
					3'b100: row_val <= 8'b00011000;
					default: row_val <= 8'b00000000;
				endcase
			default:
				write <= 0;
				row_select <= 0;
				row_val <= 0;
		endcase
		
	end
	
	always @(posegde clk) begin
		curr <= reset_n ? next : S_WAIT;
		if (curr != S_WAIT)
			row_select <= row_select + 1;
	end
	
endmodule

// Board of cells, using registers. You can update
// a row of cells at a time using the inputs:
// load_r: must be high to write to board
// r_select: selects row
// r_val: value to write to the selected row
module board(
	input load_r, clk, reset_n,
	input [2:0] r_select,
	input [7:0] r_val,
	output reg [63:0] cells);
	
	always @(posedge clk, negedge reset_n) begin
		if (!reset_n)
			cells <= 0;
		else if (load_r) begin
			case (r_select)
				3'b000: cells[7:0] = r_val[7:0];
				3'b001: cells[15:8] = r_val[7:0];
				3'b010: cells[23:16] = r_val[7:0];
				3'b011: cells[31:24] = r_val[7:0];
				3'b100: cells[39:32] = r_val[7:0];
				3'b101: cells[47:40] = r_val[7:0];
				3'b110: cells[55:48] = r_val[7:0];
				3'b111: cells[63:56] = r_val[7:0];
			endcase
		end
	end

endmodule