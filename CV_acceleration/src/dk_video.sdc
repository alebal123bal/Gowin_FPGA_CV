//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.9.03  Education (64-bit)
//Created Time: 2025-01-13 15:51:47

// Primary input clocks
create_clock -name clk -period 37.04 -waveform {0 18.52} [get_ports {clk}] -add
create_clock -name ulpi_clk -period 16.67 -waveform {0 8.33} [get_ports {ulpi_clk}] -add
create_clock -name cmos_pclk -period 10.42 -waveform {0 5.21} [get_ports {cmos_pclk}] -add

// Generated clocks from PLLs
create_generated_clock -name HDMI_TMDS_clk -source [get_ports {clk}] -master_clock clk -divide_by 4 -multiply_by 55 -add [get_nets {HDMI_TMDS_clk}]
create_generated_clock -name HDMI_pix_clk -source [get_nets {HDMI_TMDS_clk}] -master_clock HDMI_TMDS_clk -divide_by 5 -add [get_nets {HDMI_pix_clk}]
# create_generated_clock -name cmos_clk_24 -source [get_ports {clk}] -master_clock clk -divide_by 9 -multiply_by 8 -add [get_nets {cmos_clk_24}]
create_generated_clock -name ddr_fast_clk -source [get_ports {clk}] -master_clock clk -divide_by 4 -multiply_by 59 -add [get_nets {ddr_fast_clk}]
create_generated_clock -name ddr_slow_clk -source [get_nets {ddr_fast_clk}] -master_clock ddr_fast_clk -divide_by 4 -add [get_nets {ddr_slow_clk}]

// Clock domain crossing constraints
set_clock_groups -asynchronous -group [get_clocks {clk}] -group [get_clocks {ulpi_clk}]
set_clock_groups -asynchronous -group [get_clocks {clk}] -group [get_clocks {cmos_pclk}]
set_clock_groups -asynchronous -group [get_clocks {ulpi_clk}] -group [get_clocks {cmos_pclk}]
set_clock_groups -asynchronous -group [get_clocks {HDMI_pix_clk}] -group [get_clocks {cmos_pclk}]
set_clock_groups -asynchronous -group [get_clocks {HDMI_pix_clk}] -group [get_clocks {ulpi_clk}]
set_clock_groups -asynchronous -group [get_clocks {ddr_slow_clk}] -group [get_clocks {cmos_pclk}]
set_clock_groups -asynchronous -group [get_clocks {ddr_slow_clk}] -group [get_clocks {HDMI_pix_clk}]

// Input/Output delay constraints
set_input_delay -clock [get_clocks {cmos_pclk}] -max 2.0 [get_ports {cmos_db[*]}]
set_input_delay -clock [get_clocks {cmos_pclk}] -min 0.5 [get_ports {cmos_db[*]}]
set_input_delay -clock [get_clocks {cmos_pclk}] -max 2.0 [get_ports {cmos_href}]
set_input_delay -clock [get_clocks {cmos_pclk}] -min 0.5 [get_ports {cmos_href}]
set_input_delay -clock [get_clocks {cmos_pclk}] -max 2.0 [get_ports {cmos_vsync}]
set_input_delay -clock [get_clocks {cmos_pclk}] -min 0.5 [get_ports {cmos_vsync}]

set_input_delay -clock [get_clocks {ulpi_clk}] -max 2.0 [get_ports {ulpi_data[*]}]
set_input_delay -clock [get_clocks {ulpi_clk}] -min 0.5 [get_ports {ulpi_data[*]}]
set_input_delay -clock [get_clocks {ulpi_clk}] -max 2.0 [get_ports {ulpi_dir}]
set_input_delay -clock [get_clocks {ulpi_clk}] -min 0.5 [get_ports {ulpi_dir}]
set_input_delay -clock [get_clocks {ulpi_clk}] -max 2.0 [get_ports {ulpi_nxt}]
set_input_delay -clock [get_clocks {ulpi_clk}] -min 0.5 [get_ports {ulpi_nxt}]

set_output_delay -clock [get_clocks {ulpi_clk}] -max 3.0 [get_ports {ulpi_data[*]}]
set_output_delay -clock [get_clocks {ulpi_clk}] -min 1.0 [get_ports {ulpi_data[*]}]
set_output_delay -clock [get_clocks {ulpi_clk}] -max 3.0 [get_ports {ulpi_stp}]
set_output_delay -clock [get_clocks {ulpi_clk}] -min 1.0 [get_ports {ulpi_stp}]

// False path constraints for asynchronous signals
set_false_path -from [get_ports {I_rst_n}]
set_false_path -to [get_ports {O_led[*]}]
set_false_path -to [get_ports {cmos_rst_n}]
set_false_path -to [get_ports {cmos_pwdn}]
set_false_path -to [get_ports {ulpi_rst}]

// Timing reports
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
