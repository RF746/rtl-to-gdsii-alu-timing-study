# OpenROAD-flow-scripts starting configuration.
# Invoke with a compatible ORFS checkout and SKY130 HD platform installation.
export DESIGN_NAME = pipelined_alu
export PLATFORM    = sky130hd

export VERILOG_FILES = $(abspath $(dir $(DESIGN_CONFIG))/../rtl/pipelined_alu.v)
export SDC_FILE      = $(abspath $(dir $(DESIGN_CONFIG))/../constraints/alu.sdc)

export CLOCK_PORT   = clk
export CLOCK_PERIOD = 10.0
export CORE_UTILIZATION = 40
export PLACE_DENSITY_LB_ADDON = 0.05

# Keep generated results outside the source tree when the calling flow permits it.
export REMOVE_ABC_BUFFERS = 1
