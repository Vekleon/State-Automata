vlib work
vlog -timescale 1ps/1ps board.v
vsim -L altera_mf doard
log {/*}
add wave {/*}

# Initial values
force {reset_n} 1
force {load_r} 0
force {r_select} 2#000
force {r_val} 2#00000000

# Clock cycle
force {clk} 0 0, 1 1 	-r 2

# Running for a bit
run 4

# Reset
force {reset_n} 0
run 4
force {reset_n} 1

# Loading 00110011 into row 0
force {r_select} 2#000
force {r_val} 2#00110011
run 4

# Loading 11111111 into row 2
force {r_select} 2#010
force {r_val} 2#11111111
run 4

# Reset once more
force {reset_n} 0
run 4
force {reset_n} 1

# Loading 10000001 into row 3
force {r_select} 2#011
force {r_val} 2#10000001
run 4

# Loading 11011011 into row 7
force {r_select} 2#111
force {r_val} 2#11011011
run 4

# Loading 01000010 into row 5
force {r_select} 2#101
force {r_val} 2#11000011
run 4