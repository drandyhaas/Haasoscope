# -*- coding: utf-8 -*-
"""
pyqtgraph widget with UI template created with Qt Designer
"""

import pyqtgraph as pg
from pyqtgraph.Qt import QtCore, QtGui
import numpy as np
import os, sys, time
from serial import SerialException

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
#d.serialdelaytimerwait=0 #50 #100 #150 #300 # 600 # delay (in 2 us steps) between each 32 bytes of serial output (set to 600 for some slow USB serial setups, but 0 normally)
#d.dolockin=True # whether to calculate the lockin info on the FPGA and read it out (off by default)
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

        self.lastTime = time.time()
        self.fps = None
            
    def launch(self):
        #self.ui.plot.setRange(QtCore.QRectF(0, -10, 5000, 20)) 
        self.ui.plot.setLabel('bottom', 'Index', units='B')
        self.curve = self.ui.plot.plot()
        
        """            
    def on_launch_draw(self):
        plt.ion() #turn on interactive mode
        self.nlines = num_chan_per_board*num_board+len(max10adcchans)
        if self.db: print "nlines=",self.nlines
        self.figure, self.ax = plt.subplots(1)
        for l in np.arange(self.nlines):
            maxchan=l-num_chan_per_board*num_board
            c=(0,0,0)
            if maxchan>=0: # these are the slow ADC channels
                if num_board>1:
                    board = int(num_board-1-max10adcchans[maxchan][0])
                    if board%4==0: c=(1-0.1*maxchan,0,0)
                    if board%4==1: c=(0,1-0.1*maxchan,0)
                    if board%4==2: c=(0,0,1-0.1*maxchan)
                    if board%4==3: c=(1-0.1*maxchan,0,1-0.1*maxchan)
                else:
                    c=(0.1*(maxchan+1),0.1*(maxchan+1),0.1*(maxchan+1))
                line, = self.ax.plot([],[], '-', label=str(max10adcchans[maxchan]), color=c, linewidth=0.5, alpha=.5)
            else: # these are the fast ADC channels
                chan=l%4
                if num_board>1:
                    board=l/4
                    if board%4==0: c=(1-0.2*chan,0,0)
                    if board%4==1: c=(0,1-0.2*chan,0)
                    if board%4==2: c=(0,0,1-0.2*chan)
                    if board%4==3: c=(1-0.2*chan,0,1-0.2*chan)
                else:
                    if chan==0: c="red"
                    if chan==1: c="green"
                    if chan==2: c="blue"
                    if chan==3: c="magenta"
                line, = self.ax.plot([],[], '-', label=self.chtext+str(l), color=c, linewidth=1.0, alpha=.9)
            self.lines.append(line)
        #for the logic analyzer
        for l in np.arange(8):
            c=(0,0,0)
            line, = self.ax.plot([],[], '-', label="_logic"+str(l)+"_", color=c, linewidth=1.7, alpha=.65) # the leading and trailing "_"'s mean don't show in the legend
            line.set_visible(False)
            self.lines.append(line)
            if l==0: self.logicline1=len(self.lines)-1 # remember index where this first logic line is
        #other data to draw
        if self.fitline1>-1:
            line, = self.ax.plot([],[], '-', label="fit data", color="purple", linewidth=0.5, alpha=.5)
            self.lines.append(line)
            self.fitline1=len(self.lines)-1 # remember index where this line is
        #other stuff
        if hasattr(self,'ax'): self.setxaxis(self.ax,self.figure)
        self.setyaxis();
        self.ax.grid(True)
        self.vline=0
        otherline , = self.ax.plot([self.vline, self.vline], [-2, 2], 'k--', lw=1)#,label='trigger time vert')
        self.otherlines.append(otherline)
        self.hline = 0
        otherline , = self.ax.plot( [-2, 2], [self.hline, self.hline], 'k--', lw=1)#,label='trigger thresh horiz')
        self.otherlines.append(otherline)
        self.hline2 = 0
        otherline , = self.ax.plot( [-2, 2], [self.hline2, self.hline2], 'k--', lw=1, color='blue')#, label='trigger2 thresh horiz')
        otherline.set_visible(False)
        self.otherlines.append(otherline)
        if self.db: print "drew lines in launch",len(self.otherlines)
        self.figure.canvas.mpl_connect('button_press_event', self.onclick)
        self.figure.canvas.mpl_connect('key_press_event', self.onpress)
        self.figure.canvas.mpl_connect('key_release_event', self.onrelease)
        self.figure.canvas.mpl_connect('pick_event', self.onpick)
        self.figure.canvas.mpl_connect('scroll_event', self.onscroll)
        self.leg = self.ax.legend(loc='upper left', bbox_to_anchor=(1.02, 1),
              ncol=1, borderaxespad=0, fancybox=False, shadow=False, fontsize=10)
        self.leg.get_frame().set_alpha(0.4)
        self.figure.subplots_adjust(right=0.76)
        self.figure.subplots_adjust(left=.10)
        self.figure.subplots_adjust(top=.95)
        self.figure.subplots_adjust(bottom=.10)
        self.figure.canvas.set_window_title('Haasoscope')        
        self.lined = dict()
        channum=0
        for legline, origline in zip(self.leg.get_lines(), self.lines):
            legline.set_picker(5)  # 5 pts tolerance
            legline.set_linewidth(2.0)
            origline.set_picker(5)
            #save a reference to the plot line and legend line and channel number, accessible from either line or the channel number
            self.lined[legline] = (origline,legline,channum)
            self.lined[origline] = (origline,legline,channum)
            self.lined[channum] = (origline,legline,channum)
            channum+=1        
        self.drawtext()
        self.figure.canvas.mpl_connect('close_event', self.handle_main_close)
        self.figure.canvas.draw()
        #plt.show(block=False)
        
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
        
    def doplot(self):
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.updateplot)
        self.timer.start(0)
        self.ui.textBrowser.setText("going on channel "+str(self.ui.spinBox.value()))
        
    def updateplot(self):
        status = mainloop()
        channel=3
        self.curve.setData(d.xydata[channel][0],d.xydata[channel][1])
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
                        
            #if elapsedtime>1.0:
            #   self.drawtext() #redraws the measurements

try:    
    if not d.setup_connections(): sys.exit()
    if not d.init(): sys.exit()
    win.launch()
    
    #can change some things after initialization
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
