onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label SW -radix binary /testbench/SW
add wave -noupdate -label LEDR -radix binary /testbench/LEDR
add wave -noupdate -label state -radix binary /testbench/U1/state
add wave -noupdate -label score -radix binary /testbench/U1/score
add wave -noupdate -label yEdit -radix binary /testbench/U1/yEdit
add wave -noupdate -label health -radix binary /testbench/U1/health
add wave -noupdate -label HEX0 -radix binary /testbench/HEX0
add wave -noupdate -label HEX1 -radix binary /testbench/HEX1
add wave -noupdate -label count -radix binary /testbench/U1/count
add wave -noupdate -label current -radix binary /testbench/U1/current
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 80
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {120 ns}
