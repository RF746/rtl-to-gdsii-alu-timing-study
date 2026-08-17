# Public portfolio constraint scaffold: 100 MHz target clock.
create_clock -name core_clk -period 10.000 [get_ports clk]

# Conservative external interface assumptions for an educational block-level run.
set data_inputs [remove_from_collection [all_inputs] [get_ports {clk rst_n}]]
set_input_delay  0.500 -clock core_clk $data_inputs
set_output_delay 0.500 -clock core_clk [all_outputs]
set_clock_uncertainty 0.200 [get_clocks core_clk]
set_clock_transition  0.100 [get_clocks core_clk]
set_false_path -from [get_ports rst_n]

# Model modest external drive and output loading. Review for each PDK/tool release.
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 $data_inputs
set_load 0.050 [all_outputs]
