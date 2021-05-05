from serial import Serial
from struct import unpack

print("Loading HaasoscopeTrigLibQt.py")

class HaasoscopeTrig:

    def construct(self,port):
        self.ser=Serial(port,115200,timeout=1.0)
        self.extclock=0
        self.histostosend=-1

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

    def get_firmware_version(self):
        self.ser.write(bytearray([0])) # firmware version
        res = self.ser.read(1)
        if len(res)==0: return
        b = unpack('%dB' % len(res), res)
        self.firmwarev=b[0]
        print("trig board firmware v",self.firmwarev)

    def increment_trig_board_clock_phase(self):
        self.ser.write(bytearray([5])) #increment phase
        print("incremented phase of trig board")

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
        self.ser.close()
