package com.felhr.serialportexample;

import android.annotation.SuppressLint;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.support.v7.app.AppCompatActivity;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.jjoe64.graphview.GraphView;
import com.jjoe64.graphview.series.DataPoint;
import com.jjoe64.graphview.series.LineGraphSeries;

import java.lang.ref.WeakReference;
import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.util.Formatter;
import java.util.Set;

public class MainActivity extends AppCompatActivity {

    protected UsbService usbService;
    protected TextView display;
    protected EditText editText;
    protected MyHandler mHandler;
    protected LineGraphSeries<DataPoint> _series0;
    protected LineGraphSeries<DataPoint> _series1;
    protected LineGraphSeries<DataPoint> _series2;
    protected LineGraphSeries<DataPoint> _series3;
    protected LineGraphSeries<DataPoint> _series_hl;
    protected LineGraphSeries<DataPoint> _series_vl;
    protected GraphView graph;
    private int numsamples = 400; // <4096 please
    private int eventn = 0;
    private int downsample = 3;
    private boolean autogo = true;
    private ByteBuffer myserialBuffer; // for synchronizing serial data
    private String myboardid = "";
    private boolean synced = false;
    private double yscale = 7.5;
    private double clkrate = 125.0; // ADC sample rate in MHz
    private double xscaling = 1.0; // account for xaxis ns, us, ms
    protected float lastscreenX=0, lastscreenY=0;
    protected float lastscreenfracX=0, lastscreenfracY=0;

    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        int radius = 6;
        int thickness = 4;

        graph = (GraphView) findViewById(R.id.graph);
        _series0 = new LineGraphSeries<DataPoint>(new DataPoint[] {
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
        _series1 = new LineGraphSeries<DataPoint>(new DataPoint[] {
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
        _series2 = new LineGraphSeries<DataPoint>(new DataPoint[] {
                new DataPoint(-12, 3),
                new DataPoint(-6, 2),
                new DataPoint(0, 3),
                new DataPoint(6, -1),
                new DataPoint(12, -2)
        });
        _series2.setTitle("Chan 2");
        _series2.setColor(Color.BLUE);
        _series2.setDrawDataPoints(true);
        _series2.setDataPointsRadius(radius);
        _series2.setThickness(thickness);
        graph.addSeries(_series2);
        _series3 = new LineGraphSeries<DataPoint>(new DataPoint[] {
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

        _series_hl = new LineGraphSeries<DataPoint>(new DataPoint[] {
                new DataPoint(-12, 0),
                new DataPoint(12, 0)
        });
        _series_hl.setTitle("Trig thresh");
        _series_hl.setColor(Color.GRAY);
        _series_hl.setDrawDataPoints(false);
        _series_hl.setThickness(thickness);
        graph.addSeries(_series_hl);

        _series_vl = new LineGraphSeries<DataPoint>(new DataPoint[] {
                new DataPoint(0, 4),
                new DataPoint(0, -4)
        });
        _series_vl.setTitle("Trig pos");
        _series_vl.setColor(Color.GRAY);
        _series_vl.setDrawDataPoints(false);
        _series_vl.setThickness(thickness);
        graph.addSeries(_series_vl);

        setupgraph();

        graph.setOnTouchListener(new View.OnTouchListener(){
            public boolean onTouch(View v, MotionEvent event) {
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
                display.append("Click "+String.valueOf(lastscreenX)+" "+String.valueOf(lastscreenY)+"\n");
                DataPoint[] hl = new DataPoint[] {
                        new DataPoint(-12, lastscreenY),
                        new DataPoint(12, lastscreenY)
                };
                _series_hl.resetData(hl);
                int thresh = (int)(255*lastscreenfracY);
                if (thresh<0) thresh=0;
                if (thresh>255) thresh=255;
                send2usb(127); send2usb(thresh);
                DataPoint [] vl = new DataPoint[] {
                        new DataPoint(lastscreenX, 4),
                        new DataPoint(lastscreenX, -4)
                };
                _series_vl.resetData(vl);
                int tt = (int)((numsamples-1)*lastscreenfracX);
                if (tt<5) tt=5;
                if (tt>numsamples-5) tt=numsamples-5;
                tt+=Math.pow(2,12);//use the current timebase in the offset
                send2usb(121); send2usb(tt/256); send2usb(tt%256);
                display.append("Trig "+String.valueOf(thresh)+" "+String.valueOf(tt-Math.pow(2,12))+"\n");
                return false;
            }
        });

        mHandler = new MyHandler(this);
        myserialBuffer= ByteBuffer.allocateDirect(numsamples*4*2);//for good luck

        display = (TextView) findViewById(R.id.textView1);
        editText = (EditText) findViewById(R.id.editText1);
        Button sendButton = (Button) findViewById(R.id.buttonSend);
        sendButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String data = editText.getText().toString();
                if (!data.equals("")) {
                    if (data.equals("G") || data.equals("g")){
                        waitalittle();
                        send2usb(0); send2usb(20); // board ID 0
                        send2usb(30); send2usb(142); // get board ID
                        waitalittle();
                        send2usb(135); send2usb(3); send2usb(100); // serialdelaytimerwait

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

                        waitalittle(); send2usb(136); send2usb(3); send2usb(96); send2usb(80); send2usb(136); send2usb(22); send2usb(0); // board 0 calib, chan 0
                        waitalittle(); send2usb(136); send2usb(3); send2usb(96); send2usb(82); send2usb(135); send2usb(248); send2usb(0); // board 0 calib, chan 1
                        waitalittle(); send2usb(136); send2usb(3); send2usb(96); send2usb(84); send2usb(136); send2usb(52); send2usb(0); // board 0 calib, chan 2
                        waitalittle(); send2usb(136); send2usb(3); send2usb(96); send2usb(86); send2usb(136); send2usb(52); send2usb(0); // board 0 calib, chan 3

                        waitalittle();
                        display.append("sent initialization commands \n");
                        if (autogo) {
                            waitalittle(); send2usb(10); // get an event
                        }
                    }
                    else if (data.equals("p") || data.equals("P")) {
                        autogo = !autogo;
                        waitalittle(); send2usb(10); // get an event to keep things rollin
                    }
                    else if (data.equals("(") || data.equals("( ")) {
                        if (downsample<10) {
                            downsample += 1;
                            display.append("downsample is "+String.valueOf(downsample)+" \n");
                            send2usb(124); send2usb(downsample);
                            int ds=downsample-3;
                            if (ds<1) ds=1;
                            if (ds>8) ds=8; // otherwise we timeout upon readout
                            send2usb(125); send2usb(ds);
                            setupgraph();
                        }
                    }
                    else if (data.equals(")") || data.equals(") ")) {
                        if (downsample>0) {
                            downsample -= 1;
                            display.append("downsample is "+String.valueOf(downsample)+" \n");
                            send2usb(124); send2usb(downsample);
                            int ds=downsample-3;
                            if (ds<1) ds=1;
                            if (ds>8) ds=8; // otherwise we timeout upon readout
                            send2usb(125); send2usb(ds);
                            setupgraph();
                        }
                    }
                    else if (usbService != null) { // if UsbService was correctly bound, send data
                        display.append(data+"\n");
                        send2usb(Integer.parseInt(data));
                    }
                }
            }
        });
    }

    protected void setupgraph(){
        double range = (numsamples/2)*(Math.pow(2,downsample)/clkrate/xscaling);
        graph.getGridLabelRenderer().setHorizontalAxisTitle("Time (us)");
        xscaling=1.;
        //if (range>100.) {
        //    xscaling=1000.;
        //    graph.getGridLabelRenderer().setHorizontalAxisTitle("Time (ms)");
        //}
        graph.getViewport().setXAxisBoundsManual(true);
        graph.getViewport().setMinX(-(numsamples/2)*(Math.pow(2,downsample)/clkrate/xscaling));
        graph.getViewport().setMaxX((numsamples/2)*(Math.pow(2,downsample)/clkrate/xscaling));
        graph.getViewport().setMinY(-yscale/2.-.25);
        graph.getViewport().setMaxY(yscale/2.+.25);
        graph.getViewport().setYAxisBoundsManual(true);
        graph.getViewport().setScalable(true);
        //graph.getViewport().setScalableY(true);
        graph.getGridLabelRenderer().setNumHorizontalLabels(7);
        graph.getGridLabelRenderer().setHumanRounding(false,false);
        graph.getGridLabelRenderer().setVerticalAxisTitle("Volts");
        graph.getGridLabelRenderer().setNumVerticalLabels(9);
        //graph.getGridLabelRenderer().invalidate(false,true);
    }

    private String processdata(byte [] bd){
        //Formatter formatter = new Formatter();
        int histlen=bd.length/4;
        DataPoint [] series0 = new DataPoint[histlen];
        DataPoint [] series1 = new DataPoint[histlen];
        DataPoint [] series2 = new DataPoint[histlen];
        DataPoint [] series3 = new DataPoint[histlen];
        double yoffset = 0.;
        int p=0;
        String debug = "";
        for (byte b : bd) {
            //formatter.format("%02x ", b); // for debugging
            int bdp = bd[p];
            //convert to unsigned, then subtract 128
            if (bdp < 0) bdp += 256;
            bdp -= 128;
            double yval=(yoffset-bdp)*(yscale/256.); // got to flip it, since it's a negative feedback op amp
            double xoffset = (p-(p/histlen)*histlen-numsamples/2)*(Math.pow(2,downsample)/clkrate/xscaling);
            if (p<histlen) series0[p] = new DataPoint(xoffset, yval);
            else if (p<2*histlen) series1[p-histlen] = new DataPoint(xoffset, yval);
            else if (p<3*histlen) series2[p-2*histlen] = new DataPoint(xoffset, yval);
            else if (p<4*histlen) series3[p-3*histlen] = new DataPoint(xoffset, yval);
            else break;
            p++;
        }
        if (p>numsamples-2) {
            _series0.resetData(series0);
            _series1.resetData(series1);
            _series2.resetData(series2);
            _series3.resetData(series3);

            eventn++;//count the events
            if (autogo) send2usb(10); // get another event
        }
        return debug; //formatter.toString();
    }

    public static String byteArrayToHex(byte[] a) {
        StringBuilder sb = new StringBuilder(a.length * 2);
        for(byte b: a)
            sb.append(String.format("%02x", b));
        return sb.toString();
    }

    private class MyHandler extends Handler {
        private final WeakReference<MainActivity> mActivity;

        public MyHandler(MainActivity activity) {
            mActivity = new WeakReference<>(activity);
        }

        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case UsbService.MESSAGE_FROM_SERIAL_PORT:
                    byte [] bd = (byte[])msg.obj;

                    if (8==bd.length) {
                        //get the board id and save it, from the initial 142 call probably
                        if (myboardid.isEmpty()) {
                            myboardid = byteArrayToHex(bd);
                            mActivity.get().display.append("myboardid = " + myboardid+"\n");
                            synced = true;
                        } else if (byteArrayToHex(bd).equals(myboardid)) {
                            synced = true; // if we got a matching board id, we're synced up
                            if (autogo) send2usb(10);//get another event
                        }
                        else synced=false;
                        myserialBuffer.position(0);
                        myserialBuffer.clear();
                        mActivity.get().display.append("synced now "+String.valueOf(synced)+" - "+String.valueOf(eventn)+"\n");
                    }
                    else{
                        //deal with other sized packet
                        myserialBuffer.put(bd); // TODO: make sure we have enough room in the buffer
                    }

                    //make sure we have the expected number of bytes
                    //check via a call to get board id to make sure we know where we are in the serial stream
                    String res="";
                    if (synced && myserialBuffer.position()==numsamples*4) {//good!
                        byte[] dst = new byte[myserialBuffer.position()];
                        myserialBuffer.position(0);
                        myserialBuffer.get(dst, 0, dst.length);
                        myserialBuffer.clear();
                        res = processdata(dst);
                    }
                    else if (myserialBuffer.position()>numsamples*4 || myserialBuffer.position()%numsamples!=0) {//oops, we got too much data or a weird amount? better resync!
                        myserialBuffer.position(0);
                        myserialBuffer.clear();
                        synced=false;
                    }
                    if (!synced){
                        myserialBuffer.position(0);
                        myserialBuffer.clear();
                        send2usb(142);//request the board ID
                    }

                    if (mActivity.get().display.getLineCount()>10) mActivity.get().display.setText("");
                    if (bd.length!=numsamples || !res.equals("")) mActivity.get().display.append(res +" - "+String.valueOf(eventn)+" - "+String.valueOf(bd.length)+"\n");

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

    protected void waitalittle(){
        try {
            Thread.sleep(5);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    protected void send2usb(int x){
        if (x>127) x -= 256; // since it goes to bytes as twos compliment
        usbService.write( BigInteger.valueOf(x).toByteArray() );
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

    private final BroadcastReceiver mUsbReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            switch (intent.getAction()) {
                case UsbService.ACTION_USB_PERMISSION_GRANTED: // USB PERMISSION GRANTED
                    Toast.makeText(context, "USB Ready", Toast.LENGTH_SHORT).show();
                    break;
                case UsbService.ACTION_USB_PERMISSION_NOT_GRANTED: // USB PERMISSION NOT GRANTED
                    Toast.makeText(context, "USB Permission not granted", Toast.LENGTH_SHORT).show();
                    break;
                case UsbService.ACTION_NO_USB: // NO USB CONNECTED
                    Toast.makeText(context, "No USB connected", Toast.LENGTH_SHORT).show();
                    break;
                case UsbService.ACTION_USB_DISCONNECTED: // USB DISCONNECTED
                    Toast.makeText(context, "USB disconnected", Toast.LENGTH_SHORT).show();
                    break;
                case UsbService.ACTION_USB_NOT_SUPPORTED: // USB NOT SUPPORTED
                    Toast.makeText(context, "USB device not supported", Toast.LENGTH_SHORT).show();
                    break;
            }
        }
    };

    @Override
    public void onResume() {
        super.onResume();
        setFilters();  // Start listening notifications from UsbService
        startService(UsbService.class, usbConnection, null); // Start UsbService(if it was not started before) and Bind it
    }

    @Override
    public void onPause() {
        super.onPause();
        unregisterReceiver(mUsbReceiver);
        unbindService(usbConnection);
    }

    private void startService(Class<?> service, ServiceConnection serviceConnection, Bundle extras) {
        if (!UsbService.SERVICE_CONNECTED) {
            Intent startService = new Intent(this, service);
            if (extras != null && !extras.isEmpty()) {
                Set<String> keys = extras.keySet();
                for (String key : keys) {
                    String extra = extras.getString(key);
                    startService.putExtra(key, extra);
                }
            }
            startService(startService);
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