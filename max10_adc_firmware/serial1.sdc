## Generated SDC file "serial1.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.0.0 Build 614 04/24/2018 SJ Lite Edition"

## DATE    "Sat May 22 11:51:39 2021"

##
## DEVICE  "10M08SAE144C8GES"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3


#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clock_ext_osc} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clock_ext_osc}]
create_clock -name {scanclk} -period 100.000 -waveform { 0.000 50.000 } [get_registers {processor:inst|scanclk}]
create_clock -name {usb_clk60} -period 16.666 -waveform { 0.000 8.333 } [get_ports {usb_clk60}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {clk_slowadc10} -source [get_pins {inst15|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 1 -divide_by 5 -master_clock {clock_ext_osc} [get_pins {inst15|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {clk_mainadc} -source [get_pins {inst15|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 5 -divide_by 2 -master_clock {clock_ext_osc} [get_pins {inst15|altpll_component|auto_generated|pll1|clk[1]}] 
create_generated_clock -name {clk_mainadc2} -source [get_pins {inst15|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 5 -divide_by 2 -phase 180/1 -master_clock {clock_ext_osc} [get_pins {inst15|altpll_component|auto_generated|pll1|clk[4]}] 

#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty

#**************************************************************
# Set Input Delay
#**************************************************************

#set_input_delay -clock { clock_ext_osc } .1 *

#**************************************************************
# Set Output Delay
#**************************************************************

#set_output_delay -clock { clock_ext_osc } .1 *

#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group {clock_ext_osc clk_slowadc10 clk_mainadc clk_mainadc2} -group {usb_clk60}

#**************************************************************
# Set False Path
#**************************************************************

set_false_path -to [get_keepers {*altera_std_synchronizer:*|din_s1}]
set_false_path -from [get_keepers {**}] -to [get_keepers {*phasedone_state*}]
set_false_path -from [get_keepers {**}] -to [get_keepers {*internal_phasestep*}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[0]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[0]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[1]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[1]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[2]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[2]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[3]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[3]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[4]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[4]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[5]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[5]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[6]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[6]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[7]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[7]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[8]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[8]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[9]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[9]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[10]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[10]}]
set_false_path -from [get_keepers {*fiftyfivenm_adcblock_primitive_wrapper:adcblock_instance|wire_from_adc_dout[11]}] -to [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|dout_flp[11]}]
set_false_path -from [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|chsel[*]}] -to [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|chsel[*]}]
set_false_path -from [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|soc}] -to [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|soc}]

#slow signals we don't care about being on time
set_false_path -from [get_registers processor:inst|triggertot*]
set_false_path -to [get_registers processor:inst|screencolumndata*]
set_false_path -to [get_registers processor:inst|screenwren*]
set_false_path -from [get_registers uniqueid:inst19|altchip_id:uniqueid*]
set_false_path -from [get_registers processor:inst|rollingtrigger*]
set_false_path -from [get_registers processor:inst|highres*]
set_false_path -from [get_registers processor:inst|send_fast_usb2_done]
set_false_path -from [get_registers processor:inst|send_fast_usb2]
set_false_path -from [get_registers processor:inst|blockstosend*]
set_false_path -from [get_registers processor:inst|do_usb]
set_false_path -from [get_registers processor:inst|do_fast_usb]
set_false_path -from [get_registers processor:inst|imthelast]
set_false_path -from [get_registers processor:inst|noselftrig]
#ignore for now, don't understand it
#set_false_path -from [get_registers processor:inst|clockbitstowaitlockin*]
#ignore for now, not sure how to fix it
set_false_path -to [get_registers processor:inst|lockinresult*]
#probably don't care about these
#set_false_path -to [get_registers processor:inst|sendincrementfast*]
#set_false_path -from [get_registers lp_ram_dp*] -to [get_registers processor:inst|chan*mean*]
#set_false_path -from [get_registers lp_ram_dp*] -to [get_registers processor:inst|txData*]
#set_false_path -from [get_registers processor:inst|rden] -to [get_registers lp_ram_dp*]
#set_false_path -from [get_registers *triggerpoint*] -to [get_registers *rdaddress*]
#set_false_path -from [get_registers *nsmp*] -to [get_registers *nsmp2*]
#set_false_path -from [get_registers processor:inst|rdaddress_slow*]
#set_false_path -from [get_registers processor:inst|rdaddress2_slow*]
#set_false_path -to [get_registers processor:inst|usb_dataio_slow*]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Net Delay
#**************************************************************

set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|eoc}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|eoc}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|clk_dft}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|clk_dft}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[0]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[1]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[2]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[3]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[4]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[5]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[6]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[7]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[8]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[9]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[10]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[11]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[0]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[1]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[2]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[3]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[4]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[5]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[6]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[7]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[8]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[9]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[10]}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[11]}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|u_control_fsm|chsel[*]|q}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|u_control_fsm|chsel[*]|q}]
set_net_delay -max 5.000 -from [get_pins -compatibility_mode {*|u_control_fsm|soc|q}]
set_net_delay -min 0.000 -from [get_pins -compatibility_mode {*|u_control_fsm|soc|q}]
