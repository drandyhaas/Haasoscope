import HaasoscopeLib
#reload(HaasoscopeLib) # in case you changed it
import time
import matplotlib.pyplot as plt

#Run the stuff!
d = HaasoscopeLib.Haasoscope()
d.construct()
d.domaindrawing=True # whether to keep updating the main plot
#d.dolockin=True; d.dolockinplot=False # whether to calculate the lockin info on the FPGA and read it out

try:
    d.setup_connections()
    d.init()
    d.on_launch()
    nevents=0; oldnevents=0; oldtime=time.clock(); tinterval=100.; oldtime=time.time()
    while 1:
        if d.paused: time.sleep(.1)
        else:
            if not d.getchannels(): break
            #print d.lines[0].get_xydata()[100] # print the x and y data for the 100th sample on channel 0
            #if d.dolockin: print d.lockinamp, d.lockinphase
            if d.db: print "done with evt",nevents,time.clock()
            nevents+=1
            if nevents-oldnevents >= tinterval:
                lastrate = round(tinterval/(time.time()-oldtime),2)
                print nevents,"events,",lastrate,"Hz"
                oldtime=time.time()
                if lastrate>40: tinterval=500.
                else: tinterval=100.
                oldnevents=nevents
            if d.getone: d.paused=True
        d.redraw()
        if not plt.get_fignums(): break # quit when all the plots have been closed
finally:
    d.cleanup()
