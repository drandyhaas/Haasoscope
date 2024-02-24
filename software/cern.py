d.doswitchdata = False
win.triggerlevelchanged(200)

#turns off drawing
#win.ui.drawingCheck.setCheckState(QtCore.Qt.Unchecked)
#win.drawing()

d.settriggertime(100)  # Time over Threshold -> 100
# trigger time aligned closer to the left
# time sample timebase ->0
# no rolling trigger [button]
# rising edge [checkbox]

#win.record() # record to file
