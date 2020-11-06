# Run Haasoscope in a Container

Containers provide isolated environments, similar to VMs, but lighter weight, and with performance closer to the native machine they run on.  Containers start quickly from an efficient layered image which provides an identical environment each time the container starts.  This solves the "it worked on my machine" issues that often plague development due to differences between versions of the tools or libraries on different machines.  Used properly, they are ideal for building software as part of a continuous integration environment, or deploying software as part of a continuous deployment system (CI/CD.)  Today, Docker is the defacto container ecosystem, which means there are lots of resources for learning Docker, and lots of people familiar with it.  The Dockerfile used to build a container image can be quite simple, and therefore it also provides a form of executable documentation on what is required to build and/or install a piece of software.  A great place to start is the Docker website, which provides links to tutorials and documentation:

https://www.docker.com/why-docker

Containers allow you to run or test software without installing it.  This allows you to test new versions or old versions without messing with the version you have installed natively on your machine.  In fact, you can run the software without installing any version natively on your machine.

###  Build a container image locally from the Dockerfile

The Dockerfile in this repo starts with a Python container image and installs the necessary dependencies for running the Haasoscope software.  It clones the Haasoscope software and checks out the python3 branch.  You can create and tag a local image with a Docker command like:
```
docker build . -t haasoscope
```
### Running Haasoscope in a container under Linux
Once you have a haasoscope container image, you can run the container interactively.  In order to start the GUI, you may need to disable xhost authentication for local containers:

``` 
$ xhost +local:docker
```
To work with the USB hardware, you may need to run the container 
privileged with a command like:
```
$ docker run --privileged -it --rm -e DISPLAY=$DISPLAY -v "/tmp/.X11-unix:/tmp/.X11-unix" haasoscope bash
``` 
The above will execute bash within the running container.  Any
tools called through bash will run within the container.

The binary is in /root/Haasoscope/software.  Execute it with:

```
root@b8f80c88570:~/Haasoscope/software# python3 HaasoscopeQt.py
```
Closing the app brings you back to the bash shell prompt.  To exit the interactive bash session and the container type 'exit.'
```
root@b8f80c88570:~/Haasoscope/software# exit
```
When you are finished, it would be wise to re-enable xhost authentication: 
```
$ xhost -local:docker
```

