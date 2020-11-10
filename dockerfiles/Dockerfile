FROM python:3-slim-buster

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    gfortran \
    libatlas-base-dev \
    libblas3 \
    liblapack3 \
    liblapack-dev \
    libblas-dev \
    libgl1-mesa-glx \
    libgtk2.0 \
    libgtk2.0-dev \
    libqt5x11extras5 \
    libusb-1.0-0 \
    usbutils \
    x11-apps \
    udev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root

# install Haasoscope
RUN git clone https://github.com/drandyhaas/Haasoscope.git
WORKDIR /root/Haasoscope
RUN git checkout python3
RUN pip3 install pyserial numpy matplotlib PySide2 Qt.py scipy pyqtgraph  
#   
WORKDIR /root/Haasoscope/software

# Below are some example commands to build and run a docker container.
# From within the dockerfiles directory in a terminal window type:
#
# docker build . -t haasoscope 
# 
# First, you may need to enable xhost:
# 
# $ xhost +local:docker
#
# To work with the USB hardware, you may need to run the container 
# privileged with a command like:
#
# docker run --privileged -it --rm -e DISPLAY=$DISPLAY -v "/tmp/.X11-unix:/tmp/.X11-unix" haasoscope bash
# 
# The above will execute bash within the running container.  Any
# tools called through bash will run within the container.
#
# The binary is in /root/Haasoscope/software
#
# python3 HaasoscopeQt.py
#
#
# After you close the app, and exit the container, it is best to re-enable xhost authentication
#
# xhost -local:docker
#
# There is intentionally no user and no entrypoint in this container image, 
# which makes it easier to re-use this image as the base of a new container image.
