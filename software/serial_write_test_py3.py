from serial import Serial
from struct import unpack
import time

serialtimeout=1.0
ser=Serial("COM6",1500000,timeout=serialtimeout) #115200

#This sends out some data over serial - good for testing serial decoding

i=0
while i<200000:
    ser.write(bytearray([139,159]))
    time.sleep(0.1)
    i=i+1
    print(i)

ser.close()
