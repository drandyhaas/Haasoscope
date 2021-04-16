from serial import Serial
from struct import unpack
import time

serialtimeout=1.0
ser=Serial("/dev/ttyUSB0",1500000,timeout=serialtimeout)

#This is a _minimal_ test of sending a python command

i=0
while i<2000:
    ser.write(bytearray([201]));
    time.sleep(1)
    i=i+1

ser.close()
