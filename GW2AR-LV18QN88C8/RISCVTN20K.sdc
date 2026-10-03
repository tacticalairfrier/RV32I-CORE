//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2026-10-03 12:47:45
create_clock -name CLOCK0 -period 37.037 -waveform {0 25} [get_ports {clkin}]
