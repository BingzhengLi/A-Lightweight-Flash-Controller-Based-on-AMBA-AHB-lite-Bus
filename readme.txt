/*********************************************************/
This file includes the source code for the Flash controller, scripts for DC synthesis, modified moudules for integrating the Flash controller into E906-SmartRunPlatfrom as well as related programs and therir linker scripts. 
Written by @Li Bingzheng 20240501.
/*********************************************************/
The struture of the file is as follows:
A Lightweight Flash Controller Based on AMBA AHB-lite Bus
|
|__DC__read_rtl.tcl: read *.v in rtl.
|    |__run_dc_read_rtl.sh: run read_rtl.tcl in shell.
|    |__contraint_compile.tcl: constaint added to the design.
|    |__run_dc_constraint_compile.sh: synthesize and output results.
|__logs: logging the execution of the scripts.
|__reports: synthesis results inlcluding power, aread and timing. 
|__rtl: source code of the Flash controller (*.v);
|__adjusted module in E906: provide *.v changed in E906-SmartRun-Platform. Integrate them to E906-SmartRun-Platform project can simulate the Flash controller functionalities.
|__lib: process library directory(do not provide in GitHub due to related laws).    
|__program: provide bootloader.s, Prog2Flash.s and their linker scripts.
|__othe files: work directory for DC running.

There are only 2 steps to perform for DC synsthesis:
(1) cd DC_AHB_FlashController/DC
(2) ./run_dc_read_rtl.sh;
    ./run_dc_constriant_compile.sh.
It is noteworthy that necessary EDA environment ought to be configured in advance for DC.

