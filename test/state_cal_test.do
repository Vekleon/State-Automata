vlib work
vlog -timescale 1ps/1ps state_cal.v
vsim state_calculator
log {/*}
add wave {/*}

# Rule 90. 00000000 => 00000000
force {in} 2#00000000
force {rule} 2#01011010
run 2

# Rule 90. 10101010 => 00000000
force {in} 2#10101010
force {rule} 2#01011010
run 2

# Rule 90. 10011001 => 11111111
force {in} 2#10011001
force {rule} 2#01011010
run 2

# Rule 90. 10110000 => 00111001
force {in} 2#10110000
force {rule} 2#01011010
run 2

# Rule 110. 10101010 => 11111111
force {in} 2#10101010
force {rule} 2#01101110
run 2

# Rule 110. 11111111 => 00000000
force {in} 2#11111111
force {rule} 2#01101110
run 2

# Rule 110. 10110011 => 11110110
force {in} 2#10110011
force {rule} 2#01101110
run 2