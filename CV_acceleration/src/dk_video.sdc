//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.9.03  Education (64-bit)
//Created Time: 2025-01-13 15:51:47
create_clock -name clk -period 37.04 -waveform {0 18.52} [get_ports {clk}] -add
create_generated_clock -name mem_clk -source [get_ports {clk}] -master_clock clk -divide_by 4 -multiply_by 59 -add [get_nets {ddr_fast_clk}]
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
