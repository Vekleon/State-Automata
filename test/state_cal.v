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