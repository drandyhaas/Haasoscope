# -*- coding: utf-8 -*-
"""
pyqtgraph widget with UI template created with Qt Designer
"""

import numpy as np
import os, sys, time
from pyqtgraph.Qt import QtCore, QtGui
import pyqtgraph as pg
from serial import SerialException

import HaasoscopeLibQt
reload(HaasoscopeLibQt) # in case you changed it, and to always load some defaults

#Some pre-options
#HaasoscopeLibQt.num_board = 2 # Number of Haasoscope boards to read out (default is 1)
#HaasoscopeLibQt.ram_width = 12 # width in bits of sample ram to use (e.g. 9==512 samples (default), 12(max)==4096 samples) (min is 2)
#HaasoscopeLibQt.max10adcchans = [(0,110),(0,118),(1,110),(1,118)] #max10adc channels to draw (board, channel on board), channels: 110=ain1, 111=pin6, ..., 118=pin14, 119=temp # default is none, []

d = HaasoscopeLibQt.Haasoscope()
d.construct()

#Some other options
#d.serport="COM7" # the name of the serial port on your computer, connected to Haasoscope, like /dev/ttyUSB0 or COM8, leave blank to detect automatically!
#d.serialdelaytimerwait=0 #50 #100 #150 #300 # 600 # delay (in 2 us steps) between each 32 bytes of serial output (set to 600 for some slow USB serial setups, but 0 normally)
#d.dolockin=True # whether to calculate the lockin info on the FPGA and read it out (off by default)
#d.db=True #turn on debugging

app = QtGui.QApplication.instance()
standalone = app is None
if standalone:
    app = QtGui.QApplication(sys.argv)

# Define main window class from template
WindowTemplate, TemplateBaseClass = pg.Qt.loadUiType("Haasoscope.ui")

class MainWindow(TemplateBaseClass):  
    def __init__(self):
        TemplateBaseClass.__init__(self)
        
        # Create the main window
        self.ui = WindowTemplate()
        self.ui.setupUi(self)
        self.ui.plotBtn.clicked.connect(self.dostartstop)
        self.ui.actionTest2.triggered.connect(self.actionTest2)
        self.ui.statusBar.showMessage("yes")
        self.ui.textBrowser.setText("stopped")
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.updateplot)
        self.show()
        self.db=True
        self.lastTime = time.time()
        self.fps = None
        self.lines = []
        self.otherlines = []
        self.savetofile=False # save scope data to file
        if self.savetofile: self.outf = open("Haasoscope_out_"+time.strftime("%Y%m%d-%H%M%S")+".csv","wt")
            
    def launch(self):        
        self.ui.plot.setBackground('w')
        self.nlines = HaasoscopeLibQt.num_chan_per_board*HaasoscopeLibQt.num_board+len(HaasoscopeLibQt.max10adcchans)
        if self.db: print "nlines=",self.nlines
        for l in np.arange(self.nlines):
            maxchan=l-HaasoscopeLibQt.num_chan_per_board*HaasoscopeLibQt.num_board
            c=(0,0,0)
            if maxchan>=0: # these are the slow ADC channels
                if HaasoscopeLibQt.num_board>1:
                    board = int(HaasoscopeLibQt.num_board-1-HaasoscopeLibQt.max10adcchans[maxchan][0])
                    if board%4==0: c=(1-0.1*maxchan,0,0)
                    if board%4==1: c=(0,1-0.1*maxchan,0)
                    if board%4==2: c=(0,0,1-0.1*maxchan)
                    if board%4==3: c=(1-0.1*maxchan,0,1-0.1*maxchan)
                else:
                    c=(0.1*(maxchan+1),0.1*(maxchan+1),0.1*(maxchan+1))
                pen = pg.mkPen(color=c) # add linewidth=0.5, alpha=.5
                line = self.ui.plot.plot(pen=pen,name="slowadc_"+str(HaasoscopeLibQt.max10adcchans[maxchan]))
            else: # these are the fast ADC channels
                chan=l%4
                if HaasoscopeLibQt.num_board>1:
                    board=l/4
                    if board%4==0: c=(1-0.2*chan,0,0)
                    if board%4==1: c=(0,1-0.2*chan,0)
                    if board%4==2: c=(0,0,1-0.2*chan)
                    if board%4==3: c=(1-0.2*chan,0,1-0.2*chan)
                else:
                    if chan==0: c="r"
                    if chan==1: c="g"
                    if chan==2: c="b"
                    if chan==3: c="m"
                pen = pg.mkPen(color=c) # add linewidth=1.0, alpha=.9
                line = self.ui.plot.plot(pen=pen,name=d.chtext+str(l))
            self.lines.append(line)
        #for the logic analyzer
        for l in np.arange(8):
            c=(0,0,0)
            pen = pg.mkPen(color=c) # add linewidth=1.7, alpha=.65
            line = self.ui.plot.plot(pen=None,name="logic_"+str(l)) # not drawn by default
            self.lines.append(line)
            if l==0: d.logicline1=len(self.lines)-1 # remember index where this first logic line is
        #other data to draw
        if d.fitline1>-1:
            pen = pg.mkPen(color="purple") # add linewidth=0.5, alpha=.5
            line = self.ui.plot.plot(pen=None,name="fitline1") # not drawn by default
            self.lines.append(line)
            d.fitline1=len(self.lines)-1 # remember index where this line is
        #other stuff
        d.setxaxis()
        d.setyaxis()
        #self.ui.plot.setRange(QtCore.QRectF(0, -10, 5000, 20)) 
        #self.ui.plot.setLabel('bottom', 'Index', units='B')
        self.ui.plot.showGrid(x=True, y=True)
        self.vline=0.0
        pen = pg.mkPen(color="k",width=1.0,style=QtCore.Qt.DashLine)
        line = self.ui.plot.plot([self.vline, self.vline], [-2.0, 2.0], pen=pen,name="trigger time vert")
        self.otherlines.append(line)
        self.hline = 0.0
        pen = pg.mkPen(color="k",width=1.0,style=QtCore.Qt.DashLine)
        line = self.ui.plot.plot( [-2.0, 2.0], [self.hline, self.hline], pen=pen,name="trigger thresh horiz")
        self.otherlines.append(line)
        self.hline2 = 0.0
        pen = pg.mkPen(color="b",width=1.0,style=QtCore.Qt.DashLine)
        line = self.ui.plot.plot( [-2.0, 2.0], [self.hline2, self.hline2], pen=None,name="trigger thresh2 horiz") # not drawn by default
        self.otherlines.append(line)
        if self.db: print "drew",len(self.otherlines),"lines in launch"
        
        """
    def drawtext(self):
        height = 0.25 # height up from bottom to start drawing text
        xpos = 1.02 # how far over to the right to draw
        if self.firstdrawtext:
            self.texts.append(self.ax.text(xpos, height, self.chantext(),horizontalalignment='left', verticalalignment='top',transform=self.ax.transAxes))
            self.firstdrawtext=False
        else:
            self.texts[0].remove()
            self.texts[0]=(self.ax.text(xpos, height, self.chantext(),horizontalalignment='left', verticalalignment='top',transform=self.ax.transAxes))
            #for txt in self.ax.texts: print txt # debugging
        self.needtoredrawtext=True
        plt.draw()        
        
    def onclick(self,event):
            if event.button==1: #left click                
                pass
            if event.button==2: #middle click
                if self.keyShift:# if shift is held, turn off threshold2
                    self.settriggerthresh2(0)
                    self.otherlines[2].set_visible(False)
                else:
                    self.hline2 = event.ydata
                    self.settriggerthresh2(int(  self.hline2/(self.yscale/256.) + 128  ))                
                    self.otherlines[2].set_visible(True) # starts off being hidden, so now show it!
                    self.otherlines[2].set_data( [self.min_x, self.max_x], [self.hline2, self.hline2] )
            if event.button==3: #right click
                self.settriggerpoint(int(  (event.xdata / (1000.0*pow(2,max(self.downsample,0))/self.clkrate/self.xscaling)) +self.num_samples/2  )) # downsample
                self.settriggerthresh(int(  event.ydata/(self.yscale/256.) + 128  ))
                self.vline = event.xdata
                self.otherlines[0].set_visible(True)
                self.otherlines[0].set_data( [self.vline, self.vline], [self.min_y, self.max_y] ) # vertical line showing trigger time
                self.hline = event.ydata
                self.otherlines[1].set_data( [self.min_x, self.max_x], [self.hline, self.hline] ) # horizontal line showing trigger threshold
            print('%s click: button=%d, x=%d, y=%d, xdata=%f, ydata=%f' % ('double' if event.dblclick else 'single', event.button, event.x, event.y, event.xdata, event.ydata))
        """
        
    def dostartstop(self):        
        if self.timer.isActive():
            self.timer.stop()
        else:
            self.timer.start(0)
        self.ui.textBrowser.setText("going on channel "+str(self.ui.spinBox.value()))
        
    def updateplot(self):
        self.mainloop()
        #channel=self.ui.spinBox.value()
        #self.curve.setData(d.xydata[channel][0],d.xydata[channel][1])
        
        for l in range(self.nlines):
            self.lines[l].setData(d.xydata[l][0],d.xydata[l][1])
        
        now = time.time()
        dt = now - self.lastTime
        self.lastTime = now
        if self.fps is None:
            self.fps = 1.0/dt
        else:
            s = np.clip(dt*3., 0, 1)
            self.fps = self.fps * (1-s) + (1.0/dt) * s
        self.ui.plot.setTitle('%0.2f fps' % self.fps)
        
        app.processEvents()
    
    nevents=0; oldnevents=0; tinterval=100.; oldtime=time.time()
    def mainloop(self):
        if d.paused: time.sleep(.1)
        else:
            if not d.getchannels(): return 0
            
            #print d.xydata[0][0][12], d.xydata[0][1][12] # print the x and y data, respectively, for the 13th sample on fast adc channel 0
            
            if self.savetofile:
                self.outf.write(str(self.nevents)); self.outf.write(",") # start of each line is the event number
                self.outf.write(str(time.time())); self.outf.write(",") # next column is the time in seconds of the current event
                d.xydata[0][1].tofile(self.outf,",",format="%.3f") # save y data (1) from fast adc channel 0
                self.outf.write("\n") # newline
            
            #if len(HaasoscopeLibQt.max10adcchans)>0: print "slow", d.xydataslow[0][0][99], d.xydataslow[0][1][99] # print the x and y data, respectively, for the 100th sample on slow max10 adc channel 0
            
            #if d.dolockin: print d.lockinamp, d.lockinphase # print the lockin info
            
            #if d.fftdrawn: # print some fft info (the freq with the biggest amplitude)
            #    fftxdata = d.fftfreqplot.get_xdata(); fftydata = d.fftfreqplot.get_ydata()
            #    maxfftydata=np.max(fftydata); maxfftfrq=fftxdata[fftydata.argmax()]
            #    print "max amp=",maxfftydata, "at freq=",maxfftfrq, d.fftax.get_xlabel().replace('Freq ','')
            
            if d.db: print time.time()-d.self.oldtime,"done with evt",self.nevents
            self.nevents += 1
            if self.nevents-self.oldnevents >= self.tinterval:
                elapsedtime=time.time()-self.oldtime
                lastrate = round(self.tinterval/elapsedtime,2)
                print self.nevents,"events,",lastrate,"Hz"
                self.oldtime=time.time()
                if lastrate>40: self.tinterval=500.
                else: self.tinterval=100.
                self.oldnevents=self.nevents
            if d.getone and not d.timedout: d.paused=True
                        
            #if elapsedtime>1.0:
            #   self.drawtext() #redraws the measurements
            
    def closeEvent(self, event):
        print "Handling closeEvent"
        self.timer.stop()
        d.cleanup()
        if self.savetofile: self.outf.close()
        
    def actionTest2(self):
        print "Handling actionTest2"
        self.ui.statusBar.showMessage("no!")
        #self.timer.stop()
        self.updateplot()

try:    
    win = MainWindow()
    win.setWindowTitle('Haasoscope Qt')
    if not d.setup_connections(): sys.exit()
    if not d.init(): sys.exit()
    win.launch()
    win.dostartstop()
except SerialException:
    print "serial com failed!"

#can change some things after initialization
#d.selectedchannel=0
#d.tellswitchgain(d.selectedchannel)
#d.togglesupergainchan(d.selectedchannel)
#d.toggletriggerchan(d.selectedchannel)
#d.togglelogicanalyzer() # run the logic analyzer
#d.sendi2c("21 13 f0") # set extra pins E24 B0,1,2,3 off and B4,5,6,7 on (works for v8 only)

if standalone:
    sys.exit(app.exec_())
else:
    print "Done, but Qt window still active"
