module top(
	input clk, force_update, reset_n, ld_rule,
	input [1:0] rate_select,
	input [7:0] load_val,
	output [2:0] cur_state,
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
				ONE_HUNDRED_MILLION = 2- 1,
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