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
						2'b00: next <= S_RING_1_0;
						2'b01: next <= S_RING_2_0;
						2'b10: next <= S_RING_3_0;
						2'b11: next <= S_RING_4_0;
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