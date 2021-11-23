set_global_assignment -entity "uniqueid2" -library "lib_uniqueid2" -name IP_TOOL_NAME "altchip_id"
set_global_assignment -entity "uniqueid2" -library "lib_uniqueid2" -name IP_TOOL_VERSION "18.0"
set_global_assignment -entity "uniqueid2" -library "lib_uniqueid2" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_uniqueid2" -name SPD_FILE [file join $::quartus(sip_path) "uniqueid2.spd"]

set_global_assignment -library "lib_uniqueid2" -name MISC_FILE [file join $::quartus(sip_path) "uniqueid2_sim/uniqueid2.v"]
set_global_assignment -library "lib_uniqueid2" -name MISC_FILE [file join $::quartus(sip_path) "uniqueid2_sim/altchip_id/altchip_id.v"]
