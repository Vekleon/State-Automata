module select_rate_divider(
	input en, clk, reset_n,
	input [1:0] rate_select,
	output reg out_clk);
	
	localparam RATE_ZERO_HERTZ = 0,
				RATE_HALF_HERTZ = 1,
				RATE_ONE_HERTZ = 2,
				RATE_TWO_HERTZ = 3,
				ONE_HUNDRED_MILLION = 2 - 1,
				FIFTY_MILLION = 4 - 1,
				TWENTY_FIVE_MILLION = 8 - 1;
				
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