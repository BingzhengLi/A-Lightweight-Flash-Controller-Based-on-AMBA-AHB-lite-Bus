#!/bin/bash
#mkdir -p analyzed
mkdir -p logs
mkdir -p reports
mkdir -p netlist
mkdir -p tmax
mkdir -p svf
mkdir -p WORK

#dont enable ultra_switch, too slow
export ultra_switch=false

export high_switch=true
export area_switch=false
export power_switch=false
export fix_hold_switch=false
export exit_switch=true
export remove_tie_dont_use_switch=true

#dc_shell-xg-t -f ./scripts/constraint_compile.tcl |tee -i logs/constraint_compile.log
dc_shell-xg-t -f ./constraint_compile.tcl |tee -i logs/constraint_compile.log


