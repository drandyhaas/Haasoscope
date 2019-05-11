from serial import Serial
from struct import unpack
import time

num_board = 1 # Number of Haasoscope boards to read out

class Haasoscope():
    def __init__(self):
        #This is a _minimal_ set of example commands needed to send to a board to initialize it properly
        self.ser=Serial("/dev/ttyUSB0",1500000,timeout=1.0)
        waitlittle = .1 #seconds

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
            self.ser.write(bytearray(command))
            time.sleep(waitlittle)
    def getData(self):
        # OK, we're set up! Now we can read events and get good data out.
        frame=bytearray([100, 10])
        self.ser.write(frame) # arm trigger and get an event
        result = self.ser.read(40)
        byte_array = unpack('%dB' % len(result), result)
        print("Data:")
        for i in range(0,4):
            print(byte_array[ 10*i : 10*i + 10 ]) # print out the 4 channels
    def getIDs(self):
        debug3=True
        self.uniqueID=[]
        for n in range(num_board):
            frame=[]
            frame.append(30+n)
            frame.append(142)
            self.ser.write(frame)
            num_other_bytes = 8
            rslt = self.ser.read(num_other_bytes)
            if len(rslt)==num_other_bytes:
                byte_array = unpack('%dB'%len(rslt),rslt) #Convert serial data to array of numbers
                self.uniqueID.append( ''.join(format(x, '02x') for x in byte_array) )
                if debug3: print(("got uniqueID",self.uniqueID[n],"for board",n,", len is now",len(self.uniqueID)))
            else: print(("getID asked for",num_other_bytes,"bytes and got",len(rslt),"from board",n))

d=Haasoscope()
d.getIDs()
d.getData()
d.getData()
d.getData()

