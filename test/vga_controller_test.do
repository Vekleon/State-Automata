vlib work
vlog -timescale 1ps/1ps vga_controller.v
vsim vga_c
log {/*}
add wave {/*}

# Initial values
force {reset_n} 1

# Note that this is vertically mirrored compared to how the board would show up on the screen
force {cells[7:0]} 		2#01010011
force {cells[15:8]} 	2#10101110
force {cells[23:16]} 	2#01010011
force {cells[31:24]} 	2#01010011
force {cells[39:32]} 	2#01010011
force {cells[47:40]} 	2#01010011
force {cells[55:48]} 	2#01010011
force {cells[63:56]} 	2#01010011

# Clock cycle
force {clk} 0 0, 1 1 	-r 2

# Running for a bit
run 4

# Reset
force {reset_n} 0
run 4
force {reset_n} 1

# Running to cycle through the first two rows
run 512