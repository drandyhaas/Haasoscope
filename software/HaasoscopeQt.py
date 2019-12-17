# -*- coding: utf-8 -*-
"""
pyqtgraph widget with UI template created with Qt Designer
"""

import pyqtgraph as pg
from pyqtgraph.Qt import QtCore, QtGui
import numpy as np
import os, sys, time

import HaasoscopeLibQt
reload(HaasoscopeLibQt) # in case you changed it, and to always load some defaults

#Some options
#HaasoscopeLibQt.num_board = 2 # Number of Haasoscope boards to read out (default is 1)
#HaasoscopeLibQt.ram_width = 12 # width in bits of sample ram to use (e.g. 9==512 samples (default), 12(max)==4096 samples) (min is 2)
#HaasoscopeLibQt.max10adcchans = [(0,110),(0,118),(1,110),(1,118)] #max10adc channels to draw (board, channel on board), channels: 110=ain1, 111=pin6, ..., 118=pin14, 119=temp # default is none, []

d = HaasoscopeLibQt.Haasoscope()
d.construct()

#Some other options
#d.serport="COM7" # the name of the serial port on your computer, connected to Haasoscope, like /dev/ttyUSB0 or COM8, leave blank to detect automatically!
#d.domaindrawing=False # whether to keep updating the main plot (on by default)
#d.serialdelaytimerwait=0 #50 #100 #150 #300 # 600 # delay (in 2 us steps) between each 32 bytes of serial output (set to 600 for some slow USB serial setups, but 0 normally)
#d.dolockin=True; d.dolockinplot=d.domaindrawing # whether to calculate the lockin info on the FPGA and read it out (off by default)
#d.db=True #turn on debugging

app = QtGui.QApplication.instance()
standalone = app is None
if standalone:
    app = QtGui.QApplication(sys.argv)

# Define main window class from template
WindowTemplate, TemplateBaseClass = pg.Qt.loadUiType("Haasoscope.ui")

savetofile=False # save scope data to file
if savetofile: outf = open("Haasoscope_out_"+time.strftime("%Y%m%d-%H%M%S")+".csv","wt")

class MainWindow(TemplateBaseClass):  
    def __init__(self):
        TemplateBaseClass.__init__(self)
        
        # Create the main window
        self.ui = WindowTemplate()
        self.ui.setupUi(self)
        self.ui.plotBtn.clicked.connect(self.doplot)
        self.ui.actionTest2.triggered.connect(self.actionTest2)
        self.ui.statusBar.showMessage("yes")
        self.ui.textBrowser.setText("stopped")
        self.show()
        
        self.data = np.random.normal(size=(50,5000))
        self.ptr = 0
        self.lastTime = time.time()
        self.fps = None
        
        #self.ui.plot.setRange(QtCore.QRectF(0, -10, 5000, 20)) 
        self.ui.plot.setLabel('bottom', 'Index', units='B')
        self.curve = self.ui.plot.plot()
        
    def doplot(self):
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.updateplot)
        self.timer.start(0)
        self.ui.textBrowser.setText("going on channel "+str(self.ui.spinBox.value()))
        
    def updateplot(self):
        status = mainloop()
        #d.redraw()
        #self.curve.setData(self.data[self.ptr%10])
        channel=3
        self.curve.setData(d.xydata[channel][0],d.xydata[channel][1])
        self.ptr += 1
        now = time.time()
        dt = now - self.lastTime
        self.lastTime = now
        if self.fps is None:
            self.fps = 1.0/dt
        else:
            s = np.clip(dt*3., 0, 1)
            self.fps = self.fps * (1-s) + (1.0/dt) * s
        self.ui.plot.setTitle('%0.2f fps' % self.fps)
        app.processEvents()  # force complete redraw for every plot
        
    def closeEvent(self, event):
        print "Handling closeEvent"
        self.timer.stop()
        d.cleanup()
        if savetofile: outf.close()
        
    def actionTest2(self):
        print "Handling actionTest2"
        self.ui.statusBar.showMessage("no!")
        #self.timer.stop()
        self.updateplot()
        
win = MainWindow()
win.setWindowTitle('pyqtgraph example: PlotSpeedTest')

nevents2=0; oldnevents2=0; tinterval=100.; oldtime=time.time()
def mainloop():
        global d, nevents2, oldnevents2, tinterval, oldtime
        if d.paused: time.sleep(.1)
        else:
            if not d.getchannels(): return 0
            
            #print d.xydata[0][0][12], d.xydata[0][1][12] # print the x and y data, respectively, for the 13th sample on fast adc channel 0
            
            if savetofile:
                outf.write(str(nevents2)); outf.write(",") # start of each line is the event number
                outf.write(str(time.time())); outf.write(",") # next column is the time in seconds of the current event
                d.xydata[0][1].tofile(outf,",",format="%.3f") # save y data (1) from fast adc channel 0
                outf.write("\n") # newline
            
            #if len(HaasoscopeLib.max10adcchans)>0: print "slow", d.xydataslow[0][0][99], d.xydataslow[0][1][99] # print the x and y data, respectively, for the 100th sample on slow max10 adc channel 0
            
            #if d.dolockin: print d.lockinamp, d.lockinphase # print the lockin info
            
            #if d.fftdrawn: # print some fft info (the freq with the biggest amplitude)
            #    fftxdata = d.fftfreqplot.get_xdata(); fftydata = d.fftfreqplot.get_ydata()
            #    maxfftydata=np.max(fftydata); maxfftfrq=fftxdata[fftydata.argmax()]
            #    print "max amp=",maxfftydata, "at freq=",maxfftfrq, d.fftax.get_xlabel().replace('Freq ','')
            
            #print "here ",nevents2,oldnevents2,tinterval
            if d.db: print time.time()-d.oldtime,"done with evt",nevents2
            nevents2=nevents2 + 1
            if nevents2-oldnevents2 >= tinterval:
                elapsedtime=time.time()-oldtime
                lastrate = round(tinterval/elapsedtime,2)
                print nevents2,"events,",lastrate,"Hz"
                oldtime=time.time()
                if lastrate>40: tinterval=500.
                else: tinterval=100.
                oldnevents2=nevents2
            if d.getone and not d.timedout: d.paused=True

try:    
    if not d.setup_connections(): sys.exit()
    if not d.init(): sys.exit()
    d.on_launch()
    
    #can change some things
    #d.selectedchannel=0
    #d.tellswitchgain(d.selectedchannel)
    #d.togglesupergainchan(d.selectedchannel)
    #d.toggletriggerchan(d.selectedchannel)
    #d.togglelogicanalyzer() # run the logic analyzer
    #d.sendi2c("21 13 f0") # set extra pins E24 B0,1,2,3 off and B4,5,6,7 on (works for v8 only)
    
except SerialException:
    print "serial com failed!"

if standalone:
    sys.exit(app.exec_())
else:
    print "We're back with the Qt window still active"
