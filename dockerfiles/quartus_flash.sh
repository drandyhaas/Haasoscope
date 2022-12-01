#!/bin/bash
# This is an example script for uploading new code to an fpga using
# the "Quartus" software in a docker container.  This is an example -
# you may need to copy this file and modify it so that it works in
# your environment.
#
# Prior to running this script, the docker image should have been
# created with something like:
#  docker build -t quartus -f quartus.docker

# Map "USB Blaster" into container
USBBLASTER_VIDPID="09fb:6001"
BD="`lsusb -d ${USBBLASTER_VIDPID}`" # "Bus 003 Device 043: ..."
BUS="${BD:4:3}"
DEV="${BD:15:3}"
DPARAM="--device=/dev/bus/usb/${BUS}/${DEV}"

# Obtain directory of the haasoscope software (based on the location
# of this script) and map the local firmware directory to /project .
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
DPARAM="${DPARAM} -v ${SRCDIR}/max10_adc_firmware:/project -w /project"

# Run Quartus in container
docker run -it --rm ${DPARAM} localhost/quartus bash -c 'quartus_pgm -l && quartus_pgm -m jtag -o "p;output_files/serial1.sof"'
