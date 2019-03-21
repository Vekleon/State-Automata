// Part 2 skeleton

module vga
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
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
	wire display;
	wire ld_x, ld_y, ld_c, x_en;
	assign writeEn = ~KEY[1];
	assign ld_enable = ~KEY[3];
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
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
    
    // Instansiate datapath
	 //TODO will need to change the actual parameters to not take switches, the data should not be effected by the switches themselves but the rule set we give them.
	datapath d0(CLOCK_50, SW[6:0], SW[9:7], resetn, x, y, colour, ld_x, ld_y, ld_c);

    // Instansiate FSM control
    control c0(writeEn, ld_enable, resetn, ld_x, ld_y, ld_c, CLOCK_50);
    
endmodule

module datapath(clk, coord_in, colour_in, reset_n, x, y, colour, ld_x, ld_y, ld_c);
	input [6:0] coord_in;
	input [2:0] colour_in;
	input reset_n;
	input clk;
	input ld_x, ld_y, ld_c;
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] colour;
	wire filler;
	assign filler = 0;
	
	always @ (posedge clk) begin
		if(!reset_n) begin
			 x <= 8'b0;
			 y <= 7'b0;
			 colour <= 3'd0;
		end
		else begin
			if (ld_x)
				x <= {filler, coord_in};
			if (ld_y)
				y <= coord_in;
			if (ld_c)
				colour <= colour_in;
		end
	end
endmodule

module control(go, x_en, reset_n, ld_x, ld_y, ld_c, clk);
	output reg ld_x, ld_y, ld_c;
	input go, reset_n, x_en;
	input clk;
	
	reg [2:0] current_state, next_state;
	
	//TODO need to add more states to compensate for an 8x8 grid on screen
	localparam  WAIT = 3'b0,
				LOAD_X = 3'b1,
				LOAD_X_WAIT = 3'b010,
				LOAD_Y = 3'b011,
				LOAD_C = 3'b100;
				
	always@(*)
	begin: state_table
			case (current_state)
				WAIT: begin
					if(x_en)
						next_state = LOAD_X;
					else if(go)
						next_state = LOAD_Y;
					else
						next_state = WAIT;
				end
				LOAD_X: next_state = x_en ? LOAD_X_WAIT : LOAD_X;
				LOAD_X_WAIT: next_state = x_en ? LOAD_X_WAIT : WAIT;
				LOAD_Y: next_state = LOAD_C;
				LOAD_C: next_state = WAIT;
			default: next_state = WAIT;
			endcase
		end

	always @(*)
	begin: enable_signals
		ld_x = 1'b0;
		ld_y = 1'b0;
		ld_c = 1'b0;
		
		case (current_state)
			LOAD_X: ld_x = 1'b1;
			LOAD_Y: ld_y = 1'b1;
			LOAD_C: ld_c = 1'b1;
		endcase
	end

	always@(posedge clk)
	begin: state_FFs
		if(!reset_n)
			current_state <= WAIT;
		else
			current_state <= next_state;
	end
endmodule
