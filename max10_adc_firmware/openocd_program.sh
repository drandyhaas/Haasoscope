openocd -f ./haasoscope.cfg -c "svf /tmp/serial1.svf ; exit"

# This worked on my mac:
# ! sudo openFPGALoader -c usb-blaster -f /Users/ahaas/PycharmProjects/Haasoscope/max10_adc_firmware/output_files/serial1.pof
