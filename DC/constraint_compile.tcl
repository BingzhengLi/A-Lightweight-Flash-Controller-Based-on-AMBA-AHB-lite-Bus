#****************************************************
#Note: 	clocks and reset signals were assumed as ideal
#****************************************************

#****************************************************
#MAX freq : 125M
#set SYS_CLK_PERIOD 9.0
#set SYS_CLK_PERIOD 12.0 # 83MHz.
set SYS_CLK_PERIOD 8.0
#****************************************************

#****************************************************
date
#****************************************************

set fix_hold_switch 	[getenv fix_hold_switch]
set exit_switch 	[getenv exit_switch]
set area_switch  	[getenv area_switch]
set power_switch  	[getenv power_switch]
set ultra_switch 	[getenv ultra_switch]
set high_switch  	[getenv high_switch]
set remove_tie_dont_use_switch [getenv remove_tie_dont_use_switch]


# Define some variables for design -- {aes_ASIC}
#****************************************************
#set TOP_MODULE		aes_ASIC
#set TOP_MODULE SM3_ASIC
set TOP_MODULE Flash_Controller_ASIC
#set Rst_list		[list PAD_wb_rst_i]
set Rst_list [list pad_HRST_n]
#set Clk_list		[list PAD_wb_clk_i]
set Clk_list [list pad_HCLK]

set_svf 	${svfDir}/${TOP_MODULE}.svf

#Read saved unmapped ddc file
read_ddc  ${netlistDir}/${TOP_MODULE}_unmapped.ddc

#****************************************************
# Define The Design Enviroment
#****************************************************

set_min_library smic18_ss.db -min_version smic18_ff.db
set_min_library smic18IO_line_ss.db -min_version smic18IO_line_ff.db
#set_min_library smic18IO_stagger_ss.db -min_version smic18IO_stagger_ff.db

#set_min_library  vs_dp_16x64_worst.db	-min_version vs_dp_16x64_best.db


set_operating_conditions -analysis_type bc_wc -min best -max worst

set_wire_load_mode  "segmented"
set_wire_load_model -name reference_area_10000000 -library smic18_ss


#****************************************************
# List of dont use cells. Avoiding scan and jk flip-flops, latches
#****************************************************
if 1 {
set_dont_use smic18_ss/FFSD*
set_dont_use smic18_ss/FFSED*
set_dont_use smic18_ss/FFJK*
set_dont_use smic18_ss/FFSJK*

#if set_dont_use latch, the result is wrong
#set_dont_use smic18_ss/LAT*
#set_dont_use smic18_ss/RSLAT*

#set_dont_use smic18_ss/*LX
#set_dont_use smic18_ss/*1X


#set_dont_use smic18_tt/FFSD*
#set_dont_use smic18_tt/FFSED*
#set_dont_use smic18_tt/FFJK*
#set_dont_use smic18_tt/FFSJK*

#set_dont_use smic18_tt/LAT*
#set_dont_use smic18_tt/RSLAT*
#set_dont_use smic18_tt/*LX
#set_dont_use smic18_tt/*1X

set_dont_use smic18_ff/FFSD*
set_dont_use smic18_ff/FFSED*
set_dont_use smic18_ff/FFJK*
set_dont_use smic18_ff/FFSJK*
#set_dont_use smic18_ff/LAT*
#set_dont_use smic18_ff/RSLAT*
#set_dont_use smic18_ff/*LX
#set_dont_use smic18_ff/*1X

}

#****************************************************
# remove dont_use attribute
#****************************************************
if { $remove_tie_dont_use_switch == "true" } {
	set_attribute  [get_lib_cells smic18_ss/TIE*] dont_touch false
#	set_attribute  [get_lib_cells smic18_tt/TIE*] dont_touch false
	set_attribute  [get_lib_cells smic18_ff/TIE*] dont_touch false

	set_attribute  [get_lib_cells smic18_ss/TIE*] dont_use false
#	set_attribute  [get_lib_cells smic18_tt/TIE*] dont_use false
	set_attribute  [get_lib_cells smic18_ff/TIE*] dont_use false
}

#****************************************************
# clock defination and reset
#****************************************************
#MAX freq : 125M
#physical clock and reset
current_design $TOP_MODULE

#should use pins? Can PAD_* be used?

#create_clock -name wb_clk -period $SYS_CLK_PERIOD -waveform [list 0 [expr $SYS_CLK_PERIOD /2]]  [get_ports PAD_wb_clk_i]
create_clock -name PAD_clk -period $SYS_CLK_PERIOD -waveform [list 0 [expr $SYS_CLK_PERIOD/2]]  [get_ports pad_HCLK]

#create_clock -name wb_clk -period $SYS_CLK_PERIOD -waveform [list 0 [expr $SYS_CLK_PERIOD/2]]  [get_pins U_wb_clk_i/D]

set_dont_touch_network  [all_clocks]
#wb_clk
#set_ideal_network [get_pins "U_wb_clk_i/D"]
set_ideal_network [get_pins "U_clk_in"]
set_dont_touch_network  [get_ports "$Rst_list"]
set_ideal_network [get_ports "$Rst_list"]

#****************************************************
# clock constraints
#****************************************************
set_clock_latency	0.8	[all_clocks]
#set_clock_uncertainty	0.3	[all_clocks]
set_clock_uncertainty   0.1    [all_clocks]

set_clock_transition    0.3     [all_clocks]

report_clocks -nosplit >  ${reportsDir}/${TOP_MODULE}.clocks.txt

#****************************************************
# drive and load, max_fanout,max_capacitance
#****************************************************
#set MAX_LOAD	[load_of smic18_ss/NAND2HD2X/A]
set MAX_LOAD    [load_of smic18_ss/INVHD4X/A]

set_drive 0	[get_ports "$Rst_list"]
set_drive 0 	[get_ports "$Clk_list"]


#set_driving_cell -lib_cell PLBI8S [remove_from_collection [all_inputs] \
#         [get_ports [list PAD_wb_clk_i PAD_wb_rst_i]]]
set_driving_cell -lib_cell INVHD2X [remove_from_collection [all_inputs] \
         [get_ports [list pad_HCLK pad_HRST_n]]]

set_max_capacitance [expr $MAX_LOAD*12] [get_designs *]

#set_load [expr $MAX_LOAD*15] [all_outputs]
set_load [expr $MAX_LOAD*3] [all_outputs]

set_max_fanout 10 [all_inputs]

set_max_transition 1.0 $TOP_MODULE

#****************************************************
# input delay and output delay
# input delay and output delay were set to 50% clock period
#****************************************************

#should use -max and -min

#define ports (exclude *clk ports)
#jtag ports; use set_case_analysis?
#input delay : max : period - setup
#input delay : min : hold
#output delay : max : setup
#output delay : min : -hold

#set wb_in_ports [remove_from_collection [all_inputs]  [get_ports [list PAD_wb_clk_i PAD_wb_rst_i]]]
#set wb_out_ports [get_ports [list PAD_wb_dat_o PAD_wb_ack_o]]
set PAD_in_ports [remove_from_collection [all_inputs]  [get_ports [list pad_HCLK  pad_HRST_n]]]
set PAD_out_ports [get_ports [list pad_o_pad_pmodb_mosi pad_o_pad_pmodb_cs pad_o_pad_pmodb_spi_clk  pad_HREADY pad_HRESP]]


#set_input_delay -max 5 -clock wb_clk $wb_in_ports
#set_input_delay -min 0.1 -clock wb_clk $wb_in_ports
set_input_delay -max [expr $SYS_CLK_PERIOD/2] -clock PAD_clk $PAD_in_ports
set_input_delay -min 0.1 -clock PAD_clk $PAD_in_ports

#set_output_delay -max 5 -clock wb_clk $wb_out_ports
#set_output_delay -min -1 -clock wb_clk $wb_out_ports
set_output_delay -max [expr $SYS_CLK_PERIOD/2] -clock PAD_clk $PAD_out_ports
set_output_delay -min -1 -clock PAD_clk $PAD_out_ports


#exit


#****************************************************
# false path
#****************************************************
#set_case_analysis is enough?
set_false_path -from [get_ports "$Rst_list"]


#****************************************************
# case_analysis
#****************************************************
#set_case_analysis 0 [get_pins "U_wb_rst_i/D"]
set_case_analysis 0 [get_pins "U_reset_in"]

#****************************************************
# area and power
#****************************************************
if { $area_switch == "true" } {
	set_max_area     0   
}
if { $power_switch == "true" } {
	set_max_total_power 0 uw
}

#****************************************************
# don't touch
#****************************************************

set_dont_touch        [get_cells U_* ]

#****************************************************
#  Map and Optimize the design
#****************************************************
check_design

#compile
#avoid "assign"
set verilogout_no_tri true
set verilogout_equation false

#dxzhang:should be used only once
set_fix_multiple_port_nets -buffer_constants -all

#compile  -map_effort high -boundary_optimization
#compile  -map_effort medium -boundary_optimization

if {$ultra_switch == "true"} {
	set_ultra_optimization true -force
	}
if {$high_switch == "true"} {
	compile -map_effort high -boundary_optimization
} else {
	compile -map_effort medium -boundary_optimization
	}

#****************************************************
#  fix_hold_time
#****************************************************

if {$fix_hold_switch == "true"} {
        set_fix_hold [get_clocks *]
        compile -incremental -only_hold_time
}	


check_design  >  ${reportsDir}/${TOP_MODULE}.check_design.txt
check_timing  >  ${reportsDir}/${TOP_MODULE}.check_timing.txt

#****************************************************
#  Output Reports
#****************************************************

report_design -nosplit >  ${reportsDir}/${TOP_MODULE}.design.txt
report_port -nosplit >  ${reportsDir}/${TOP_MODULE}.port.txt
report_net -nosplit >  ${reportsDir}/${TOP_MODULE}.net.txt
report_timing_requirements -nosplit >  ${reportsDir}/${TOP_MODULE}.timing_requirements.txt
report_constraint -nosplit -all_violators >  ${reportsDir}/${TOP_MODULE}.constraint.txt
report_timing -nosplit >  ${reportsDir}/${TOP_MODULE}.timing.txt
report_area -nosplit >  ${reportsDir}/${TOP_MODULE}.area.txt
report_power -nosplit > ${reportsDir}/${TOP_MODULE}.power.txt

#****************************************************
#  Change Naming Rule
#****************************************************
remove_unconnected_ports -blast_buses [find -hierarchy cell {"*"}]
set bus_inference_style {%s[%d]}
set bus_naming_style {%s[%d]}
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed {a-z A-Z 0-9 _} -max_length 255 -type cell
define_name_rules name_rule -allowed {a-z A-Z 0-9 _[]} -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive -remove_internal_net_bus -equal_ports_nets
change_names -hierarchy -rules name_rule

#****************************************************
#  Output Results
#****************************************************

write -format verilog   -hierarchy      -output  ${netlistDir}/${TOP_MODULE}.vg
write -format ddc -hierarchy -output ${netlistDir}/${TOP_MODULE}.ddc
write_sdf  ${netlistDir}/${TOP_MODULE}_post_dc.sdf
write_sdc  -nosplit ${netlistDir}/${TOP_MODULE}.sdc

date

#****************************************************
#  Finish and Quit
#****************************************************
if {$exit_switch == "true"} {
exit
}
