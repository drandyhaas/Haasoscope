from serial import Serial
from struct import unpack
import random

print("Loading HaasoscopeTrigLibQt.py")

class HaasoscopeTrig:

    def construct(self,port):
        self.ser=Serial(port,921600,timeout=0.2)
        self.extclock=0
        self.histostosend=-1
        self.dorolling=1
        print("connected trigboard serial to", port)
    
    def togglerolling(self):
        self.dorolling = not self.dorolling
        self.ser.write(bytearray([13]))  # toggle rolling
        print("trigboard rolling is now",self.dorolling)

    def setclock(self, wantactiveclock): # True for wanting sync with external clock
        self.extclock = 0
        self.ser.write(bytearray([8]))  # active clock info
        res = self.ser.read(1)
        if len(res)==0: return
        b = unpack('%dB' % len(res), res)
        print("trig board was using clock", b[0])
        self.extclock = b[0]
        if wantactiveclock and not self.extclock:
            self.ser.write(bytearray([4]))  # toggle use other clk input
        if not wantactiveclock and self.extclock:
            self.ser.write(bytearray([4]))  # toggle use other clk input
        self.ser.write(bytearray([8]))  # active clock info
        res = self.ser.read(1)
        b = unpack('%dB' % len(res), res)
        print("trig board now using clock", b[0])
        self.extclock = b[0]

    def setrngseed(self):
        random.seed()
        b1=random.randint(0,255)
        b2=random.randint(0,255)
        b3=random.randint(0,255)
        b4=random.randint(0,255)
        self.ser.write(bytearray([6,b1,b2,b3,b4]))
        print("set trigboard random seed to",b1,b2,b3,b4)

    def set_prescale(self,prescale): # takes a float from 0-1 that is the fraction of events to pass
        if prescale>1.0 or prescale<0.0:
            print("bad prescale value,",prescale)
            return
        prescaleint = int((pow(2, 32) - 1) * prescale)
        b4=int(prescaleint/256/256/256)%256
        b3=int(prescaleint/256/256)%256
        b2=int(prescaleint/256)%256
        b1=int(prescaleint)%256
        self.ser.write(bytearray([7,b1,b2,b3,b4]))
        print("set trigboard prescale to",prescale," - will pass",prescaleint,"out of every 4294967295",", bytes:",b1,b2,b3,b4)

    def get_firmware_version(self):
        self.ser.write(bytearray([0])) # firmware version
        res = self.ser.read(1)
        if len(res)==0:
            print("could not get trigboard firmware version!")
            return 0
        b = unpack('%dB' % len(res), res)
        self.firmwarev=b[0]
        print("trig board firmware v",self.firmwarev)
        return self.firmwarev

    def increment_trig_board_clock_phase(self, times=1):
        for t in range(times): self.ser.write(bytearray([5])) #increment phase
        print("incremented phase of trig board",times,"time(s)")

    def get_delaycounters(self):
        self.ser.write(bytearray([11]))  # delaycounter trigger info
        res = self.ser.read(16)
        self.delaycounters = unpack('%dB' % len(res), res)
        #print("all delaycounters:",self.delaycounters)
        return self.delaycounters

    def set_histostosend(self,h):
        self.ser.write(bytearray([2, h]))  # set histos to be from channel h
        self.histostosend=h
        print("will send histos from board",self.histostosend)

    def get_histos(self):
        self.ser.write(bytearray([10])) # get histos
        res = self.ser.read(32)
        b = unpack('%dB' % len(res), res)
        mystr="histos for board"+str(self.histostosend)+": "
        myint=[]
        for i in range(8):
            myint.append( b[4*i+0]+256*b[4*i+1]+256*256*b[4*i+2]+0*256*256*256*b[4*i+3] )
            mystr+=str(myint[i])+" "
            if i==3: mystr+=", "
        return mystr

    def cleanup(self):
        self.setclock(False)
        if not self.dorolling: self.togglerolling()
        self.ser.close()
    
