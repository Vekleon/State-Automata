vlib work
vlog -timescale 1ps/1ps board_control.v
vsim top
log {/*}
add wave {/*}

# Initial values
force {force_update} 0
force {reset_n} 1
force {ld_rule} 0
force {rate_select} 2#00

# Starting state
force {load_val} 2#10001001

# Clock cycle
force {clk} 0 0, 1 1 	-r 2

# Running for a bit
run 4

# Resetting, and loading new starting state
force {load_val} 2#00001000
run 4
force {reset_n} 0
run 4
force {reset_n} 1

# Nothing should be happening right now because rate_select is set to 0Hz
run 24

# Loading a rule (86)
force {load_val} 2#01010110
run 4
force {ld_rule} 1
run 8
force {ld_rule} 0
run 8

# Forcing an update
force {force_update} 1
run 8
force {force_update} 0
run 8

# Forcing another update
force {force_update} 1
run 8
force {force_update} 0
run 8

# Setting rate_select to 1/4 CLOCK_50
force {rate_select} 2#10

# Letting it run for a bit
run 512

# Resetting, and loading new starting state
force {load_val} 2#11111111
run 4
force {reset_n} 0
run 4
force {reset_n} 1
run 16