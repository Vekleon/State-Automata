/*
*	KEY[0] load initial state
*  KEY[1] load rule set
*  KEY[2] low synchrounous reset
*	KEY[3] GO!
*  SW[8:0] determine display initial state
*  Sw[...] determine rule set
*/
module milestone2(SW, KEY, CLOCK_50, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B, HEX0, HEX1);
	input [3:0] KEY;
	input [9:0] SW;
	input CLOCK_50;
	
	wire rate_clock;
	wire [7:0] cur_rule;
	wire [63:0] cells;
	
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output [6:0] HEX0,HEX1;
	
	vga visual(
		.CLOCK_50(CLOCK_50),
		.cells(cells),
		.KEY(KEY[3:0]),
		.SW(SW[9:0]),
		.VGA_CLK(VGA_CLK),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK_N(VGA_BLANK_N),
		.VGA_SYNC_N(VGA_SYNC_N),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B)
	);
	
	automaton a0(
		.clk(CLOCK_50),
		.force_update(KEY[2]),
		.reset_n(KEY[0]),
		.ld_rule(KEY[1]),
		.rate_select(SW[9:8]),
		.load_val(SW[7:0]),
		.cur_rule(cur_rule),
		.cells(cells));
		
	// So you can see what rule is currently being used :)
	hex_decoder h0(cur_rule[3:0], HEX0);
	hex_decoder h1(cur_rule[7:4], HEX1);
	
endmodule

module automaton(
	input clk, force_update, reset_n, ld_rule,
	input [1:0] rate_select,
	input [7:0] load_val,
	output [7:0] cur_rule,
	output [63:0] cells);
	
	wire load_r, regular_update;
	wire [63:0] board_cells;
	wire [2:0] row_select;
	wire [7:0] row_val;
	
	assign cells = board_cells;
	
	select_rate_divider r0(
		.en(1'b1),
		.clk(clk),
		.reset_n(reset_n),
		.rate_select(rate_select),
		.out_clk(regular_update));
	
	board b0(
		.load_r(load_r),
		.clk(clk),
		.reset_n(reset_n),
		.r_select(row_select),
		.r_val(row_val),
		.cells(board_cells));
		
	board_control c0(
		.clk(clk),
		.update(regular_update | force_update),
		.reset_n(reset_n),
		.ld_rule(ld_rule),
		.load_val(load_val),
		.board(board_cells),
		.cur_state(cur_state),
		.cur_rule(cur_rule),
		.load_r(load_r),
		.row_select(row_select),
		.r_val(row_val));
	
	
endmodule

// Module which handles writing to the VGA based on given inputs.
// For now, only SW[9:8] function as inputs, and control which
// ring of the 8x8 pixel board are active and red.
module vga
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		cells,
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
	input [63:0] cells;
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

// Gives the controls for a given board using internal states
// ld_rule: Internal rule loads from load_val when high
module board_control(
	input clk, update, reset_n, ld_rule,
	input [7:0] load_val,
	input [63:0] board,
	output [2:0] cur_state,
	output reg [7:0] cur_rule,
	output reg load_r,
	output reg [2:0] row_select,
	output reg [7:0] r_val);
	
	reg next_load_r;
	reg [2:0] curr, next, next_row_select;
	reg [7:0] next_r_val, next_rule;
	
	assign cur_state = curr;
	
	wire [7:0] cur_row, cal_row;
	row_selector r0(board, row_select, cur_row);
	state_calculator s0(cur_row, cur_rule, cal_row);
	
	localparam S_STANDBY = 0,
				S_UPDATE_ROW_WAIT = 1,
				S_UPDATE_ROW = 2,
				S_LOAD_RULE_WAIT = 3,
				S_LOAD_RULE = 4,
				S_RESET = 5;
		
	// Handling the "next" state
	always @(*) begin
		case (curr)
			S_STANDBY: begin
				if (update)
					next <= S_UPDATE_ROW_WAIT;
				else if (ld_rule)
					next <= S_LOAD_RULE_WAIT;
				else
					next <= S_STANDBY;
				end
			S_UPDATE_ROW_WAIT:
				next <= update ? S_UPDATE_ROW_WAIT : S_UPDATE_ROW;
			S_UPDATE_ROW:
				next <= S_STANDBY;
			S_LOAD_RULE_WAIT:
				next <= ld_rule ? S_LOAD_RULE_WAIT : S_LOAD_RULE;
			S_LOAD_RULE:
				next <= S_STANDBY;
			S_RESET:
				next <= S_STANDBY;
			default:
				next <= S_STANDBY;
		endcase
	end	
	
	// Controls for the current state
	always @(*) begin
	
		// Defaults
		next_load_r = 0;
		next_row_select = row_select;
		next_r_val = r_val;
		next_rule = cur_rule;
		
		case (curr)
			S_UPDATE_ROW: begin
				next_load_r <= 1;
				next_row_select <= row_select + 1;
				next_r_val <= cal_row;
				end
			S_LOAD_RULE: begin
				next_rule <= load_val;
				end
			S_RESET: begin
				next_load_r <= 1;
				next_row_select <= 0;
				next_r_val <= load_val;
				next_rule <= 0;
				end
		endcase
		
	end
	
	// Handling logic for this clock cycle
	always @(posedge clk, negedge reset_n) begin
		if (!reset_n) begin
			curr <= S_RESET;
			load_r <= 0;
			row_select <= 0;
			r_val <= 0;
			cur_rule <= 0;
		end else begin
			row_select <= next_row_select;
			cur_rule <= next_rule;
			r_val <= next_r_val;
			load_r <= next_load_r;
			curr <= next;
		end
	end
	
endmodule

module select_rate_divider(
	input en, clk, reset_n,
	input [1:0] rate_select,
	output reg out_clk);
	
	localparam RATE_ZERO_HERTZ = 0,
				RATE_HALF_HERTZ = 1,
				RATE_ONE_HERTZ = 2,
				RATE_TWO_HERTZ = 3,
				ONE_HUNDRED_MILLION = 100000000 - 1,
				FIFTY_MILLION = 50000000 - 1,
				TWENTY_FIVE_MILLION = 25000000 - 1;
				
	wire [26:0] next_num;
	reg [26:0] max_num;
	reg [26:0] cur_num;
	
	assign next_num = cur_num + 1;
	
	// Selecting the counter cap
	always @(*) begin
		case (rate_select)
			RATE_ZERO_HERTZ:max_num = 0;
			RATE_HALF_HERTZ:max_num = ONE_HUNDRED_MILLION;
			RATE_ONE_HERTZ:	max_num = FIFTY_MILLION;
			RATE_TWO_HERTZ:	max_num = TWENTY_FIVE_MILLION;
		endcase
	end
	
	always @(posedge clk, negedge reset_n) begin
		if (!reset_n) begin
			cur_num <= 26'd0;
		end
		if (en) begin
			if (rate_select == RATE_ZERO_HERTZ)
				out_clk <= 0;
			else if (cur_num >= max_num) begin
				out_clk <= 1;
				cur_num <= 26'd0;
			end else begin
				out_clk <= 0;
				cur_num <= next_num;
			end
		end
	end
	
endmodule

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

/*
HERE BE HELPER MODULES
*/

module row_selector(
	input [63:0] board,
	input [2:0] row_select,
	output reg [7:0] row);
	
	always @(*) begin
		case(row_select)
			3'd0: row[7:0] = board[7:0];
			3'd1: row[7:0] = board[15:8];
			3'd2: row[7:0] = board[23:16];
			3'd3: row[7:0] = board[31:24];
			3'd4: row[7:0] = board[39:32];
			3'd5: row[7:0] = board[47:40];
			3'd6: row[7:0] = board[55:48];
			3'd7: row[7:0] = board[63:56];
		endcase
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

// Self-explanatory
module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule