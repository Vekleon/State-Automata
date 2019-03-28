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
	
	/*
	// Setting next clock cycle's internal values
	always @(*) begin
		next_off = offset + 1;
		if ((& offset)) begin
			next_x = cur_x + 1;
			if ((& cur_x))
				next_y = cur_y + 1;
		end
	end*/
	
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