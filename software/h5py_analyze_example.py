import h5py
import time
import matplotlib.pyplot as plt

f=h5py.File('Haasoscope_out_20210930-135106.h5',"r") # can get from https://www.dropbox.com/s/uzmqxn81o9c74e2/Haasoscope_out_20210930-135106.h5?dl=1
nevents=len(f.keys()) #number of events stored
print(nevents,"events")
events=list(f.items())
def mysort(val): return int(val[0])
events.sort(key=mysort)

xdata=[]
ydata=[]
starttime=time.time()
nevents=4 # limit to running over first N events
for evtindex in range(0,nevents):
    e=events[evtindex] #get the event
    if evtindex == 0: print("first event:", e)
    evtnum=int(e[0])
    data=e[1]
    nsamples=data.shape[-1]
    lendatashape=len(data.shape)
    etime=data.attrs.get("time")
    for chan in range(0,4):
        if lendatashape == 3:
            xdata = data[chan][0]
            ydata = data[chan][1]
            print(evtindex,"event",evtnum,"time",etime,"nsamp",nsamples,"chan",chan,xdata,ydata)
        elif lendatashape == 2:
            ydata = data[chan]
            #print(evtindex,"event",evtnum,"time",etime,"nsamp",nsamples,"chan",chan,xdata,ydata)
        else: print("unknown data shape length",lendatashape,"!")
        if evtindex == 1:
            if chan == 0: plt.plot(xdata, ydata, label="chan 0")
            if chan == 1: plt.plot(xdata, ydata, label="chan 1")

f.close()
totaltime = time.time() - starttime
print("file closed... read",nevents,"events in",totaltime,"seconds")

plt.show()
