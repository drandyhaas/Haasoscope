package com.felhr.serialportexample;

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

    /*
     * Notifications from UsbService will be received here.
     */
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
    protected UsbService usbService;
    protected TextView display;
    protected EditText editText;
    protected MyHandler mHandler;
    protected LineGraphSeries<DataPoint> _series0;
    protected LineGraphSeries<DataPoint> _series1;
    protected LineGraphSeries<DataPoint> _series2;
    protected LineGraphSeries<DataPoint> _series3;
    protected GraphView graph;
    private int numsamples = 200; // <256 please
    private int eventn = 0;
    private int downsample = 3;
    private boolean autogo = true;
    private ByteBuffer myserialBuffer; // for syncronizing serial data
    private String myboardid = "";
    private boolean synced = false;

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

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        int radius = 6;
        int thickness = 4;

        graph = (GraphView) findViewById(R.id.graph);
        _series0 = new LineGraphSeries<DataPoint>(new DataPoint[] {
                new DataPoint(0, 1),
                new DataPoint(1, 5),
                new DataPoint(2, 3),
                new DataPoint(3, 2),
                new DataPoint(4, 6)
        });
        _series0.setTitle("Chan 0");
        _series0.setColor(Color.RED);
        _series0.setDrawDataPoints(true);
        _series0.setDataPointsRadius(radius);
        _series0.setThickness(thickness);
        graph.addSeries(_series0);
        _series1 = new LineGraphSeries<DataPoint>(new DataPoint[] {
                new DataPoint(0, 2),
                new DataPoint(1, 6),
                new DataPoint(2, 4),
                new DataPoint(3, 0),
                new DataPoint(4, 0)
        });
        _series1.setTitle("Chan 1");
        _series1.setColor(Color.GREEN);
        _series1.setDrawDataPoints(true);
        _series1.setDataPointsRadius(radius);
        _series1.setThickness(thickness);
        graph.addSeries(_series1);
        _series2 = new LineGraphSeries<DataPoint>(new DataPoint[] {
                new DataPoint(0, 9),
                new DataPoint(1, 2),
                new DataPoint(2, 3),
                new DataPoint(3, -1),
                new DataPoint(4, -2)
        });
        _series2.setTitle("Chan 2");
        _series2.setColor(Color.BLUE);
        _series2.setDrawDataPoints(true);
        _series2.setDataPointsRadius(radius);
        _series2.setThickness(thickness);
        graph.addSeries(_series2);
        _series3 = new LineGraphSeries<DataPoint>(new DataPoint[] {
                new DataPoint(0, -3),
                new DataPoint(1, -5),
                new DataPoint(2, -3),
                new DataPoint(3, -2),
                new DataPoint(4, -1)
        });
        _series3.setTitle("Chan 3");
        _series3.setColor(Color.MAGENTA);
        _series3.setDrawDataPoints(true);
        _series3.setDataPointsRadius(radius);
        _series3.setThickness(thickness);
        graph.addSeries(_series3);

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
                        send2usb(122); send2usb(0); send2usb(numsamples); // samples per channel

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
                            waitalittle();
                            send2usb(10); // get an event
                        }
                    }
                    else if (data.equals("(")) {
                        if (downsample<10) {
                            downsample += 1;
                            send2usb(124); send2usb(downsample);
                            int ds=downsample-3;
                            if (ds<1) ds=1;
                            if (ds>8) ds=8; // otherwise we timeout upon readout
                            send2usb(125);  send2usb(ds);
                        }
                    }
                    else if (data.equals(")")) {
                        if (downsample>0) {
                            downsample -= 1;
                            send2usb(124); send2usb(downsample);
                            int ds=downsample-3;
                            if (ds<1) ds=1;
                            if (ds>8) ds=8; // otherwise we timeout upon readout
                            send2usb(125);  send2usb(ds);
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

    private String processdata(byte [] bd){
        //Formatter formatter = new Formatter();
        int histlen=bd.length/4;
        double xoffset = 1.0;
        int yoffset=0;
        double yscale = 7.5;
        DataPoint [] series0 = new DataPoint[histlen];
        DataPoint [] series1 = new DataPoint[histlen];
        DataPoint [] series2 = new DataPoint[histlen];
        DataPoint [] series3 = new DataPoint[histlen];
        int p=0;
        for (byte b : bd) {
            //formatter.format("%02x ", b); // for debugging
            int bdp = bd[p];
            //convert to unsigned, then subtract 128
            if (bdp < 0) bdp += 256;
            bdp -= 128;
            double yval=(yoffset-bdp)*(yscale/256.); // got to flip it, since it's a negative feedback op amp
            if (p<histlen) series0[p] = new DataPoint(p+xoffset, yval);
            else if (p<2*histlen) series1[p-histlen] = new DataPoint(p-histlen+xoffset, yval);
            else if (p<3*histlen) series2[p-2*histlen] = new DataPoint(p-2*histlen+xoffset, yval);
            else if (p<4*histlen) series3[p-3*histlen] = new DataPoint(p-3*histlen+xoffset, yval);
            else break;
            p++;
        }
        if (p>numsamples-2) {
            _series0.resetData(series0);
            _series1.resetData(series1);
            _series2.resetData(series2);
            _series3.resetData(series3);
            graph.getViewport().setMinX(xoffset);
            graph.getViewport().setMaxX(numsamples-1+xoffset);
            graph.getViewport().setXAxisBoundsManual(true);
            graph.getViewport().setMinY(-yscale*1.1/2.);
            graph.getViewport().setMaxY(yscale*1.1/2.);
            graph.getViewport().setYAxisBoundsManual(true);

            eventn++;//count the events
            if (autogo) send2usb(10); // get another event
        }
        return ""; //formatter.toString();
    }

    public static String byteArrayToHex(byte[] a) {
        StringBuilder sb = new StringBuilder(a.length * 2);
        for(byte b: a)
            sb.append(String.format("%02x", b));
        return sb.toString();
    }

    /*
     * This handler will be passed to UsbService. Data received from serial port is displayed through this handler
     */
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

                    //if (bd.length!=numsamples) mActivity.get().display.append("was"+String.valueOf(myserialBuffer.position())+" - "+String.valueOf(eventn)+" - "+String.valueOf(bd.length)+"\n");

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

                    //if (bd.length!=numsamples) mActivity.get().display.append("now"+String.valueOf(myserialBuffer.position())+" - "+String.valueOf(eventn)+" - "+String.valueOf(bd.length)+"\n");
                    //if (mActivity.get().display.getLineCount()>3) mActivity.get().display.setText("");
                    if (bd.length!=numsamples) mActivity.get().display.append(res +" - "+String.valueOf(eventn)+" - "+String.valueOf(bd.length)+"\n");

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
}