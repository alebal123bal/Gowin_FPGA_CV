//Copyright (C)2014-2019 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.2.01 Beta
//Created Time: 2019-11-29 11:12:06
create_clock -name I_clk -period 37.04  [get_ports {I_clk}] -add
//create_clock -name cmos_clk_24 -period 41.67 [get_nets {cmos_clk_24}] -add
create_clock -name cmos_scl -period 4000 [get_nets {cmos_scl}] -add
//create_clock -name cmos_vsync -period 1000 [get_ports {cmos_vsync}] -add

//create_clock -name mem_clk -period 2.5 -waveform {0 1.25} [get_nets {memory_clk}]
report_timing -hold -from_clock [get_clocks {I_clk*}] -to_clock [get_clocks {I_clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {I_clk*}] -to_clock [get_clocks {I_clk*}] -max_paths 25 -max_common_paths 1

