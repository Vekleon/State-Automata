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
	vga_controller v0(	.clk(CLOCK_50),
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
module vga_controller(
	input clk, reset_n,
	input [63:0] cells,
	
	output ld_x, ld_y, ld_c, plot
	output [2:0] c_out,
	output [6:0] x_out,
	output [7:0] y_out);
	
	reg [2:0] cur_x, cur_y;
	reg [3:0] offset;
	
	reg [2:0] next_x, next_y;
	reg [3:0] next_off;
	
	// Setting output values dependent on internal values
	assign ld_x = 1;
	assign ld_y = 1;
	assign ld_c = 1;
	assign c_out = cells[{curr_y, curr_x}] ? 3'b100 : 3'b111;
	assign y_out[6:2] = curr_y[6:2];
	assign y_out[1:0] = curr_y[1:0] + offset[3:2];
	assign x_out[7] = 0;
	assign x_out[6:2] = curr_x[6:2];
	assign x_out[1:0] = curr_x[1:0] + offset[1:0];
	
	// Setting next clock cycle's internal values
	always @(*) begin
		next_off = cur_off + 1;
		if ((& cur_off)) begin
			next_x = cur_x + 1;
			if ((& cur_x))
				next_y = cur_y + 1;
		end
	end
	
	// Handling controls
	always @(posedge clk, negedge reset_n) begin
		if (!reset_n) begin
			cur_x <= 0;
			cur_y <= 0;
			offset <= 0;
			next_x <= 0;
			next_y <= 0;
			next_off <= 0;
		end
		else begin
			cur_x <= next_x;
			cur_y <= next_y;
			offset <= next_off;
		end
	end

	
endmodule

module select_rate_divider(
	input en, clk, reset_n,
	input [1:0] rate_select,
	output reg out_clk);
	
	localparam RATE_ZERO_HERTZ = 2'bd0,
				RATE_HALF_HERTZ = 2'bd1,
				RATE_ONE_HERTZ = 2'bd2,
				RATE_TWO_HERTZ = 2'bd3,
				ONE_HUNDRED_MILLION = 27'd100000000,
				FIFTY_MILLION = 27'd50000000;
				TWENTY_FIVE_MILLION = 27'd25000000;
				
	wire [1:0] cur_rate;
	reg [26:0] cur_num;
	
	assign cur_rate = rate_select;
	
	always @(posedge clk, negedge reset_n) begin
		if (en) begin
			if (!reset_n) begin
				cur_num <= 0;
				out_clk <= 0;
			end
			else begin
				cur_num <= cur_num + 1;
				case (cur_rate)
					RATE_HALF_HERTZ:
						if (cur_num >= ONE_HUNDRED_MILLION) begin
							out_clk <= 1
							cur_num <= 0;
						end
						else
							out_clk <= 0;
					RATE_ONE_HERTZ:
						if (cur_num >= FIFTY_MILLION) begin
							out_clk <= 1
							cur_num <= 0;
						end
						else
							out_clk <= 0;
					RATE_HALF_HERTZ:
						if (cur_num >= TWENTY_FIVE_MILLION) begin
							out_clk <= 1
							cur_num <= 0;
						end
						else
							out_clk <= 0;
					default:
						out_clk <= 0
				endcase
			end
		end
	end
	
endmodule

module automaton(
	input clk, update, reset_n, en, ld_rule, ld_state,
	input [7:0] load_val,
	output [63:0] cells);
	
	wire load_r;
	wire [2:0] row_select;
	wire [7:0] r_val;
	wire [63:0] board_cells;
	
	// Controls
	board_control c0(	.clk(clk),
						.reset_n(reset_n),
						.ld_rule(ld_rule),
						.ld_state(ld_state),
						.load_val(rule_val),
						.board(board_cells),
						.load_r(load_r),
						.row_select(row_select),
						.r_val(r_val));

	// Datapath
	board_datapath d0(	.load_r(load_r),
						.clk(clk | update),
						.reset_n(reset_n),
						.r_select(row_select),
						.r_val(r_val),
						.cells(board_cells));
						
	
endmodule

module board_datapath(
	input load_r, clk, reset_n
	input [2:0] r_select,
	input [7:0] r_val,
	output [63:0] cells);
	
	board b0(	.load_r(load_r),
				.clk(clk),
				.reset_n(reset_n),
				.r_val(r_val),
				.cells(cells));
	
endmodule

module board_control(
	input clk, reset_n, ld_rule, ld_state,
	input [7:0] load_val,
	input [63:0] board,
	output reg load_r,
	output reg [2:0] row_select,
	output reg [7:0] r_val);
	
	reg curr, next;
	reg [7:0] cur_rule;
	
	wire [7:0] curr_row, row_out;
	assign curr_row = cells[8 * row_select + 7 : 8 * row_select];
	
	localparam S_RUN = 1'b0,
				S_RESET = 1'b1;
				
	state_calculator s0(	.in(cur_row),
							.rule(cur_rule),
							.out(row_out));
	
	// Handling the next state
	always @(*) begin
		case (curr)
			S_RESET: next <= (row_select == 3'b111) ? S_RUN : S_RESET;
			S_RUN: next <= (reset_n) ? S_RUN : S_RESET;
			default: next <= S_RESET;
		endcase
	end
	
	// Loading a new rule
	always @(posedge ld_rule)
		cur_rule <= load_val;
	
	// Controls
	always @(*) begin
		
		// Default controls
		load_r = 1;
		
		case (curr)
			S_RESET: r_val <= (row_select == 3'b000) ? load_val : 8'b00000000;
			S_RUN: r_val <= row_out;
		endcase
	end
	
	always @(posedge clk, negedge reset_n) begin
		if (!reset_n) begin
			curr <= S_RESET;
			next <= S_RESET;
			row_select <= 0;
		end
		row_select <= row_select + 1;
		curr <= next;
	end
	
endmodule

module state_calculator(
	input [7:0] in, rule,
	output [7:0] out);
	
	assign out[0] = rule[{in[1], in[0], in[7]}];
	assign out[1] = rule[{in[2], in[1], in[0]}];
	assign out[2] = rule[{in[3], in[2], in[1]}];
	assign out[3] = rule[{in[4], in[3], in[2]}];
	assign out[4] = rule[{in[5], in[4], in[3]}];
	assign out[5] = rule[{in[6], in[5], in[4]}];
	assign out[6] = rule[{in[7], in[6], in[5]}];
	assign out[7] = rule[{in[0], in[7], in[6]}];
	
endmodule

// Board of cells, using registers. You can update
// a row of cells at a time using the inputs:
// load_r: must be high to write to board
// r_select: selects row
// r_val: value to write to the selected row
module board(
	input load_r, clk, reset_n
	input [2:0] r_select,
	input [7:0] r_val,
	output reg [63:0] cells);
	
	always @(posedge clk, negedge reset_n) begin
		if (!reset_n)
			cells <= 0;
		else if (load_r)
			cells[8 * r_select + 7 : 8 * r_select] <= r_val[7:0];
		end
	end

endmodule