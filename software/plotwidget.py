# -*- coding: utf-8 -*-
"""
pyqtgraph widget with UI template created with Qt Designer
"""

import pyqtgraph as pg
from pyqtgraph.Qt import QtCore, QtGui
import numpy as np
import os, sys
from pyqtgraph.ptime import time

app = QtGui.QApplication.instance()
standalone = app is None
if standalone:
    app = QtGui.QApplication(sys.argv)

# Define main window class from template
WindowTemplate, TemplateBaseClass = pg.Qt.loadUiType("plotwidget.ui")

class MainWindow(TemplateBaseClass):  
    def __init__(self):
        TemplateBaseClass.__init__(self)
        
        # Create the main window
        self.ui = WindowTemplate()
        self.ui.setupUi(self)
        self.ui.plotBtn.clicked.connect(self.doplot)        
        self.show()
        
        self.data = np.random.normal(size=(50,5000))
        self.ptr = 0
        self.lastTime = time()
        self.fps = None
        
        self.ui.plot.setRange(QtCore.QRectF(0, -10, 5000, 20)) 
        self.ui.plot.setLabel('bottom', 'Index', units='B')
        self.curve = self.ui.plot.plot()
        
    def doplot(self):
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.updateplot)
        self.timer.start(0)
        
    def updateplot(self):
        self.curve.setData(self.data[self.ptr%10])
        self.ptr += 1
        now = time()
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
        
win = MainWindow()
win.setWindowTitle('pyqtgraph example: PlotSpeedTest')

if standalone:
    sys.exit(app.exec_())
else:
    print "We're back with the Qt window still active"
