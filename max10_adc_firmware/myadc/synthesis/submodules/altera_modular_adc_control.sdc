# (C) 2001-2018 Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files from any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License Subscription 
# Agreement, Intel FPGA IP License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Intel and sold by 
# Intel or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


#**************************************************************
# Set False Path - ADC Hard to/from Soft Logic is asynchronous
#**************************************************************
## EOC - Automatically covered in reset_synchronizer SDC
## CLK_DFT - Automatically covered in reset_synchronizer SDC

## DOUT
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

## CHSEL
set_false_path -from [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|chsel[*]}] -to [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|chsel[*]}]

## SOC
set_false_path -from [get_registers {*altera_modular_adc_control_fsm:u_control_fsm|soc}] -to [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|soc}]


#******************************************************************************************************************
# Set Net Delay - ADC Hard to/from Soft Logic is constrained to be max data delay of 5ns and min data delay of 0ns
#******************************************************************************************************************

## EOC
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|eoc}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|eoc}] -min 0

## CLK_DFT
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|clk_dft}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|clk_dft}] -min 0

## DOUT
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[0]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[1]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[2]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[3]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[4]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[5]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[6]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[7]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[8]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[9]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[10]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[11]}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[0]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[1]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[2]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[3]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[4]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[5]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[6]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[7]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[8]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[9]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[10]}] -min 0
set_net_delay -from [get_pins -compatibility_mode {*|adc_inst|adcblock_instance|primitive_instance|dout[11]}] -min 0

## CHSEL
set_net_delay -from [get_pins -compatibility_mode {*|u_control_fsm|chsel[*]|q}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|u_control_fsm|chsel[*]|q}] -min 0

## SOC
set_net_delay -from [get_pins -compatibility_mode {*|u_control_fsm|soc|q}] -max 5
set_net_delay -from [get_pins -compatibility_mode {*|u_control_fsm|soc|q}] -min 0

