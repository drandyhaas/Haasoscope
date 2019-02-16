from serial import Serial
from struct import unpack
import time

ser=Serial("COM16",1500000,timeout=1.0)
waitlittle = .1 #seconds

#This is a _minimal_ set of example commands needed to send to a board to initialize it properly
commands = [
    [0, 20], #Set board id to 0
    [135, 0, 100], #serialdelaytimerwait of 100
    [122, 0, 10],  #number of samples 10
    [123, 0], #send increment
    [124, 3], #downsample 3
    [125, 1], #tickstowait 1
    [136, 2, 32,  0,   0, 255, 200], # io expanders on (!)
    [136, 2, 32,  1,   0, 255, 200], # io expanders on (!)
    [136, 2, 33,  0,   0, 255, 200], #, io expanders on (!)
    [136, 2, 33,  1,   0, 255, 200], # io expanders on (!)
    [136, 2, 32, 18, 240, 255, 200], # init
    [136, 2, 32, 19, 15, 255, 200], # init (and turn on ADCs!)
    [136, 2, 33, 18,  0, 255, 200], # init
    [136, 2, 33, 19,  0, 255, 200], # init
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
ser.write(bytearray([100, 10])) # arm trigger and get an event
result = ser.read(40)
byte_array = unpack('%dB' % len(result), result)

for i in range(0,4):
    print byte_array[ 10*i : 10*i + 10 ] # print out the 4 channels

ser.close()
