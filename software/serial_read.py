from serial import Serial
from struct import unpack
import time

ser=Serial("COM7",1500000,timeout=1.0)
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

ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(32)); ser.write(chr(0)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # io expanders on (!)
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(32)); ser.write(chr(1)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # io expanders on (!)
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(33)); ser.write(chr(0)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # io expanders on (!)
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(33)); ser.write(chr(1)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # io expanders on (!)
time.sleep(waitlittle)

ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(32)); ser.write(chr(18)); ser.write(chr(240)); ser.write(chr(255)); ser.write(chr(200)); # init
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(32)); ser.write(chr(19)); ser.write(chr(15)); ser.write(chr(255)); ser.write(chr(200)); # init (and turn on ADCs!)
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(33)); ser.write(chr(18)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # init
time.sleep(waitlittle)
ser.write(chr(136)); ser.write(chr(2)); ser.write(chr(33)); ser.write(chr(19)); ser.write(chr(0)); ser.write(chr(255)); ser.write(chr(200)); # init
time.sleep(waitlittle)

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

ser.write(chr(100)); ser.write(chr(10)) # arm trigger and get an event
rslt = ser.read(40)#[0:10]
byte_array = unpack('%dB'%len(rslt),rslt)

for i in range(4): print byte_array[10*i:10*i+10] # print out the 4 channels

ser.close()
