PYTHON ?= python3
IVERILOG ?= iverilog
VVP ?= vvp
BUILD_DIR := build

.PHONY: all test test-rtl test-python metrics clean

all: test

test: test-rtl test-python

test-rtl:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s pipelined_alu_tb \
		-o $(BUILD_DIR)/pipelined_alu_tb \
		rtl/pipelined_alu.v tb/pipelined_alu_tb.v
	$(VVP) $(BUILD_DIR)/pipelined_alu_tb

test-python:
	$(PYTHON) -m unittest discover -s tests -v

metrics:
	$(PYTHON) scripts/summarize_reports.py

clean:
	rm -rf $(BUILD_DIR)
