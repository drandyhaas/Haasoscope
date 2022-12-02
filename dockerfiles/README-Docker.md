# Run Haasoscope in a Container

Containers provide isolated environments, similar to VMs, but lighter weight, and with performance closer to the native machine they run on.  Containers start quickly from an efficient layered image which provides an identical environment each time the container starts.  This solves the "it worked on my machine" issues that often plague development due to differences between versions of the tools or libraries on different machines.  Used properly, they are ideal for building software as part of a continuous integration environment, or deploying software as part of a continuous deployment system (CI/CD.)  Today, Docker is the defacto container ecosystem, which means there are lots of resources for learning Docker, and lots of people familiar with it.  The Dockerfile used to build a container image can be quite simple, and therefore it also provides a form of executable documentation on what is required to build and/or install a piece of software.  A great place to start is the Docker website, which provides links to tutorials and documentation:

https://www.docker.com/why-docker

Containers allow you to run or test software without installing it.  This allows you to test new versions or old versions without messing with the version you have installed natively on your machine.  In fact, you can run the software without installing any version natively on your machine.

## Building a container image to run the HaasoscopeQt.py application

The following command will create a container locally named
"haasoscope" that can be used to run the HaasocopeQt.py graphical
tool:
```
docker build -t haasoscope -f haasoscope.docker
```

The [haasoscope.sh](./haasoscope.sh) script may be used to run
HaasoscopeQt.py once the above "haasoscope" container is built:
```
./haasoscope.sh
```
This script attempts to map the Haasoscope USB devices, X-Windows
display socket, and the `../software/` directory into the container
prior to running HaasoscopeQt.py.  It may be necessary to copy and
modify this script to work on your machine.  See the script for
details.

## Building a container image for the Intel Quartus FPGA software

The Quartus software is used to compile the FPGA firmware.  It can
also be used to program that firmware into the Haasoscope hardware.

The following command will create a container locally named
"quartus" that can be used to run the Quartus tool:
```
docker build -t quartus -f quartus.docker
```

Important! Building this container involves a download of over 6GB and
the full installation requires around 25GB of disk space!

Once the container is built one can run the Quartus GUI in the
container. See the [quartus.sh](./quartus.sh) file for details.  For
example:
```
./quartus.sh
```

It is also possible to run an FPGA simulation and compilation from the
command line:
```
./quartus_compile.sh
```

The firmware image can also be uploaded to the Haasoscope hardware
from the command line:
```
./quartus_flash.sh
```

The above scripts are examples - it may be necessary to copy and
modify these scripts for your machine.
