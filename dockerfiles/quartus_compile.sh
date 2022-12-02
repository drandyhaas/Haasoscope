#!/bin/bash
# This is an example script for compiling the firmware using the
# "Quartus" software in a docker container.  This is an example - you
# may need to copy this file and modify it so that it works in your
# environment.
#
# Prior to running this script, the docker image should have been
# created with something like:
#  docker build -t quartus -f quartus.docker

# Obtain directory of the haasoscope software (based on the location
# of this script) and map the local firmware directory to /project .
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
DPARAM="-v ${SRCDIR}/max10_adc_firmware:/project -w /project"

# Run Quartus compiler in container
docker run -it --rm ${DPARAM} localhost/quartus quartus_sh --flow compile serial1.qpf
