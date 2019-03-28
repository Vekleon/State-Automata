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