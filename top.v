/*
*	KEY[0] load initial state
*  KEY[1] load rule set
*  KEY[2] low synchrounous reset
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


