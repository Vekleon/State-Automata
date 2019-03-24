// Part 2 skeleton

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
	assign resetn = KEY[2];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	assign x = 7'b0;
	assign y = 7'b0;
	
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
	wire ld_x, ld_y, ld_c, plot;
	wire [3:0] offset;
    
    // Instansiate datapath
	// datapath d0(...);
//	datapath d0(	.clk(CLOCK_50),
//						.reset_n(resetn),
//						.ld_x(ld_x),
//						.ld_y(ld_y),
//						.ld_c(ld_c),
//						.x_off(offset[1:0]),
//						.y_off(offset[3:2]),
//						.c_in(SW[9:7]),
//						.y_in(SW[6:0]),
//						.x_in(SW[6:0]),
//						.c_out(colour),
//						.y_out(y),
//						.x_out(x));

    // Instansiate FSM control
    // control c0(...);
	 control c0(	.clk(CLOCK_50),
						.resetn(resetn),
						.go(~KEY[3]),
						.ld_init_state(~KEY[0]),
						.ld_rule_set(~KEY[1]),
						.ld_x(ld_x),
						.ld_y(ld_y),
						.ld_c(ld_c),
						.plot(plot),
						.y(y),
						.x(x);
						/*.pixel_offset(offset)*/);
    
endmodule

module datapath(
	input clk, reset_n, ld_x, ld_y, ld_c,
	input [1:0] x_off, y_off,
	input [2:0] c_in,
	input [6:0]	y_in,
	input [6:0] x_in,
	
	output reg [2:0] c_out,
	output [6:0] y_out,
	output [7:0] x_out);
	
	// Holding raw input for x,y ignoring offset
	reg [6:0] x, y;
	
	// Input logic for x, y, c
	always @(posedge clk, negedge reset_n)
	begin
		if (!reset_n) begin
			c_out <= 3'b0;
			x <= 7'b0;
			y <= 7'b0;
		end
		else begin
			if (ld_x)
				x <= x_in;
			if (ld_y)
				y <= y_in;
			if (ld_c)
				c_out <= c_in;
		end
	end
	
	// Adding offset to final output value
	assign y_out[6:2] = y[6:2];
	assign y_out[1:0] = y[1:0] + y_off[1:0];
	assign x_out[7] = 0;
	assign x_out[6:2] = x[6:2];
	assign x_out[1:0] = x[1:0] + x_off[1:0];
	
endmodule
	

module control(
	input clk, 
	input resetn, 
	input go, 
	input ld_init_state, ld_rule_set,
	
	output reg ld_x, ld_y, ld_c, plot, 
	/*output reg [3:0] pixel_offset*/
	output[6:0] y,
	output[7:0] x);
	
	reg [1:0] curr, next;
	reg [3:0] next_offset;
	
	wire [2:0] color;
	wire [6:0] x_coord, y_coord;
	wire [6:0] next_x, next_y;
	wire [5:0] offset;
	wire [3:0] pixel_offset;
	
	//Currently the amount of states needed is unknown
	localparam 	S_INITIALIZE = 5'd0;
					S_WAIT = 4'd1,
					S_LOAD_INIT_STATE = 4'd2,
					S_LOAD_RULE_STATE = 4'd3, // All
					S_PLOT = 4'd4;
				
	// Handling the "next state"
	always @(*)
	begin
		case(curr)
			S_INITIALIZE: next <= (& offset) ? S_WAIT : S_INITIALIZE;
			S_WAIT: begin
				if (ld_init_state == 1)
					next <= S_LOAD_INIT_STATE;
				else if(ld_rule_set == 1)
					next <= S_LOAD_RULE_STATE;
			end
			//S_LOAD_X: next <= wr_x ? S_LOAD_X : S_WAIT;
			//S_LOAD_A: next <= go ? S_LOAD_A : S_PLOT;
			//S_PLOT: next <= (& pixel_offset) ? S_WAIT : S_PLOT;
			default: next <= S_INITIALIZE;
		endcase
	end
	
	always @(*)
	begin
		
		// Default controls
		ld_x = 1'b0;
		ld_y = 1'b0;
		ld_c = 1'b0;
		plot = 1'b0;
		color = 3'b0;
		next_offset = 0;
		
		case(curr)
			S_INITILIZE: begin
				color = 3'b111;
				//conditions for x
				if(offset % 8 == 0)
					x_coord <= 0;
				else if(offset % 8 == 1)
					x_coord <= 8;
				else if(offset % 8 == 2)
					x_coord <= 16;
				else if(offset % 8 == 3)
					x_coord <= 24;
				else if(offset % 8 == 4)
					x_coord <= 32;
				else if(offset % 8 == 5)
					x_coord <= 40;
				else if(offset %8 == 6)
					x_coord <= 48;
				else if(offset % 8 == 7)
					x_coord <= 56;
				
				if(offset != 0 && offset % 8 == 0)
					y_coord <= y_coord + 8;
				plot <= 1'b1;
			
				next_offset <= pixel_offset +1;
				offset <= offset + 1;
			end
			S_WAIT: begin
				//next_offset <= 4'b0000;
				end
			S_LOAD_X: begin
				ld_x <= 1'b1;
				end
			S_LOAD_A: begin
				ld_y <= 1'b1;
				ld_c <= 1'b1;
				end
			S_PLOT: begin
				plot <= 1'b1;
				next_offset <= pixel_offset + 1;
				end
		endcase
	end
	
	// Incrementing the pixel offset value after curr may have changed
//	always @(negedge clk)
//	begin
//		if (curr == S_PLOT)
//			pixel_offset <= pixel_offset + 1'b1;
//	end
	
	// Changing state
	always @(posedge clk)
	begin
		curr <= resetn ? next : S_WAIT;
		pixel_offset <= next_offset;
	end
	
		datapath d0(	.clk(clk),
						.reset_n(resetn),
						.ld_x(ld_x),
						.ld_y(ld_y),
						.ld_c(ld_c),
						.x_off(offset[1:0]),
						.y_off(offset[3:2]),
						.c_in(color),
						.y_in(y_coord),
						.x_in(x_coord),
						.c_out(colour),
						.y_out(y),
						.x_out(x));

	
endmodule
