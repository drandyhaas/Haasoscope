import libs.HaasoscopeLib as HaasoscopeLib
reload(HaasoscopeLib) # in case you changed it, and to always load some defaults
import time, sys
import matplotlib.pyplot as plt
#import numpy as np
from serial import SerialException

#Some options
#HaasoscopeLib.num_board = 2 # Number of Haasoscope boards to read out (default is 1)
#HaasoscopeLib.ram_width = 12 # width in bits of sample ram to use (e.g. 9==512 samples (default), 12(max)==4096 samples) (min is 2)
#HaasoscopeLib.max10adcchans = [(0,110),(0,118),(1,110),(1,118)] #max10adc channels to draw (board, channel on board), channels: 110=ain1, 111=pin6, ..., 118=pin14, 119=temp # default is none, []

d = HaasoscopeLib.Haasoscope()

#Some other options
#d.serport="COM7" # the name of the serial port on your computer, connected to Haasoscope, like /dev/ttyUSB0 or COM8, leave blank to detect automatically!
#d.domaindrawing=False # whether to keep updating the main plot (on by default)
#d.serialdelaytimerwait=0 #50 #100 #150 #300 # 600 # delay (in 2 us steps) between each 32 bytes of serial output (set to 600 for some slow USB serial setups, but 0 normally)
#d.dolockin=True; d.dolockinplot=d.domaindrawing # whether to calculate the lockin info on the FPGA and read it out (off by default)

try:

    savetofile=False # save scope data to file
    if savetofile: outf = open("Haasoscope_out_"+time.strftime("%Y%m%d-%H%M%S")+".csv","wt")
    
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
    
    nevents=0; oldnevents=0; tinterval=100.; oldtime=time.time()
    while 1:
        if d.paused: time.sleep(.1)
        else:
            if not d.getchannels(): break
            
            #print d.xydata[0][0][12], d.xydata[0][1][12] # print the x and y data, respectively, for the 13th sample on fast adc channel 0
            
            if savetofile:
                outf.write(str(nevents)); outf.write(",") # start of each line is the event number
                outf.write(str(time.time())); outf.write(",") # next column is the time in seconds of the current event
                d.xydata[0][1].tofile(outf,",",format="%.3f") # save y data (1) from fast adc channel 0
                outf.write("\n") # newline
            
            #if len(HaasoscopeLib.max10adcchans)>0: print "slow", d.xydataslow[0][0][99], d.xydataslow[0][1][99] # print the x and y data, respectively, for the 100th sample on slow max10 adc channel 0
            
            #if d.dolockin: print d.lockinamp, d.lockinphase # print the lockin info
            
            #if d.fftdrawn: # print some fft info (the freq with the biggest amplitude)
            #    fftxdata = d.fftfreqplot.get_xdata(); fftydata = d.fftfreqplot.get_ydata()
            #    maxfftydata=np.max(fftydata); maxfftfrq=fftxdata[fftydata.argmax()]
            #    print "max amp=",maxfftydata, "at freq=",maxfftfrq, d.fftax.get_xlabel().replace('Freq ','')
            
            if d.db: print time.time()-d.oldtime,"done with evt",nevents
            nevents+=1
            if nevents-oldnevents >= tinterval:
                elapsedtime=time.time()-oldtime
                lastrate = round(tinterval/elapsedtime,2)
                print nevents,"events,",lastrate,"Hz"
                oldtime=time.time()
                if lastrate>40: tinterval=500.
                else: tinterval=100.
                oldnevents=nevents
            if d.getone and not d.timedout: d.paused=True
        d.redraw()
        if len(plt.get_fignums())==0:
            if d.domaindrawing: break # quit when all the plots have been closed
            elif nevents>50: break
except SerialException:
    print "serial com failed!"
finally:
    d.cleanup()
    if savetofile: outf.close()
