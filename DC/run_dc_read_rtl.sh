#!/bin/bash
#mkdir -p analyzed
mkdir -p logs
mkdir -p reports
mkdir -p netlist
mkdir -p tmax
mkdir -p svf
mkdir -p WORK

export ultra_switch=false
export high_switch=false
export area_switch=false
export power_switch=false
export fix_hold_switch=false
export exit_switch=true

dc_shell-xg-t -f ./read_rtl.tcl             |tee -i logs/read_rtl.log


