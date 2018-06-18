package com.felhr.serialportexample;

import android.Manifest;
import android.annotation.SuppressLint;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.support.v4.app.ActivityCompat;
import android.support.v4.view.GestureDetectorCompat;
import android.support.v7.app.AppCompatActivity;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.jjoe64.graphview.GraphView;
import com.jjoe64.graphview.series.DataPoint;
import com.jjoe64.graphview.series.DataPointInterface;
import com.jjoe64.graphview.series.LineGraphSeries;
import com.jjoe64.graphview.series.OnDataPointTapListener;
import com.jjoe64.graphview.series.Series;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.ref.WeakReference;
import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.util.Set;
import java.util.UUID;

import static com.felhr.serialportexample.UsbService.MESSAGE_FROM_SERIAL_PORT;

public class MainActivity extends AppCompatActivity {

    protected boolean findBT()
    {
        mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if(mBluetoothAdapter == null)
        {
            display.append("No bluetooth adapter available\n");
        }

        if(!mBluetoothAdapter.isEnabled())
        {
            Intent enableBluetooth = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            startActivityForResult(enableBluetooth, 0);
        }

        Set<BluetoothDevice> pairedDevices = mBluetoothAdapter.getBondedDevices();
        if(pairedDevices.size() > 0)
        {
            for(BluetoothDevice device : pairedDevices)
            {
                if(device.getName().equals("HC-05"))
                {
                    mmDevice = device;
                    display.append("Bluetooth Device Paired\n");
                    return true;
                }
            }
        }
        return false;
    }

    void openBT() throws IOException
    {
        UUID uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"); //Standard SerialPortService ID
        mmSocket = mmDevice.createRfcommSocketToServiceRecord(uuid);
        mmSocket.connect();
        mmOutputStream = mmSocket.getOutputStream();
        mmInputStream = mmSocket.getInputStream();

        beginListenForData();
        doingusb = false;
        display.append("Bluetooth Opened\n");
    }

    void beginListenForData()
    {
        final Handler handler = new Handler();

        stopWorker = false;
        workerThread = new Thread(new Runnable()
        {
            public void run()
            {
                int bytessofar=0;
                while(!Thread.currentThread().isInterrupted() && !stopWorker) {
                    try {
                        int bytesAvailable = mmInputStream.available();
                        if(bytesAvailable > 0) {
                            bytessofar+=bytesAvailable;
                            byte[] packetBytes = new byte[bytesAvailable];
                            //noinspection ResultOfMethodCallIgnored
                            mmInputStream.read(packetBytes);
                            mHandler.obtainMessage(MESSAGE_FROM_SERIAL_PORT, packetBytes).sendToTarget();
                            String data = byteArrayToHex(packetBytes);
                            String deb = "";
                            if (bytessofar==8) {
                                if (debugme) deb=" : sync";
                                bytessofar=0;
                            }
                            if (bytessofar==numsamples*4) {
                                if (debugme) deb=" : event";
                                bytessofar=0;
                            }
                            if (debugme) {
                                final String dataf = data + deb;
                                handler.post(new Runnable() {
                                    public void run() {
                                        display.append(dataf + "\n");
                                    }
                                });
                            }
                        }
                    }
                    catch (IOException ex){
                        stopWorker = true;
                    }
                }
            }
        });

        workerThread.start();
    }

    void sendData(int x) throws IOException
    {
        if (x>127) x -= 256; // since it goes to bytes as twos
        if (mmOutputStream!=null) mmOutputStream.write(x);
        //display.append(eventn+" Data Sent: "+x+"\n");
    }

    void closeBT() throws IOException
    {
        stopWorker = true;
        if (mmOutputStream!=null){
            mmOutputStream.close();
            mmInputStream.close();
            mmSocket.close();
        }
        //display.append("Bluetooth Closed\n");
    }

    protected UsbService usbService;
    protected TextView display;
    protected EditText editText;
    protected MyHandler mHandler;
    private GestureDetectorCompat mDetector;
    protected ToggleButton toggle_selectchan;
    protected LineGraphSeries<DataPoint> _series0;
    protected LineGraphSeries<DataPoint> _series1;
    protected LineGraphSeries<DataPoint> _series2;
    protected LineGraphSeries<DataPoint> _series3;
    protected LineGraphSeries<DataPoint> _series_hl;
    protected LineGraphSeries<DataPoint> _series_vl;
    protected GraphView graph;
    private int numsamples = (int)Math.pow(2,9)+1; // <4096 please, and odd (why?), and close to a power of 2 for FFT
    private int eventn = 0;
    private int downsample = 3;
    private boolean autogo = true;
    private boolean oldautogo = autogo;
    private ByteBuffer myserialBuffer; // for synchronizing serial data
    private String myboardid = "";
    private boolean synced = false;
    private double yscale = 7.5;
    private double clkrate = 125.0; // ADC sample rate in MHz
    private double xscaling = 1.0; // account for xaxis ns, us, ms
    protected float lastscreenX=0, lastscreenY=0;
    protected float lastscreenfracX=0, lastscreenfracY=0;
    protected int selectedchannel=-1; // the selected channel, or -1 if none
    protected boolean [] gain = {false,false,false,false}; // true if high gain
    protected int [] daclevel = {0,0,0,0}; // the dac level of each channel
    protected boolean doingfft = false;
    protected static final boolean debugme = false;

    BluetoothAdapter mBluetoothAdapter;
    BluetoothSocket mmSocket;
    BluetoothDevice mmDevice;
    OutputStream mmOutputStream;
    InputStream mmInputStream;
    Thread workerThread;
    volatile boolean stopWorker;

    @Override
    protected void onDestroy(){
        super.onDestroy();
        if (!doingusb) {
            try {closeBT();}
            catch (IOException ignored) { }
        }
    }

    // this function is called upon creation, and whenever the layout (e.g. portrait/landscape) changes
    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        mDetector = new GestureDetectorCompat(this, new MyGestureListener());

        if (savedInstanceState!=null) {
            autogo = savedInstanceState.getBoolean("autogo");
            doingfft = savedInstanceState.getBoolean("doingfft");
            downsample = savedInstanceState.getInt("downsample");
            lastscreenX = savedInstanceState.getFloat("lastscreenX");
            lastscreenY = savedInstanceState.getFloat("lastscreenY");
            doingusb = savedInstanceState.getBoolean("doingusb");
        }

        init_graph();
        setupgraph();

        graph.setOnTouchListener(new View.OnTouchListener(){
            public boolean onTouch(View v, MotionEvent event) {
                mDetector.onTouchEvent(event);
                if(event.getAction() == MotionEvent.ACTION_DOWN) {
                    lastscreenfracX = (event.getX()-graph.getGraphContentLeft())/graph.getGraphContentWidth();
                    lastscreenfracY = (event.getY()-graph.getGraphContentTop())/graph.getGraphContentHeight();
                    lastscreenX=(float)(graph.getViewport().getMinX(false)+lastscreenfracX*(graph.getViewport().getMaxX(false)-graph.getViewport().getMinX(false)));
                    lastscreenY= (float)(graph.getViewport().getMaxY(false)-lastscreenfracY*(graph.getViewport().getMaxY(false)-graph.getViewport().getMinY(false)));
                    //display.append("Touch "+String.valueOf(lastscreenX)+" "+String.valueOf(lastscreenY)+"\n");
                }
                return false;
            }
        });
        graph.setOnLongClickListener(new View.OnLongClickListener(){
            public boolean onLongClick(View v) {
                if (doingfft) return true;
                //display.append("Long click "+String.valueOf(lastscreenX)+" "+String.valueOf(lastscreenY)+"\n");
                graph.removeSeries(_series_hl);
                graph.removeSeries(_series_vl);
                add_vl_hl();
                int thresh = (int)(255*lastscreenfracY);
                if (thresh<0) thresh=0;
                if (thresh>255) thresh=255;
                waitalot();
                send2usb(127); send2usb(thresh);
                int tt = (int)((numsamples-1)*lastscreenfracX);
                if (tt<5) tt=5;
                if (tt>numsamples-5) tt=numsamples-5;
                tt+=Math.pow(2,12);//use the current timebase in the offset
                send2usb(121); send2usb(tt/256); send2usb(tt%256);
                display.append("Trig "+String.valueOf(thresh)+" "+String.valueOf(tt-Math.pow(2,12))+"\n");
                donewaitalot();
                return false;
            }
        });

        mHandler = new MyHandler(this);
        myserialBuffer= ByteBuffer.allocateDirect(numsamples*4*2);//for good luck

        editText = findViewById(R.id.editText1);
        display = findViewById(R.id.textView1);
        toggle_selectchan = findViewById(R.id.toggle_selectchan);
        final ImageButton button_up = findViewById(R.id.button_up);
        button_up.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                //display.append("up\n");
                waitalot(); downsample_plus(); donewaitalot();
            }
        });
        final ImageButton button_down = findViewById(R.id.button_down);
        button_down.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                //display.append("down\n");
                waitalot(); downsample_minus(); donewaitalot();
            }
        });
        final ImageButton button_share = findViewById(R.id.button_share);
        button_share.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                //display.append("share\n");
                if (isStoragePermissionGranted()){
                    graph.takeSnapshotAndShare(graph.getContext(), "Haasoscope share", "Haasoscope share");
                }
                else{
                    display.append("no permissions?\n");
                }
            }
        });
        final ImageButton button_pause = findViewById(R.id.button_pause);
        button_pause.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                //display.append("pause\n");
                waitalot();
                autogo = !oldautogo;
                oldautogo = autogo;
                donewaitalot();
            }
        });
        toggle_selectchan.setTextOff("-1");
        toggle_selectchan.setChecked(false);
        toggle_selectchan.invalidate();
        toggle_selectchan.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (selectedchannel>=0) {
                    myseries[selectedchannel].setThickness(thickness);
                    graph.invalidate();
                    selectedchannel = -1;
                    toggle_selectchan.setTextOff("-1");
                    toggle_selectchan.setChecked(false);
                    toggle_selectchan.invalidate();
                }
                else{
                    selectedchannel = 0;
                    myseries[selectedchannel].setThickness(2*thickness);
                    graph.invalidate();
                    toggle_selectchan.setTextOn("0");
                    toggle_selectchan.setChecked(true);
                    toggle_selectchan.invalidate();
                }
            }
        });
        if (getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE) {
            display.setVisibility(View.GONE);
        }
        else {
            display.setVisibility(View.VISIBLE);
        }
        final Button sendButton = findViewById(R.id.buttonSend);
        sendButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String data = editText.getText().toString();
                if (!data.equals("")) {
                    waitalot();
                    switch (data) {
                        case "G":
                        case "g":
                            send_initialize();
                            editText.setText("");
                            break;
                        case "p":
                        case "P":
                            autogo = !oldautogo;
                            oldautogo = autogo;
                            break;
                        case "f":
                        case "F":
                            doingfft = !doingfft;
                            display.append("dofft now = "+doingfft+"\n");
                            setupgraph();
                            break;
                        case "(":
                        case "( ":
                            downsample_plus();
                            break;
                        case ")":
                        case ") ":
                            downsample_minus();
                            break;
                        case "x":
                            send2usb(134);
                            send2usb(0);
                            togglegain(0);
                            send2usb(134);
                            send2usb(1);
                            togglegain(1);
                            send2usb(134);
                            send2usb(2);
                            togglegain(2);
                            send2usb(134);
                            send2usb(3);
                            togglegain(3);
                            break;
                        case "x0":
                            send2usb(134);
                            send2usb(0);
                            togglegain(0);
                            break;
                        case "x1":
                            send2usb(134);
                            send2usb(1);
                            togglegain(1);
                            break;
                        case "x2":
                            send2usb(134);
                            send2usb(2);
                            togglegain(2);
                            break;
                        case "x3":
                            send2usb(134);
                            send2usb(3);
                            togglegain(3);
                            break;
                        default:
                            display.append(data + "\n");
                            int di;
                            try {
                                di = Integer.parseInt(data);
                            } catch (NumberFormatException e) {
                                di = -1;
                            }
                            if (di >= 0 && di <= 255) {
                                send2usb(di); // only send if it was a positive integer, 0-255
                            }
                            else {
                                display.append("bad/unknown command!\n");
                                editText.setText("");
                            }
                            break;
                    }
                    donewaitalot();
                }
            }
        });

        if (findBT()) {
            try {
                openBT();
            } catch (IOException ex) {
                display.append("BT not opened\n");
            }
        }

        // a little kickstart for autogo...
        if (autogo) new kickstartThread().start();

        display.append("Haasoscope "+BuildConfig.VERSION_NAME+"\n");
    }

    private void togglegain(int chan){
        gain[chan]=!gain[chan];
        waitalittle();
        if (gain[chan]) setdac(chan,daclevel[chan]+800);
        else setdac(chan,daclevel[chan]-800);
    }

    private void downsample_plus(){
        if (downsample < 15) {
            downsample += 1;
            display.append("downsample is " + String.valueOf(downsample) + " \n");
            send2usb(124);
            send2usb(downsample);
            int ds = downsample - 3;
            if (ds < 1) ds = 1;
            if (ds > 8) ds = 8; // otherwise we timeout upon readout
            send2usb(125);
            send2usb(ds);
            setupgraph();
        }
    }

    private void downsample_minus(){
        if (downsample > 0) {
            downsample -= 1;
            display.append("downsample is " + String.valueOf(downsample) + " \n");
            send2usb(124);
            send2usb(downsample);
            int ds = downsample - 3;
            if (ds < 1) ds = 1;
            if (ds > 8) ds = 8; // otherwise we timeout upon readout
            send2usb(125);
            send2usb(ds);
            setupgraph();
        }
    }

    class MyGestureListener extends GestureDetector.SimpleOnGestureListener {
        @Override
        public boolean onDown(MotionEvent event) {
            return true;
        }
        @Override
        public boolean onFling(MotionEvent event1, MotionEvent event2,
                               float velocityX, float velocityY) {
            //display.append( "onFling: " + event1.toString() + event2.toString() +"\n" + velocityX + " " + velocityY +"\n");
            if (velocityX<-10000) {
                display.append("fling left\n");
                //waitalot(); downsample_minus(); donewaitalot();
                return true;
            }
            if (velocityX>10000) {
                display.append("fling right\n");
                //waitalot(); downsample_plus(); donewaitalot();
                return true;
            }
            if (selectedchannel>=0 && selectedchannel<=3){
                int dy = (int)(event2.getY() - event1.getY());
                display.append("dy = "+dy+"\n");
                waitalot();
                setdac(selectedchannel,daclevel[selectedchannel]+dy);
                donewaitalot();
            }

            return true;
        }
    }

    private boolean gotaneventlately=false;
    private class kickstartThread extends Thread {
        @Override
        public void run() {
            gotaneventlately=false;
            while (true) {
                try {
                    kickstartThread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                    return;
                }
                if (!gotaneventlately) {
                    send2usb(10);
                }
                else return;
            }
        }
    }

    @Override
    public void onSaveInstanceState(Bundle savedInstanceState) {
        super.onSaveInstanceState(savedInstanceState);
        // Save UI state changes to the savedInstanceState.
        savedInstanceState.putBoolean("autogo", autogo);
        savedInstanceState.putBoolean("doingfft",doingfft);
        savedInstanceState.putInt("downsample",downsample);
        savedInstanceState.putFloat("lastscreenX",lastscreenX);
        savedInstanceState.putFloat("lastscreenY",lastscreenY);
        savedInstanceState.putBoolean("doingusb",doingusb);
    }

    void send_initialize(){
        waitalittle();
        send2usb(0); send2usb(20); // board ID 0
        send2usb(30); send2usb(142); // get board ID
        waitalittle();
        if (doingusb) {
            send2usb(135); send2usb(3); send2usb(100); // serialdelaytimerwait
        }
        else {
            send2usb(135); send2usb(0); send2usb(0); // serialdelaytimerwait
        }
        send2usb(143); // enable highres mode
        waitalittle(); send2usb(139); // auto-rearm trigger
        send2usb(100);//final arming

        //send2usb(122); send2usb(1); send2usb(0); // 256 samples per channel
        send2usb(122); send2usb(numsamples/256); send2usb(numsamples%256); // samples per channel

        send2usb(123); send2usb(0); // send increment
        send2usb(124); send2usb(downsample); // downsample 3
        send2usb(125); send2usb(1); // tickstowait 1

        //100, 10 // get event (or just 10 if auto-rearming)

        waitalittle(); send2usb(136); send2usb(2); send2usb(32); send2usb(0); send2usb(0); send2usb(255); send2usb(200);// io expanders on
        waitalittle(); send2usb(136); send2usb(2); send2usb(32); send2usb(1); send2usb(0); send2usb(255); send2usb(200);// io expanders on
        waitalittle(); send2usb(136); send2usb(2); send2usb(33); send2usb(0); send2usb(0); send2usb(255); send2usb(200);// io expanders on
        waitalittle(); send2usb(136); send2usb(2); send2usb(33); send2usb(1); send2usb(0); send2usb(255); send2usb(200);// io expanders on
        waitalittle(); send2usb(136); send2usb(2); send2usb(32); send2usb(18); send2usb(240); send2usb(255); send2usb(200);// init, and turn on ADCs!
        waitalittle(); send2usb(136); send2usb(2); send2usb(32); send2usb(19); send2usb(15); send2usb(255); send2usb(200);// init, and turn on ADCs!
        waitalittle(); send2usb(136); send2usb(2); send2usb(33); send2usb(18); send2usb(0); send2usb(255); send2usb(200);// init, and turn on ADCs!
        waitalittle(); send2usb(136); send2usb(2); send2usb(33); send2usb(19); send2usb(0); send2usb(255); send2usb(200);// init, and turn on ADCs!

        waitalittle(); send2usb(131);  send2usb(8); send2usb(0); // spi offset
        waitalittle(); send2usb(131);  send2usb(6); send2usb(16); // spi offset binary output
        //waitalittle(); send2usb(131);  send2usb(6); send2usb(80); // spi offset binary output - test pattern
        waitalittle(); send2usb(131);  send2usb(1); send2usb(0 ); // spi not multiplexed output

        //waitalittle(); send2usb(136); send2usb(3); send2usb(96); send2usb(80); send2usb(136); send2usb(22); send2usb(0); // board 0 calib, chan 0
        //waitalittle(); send2usb(136); send2usb(3); send2usb(96); send2usb(82); send2usb(135); send2usb(248); send2usb(0); // board 0 calib, chan 1
        //waitalittle(); send2usb(136); send2usb(3); send2usb(96); send2usb(84); send2usb(136); send2usb(52); send2usb(0); // board 0 calib, chan 2
        //waitalittle(); send2usb(136); send2usb(3); send2usb(96); send2usb(86); send2usb(136); send2usb(52); send2usb(0); // board 0 calib, chan 3
        waitalittle(); setdac(0,2070);
        waitalittle(); setdac(1,2040);
        waitalittle(); setdac(2,2100);
        waitalittle(); setdac(3,2100);

        waitalittle();
        display.append("sent initialization commands \n");
    }

    protected void setupgraph(){
        if (doingfft){
            double range = (clkrate/2.)/Math.pow(2,downsample);
            graph.getViewport().setMinX(0.);
            if (range>1.) {
                xscaling = 1.;
                graph.getGridLabelRenderer().setHorizontalAxisTitle("Frequency (MHz)");
            }
            else if (range<1.){
                xscaling = .001;
                graph.getGridLabelRenderer().setHorizontalAxisTitle("Frequency (kHz)");
            }
            graph.getViewport().setMaxX(range/xscaling);

            graph.removeSeries(_series_hl);
            graph.removeSeries(_series_vl);
        }
        else {
            double range = (numsamples/2)*(Math.pow(2,downsample)/clkrate);
            if (range>1000.) {
                xscaling=1000.;
                graph.getGridLabelRenderer().setHorizontalAxisTitle("Time (ms)");
            }
            else {
                graph.getGridLabelRenderer().setHorizontalAxisTitle("Time (us)");
                xscaling=1.;
            }
            graph.getViewport().setMinX(-range/xscaling);
            graph.getViewport().setMaxX(range/xscaling);

            graph.removeSeries(_series_hl);
            graph.removeSeries(_series_vl);
            add_vl_hl();
        }
        graph.invalidate();
    }

    private String processdata(byte [] bd){
        int histlen=bd.length/4;
        double yoffset = 0.;
        String debug = "";
        DataPoint [] [] seriesies = new DataPoint[4][histlen-1];
        int s=0;
        for (int ss=0; ss<4; ++ss) {
            for (int p = 0; p < histlen - 1; ++p) {
                int bdp = bd[1+p+s];//ignore the first sample in each channel
                if (bdp < 0) bdp += 256;
                bdp -= 128;
                double yval = (yoffset - bdp) * (yscale / 256.); // got to flip it, since it's a negative feedback op amp
                double xoffset = (p - (p / histlen) * histlen - numsamples / 2) * (Math.pow(2, downsample) / clkrate / xscaling);
                seriesies[ss][p] = new DataPoint(xoffset, yval);
            }
            s+=histlen;
        }

        if (doingfft){
            FFT.FFTresult [] ffTresult = new FFT.FFTresult[4];
            double MaxFFTSample = 0.;
            for (int ss=0; ss<4; ++ss) {
                double[] x = new double[seriesies[ss].length];
                for (int i = 0; i < seriesies[ss].length; ++i) {
                    x[i] = seriesies[ss][i].getY();
                    ++i;
                }
                FFT myfft = new FFT();
                ffTresult[ss] = myfft.calculateFFT(x);
                if (ffTresult[ss].mMaxFFTSample>MaxFFTSample) MaxFFTSample=ffTresult[ss].mMaxFFTSample;
            }
            for (int ss=0; ss<4; ++ss) {
                seriesies[ss] = new DataPoint[ffTresult[ss].absSignal.length/2-1];
                double fftscale = 8.0/MaxFFTSample;
                for (int i = 0; i < ffTresult[ss].absSignal.length/2-1; ++i) {
                    double freq = (clkrate/2./xscaling)*(i+1)/(ffTresult[ss].absSignal.length/2)/Math.pow(2,downsample);
                    seriesies[ss][i] = new DataPoint(freq, -4.0 + fftscale * ffTresult[ss].absSignal[i+1]);
                }
            }
        }

        _series0.resetData(seriesies[0]);
        _series1.resetData(seriesies[1]);
        _series2.resetData(seriesies[2]);
        _series3.resetData(seriesies[3]);

        eventn++;//count the events
        gotaneventlately=true;
        if (eventn%100==0) display.append("event "+String.valueOf(eventn)+"\n");
        if (autogo) send2usb(10); // get another event
        return debug;
    }

    public static String byteArrayToHex(byte[] a) {
        StringBuilder sb = new StringBuilder(a.length * 2);
        for(byte b: a)
            sb.append(String.format("%02x", b));
        return sb.toString();
    }

    static class MyHandler extends Handler {
        private final WeakReference<MainActivity> mActivity;

        private MyHandler(MainActivity activity) {
            mActivity = new WeakReference<>(activity);
        }

        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MESSAGE_FROM_SERIAL_PORT:
                    byte [] bd = (byte[])msg.obj;
                    if (8==bd.length) {
                        //get the board id and save it, from the initial 142 call probably
                        if (mActivity.get().myboardid.isEmpty()) {
                            mActivity.get().myboardid = byteArrayToHex(bd);
                            if (debugme) mActivity.get().display.append("myboardid = " + mActivity.get().myboardid+"\n");
                            mActivity.get().synced = true;
                        } else if (byteArrayToHex(bd).equals(mActivity.get().myboardid)) {
                            mActivity.get().synced = true; // if we got a matching board id, we're synced up
                            if (mActivity.get().autogo) mActivity.get().send2usb(10);//get another event
                        }
                        else mActivity.get().synced=false;
                        mActivity.get().myserialBuffer.position(0);
                        mActivity.get().myserialBuffer.clear();
                        if (debugme) mActivity.get().display.append("synced now "+String.valueOf(mActivity.get().synced)+" - "+String.valueOf(mActivity.get().eventn)+"\n");
                    }
                    else{
                        //deal with other sized packet
                        mActivity.get().myserialBuffer.put(bd); // hopefully we have enough room in the buffer
                    }

                    //make sure we have the expected number of bytes
                    //check via a call to get board id to make sure we know where we are in the serial stream
                    String res="";
                    if (mActivity.get().synced && mActivity.get().myserialBuffer.position()==mActivity.get().numsamples*4) {//good!
                        byte[] dst = new byte[mActivity.get().myserialBuffer.position()];
                        mActivity.get().myserialBuffer.position(0);
                        mActivity.get().myserialBuffer.get(dst, 0, dst.length);
                        mActivity.get().myserialBuffer.clear();
                        if (debugme) res = mActivity.get().processdata(dst);
                        else mActivity.get().processdata(dst);
                    }
                    else if ((mActivity.get().doingusb) && mActivity.get().myserialBuffer.position()%mActivity.get().numsamples!=0){
                        //oops, we got a weird amount over usb? better resync! (BT often gives odd sized packets)
                        mActivity.get().myserialBuffer.position(0);
                        mActivity.get().myserialBuffer.clear();
                        mActivity.get().synced=false;
                    }
                    else if (mActivity.get().myserialBuffer.position()>mActivity.get().numsamples*4) {
                        //oops, we got too much data? better resync!
                        mActivity.get().myserialBuffer.position(0);
                        mActivity.get().myserialBuffer.clear();
                        mActivity.get().synced=false;
                    }

                    if (!mActivity.get().synced){
                        mActivity.get().myserialBuffer.position(0);
                        mActivity.get().myserialBuffer.clear();
                        mActivity.get().send2usb(142);//request the board ID
                    }

                    //if (mActivity.get().display.getLineCount()>10) mActivity.get().display.setText("");
                    if (debugme) if (bd.length!=mActivity.get().numsamples || !res.equals("")) mActivity.get().display.append(res +" - "+String.valueOf(mActivity.get().eventn)+" - "+String.valueOf(bd.length)+"\n");

                    break;
                case UsbService.CTS_CHANGE:
                    Toast.makeText(mActivity.get(), "CTS_CHANGE",Toast.LENGTH_LONG).show();
                    break;
                case UsbService.DSR_CHANGE:
                    Toast.makeText(mActivity.get(), "DSR_CHANGE",Toast.LENGTH_LONG).show();
                    break;
            }
        }
    }

    final int radius = 6;
    final int thickness = 4;
    protected LineGraphSeries [] myseries;

    protected void init_graph() {

        graph = findViewById(R.id.graph);
        graph.getViewport().setBackgroundColor(Color.WHITE);
        graph.getViewport().setDrawBorder(true);
        graph.getGridLabelRenderer().setHighlightZeroLines(false);
        graph.getGridLabelRenderer().setPadding(60);

        _series0 = new LineGraphSeries<>(new DataPoint[]{
                new DataPoint(-12, 1),
                new DataPoint(-6, 2),
                new DataPoint(0, 3),
                new DataPoint(6, 2),
                new DataPoint(12, -2)
        });
        _series0.setTitle("Chan 0");
        _series0.setColor(Color.RED);
        _series0.setDrawDataPoints(true);
        _series0.setDataPointsRadius(radius);
        _series0.setThickness(thickness);
        graph.addSeries(_series0);
        _series1 = new LineGraphSeries<>(new DataPoint[]{
                new DataPoint(-12, 2),
                new DataPoint(-6, 1),
                new DataPoint(0, -1),
                new DataPoint(6, 0),
                new DataPoint(12, 1)
        });
        _series1.setTitle("Chan 1");
        _series1.setColor(Color.GREEN);
        _series1.setDrawDataPoints(true);
        _series1.setDataPointsRadius(radius);
        _series1.setThickness(thickness);
        graph.addSeries(_series1);
        _series2 = new LineGraphSeries<>(new DataPoint[]{
                new DataPoint(-12, 3),
                new DataPoint(-6, 2),
                new DataPoint(0, 2),
                new DataPoint(6, -1),
                new DataPoint(12, -2)
        });
        _series2.setTitle("Chan 2");
        _series2.setColor(Color.BLUE);
        _series2.setDrawDataPoints(true);
        _series2.setDataPointsRadius(radius);
        _series2.setThickness(thickness);
        graph.addSeries(_series2);
        _series3 = new LineGraphSeries<>(new DataPoint[]{
                new DataPoint(-12, -3),
                new DataPoint(-6, -2),
                new DataPoint(0, -3),
                new DataPoint(6, -2),
                new DataPoint(12, -1)
        });
        _series3.setTitle("Chan 3");
        _series3.setColor(Color.MAGENTA);
        _series3.setDrawDataPoints(true);
        _series3.setDataPointsRadius(radius);
        _series3.setThickness(thickness);
        graph.addSeries(_series3);
        myseries = new LineGraphSeries[]{_series0, _series1, _series2, _series3};

        for (LineGraphSeries s : myseries) {
            s.setOnDataPointTapListener(new OnDataPointTapListener() {
                @Override
                public void onTap(Series series, DataPointInterface dataPoint) {
                    display.append("clicked: " + series.getTitle() + "  " + dataPoint.toString() + "\n");
                    int i = 0;
                    selectedchannel = -1;
                    for (LineGraphSeries s : myseries) {
                        if (s.getTitle().equals(series.getTitle())) {
                            if (toggle_selectchan.isChecked()) {
                                s.setThickness(2 * thickness);
                                selectedchannel = i;
                                toggle_selectchan.setTextOn(String.valueOf(selectedchannel));
                                toggle_selectchan.setChecked(true);
                                toggle_selectchan.invalidate();
                            } else {
                                display.append("Locked! Click -1 button to unlock.\n");
                            }
                        } else {
                            s.setThickness(thickness);
                        }
                        ++i;
                    }
                    graph.invalidate();
                }
            });
        }

        if (!doingfft) {
            add_vl_hl();
        }

        graph.getViewport().setXAxisBoundsManual(true);
        graph.getViewport().setMinY(-yscale/2.-.25);
        graph.getViewport().setMaxY(yscale/2.+.25);
        graph.getViewport().setYAxisBoundsManual(true);
        graph.getViewport().setScrollable(true);
        graph.getViewport().setScalable(true);
        graph.getGridLabelRenderer().setNumHorizontalLabels(7);
        graph.getGridLabelRenderer().setHumanRounding(true,false);
        graph.getGridLabelRenderer().setVerticalAxisTitle("Volts");
        graph.getGridLabelRenderer().setNumVerticalLabels(9);
    }

    protected void add_vl_hl() {
        if (graph.getSeries().contains(_series_hl)) return;
        _series_hl = new LineGraphSeries<>(new DataPoint[]{
                new DataPoint(-numsamples/2/clkrate/xscaling * Math.pow(2, downsample), lastscreenY),
                new DataPoint( numsamples/2/clkrate/xscaling * Math.pow(2, downsample), lastscreenY)
        });
        _series_hl.setTitle("Trig thresh");
        _series_hl.setColor(Color.GRAY);
        _series_hl.setDrawDataPoints(false);
        _series_hl.setThickness(thickness);
        graph.addSeries(_series_hl);

        _series_vl = new LineGraphSeries<>(new DataPoint[]{
                new DataPoint(lastscreenX, 4),
                new DataPoint(lastscreenX, -4)
        });
        _series_vl.setTitle("Trig pos");
        _series_vl.setColor(Color.GRAY);
        _series_vl.setDrawDataPoints(false);
        _series_vl.setThickness(thickness);
        graph.addSeries(_series_vl);
    }

    public boolean isStoragePermissionGranted() {
        if (Build.VERSION.SDK_INT >= 23) {
            if (checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    == PackageManager.PERMISSION_GRANTED) {
                return true;
            } else {
                ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, 1);
                return false;
            }
        }
        else { //permission is automatically granted on sdk<23 upon installation
            return true;
        }
    }

    protected void waitalittle(){
        try {
            if (doingusb) Thread.sleep(50);
            else Thread.sleep(150); // need longer delay for BT??
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    protected void waitalot(){
        oldautogo = autogo;
        autogo=false;
        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
    protected void donewaitalot(){
        autogo=oldautogo;
        if (autogo) send2usb(10);//for good luck

    }

    protected void setdac(int chan, int val){
        // channel 0 , board 0 calib
        // 136, 3, // header for i2c command with 3 bytes of data
        // 96, // i2c address of dac
        // 80, // channel 80,82,84,86 for chan 0,1,2,3
        // 136, 22, // high 4 bits can be 8 or 9 (internal ref 2V or 4V, respectively), next 12 bits are the 0-4095 level
        // 0 // send to board 0 (200 for all boards)

        if (chan<0 || chan>3) return;
        if (val>4096*2-1 || val<0) return;
        daclevel[chan]=val; //remember it
        int d=8*16; //internal ref, gain=1 (0-2V)
        if (val>4095) {
            d=9*16; //internal ref, gain=2 (0-4V)
            val/=2;
        }
        send2usb(136); send2usb(3);
        send2usb(96);
        send2usb(80+2*chan);
        send2usb(d+val/256);
        send2usb(val%256);
        send2usb(200);
    }

    protected void send2usb(int x){

        try{sendData(x);}
        catch (IOException ex) {
            display.append("IOexception!");
        }

        if (x>127) x -= 256; // since it goes to bytes as twos
        if (usbService != null) usbService.write( BigInteger.valueOf(x).toByteArray() );
    }

    private final ServiceConnection usbConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName arg0, IBinder arg1) {
            usbService = ((UsbService.UsbBinder) arg1).getService();
            usbService.setHandler(mHandler);
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            usbService = null;
        }
    };

    public boolean doingusb=false;
    private final BroadcastReceiver mUsbReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent.getAction() == null) return;
            switch (intent.getAction()) {
                case UsbService.ACTION_USB_PERMISSION_GRANTED: // USB PERMISSION GRANTED
                    doingusb=true;
                    Toast.makeText(context, "Haasoscope USB Ready", Toast.LENGTH_SHORT).show();
                    waitalot();
                    send_initialize();
                    donewaitalot();
                    break;
                case UsbService.ACTION_USB_PERMISSION_NOT_GRANTED: // USB PERMISSION NOT GRANTED
                    doingusb=false;
                    Toast.makeText(context, "USB Permission not granted", Toast.LENGTH_SHORT).show();
                    break;
                case UsbService.ACTION_NO_USB: // NO USB CONNECTED
                    doingusb=false;
                    Toast.makeText(context, "No USB connected", Toast.LENGTH_SHORT).show();
                    break;
                case UsbService.ACTION_USB_DISCONNECTED: // USB DISCONNECTED
                    doingusb=false;
                    Toast.makeText(context, "USB disconnected", Toast.LENGTH_SHORT).show();
                    break;
                case UsbService.ACTION_USB_NOT_SUPPORTED: // USB NOT SUPPORTED
                    doingusb=false;
                    Toast.makeText(context, "USB device not supported", Toast.LENGTH_SHORT).show();
                    break;
            }
        }
    };

    @Override
    public void onResume() {
        super.onResume();
        setFilters();  // Start listening notifications from UsbService
        startService(UsbService.class, usbConnection); // Start UsbService(if it was not started before) and Bind it
    }

    @Override
    public void onPause() {
        super.onPause();
        unregisterReceiver(mUsbReceiver);
        unbindService(usbConnection);
    }

    private void startService(Class<?> service, ServiceConnection serviceConnection) {
        if (!UsbService.SERVICE_CONNECTED) {
            startService(new Intent(this, service));
        }
        Intent bindingIntent = new Intent(this, service);
        bindService(bindingIntent, serviceConnection, Context.BIND_AUTO_CREATE);
    }

    private void setFilters() {
        IntentFilter filter = new IntentFilter();
        filter.addAction(UsbService.ACTION_USB_PERMISSION_GRANTED);
        filter.addAction(UsbService.ACTION_NO_USB);
        filter.addAction(UsbService.ACTION_USB_DISCONNECTED);
        filter.addAction(UsbService.ACTION_USB_NOT_SUPPORTED);
        filter.addAction(UsbService.ACTION_USB_PERMISSION_NOT_GRANTED);
        registerReceiver(mUsbReceiver, filter);
    }

}
