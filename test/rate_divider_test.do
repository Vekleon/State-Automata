vlib work
vlog -timescale 1ps/1ps rate_divider.v
vsim select_rate_divider
log {/*}
add wave {/*}

# Initial values
force {reset_n} 1
force {en} 1
force {rate_select} 2#00

# Clock cycle
force {clk} 0 0, 1 1 	-r 2

# Running for a bit
run 4

# Reset
force {reset_n} 0
run 4
force {reset_n} 1

# Trying the 01 rate (1/2)
force {rate_select} 2#01
run 64

# Trying the 10 rate (1/4)
force {rate_select} 2#10
run 64

# Trying the 10 rate (1/8)
force {rate_select} 2#11
run 64

# Trying the 00 rate (freeze)
force {rate_select} 2#00
run 64