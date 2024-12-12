//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.01 (64-bit) 
//Created Time: 2024-12-11 13:29:48
create_clock -name sys_clk -period 1000 -waveform {0 5} [get_ports {i_clk}]
