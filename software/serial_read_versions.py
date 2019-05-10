from serial import Serial
from struct import unpack
import time

serialtimeout=1.0
ser=Serial("COM5",1500000,timeout=serialtimeout)
waitlittle = .1 #seconds

#This is a _minimal_ set of example commands needed to send to a board to initialize it properly

ser.write(chr(0)); ser.write(chr(20)) #set board id to 0
time.sleep(waitlittle)
ser.write(chr(135)); ser.write(chr(0)); ser.write(chr(100)); #serialdelaytimerwait of 100
time.sleep(waitlittle)

oldtime=time.time()
boa=0 # board to get ID from
ser.write(chr(30+boa)) #make the next board active (serial_passthrough 0)
ser.write(chr(142)) #request the unique ID
rslt = ser.read(8)
byte_array = unpack('%dB'%len(rslt),rslt) #Convert serial data to array of numbers
uniqueID = ''.join(format(x, '02x') for x in byte_array) 
print("got uniqueID",uniqueID,"for board",boa," in",round((time.time()-oldtime)*1000.,2),"ms")

oldtime=time.time()
boa=0 # board to get firmware version from
ser.write(chr(30+boa)) #make the next board active (serial_passthrough 0)
ser.write(chr(147)) #request the firmware version byte
ser.timeout=0.1; rslt = ser.read(1); ser.timeout=serialtimeout # reduce the serial timeout temporarily, since the old firmware versions will return nothing for command 147
byte_array = unpack('%dB'%len(rslt),rslt)
firmwareversion=0
if len(byte_array)>0: firmwareversion=byte_array[0]
print("got firmwareversion",firmwareversion,"for board",boa,"in",round((time.time()-oldtime)*1000.,2),"ms")

ser.close()
