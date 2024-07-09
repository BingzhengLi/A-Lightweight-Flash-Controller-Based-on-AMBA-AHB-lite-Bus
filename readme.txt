/*********************************************************/
This file includes the source code for the Flash controller and scripts for DC synthesis. 
Written by @Li Bingzheng 20240501.
/*********************************************************/
The struture of the file is as follows:
DC_AHB_FlashController
|
|__DC__read_rtl.tcl: read *.v in rtl.
|    |__run_dc_read_rtl.sh: run read_rtl.tcl in shell.
|    |__contraint_compile.tcl: constaint added to the design.
|    |__run_dc_constraint_compile.sh: synthesize and output results.
|__logs: logging the execution of the scripts.
|__reports: synthesis results inlcluding power, aread and timing. 
|__rtl: source code of the Flash controller (*.v).\
|__lib: SIMC process library.    
|__othe files: work directory for DC.

There are only 2 steps to perform:
(1) cd DC_AHB_FlashController/DC
(2) ./run_dc_read_rtl.sh;
    ./run_dc_constriant_compile.sh.

It is noteworthy that necessary EDA environment ought to be configured in advance.

