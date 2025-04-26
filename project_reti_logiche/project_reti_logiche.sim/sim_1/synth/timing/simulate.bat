@echo off
set xv_path=C:\\Xilinx\\Vivado\\2016.1\\bin
call %xv_path%/xsim tb2425_time_synth -key {Post-Synthesis:sim_1:Timing:tb2425} -tclbatch tb2425.tcl -view C:/Users/Nicky/Desktop/POLIMI/Corsi/ProveFinali/RL/project_reti_logiche/project_reti_logiche.sim/waves/tb2425_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
