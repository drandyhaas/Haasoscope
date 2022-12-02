#!/bin/bash
# This is an example script for running HaasoscopeQt.py in a docker
# container.  This is an example - you may need to copy this file and
# modify it so that it works in your environment.
#
# Prior to running this script, the docker image should have been
# created with something like:
#  docker build -t haasoscope -f haasoscope.docker

# Map main USB port into container
U1="/dev/serial/by-id/usb-1a86_USB2.0-Serial-if00-port0"
DPARAM="--device=${U1}"

# Map ft232h USB port into container (if found)
U2=( /dev/serial/by-id/usb-FTDI_Haasoscope_USB2_*-if00-port0 )
if [ -e "${U2}" ]; then
    DPARAM="${DPARAM} --device=${U2}"
fi

# Map x-windows socket into container
DPARAM="${DPARAM} -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=${DISPLAY}"

# If passing the x-windows socket doesn't work, then the following may
# work instead:
#xhost +localhost
#DPARAM="${DPARAM} --net=host -e DISPLAY=host.docker.internal:0"

# Obtain directory of the haasoscope software (based on the location
# of this script) and map the local "software/" directory to /haasoscope .
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
DPARAM="${DPARAM} -v ${SRCDIR}/software:/haasoscope -w /haasoscope"

# Run HaasoscopeQt.py in container
docker run -it --rm ${DPARAM} localhost/haasoscope python3 HaasoscopeQt.py "$@"

# If "xhost +localhost" was used above then reenable security here.
#xhost -localhost
