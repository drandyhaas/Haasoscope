d.doswitchdata = False
win.triggerlevelchanged(80+128)# 128 is middle

#turns off drawing
#win.ui.drawingCheck.setCheckState(QtCore.Qt.Unchecked)
#win.drawing()

d.settriggertime(100)  # Time over Threshold -> 100, target 1Hz for all boards

# time sample timebase -> 0 (horizontal scaling, represent the actual sampling rate of the ADC)
#d.telldownsample(0)
win.timefast()
win.timefast()

win.triggerposchanged(40) # 1-256 trigger time aligned closer to the left (1x to the left, ~5x to the right) slider needs resetting

#win.rolling() # no rolling trigger [button] (record only on trigger) dont have channel 0 on board 0 error
d.rolltrigger = not d.rolltrigger
#d.tellrolltrig(d.rolltrigger)

win.risingfalling() # rising edge [checkbox] (as opposed to falling)
#win.ui.risingedgeCheck.blockSignals(True)
#win.ui.risingedgeCheck.setChecked(d.fallingedge)
#win.ui.risingedgeCheck.blockSignals(False)

win.doh5=True
#win.numrecordeventsperfile=100
win.record() # record to file (truncating and starting new files)
# and auto transfer

# think about 8 kB per event. compression