set_global_assignment -entity "uniqueid" -library "lib_uniqueid" -name IP_TOOL_NAME "altchip_id"
set_global_assignment -entity "uniqueid" -library "lib_uniqueid" -name IP_TOOL_VERSION "15.0"
set_global_assignment -entity "uniqueid" -library "lib_uniqueid" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_uniqueid" -name SPD_FILE [file join $::quartus(sip_path) "uniqueid.spd"]

set_global_assignment -library "lib_uniqueid" -name MISC_FILE [file join $::quartus(sip_path) "uniqueid_sim/uniqueid.v"]
set_global_assignment -library "lib_uniqueid" -name MISC_FILE [file join $::quartus(sip_path) "uniqueid_sim/altchip_id/altchip_id.v"]
