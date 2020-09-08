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
## not in p3??? reload(HaasoscopeLibQt) # in case you changed it, and to always load some defaults

#Some pre-options
#HaasoscopeLibQt.num_board = 2 # Number of Haasoscope boards to read out (default is 1)
#HaasoscopeLibQt.ram_width = 12 # width in bits of sample ram to use (e.g. 9==512 samples (default), 12(max)==4096 samples) (min is 2)
#HaasoscopeLibQt.max10adcchans =  [(0,110),(0,118)] #[(0,110),(0,118),(1,110),(1,118)] #max10adc channels to draw (board, channel on board), channels: 110=ain1, 111=pin6, ..., 118=pin14, 119=temp # default is none, []

d = HaasoscopeLibQt.Haasoscope()
d.construct()

#Some other options
#d.serport="COM7" # the name of the serial port on your computer, connected to Haasoscope, like /dev/ttyUSB0 or COM8, leave blank to detect automatically!
d.serialdelaytimerwait=300 #50 #100 #150 #300 # 600 # delay (in 2 us steps) between each 32 bytes of serial output (set to 600 for some slow USB serial setups, but 0 normally)
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
        self.ui.runButton.clicked.connect(self.dostartstop)
        self.ui.actionRecord.triggered.connect(self.record)
        self.ui.verticalSlider.valueChanged.connect(self.triggerlevelchanged)
        self.ui.verticalSlider2.valueChanged.connect(self.triggerlevel2changed)
        self.ui.thresh2Check.clicked.connect(self.thresh2)
        self.ui.horizontalSlider.valueChanged.connect(self.triggerposchanged)
        self.ui.rollingButton.clicked.connect(self.rolling)
        self.ui.singleButton.clicked.connect(self.single)
        self.ui.timeslowButton.clicked.connect(self.timeslow)
        self.ui.timefastButton.clicked.connect(self.timefast)
        self.ui.risingedgeCheck.stateChanged.connect(self.risingfalling)
        self.ui.exttrigCheck.stateChanged.connect(self.exttrig)
        self.ui.totBox.valueChanged.connect(self.tot)
        self.ui.autorearmCheck.stateChanged.connect(self.autorearm)
        self.ui.avgCheck.stateChanged.connect(self.avg)
        self.ui.logicCheck.stateChanged.connect(self.logic)
        self.ui.highresCheck.stateChanged.connect(self.highres)
        self.ui.usb2Check.stateChanged.connect(self.usb2)
        self.ui.gridCheck.stateChanged.connect(self.grid)
        self.ui.markerCheck.stateChanged.connect(self.marker)
        self.ui.resampBox.valueChanged.connect(self.resamp)
        self.ui.upposButton.clicked.connect(self.uppos)
        self.ui.downposButton.clicked.connect(self.downpos)
        self.ui.chanBox.valueChanged.connect(self.selectchannel)
        self.ui.dacBox.valueChanged.connect(self.setlevel)
        self.ui.minidisplayCheck.stateChanged.connect(self.minidisplay)
        self.ui.acdcCheck.stateChanged.connect(self.acdc)
        self.ui.gainCheck.stateChanged.connect(self.gain)
        self.ui.supergainCheck.stateChanged.connect(self.supergain)
        self.ui.actionRead_from_file.triggered.connect(self.actionRead_from_file)
        self.ui.actionStore_to_file.triggered.connect(self.actionStore_to_file)
        self.ui.actionDo_autocalibration.triggered.connect(self.actionDo_autocalibration)
        self.ui.chanonCheck.stateChanged.connect(self.chanon)
        self.ui.trigchanonCheck.stateChanged.connect(self.trigchanon)
        self.ui.oversampCheck.clicked.connect(self.oversamp)
        self.ui.overoversampCheck.clicked.connect(self.overoversamp)
        self.db=False
        self.lastTime = time.time()
        self.fps = None
        self.lines = []
        self.otherlines = []
        self.savetofile=False # save scope data to file
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.updateplot)
        self.timer2 = QtCore.QTimer()
        self.timer2.timeout.connect(self.drawtext)
        self.selectchannel()
        self.ui.statusBar.showMessage("Hello!")
        self.show()

    def selectchannel(self):
        d.selectedchannel=self.ui.chanBox.value()
        self.ui.dacBox.setValue(d.chanlevel[d.selectedchannel])
        
        if d.chanforscreen == d.selectedchannel:   self.ui.minidisplayCheck.setCheckState(QtCore.Qt.Checked)
        else:   self.ui.minidisplayCheck.setCheckState(QtCore.Qt.Unchecked)
        if d.acdc[d.selectedchannel]:   self.ui.acdcCheck.setCheckState(QtCore.Qt.Unchecked)
        else:   self.ui.acdcCheck.setCheckState(QtCore.Qt.Checked)
        if d.gain[d.selectedchannel]:   self.ui.gainCheck.setCheckState(QtCore.Qt.Unchecked)
        else:   self.ui.gainCheck.setCheckState(QtCore.Qt.Checked)
        if d.supergain[d.selectedchannel]:   self.ui.supergainCheck.setCheckState(QtCore.Qt.Unchecked)
        else:   self.ui.supergainCheck.setCheckState(QtCore.Qt.Checked)
        if d.havereadswitchdata: self.ui.supergainCheck.setEnabled(False)
        
        chanonboard = d.selectedchannel%HaasoscopeLibQt.num_chan_per_board
        theboard = int(HaasoscopeLibQt.num_board-1-d.selectedchannel/HaasoscopeLibQt.num_chan_per_board)
        if d.havereadswitchdata:
            if d.testBit(d.switchpos[theboard],chanonboard):   self.ui.ohmCheck.setCheckState(QtCore.Qt.Unchecked)
            else:   self.ui.ohmCheck.setCheckState(QtCore.Qt.Checked)
            
        if d.dousb:   self.ui.usb2Check.setCheckState(QtCore.Qt.Checked)
        else:   self.ui.usb2Check.setCheckState(QtCore.Qt.Unchecked)
        
        if len(self.lines)>0:
            if self.lines[d.selectedchannel].isVisible():   self.ui.chanonCheck.setCheckState(QtCore.Qt.Checked)
            else:   self.ui.chanonCheck.setCheckState(QtCore.Qt.Unchecked)
        if d.trigsactive[d.selectedchannel]:   self.ui.trigchanonCheck.setCheckState(QtCore.Qt.Checked)
        else:   self.ui.trigchanonCheck.setCheckState(QtCore.Qt.Unchecked)
        
        if d.dooversample[d.selectedchannel]>0:   self.ui.oversampCheck.setCheckState(QtCore.Qt.Checked)
        else:   self.ui.oversampCheck.setCheckState(QtCore.Qt.Unchecked)
        if d.selectedchannel%HaasoscopeLibQt.num_chan_per_board>1:   self.ui.oversampCheck.setEnabled(False)
        else:  self.ui.oversampCheck.setEnabled(True)
        
        if d.dooversample[d.selectedchannel]>=9:   self.ui.overoversampCheck.setCheckState(QtCore.Qt.Checked)
        else:   self.ui.overoversampCheck.setCheckState(QtCore.Qt.Unchecked)
        if d.selectedchannel%HaasoscopeLibQt.num_chan_per_board>0:  self.ui.overoversampCheck.setEnabled(False)
        else:   self.ui.overoversampCheck.setEnabled(True)
    
    def oversamp(self):
        if d.oversamp(d.selectedchannel)>=0:
            self.prepareforsamplechange()
            self.timechanged()
            #turn off chan+2
            self.lines[d.selectedchannel+2].setVisible(False)
            if d.trigsactive[d.selectedchannel+2]: d.toggletriggerchan(d.selectedchannel+2)
    
    def overoversamp(self):
        if d.overoversamp()>=0:
            self.prepareforsamplechange()
            self.timechanged()
            #turn off chan+1
            self.lines[d.selectedchannel+1].setVisible(False)
            if d.trigsactive[d.selectedchannel+1]: d.toggletriggerchan(d.selectedchannel+2)
    
    def chanon(self):
        if self.ui.chanonCheck.checkState() == QtCore.Qt.Checked:
            self.lines[d.selectedchannel].setVisible(True)
            self.ui.trigchanonCheck.setCheckState(QtCore.Qt.Checked)
        else:
            self.lines[d.selectedchannel].setVisible(False)
            self.ui.trigchanonCheck.setCheckState(QtCore.Qt.Unchecked)
        
    def trigchanon(self):
        if self.ui.trigchanonCheck.checkState() == QtCore.Qt.Checked:
            if not d.trigsactive[d.selectedchannel]: d.toggletriggerchan(d.selectedchannel)
        else:
             if d.trigsactive[d.selectedchannel]: d.toggletriggerchan(d.selectedchannel)
    
    def acdc(self):
        if self.ui.acdcCheck.checkState() == QtCore.Qt.Checked: #ac coupled
            if d.acdc[d.selectedchannel]:
                d.setacdc()
        if self.ui.acdcCheck.checkState() == QtCore.Qt.Unchecked: #dc coupled
            if not d.acdc[d.selectedchannel]:
                d.setacdc()
    
    def gain(self):
        if self.ui.gainCheck.checkState() == QtCore.Qt.Checked: #x10
            if d.gain[d.selectedchannel]:
                d.tellswitchgain(d.selectedchannel)
        if self.ui.gainCheck.checkState() == QtCore.Qt.Unchecked: #x1
            if not d.gain[d.selectedchannel]:
                d.tellswitchgain(d.selectedchannel)
 
    def supergain(self):
        if self.ui.supergainCheck.checkState() == QtCore.Qt.Checked: #x100
            if d.supergain[d.selectedchannel]:
                d.togglesupergainchan(d.selectedchannel)
        if self.ui.supergainCheck.checkState() == QtCore.Qt.Unchecked: #x1
            if not d.supergain[d.selectedchannel]:
                d.togglesupergainchan(d.selectedchannel)
                   
    def minidisplay(self):
        if self.ui.minidisplayCheck.checkState()==QtCore.Qt.Checked:
            if d.chanforscreen != d.selectedchannel:
                d.tellminidisplaychan(d.selectedchannel)
    
    def posamount(self):
        amount=10
        modifiers = app.keyboardModifiers()
        if modifiers == QtCore.Qt.ShiftModifier:
            amount*=5
        elif modifiers == QtCore.Qt.ControlModifier:
            amount/=10
        return amount
    def uppos(self):
         d.adjustvertical(True,self.posamount())
         self.ui.dacBox.setValue(d.chanlevel[d.selectedchannel])
    def downpos(self):
         d.adjustvertical(False,self.posamount())
         self.ui.dacBox.setValue(d.chanlevel[d.selectedchannel])
    def setlevel(self):
        if d.chanlevel[d.selectedchannel] != self.ui.dacBox.value():
            d.chanlevel[d.selectedchannel] = self.ui.dacBox.value()
            d.rememberdacvalue()
            d.setdacvalue()
    
    def wheelEvent(self, event): #QWheelEvent
        if hasattr(event,"delta"):
            if event.delta()>0: self.uppos()
            else: self.downpos()
        elif hasattr(event,"angleDelta"):
            if event.angleDelta()>0: self.uppos()
            else: self.downpos()
    
    def keyPressEvent(self, event):
        if event.key()==QtCore.Qt.Key_Up:
            self.uppos()
        if event.key()==QtCore.Qt.Key_Down:
            self.downpos()
        if event.key()==QtCore.Qt.Key_Left:
            self.timefast()
        if event.key()==QtCore.Qt.Key_Right:
            self.timeslow()
            
    def actionRead_from_file(self):
        d.readcalib()
        
    def actionStore_to_file(self):
        d.storecalib()
        
    def actionDo_autocalibration(self):
        print("starting autocalibration")
        d.autocalibchannel=0
        
    def exttrig(self):
         d.toggleuseexttrig()
         
    def tot(self):
        d.triggertimethresh = self.ui.totBox.value()
        d.settriggertime(d.triggertimethresh)
        
    def autorearm(self):
        d.toggleautorearm()
        
    def avg(self):
        d.average = not d.average
        print("average",d.average)
        
    def logic(self):
        d.togglelogicanalyzer()
        if d.dologicanalyzer:
             for l in np.arange(8):
                c=(0,0,0)
                pen = pg.mkPen(color=c) # add linewidth=1.7, alpha=.65
                self.lines[d.logicline1+l].setPen(pen)
        else:
            for l in np.arange(8):
                self.lines[d.logicline1+l].setPen(None)
        
    def highres(self):
        d.togglehighres()
        
    def usb2(self):
        if self.ui.usb2Check.checkState() == QtCore.Qt.Checked:
            if not d.dousb:
                d.toggledousb()
        else:
            if d.dousb:
                d.toggledousb()
        
    def grid(self):
        if self.ui.gridCheck.isChecked():
            self.ui.plot.showGrid(x=True, y=True)
        else:
            self.ui.plot.showGrid(x=False, y=False)
            
    def marker(self):
         if self.ui.markerCheck.isChecked():
            for l in range(self.nlines):
                self.lines[l].setSymbol("o")
         else:
            for l in range(self.nlines):
                self.lines[l].setSymbol(None)
                
    def resamp(self):
        d.sincresample = self.ui.resampBox.value()
        if d.sincresample>0: d.xydata=np.empty([HaasoscopeLibQt.num_chan_per_board*HaasoscopeLibQt.num_board,2,d.sincresample*(d.num_samples-1)],dtype=float)
        else: d.xydata=np.empty([HaasoscopeLibQt.num_chan_per_board*HaasoscopeLibQt.num_board,2,1*(d.num_samples-1)],dtype=float)
        self.prepareforsamplechange();
    
    def dostartstop(self):        
        if d.paused:
            self.timer.start(20)
            self.timer2.start(1000)
            d.paused=False
            self.ui.runButton.setChecked(True)            
        else:
            self.timer.stop()
            self.timer2.stop()
            d.paused=True
            self.ui.runButton.setChecked(False)
    
    def prepareforsamplechange(self): #called when sampling is changed, to reset some things
        d.recordedchannel=[]
        #if d.doxyplot:
          #  plt.close(self.figxy)
        #if d.recorddata:
          #  plt.close(self.fig2d)
        
    def triggerlevelchanged(self,value):
        d.settriggerthresh(value)
        self.hline = (float(  value-128  )*d.yscale/256.)
        self.otherlines[1].setData( [d.min_x, d.max_x], [self.hline, self.hline] ) # horizontal line showing trigger threshold
    
    def triggerlevel2changed(self,value):
        d.settriggerthresh2(value)                
        self.hline2 =(float(  value-128  )*d.yscale/256.)
        self.otherlines[2].setVisible(True) # starts off being hidden, so now show it!
        self.otherlines[2].setData( [d.min_x, d.max_x], [self.hline2, self.hline2] )
        
    def thresh2(self):
        if self.ui.thresh2Check.checkState() == QtCore.Qt.Checked:
            self.ui.verticalSlider2.setEnabled(True)
            self.otherlines[2].setVisible(True)
        else:
            self.ui.verticalSlider2.setValue(0)
            self.ui.verticalSlider2.setEnabled(False)
            self.otherlines[2].setVisible(False)
    
    def triggerposchanged(self,value):
        if value>253 or value<3: return
        offset=5.0 # trig to readout delay
        scal = d.num_samples/256.
        point = value*scal + offset/pow(2,d.downsample)
        if d.downsample<0: point = 128*scal + (point-128*scal)*pow(2,d.downsample)
        d.settriggerpoint(int(point))
        self.vline = float(  2*(value-128)/256. *d.xscale /d.xscaling)
        self.otherlines[0].setData( [self.vline, self.vline], [d.min_y, d.max_y] ) # vertical line showing trigger time
    
    def rolling(self):
         d.rolltrigger = not d.rolltrigger
         d.tellrolltrig(d.rolltrigger)
         self.ui.rollingButton.setChecked(d.rolltrigger)
         if d.rolltrigger: self.ui.rollingButton.setText("Rolling/Auto")
         else: self.ui.rollingButton.setText("Normal")
         app.processEvents()
        
    def single(self):
        d.getone = not d.getone
        self.ui.singleButton.setChecked(d.getone)
        
    def timefast(self):
        amount=1
        modifiers = app.keyboardModifiers()
        if modifiers == QtCore.Qt.ShiftModifier:
            amount*=5
        d.telldownsample(d.downsample-amount)
        self.timechanged()
    
    def timeslow(self):
        amount=1
        modifiers = app.keyboardModifiers()
        if modifiers == QtCore.Qt.ShiftModifier:
            amount*=5
        d.telldownsample(d.downsample+amount)
        self.timechanged()
    
    def timechanged(self):
        self.ui.plot.setRange(xRange=(d.min_x, d.max_x), yRange=(d.min_y, d.max_y)) 
        self.ui.plot.setMouseEnabled(x=False,y=False)
        self.ui.plot.setLabel('bottom', d.xlabel)
        self.ui.plot.setLabel('left', d.ylabel)
        self.triggerposchanged(self.ui.horizontalSlider.value())
        self.ui.timebaseBox.setText("downsample "+str(d.downsample))
        
    def risingfalling(self):
        d.fallingedge=not self.ui.risingedgeCheck.checkState()
        d.settriggertype(d.fallingedge)
        
    def record(self):
        self.savetofile = not self.savetofile
        if self.savetofile:
            fname="Haasoscope_out_"+time.strftime("%Y%m%d-%H%M%S")+".csv"
            self.outf = open(fname,"wt")
            self.ui.statusBar.showMessage("now recording to file"+fname)
            self.ui.actionRecord.setText("Stop recording")
        else:
            self.outf.close()
            self.ui.statusBar.showMessage("stopped recording to file")
            self.ui.actionRecord.setText("Record to file")
    
    def fastadclineclick(self, curve):
        for l in range(self.nlines):
            if curve is self.lines[l].curve:
                maxchan=l-HaasoscopeLibQt.num_chan_per_board*HaasoscopeLibQt.num_board
                if maxchan>=0: # these are the slow ADC channels
                    self.ui.slowchanBox.setValue(maxchan)
                    #print "selected slow curve", maxchan
                else:
                    self.ui.chanBox.setValue(l)
                    #print "selected curve", l
                    modifiers = app.keyboardModifiers()
                    if modifiers == QtCore.Qt.ShiftModifier:
                        self.ui.trigchanonCheck.toggle()
                    elif modifiers == QtCore.Qt.ControlModifier:
                        self.ui.chanonCheck.toggle()
    
    """ TODO:
            elif event.key=="ctrl+x": 
                for chan in range(num_chan_per_board*num_board): self.tellswitchgain(chan)
            elif event.key=="ctrl+X": 
                for chan in range(num_chan_per_board*num_board): self.selectedchannel=chan; self.togglesupergainchan(chan)
            
            elif event.key=="D": self.decode(); return
            
            elif event.key=="ctrl+r": 
                if self.ydatarefchan<0: self.ydatarefchan=self.selectedchannel
                else: self.ydatarefchan=-1
            elif event.key==">": self.refsinchan=self.selectedchannel; self.oldchanphase=-1.; self.reffreq=0;
            
            elif event.key=="Y": 
                if self.selectedchannel+1>=len(self.dooversample): print "can't do XY plot on last channel"
                else:
                    if self.dooversample[self.selectedchannel]==self.dooversample[self.selectedchannel+1]:
                        self.doxyplot=True; self.xychan=self.selectedchannel; print "doxyplot now",self.doxyplot,"for channel",self.xychan; return;
                    else: print "oversampling settings must match between channels for XY plotting"
                self.keyShift=False
            elif event.key=="Z": self.recorddata=True; self.recorddatachan=self.selectedchannel; self.recordedchannel=[]; print "recorddata now",self.recorddata,"for channel",self.recorddatachan; self.keyShift=False; return;
            elif event.key=="F": self.fftchan=self.selectedchannel; self.dofft=True; self.keyShift=False; return
    """
    
    def launch(self):        
        self.ui.plot.setBackground('w')
        self.nlines = HaasoscopeLibQt.num_chan_per_board*HaasoscopeLibQt.num_board+len(HaasoscopeLibQt.max10adcchans)
        if self.db: print("nlines=",self.nlines)
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
                board=int(l/4)
                if self.db: print("chan =",chan,"and board =",board)
                if HaasoscopeLibQt.num_board>1:                    
                    if board%4==0: c=(255-0.2*255*chan,0,0)
                    if board%4==1: c=(0,255-0.2*255*chan,0)
                    if board%4==2: c=(0,0,255-0.2*255*chan)
                    if board%4==3: c=(255-0.2*255*chan,0,255-0.2*255*chan)
                else:
                    if chan==0: c="r"
                    if chan==1: c="g"
                    if chan==2: c="b"
                    if chan==3: c="m"
                pen = pg.mkPen(color=c) # add linewidth=1.0, alpha=.9
                line = self.ui.plot.plot(pen=pen,name=d.chtext+str(l))
            line.curve.setClickable(True)
            line.curve.sigClicked.connect(self.fastadclineclick)
            self.lines.append(line)
        self.ui.chanBox.setMaximum(HaasoscopeLibQt.num_chan_per_board*HaasoscopeLibQt.num_board-1)
        self.ui.slowchanBox.setMaximum(len(HaasoscopeLibQt.max10adcchans)-1)
        #for the logic analyzer
        for l in np.arange(8):
            line = self.ui.plot.plot(pen=None,name="logic_"+str(l)) # not drawn by default
            self.lines.append(line)
            if l==0: d.logicline1=len(self.lines)-1 # remember index where this first logic line is
        #other data to draw
        if d.fitline1>-1:
            pen = pg.mkPen(color="purple") # add linewidth=0.5, alpha=.5
            line = self.ui.plot.plot(pen=pen,name="fitline1") # not drawn by default
            line.setVisible(False)
            self.lines.append(line)
            d.fitline1=len(self.lines)-1 # remember index where this line is
        #trigger lines
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
        line = self.ui.plot.plot( [-2.0, 2.0], [self.hline2, self.hline2], pen=pen,name="trigger thresh2 horiz") # not drawn by default
        line.setVisible(False)
        self.otherlines.append(line)
        #other stuff
        d.setxaxis()
        d.setyaxis()
        self.timechanged()
        self.ui.plot.showGrid(x=True, y=True)
    
    def closeEvent(self, event):
        print("Handling closeEvent")
        self.timer.stop()
        self.timer2.stop()
        d.cleanup()
        if self.savetofile: self.outf.close()
        
    def updateplot(self):
        self.mainloop()        
        for l in range(self.nlines):
            maxchan=l-HaasoscopeLibQt.num_chan_per_board*HaasoscopeLibQt.num_board
            if maxchan>=0: # these are the slow ADC channels
                self.lines[l].setData(d.xydataslow[maxchan][0],d.xydataslow[maxchan][1])
            else:
                self.lines[l].setData(d.xydata[l][0],d.xydata[l][1])
        if d.dologicanalyzer:
             for l in np.arange(8):
                 self.lines[d.logicline1+l].setData(d.xydatalogic[l][0],d.xydatalogic[l][1])
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
    
    def dosavetofile(self):
        time_s=str(time.time())
        for c in range(HaasoscopeLibQt.num_chan_per_board*HaasoscopeLibQt.num_board):
            if self.lines[c].isVisible(): # only save the data for visible channels
                self.outf.write(str(self.nevents)); self.outf.write(",") # start of each line is the event number
                self.outf.write(time_s); self.outf.write(",") # next column is the time in seconds of the current event
                self.outf.write(str(c)); self.outf.write(",") # next column is the channel number
                self.outf.write(str(self.vline*d.xscaling)); self.outf.write(",") # next column is the trigger time
                self.outf.write(str( 2.*d.xscale/d.num_samples ) ); self.outf.write(",") # next column is the time between samples, in ns
                self.outf.write(str(d.num_samples)); self.outf.write(",") # next column is the number of samples
                d.xydata[c][1].tofile(self.outf,",",format="%.3f") # save y data (1) from fast adc channel c
                self.outf.write("\n") # newline
    
    nevents=0
    oldnevents=0
    tinterval=100.
    oldtime=time.time()
    def mainloop(self):
        if d.paused: time.sleep(.1)
        else:
            try:
                status=d.getchannels()
            except SerialException:
                sys.exit(1)
            if status==2:#we updated the switch data
                self.selectchannel()
            
            #print d.xydata[0][0][12], d.xydata[0][1][12] # print the x and y data, respectively, for the 13th sample on fast adc channel 0
            
            if self.savetofile: self.dosavetofile()
            
            #if len(HaasoscopeLibQt.max10adcchans)>0: print "slow", d.xydataslow[0][0][99], d.xydataslow[0][1][99] # print the x and y data, respectively, for the 100th sample on slow max10 adc channel 0
            
            #if d.dolockin: print d.lockinamp, d.lockinphase # print the lockin info
            
            #if d.fftdrawn: # print some fft info (the freq with the biggest amplitude)
            #    fftxdata = d.fftfreqplot.get_xdata(); fftydata = d.fftfreqplot.get_ydata()
            #    maxfftydata=np.max(fftydata); maxfftfrq=fftxdata[fftydata.argmax()]
            #    print "max amp=",maxfftydata, "at freq=",maxfftfrq, d.fftax.get_xlabel().replace('Freq ','')
            
            if d.db: print(time.time()-d.self.oldtime,"done with evt",self.nevents)
            self.nevents += 1
            if self.nevents-self.oldnevents >= self.tinterval:
                now=time.time()
                elapsedtime=now-self.oldtime
                self.oldtime=now
                lastrate = round(self.tinterval/elapsedtime,2)
                print(self.nevents,"events,",lastrate,"Hz")
                if lastrate>40: self.tinterval=500.
                else: self.tinterval=100.
                self.oldnevents=self.nevents
            if d.getone and not d.timedout: self.dostartstop()

    def drawtext(self):
        self.ui.textBrowser.setText(d.chantext())

try:    
    win = MainWindow()
    win.setWindowTitle('Haasoscope Qt')
    if not d.setup_connections(): sys.exit()
    if not d.init(): sys.exit()
    win.launch()
    win.triggerposchanged(128) # center the trigger
    win.dostartstop()
except SerialException:
    print("serial com failed!")

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
    print("Done, but Qt window still active")

