from serial import Serial
from struct import unpack
import time

serialtimeout=10.0
ser=Serial("COM5",1500000,timeout=serialtimeout)
waitlittle = .1 #seconds

#This is a _minimal_ set of example commands needed to send to a board to initialize it properly

ser.write(chr(0)); ser.write(chr(20)) #set board id to 0
time.sleep(waitlittle)
ser.write(chr(135)); ser.write(chr(0)); ser.write(chr(100)); #serialdelaytimerwait of 100
time.sleep(waitlittle)
ser.write(chr(122)); ser.write(chr(0)); ser.write(chr(10)); #number of samples 10
time.sleep(waitlittle)

ser.write(chr(123)); ser.write(chr(0)); #send increment
time.sleep(waitlittle)
ser.write(chr(124)); ser.write(chr(3)); #downsample 3
time.sleep(waitlittle)
ser.write(chr(125)); ser.write(chr(1)); #tickstowait 1
time.sleep(waitlittle)

ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(32)); ser.write(chr(0)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # io expander 1A on - use as outputs
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(32)); ser.write(chr(1)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # io expander 1B on - use as outputs
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(33)); ser.write(chr(0)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # io expander 2A on - use as outputs
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(33)); ser.write(chr(1)); ser.write(chr(255)); ser.write(chr(255)); ser.write(chr(200)); # io expander 2B on - use as inputs !
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(33)); ser.write(chr(13)); ser.write(chr(255)); ser.write(chr(255)); ser.write(chr(200)); # io expander 2B enable pull-up resistors!
time.sleep(waitlittle)

ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(32)); ser.write(chr(18)); ser.write(chr(240)); ser.write(chr(255)); ser.write(chr(200)); # init io expander 1A
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(32)); ser.write(chr(19)); ser.write(chr(15)); ser.write(chr(255)); ser.write(chr(200)); # init io expander 1B (turns on ADCs!)
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(33)); ser.write(chr(18)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # init io expander 2A
time.sleep(waitlittle)
#ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(33)); ser.write(chr(19)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # init io expander 2B
#time.sleep(waitlittle)

time.sleep(waitlittle)
ser.write(chr(131)); ser.write(chr(8)); ser.write(chr(0)); # adc offset
time.sleep(waitlittle)
ser.write(chr(131)); ser.write(chr(6)); ser.write(chr(16)); #offset binary output
#ser.write(chr(131)); ser.write(chr(6)); ser.write(chr(80)); #test pattern output
time.sleep(waitlittle)
ser.write(chr(131)); ser.write(chr(1)); ser.write(chr(0)); #not multiplexed
time.sleep(waitlittle)

ser.write(chr(136)); ser.write(chr(3)); ser.write(chr(96)); ser.write(chr(80)); ser.write(chr(136)); ser.write(chr(22)); ser.write(chr(0)); # channel 0 , board 0 calib
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(3)); ser.write(chr(96)); ser.write(chr(82)); ser.write(chr(136)); ser.write(chr(22)); ser.write(chr(0)); # channel 1 , board 0 calib
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(3)); ser.write(chr(96)); ser.write(chr(84)); ser.write(chr(136)); ser.write(chr(22)); ser.write(chr(0)); # channel 2 , board 0 calib
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(3)); ser.write(chr(96)); ser.write(chr(86)); ser.write(chr(136)); ser.write(chr(22)); ser.write(chr(0)); # channel 3 , board 0 calib
time.sleep(waitlittle)

# OK, we're set up! Now we can read events and get good data out.

oldtime=time.time()
boa=0 # board to get ID from
ser.write(chr(30+boa)) #make the next board active (serial_passthrough 0)
ser.write(chr(142)) #request the unique ID
rslt = ser.read(8)
byte_array = unpack('%dB'%len(rslt),rslt) #Convert serial data to array of numbers
uniqueID = ''.join(format(x, '02x') for x in byte_array) 
print "got uniqueID",uniqueID,"for board",boa," in",round((time.time()-oldtime)*1000.,2),"ms"

oldtime=time.time()
boa=0 # board to get firmware version from
ser.write(chr(30+boa)) #make the next board active (serial_passthrough 0)
ser.write(chr(147)) #request the firmware version byte
ser.timeout=0.1; rslt = ser.read(1); ser.timeout=serialtimeout # reduce the serial timeout temporarily, since the old firmware versions will return nothing for command 147
byte_array = unpack('%dB'%len(rslt),rslt)
firmwareversion=0
if len(byte_array)>0: firmwareversion=byte_array[0]
print "got firmwareversion",firmwareversion,"for board",boa,"in",round((time.time()-oldtime)*1000.,2),"ms"

oldtime=time.time()
for i in range(2):
    ser.write(chr(146)) #request the IO expander data - takes about 2ms to send the command and read the i2c data
    ser.write(chr(33)); ser.write(chr(19)) # from 2B
    ser.write(chr(0)) # for board 0
    rslt = ser.read(1)
    #print "result is length",len(rslt)
    if len(rslt)>0: 
        byte_array = unpack('%dB'%len(rslt),rslt)
        print i,byte_array[0]
print "got i2c data in",round((time.time()-oldtime)*1000./2.,2),"ms"

ser.write(chr(100)); ser.write(chr(10)) # arm trigger and get an event
rslt = ser.read(40)#[0:10]
byte_array = unpack('%dB'%len(rslt),rslt)

for i in range(4): print byte_array[10*i:10*i+10] # print out the 4 channels

ser.close()
