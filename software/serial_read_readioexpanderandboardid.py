from serial import Serial
from struct import unpack
import time

serialtimeout=10.0
ser=Serial("COM5",1500000,timeout=serialtimeout)
waitlittle = .1 #seconds

#This is a _minimal_ set of example commands needed to send to a board to initialize it properly
commands = [
    [0, 20], #Set board id to 0
    [135, 0, 100], #serialdelaytimerwait of 100
    [122, 0, 10],  #number of samples 10
    [123, 0], #send increment
    [124, 3], #downsample 3
    [125, 1], #tickstowait 1
    [136, 2, 32,  0,   0, 255, 200], # io expander 1A on - use as outputs
    [136, 2, 32,  1,   0, 255, 200], # io expander 1B on - use as outputs
    [136, 2, 33,  0,   0, 255, 200], # io expander 2A on - use as outputs
    [136, 2, 33,  1, 255, 255, 200], # io expander 2B on - use as inputs !
    [136, 2, 33, 13, 255, 255, 200], # io expander 2B enable pull-up resistors!
    [136, 2, 32, 18, 240, 255, 200], # init
    [136, 2, 32, 19, 15, 255, 200], # init (and turn on ADCs!)
    [136, 2, 33, 18,  0, 255, 200], # init
    # [136, 2, 33, 19,  0, 255, 200], # init
    [131, 8,  0], # adc offset
    [131, 6, 16], #offset binary output
    # [131, 6, 80], #test pattern output
    [131, 4, 36], #300 Ohm termination A
    [131, 5, 36], #300 Ohm termination B
    [131, 1,  0], #not multiplexed
    [136, 3, 96, 80, 136, 22, 0], # channel 0 , board 0 calib 
    [136, 3, 96, 82, 136, 22, 0], # channel 1 , board 0 calib 
    [136, 3, 96, 84, 136, 22, 0], # channel 2 , board 0 calib 
    [136, 3, 96, 86, 136, 22, 0], # channel 3 , board 0 calib 
]

for command in commands:
    ser.write(bytearray(command))
    time.sleep(waitlittle)

# OK, we're set up! Now we can read events and get good data out.

oldtime=time.time()
boa=0 # board to get ID from
ser.write(bytearray([30+boa, 142])) #request the unique ID
rslt = ser.read(8)
byte_array = unpack('%dB'%len(rslt),rslt) #Convert serial data to array of numbers
uniqueID = ''.join(format(x, '02x') for x in byte_array) 
print("got uniqueID",uniqueID,"for board",boa," in",round((time.time()-oldtime)*1000.,2),"ms")

oldtime=time.time()
boa=0 # board to get firmware version from
ser.write(bytearray([30+boa, 147])) #request the firmware version
ser.timeout=0.1; rslt = ser.read(1); ser.timeout=serialtimeout # reduce the serial timeout temporarily, since the old firmware versions will return nothing for command 147
byte_array = unpack('%dB'%len(rslt),rslt)
firmwareversion=0
if len(byte_array)>0: firmwareversion=byte_array[0]
print("got firmwareversion",firmwareversion,"for board",boa,"in",round((time.time()-oldtime)*1000.,2),"ms")

oldtime=time.time()
for i in range(2):
    ser.write(bytearray([146, 33, 19, 0]))# #request the IO expander data from 2B for board 0
    rslt = ser.read(1)
    #print "result is length",len(rslt)
    if len(rslt)>0: 
        byte_array = unpack('%dB'%len(rslt),rslt)
        print(i,byte_array[0])
print("got i2c data in",round((time.time()-oldtime)*1000./2.,2),"ms")

ser.write(bytearray([100, 10])) # arm trigger and get an event
rslt = ser.read(40)#[0:10]
byte_array = unpack('%dB'%len(rslt),rslt)

for i in range(4):
    print(byte_array[10*i : 10*i+10]) # print out the 4 channels

ser.close()
