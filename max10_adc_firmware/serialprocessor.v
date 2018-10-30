// from http://www.sparxeng.com/blog/software/communicating-with-your-cyclone-ii-fpga-over-serial-port-part-3-number-crunching

module processor(clk, rxReady, rxData, txBusy, txStart, txData, readdata, get_ext_data, ext_data_ready, wraddress_triggerpoint, rden, rdaddress, ram_output1, ram_output2, ram_output3, ram_output4,
newcomdata,comdata,spare1,spare2,spare3,serial_passthrough,master_clock, imthelast,imthefirst,rollingtrigger,trigDebug, 
adcdata,adcready,getadcdata,getadcadr,adcvalid,adcreset,adcramdata,writesamp,writeadc,adctestout,
triggerpoint,downsample, screendata,screenwren,screenaddr,screenreset,trigthresh,trigchannels,triggertype,triggertot,
SPIsend,SPIsenddata,delaycounter,carrycounter,usb_siwu,SPIstate,offset,gainsw,do_usb,
i2c_ena,i2c_addr,i2c_rw,i2c_datawr,i2c_datard,i2c_busy,i2c_ackerror,   usb_clk60,usb_dataio,usb_txe_busy,usb_wr,
rdaddress2,trigthresh2, debug1,debug2,chip_id, highres,  use_ext_trig,  digital_buffer1, nsmp);
   input clk;
	input[7:0] rxData;
   input rxReady;
   input txBusy;
   output reg txStart;
   output reg[7:0] txData;
   output reg[7:0] readdata;//first byte we got
   output reg spare1,spare2,spare3;
	reg led1,led2,led3,led4,led5,led6,led7,led8;
  	output reg get_ext_data;
	input ext_data_ready;
	parameter ram_width=12;//9 is 512 samples
	input wire[ram_width-1:0] wraddress_triggerpoint;
	output reg [ram_width-1:0] rdaddress;
	output reg [ram_width-1:0] rdaddress2;
	output reg [ram_width-1:0] triggerpoint;
	output reg rden;
	input wire [7:0] ram_output1;
	input wire [7:0] ram_output2;
	input wire [7:0] ram_output3;
	input wire [7:0] ram_output4;
	input wire [7:0] digital_buffer1;
	output reg serial_passthrough;
	output reg [1:0] master_clock;
	output reg[7:0] comdata;
	output reg newcomdata;
	output reg imthelast; // to remember if we're the last one in the chain
	output wire imthefirst; // to remember if we're the last one in the chain
	output reg rollingtrigger;
	input trigDebug;
	input [11:0] adcdata;
	input adcready;
	input adcvalid;
	output reg getadcdata;
	output reg [4:0] getadcadr;
	output reg adcreset;
	output reg [11:0] writesamp;//max of 4096 samples
	output reg writeadc;
	output reg [11:0] adctestout;
	output reg [7:0] downsample;
	output reg [7:0] screendata;
	output reg screenwren=0;
	output reg [9:0] screenaddr = 10'd0;
	output reg screenreset=0;
	output reg [7:0] trigthresh = 8'h80, trigthresh2=8'hff; // the normal and high trigger thresholds
	output reg [3:0] trigchannels = 4'b1111;
	output reg [3:0] triggertype = 4'b0001;//rising edge on, falling edge off, other off
   output reg [ram_width:0] triggertot;
	output reg [15:0] SPIsenddata;//the bits to send
	output reg SPIsend;//start sending
	input [7:0] delaycounter;
	input [7:0] carrycounter;
	input [3:0] SPIstate;
	output wire[3:0] offset;
	output reg[3:0] gainsw;
	reg[3:0] oversamp;
	output reg debug1,debug2;
	input [63:0] chip_id;
	output reg highres=0;
	output reg use_ext_trig=0;
	
	output reg i2c_ena;
	output reg [6:0] i2c_addr;
	output reg i2c_rw;
	output reg [7:0] i2c_datawr;
	input [7:0] i2c_datard;
	input i2c_busy;
	input i2c_ackerror;
	reg [7:0] i2cdata[8];//up to 8 bytes of data to send
	reg [3:0] i2c_datacounttosend,i2c_datacount;
	reg i2cgo=0;
	reg i2cdoread=0;

  localparam READ=0, SOLVING=1, WAITING=2, WRITE_EXT1=3, WRITE_EXT2=4, WAIT_ADC1=5, WAIT_ADC2=6, WRITE_BYTE1=7, WRITE_BYTE2=8, READMORE=9, 
	WRITE1=10, WRITE2=11,SPIWAIT=12,I2CWAIT=13,I2CSEND1=14,I2CSEND2=15, //WRITEUSB1=16,WRITEUSB2=17, 
	LOCKIN1=18,LOCKIN2=19,LOCKIN3=20,LOCKINWRITE1=21,LOCKINWRITE2=22,
	WRITE_USB_EXT1=33, WRITE_USB_EXT2=34, WRITE_USB_EXT3=35, WRITE_USB_EXT4=36, WRITE_USB_EXT5=37;
  integer state,i2cstate;

  reg [7:0] myid;
  assign imthefirst = (myid==0);
  reg [7:0] extradata[10];//to store command extra data, like arguemnts (up to 10 bytes)
  reg [ram_width+2:0] SendCount=0;
  reg [2:0] blockstosend=4; // will be 4 for normal, but 5 (or more) for sending logic analyzer stuff etc.
  integer nsamp = 6;
  input [11:0] adcramdata;
  reg writebyte;//whether we're sending the first or second byte (since it's 12 bits from the Max10 ADC)
  integer bytesread, byteswanted;
  reg thecounterbit, thecounterbitlockin;
  integer clockbitstowait=5, clockbitstowaitlockin=3; //wait 2^clockbitstowait (8?) ticks before sending each data byte
  reg [3:0] sendincrement = 0; //skip 2**sendincrement bytes each time
  output reg [ram_width-1:0] nsmp = 0; // samplestosend
  reg [7:0] chanforscreen=0;
  reg autorearm=0;
  integer thecounter=0, timeoutcounter=0, serialdelaytimer=0,serialdelaytimerwait=0;
  
  reg [7:0] usb2counter;
  output reg do_usb=0;
  input usb_clk60;
  output reg [7:0] usb_dataio;
  input usb_txe_busy;
  output reg usb_wr, usb_siwu;
  reg usb_txe_not_busy;
  
  //TODO: use memory bits for this, not register space??
  reg [5:0] screencolumndata [128]; //all the screen data, 128 columns of (8 rows of 8 dots)
  
  //For writing out data in WRITE1,2
  integer ioCount, ioCountToSend;
  reg[7:0] data[0:15];
  
  //For lockin calculations
  reg [7:0] numlockinbytes=16;//number of bytes of info to send for lockin info
  integer lockinresult1;
  integer lockinresult2;
  reg [15:0] lockinnumtoshift = 0;
  integer chan2mean, chan3mean;
  reg calcmeans;
  
  initial begin
    state<=READ;
	 i2cstate<=READ;
	 myid<=200;
	 master_clock<=2'b00;//start as my own master
	 imthelast<=0;//probably not last
	 rollingtrigger<=1;
	 triggerpoint<=(2**(ram_width-2));// 1/4 of the screen
	 downsample<=1;
	 serial_passthrough<=0;
	 usb_siwu<=1;
	 gainsw<=4'b0000;//1 is for 1k resistor (gain 2), 0 is for 100 Ohm resistor (gain .2)
	 oversamp<=4'b0011;//1 is for _no_ oversampling (and only matters for bits 0 and 1)
  	 debug1<=0; debug2<=0;
	 spare1<=0;
	 spare2<=0;
	 spare3<=0;
	 led4<=1; //on
	 led5<=0; //off
	 led6<=0; //off
	 led7<=0; //off
	 led8<=0; //off
  end
  
  //set the LEDs to indicate my ID
  always @(posedge clk) begin
	thecounter<=thecounter+1;
	usb_txe_not_busy <= ~usb_txe_busy;
	debug1 <= usb_txe_not_busy;
   if ( imthelast & thecounter[26]==1'b1 ) begin //flash every few seconds
		led1<=0;		led2<=0;		led3<=0;//all off
	end
	//else if (txStart) begin
	//else if (trigDebug) begin		
		//led1<=0;		led2<=0;		led3<=0;//all off
	//end
	else if (myid==0) begin	   
		led1<=1;		led2<=1;		led3<=1;//all on
	end
	else if (myid==1) begin	   
		led1<=0;		led2<=1;		led3<=1;//binary 1
	end
	else if (myid==2) begin	   
		led1<=1;		led2<=0;		led3<=1;//binary 2
	end
	else if (myid==3) begin	   
		led1<=0;		led2<=0;		led3<=1;//binary 3
	end
	else if (myid==4) begin	   
		led1<=1;		led2<=1;		led3<=0;//binary 4
	end
	else begin		
		led1<=0;		led2<=0;		led3<=0;//all off
	end
  end
  reg oldled1,oldled2,oldled3,oldled4,oldled5,oldled6,oldled7,oldled8;
  
//	reg [7:0] PWMoffset0 = 58; //22.7% *256;
//	reg [7:0] PWMoffset1 = 58; //22.7% *256;
//	reg [7:0] PWMoffset2 = 58; //22.7% *256;
//	reg [7:0] PWMoffset3 = 58; //22.7% *256;
//	reg [7:0] pwmcounter;
//	//For 1k and 0.1uF, freq=1.6kHz
//	//For 1k and 1uF, freq=160Hz
//	integer PWMratecounter=0;
//	integer PWMrate=2;//how fast we count the pwm clock
//   always @(posedge clk) begin
//		if (PWMratecounter>=PWMrate) begin
//			pwmcounter <= pwmcounter + 1'b1;  // free-running counter
//			PWMratecounter=0;
//		end
//		else PWMratecounter=PWMratecounter+1;
//	end
//	assign offset[0] = (PWMoffset0 > pwmcounter);  // comparators
//	assign offset[1] = (PWMoffset1 > pwmcounter);  // comparators
//	assign offset[2] = (PWMoffset2 > pwmcounter);  // comparators
//	assign offset[3] = (PWMoffset3 > pwmcounter);  // comparators
  
  always @(posedge clk) begin
    case (state)
	 
      READ: begin
		  get_ext_data<=0;
		  adcreset<=1;
		  txStart<=0;
		  getadcdata<=0;
		  bytesread<=0;
		  byteswanted<=0;
		  newcomdata<=0;
		  SPIsend<=0;
		  i2cgo=0;
		  usb_wr<=1;
        ioCount = 0;
        if (rxReady) begin
			 readdata = rxData;
          state = SOLVING;
        end
		  if (oldled1!=led1 || oldled2!=led2 || oldled3!=led3 || oldled4!=led4 || oldled5!=led5 || oldled6!=led6 || oldled7!=led7 || oldled8!=led8) begin
			 oldled1=led1; oldled2=led2; oldled3=led3; oldled4=led4;
			 oldled5=led5; oldled6=led6; oldled7=led7; oldled8=led8;
			 //now send to i2c
			 i2c_datacounttosend=2;//how many bytes of info to send (not counting address)
			 i2c_addr=8'h21; // the second mcp io expander
			 i2cdata[0]=8'h12; // port a
			 i2cdata[1][0]=led1; i2cdata[1][1]=led2; i2cdata[1][2]=led3; i2cdata[1][3]=led4; // set the low 4 bits to be correct for the leds
			 i2cdata[1][4]=led5; i2cdata[1][5]=led6; i2cdata[1][6]=led7; i2cdata[1][7]=led8; // set the high 4 bits to be correct for the leds
			 i2cdata[2]=0; // not used for mcp io expanders
			 if (i2cstate==READ) begin // if it's busy, we'll do nothing, oh well
			   i2cdoread = 0;
				i2cgo=1;
			 end
		  end
      end
		
		READMORE: begin
			newcomdata=0;
			if (rxReady) begin
				extradata[bytesread] = rxData;
				comdata=rxData;
				newcomdata=1; //pass it on
				bytesread = bytesread+1;
				if (bytesread>=byteswanted) state=SOLVING;
			end
		end

      SOLVING: begin
			if (readdata < 10) begin // got character "0-9"
				myid=readdata;//remember my ID
				if (readdata==0) begin
					master_clock=2'b00; //remain my own master
				end
				else master_clock=2'b01; //now a slave!
				comdata=(readdata+1); // give the next one an ID one larger
				newcomdata=1; //pass it on
				state=READ;
			end
			else if (readdata > 9 && readdata < 20) begin // got character "10-19"
				if (myid==(readdata-10)) begin
					//read me out
					serial_passthrough=0;
					timeoutcounter=0;//start the clock
					state=WAITING;
				end
				else begin
					//pass it on, and set serial to "passthrough mode"
					serial_passthrough=1;
					comdata=readdata;
					newcomdata=1; //pass it on
					state=READ;
				end
			end
			else if (readdata > 19 && readdata < 30) begin // got character "20-29"
				if (myid==(readdata-20)) imthelast=1; // I'm the last one
				else imthelast=0;
				comdata=readdata;
				newcomdata=1; //pass it on
				state=READ;
			end
			else if (readdata > 29 && readdata < 40) begin // got character "30-39"
				if (myid==(readdata-30)) begin
					//make me active
					serial_passthrough=0;
				end
				else begin
					//pass it on, and set serial to "passthrough mode"
					serial_passthrough=1;
					comdata=readdata;
					newcomdata=1; //pass it on
				end
				state=READ;
			end
			
			else if (100==readdata) begin
				//tell them all to prime the trigger
				get_ext_data=1;
				comdata=readdata;
				newcomdata=1; //pass it on
				state=READ;
			end
			
			else if (101==readdata) begin
				//tell them all to roll the trigger
				led5=1;
				rollingtrigger=1;
				comdata=readdata;
				newcomdata=1; //pass it on
				state=READ;
			end
			else if (102==readdata) begin
				//tell them all to not roll the trigger
				led5=0;
				rollingtrigger=0;
				comdata=readdata;
				newcomdata=1; //pass it on
				state=READ;
			end
			
			else if (readdata>109 && readdata<120) begin // 110 to 119
				if (serial_passthrough) begin
					comdata=readdata;
					newcomdata=1; //pass it on
					state=READ;
				end
				else begin
					if (readdata==119) getadcadr<=17;//send the data from the temp sensor
					else getadcadr<=(readdata-110);//send the data from adc, so 110->0 (pin AIN1), 111->1 (pin 6), up to 118->8 (pin 14)
					writesamp<=0;
					state=WAIT_ADC1;
				end
			end
			else if (readdata==120) begin
				byteswanted=2;//wait for next bytes which are the number of samples to read from max10 adc
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					nsamp=256*extradata[0]+extradata[1];
					if (nsamp>4095) nsamp=4095; //max of 4096 samples stored in the ram (12 bit writesamp address), and one less is needed (not sure why...)
					state=READ;
				end
			end
			else if (readdata==121) begin
				byteswanted=2;//wait for next bytes which are the trigger point
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					triggerpoint=256*extradata[0]+extradata[1];
					if (triggerpoint>(2**ram_width)-16) triggerpoint=(2**ram_width)-16;
					else if (triggerpoint<4) triggerpoint=4;
					state=READ;
				end
			end
			else if (readdata==122) begin
				byteswanted=2;//wait for next bytes which are the number of samples to send
				comdata=readdata;	
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					nsmp=256*extradata[0]+extradata[1];
					if (triggerpoint>(nsmp-5)) triggerpoint=nsmp/2;
					state=READ;
				end
			end
			else if (readdata==123) begin
				byteswanted=1;//wait for next byte which is the number of bytes to skip after each send, log2
				comdata=readdata;	
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					sendincrement=extradata[0];
					state=READ;
				end
			end
			else if (readdata==124) begin
				comdata=readdata;	newcomdata=1; //pass it on
				byteswanted=1;//wait for next byte which is the number of samples to skip in the ADC, log2
				if (bytesread<byteswanted) state=READMORE;
				else begin
					if (extradata[0]>30) extradata[0]=30;
					downsample=extradata[0];
					clockbitstowaitlockin = extradata[0]-2; // TODO - seems to work OK
					state=READ;
				end
			end
			else if (readdata==125) begin
				comdata=readdata;	newcomdata=1; //pass it on
				byteswanted=1;//wait for next byte which is the number of clock ticks to wait between sending bytes, log2
				if (bytesread<byteswanted) state=READMORE;
				else begin
					if (extradata[0]>30) extradata[0]=30;
					clockbitstowait=extradata[0];
					state=READ;
				end
			end
			else if (readdata==126) begin
				comdata=readdata;	newcomdata=1; //pass it on
				byteswanted=1;//wait for next byte which is the channel to draw on the mini-display
				if (bytesread<byteswanted) state=READMORE;
				else begin
					chanforscreen=extradata[0];
					state=READ;
				end
			end
			
			else if (readdata==127) begin
				comdata=readdata;	newcomdata=1; //pass it on
				byteswanted=1;//wait for next byte which is the trigger threshold
				if (bytesread<byteswanted) state=READMORE;
				else begin
					trigthresh=extradata[0];
					state=READ;
				end
			end
			else if (readdata==128) begin
				comdata=readdata;	newcomdata=1; //pass it on
				byteswanted=1;//wait for next byte which is the trigger type: rising, falling, either, ...
				if (bytesread<byteswanted) state=READMORE;
				else begin
					triggertype=extradata[0];
					state=READ;
				end
			end
			else if (readdata==129) begin
				byteswanted=2;//wait for next bytes which are the trigger time over/under threshold required
				comdata=readdata;	
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					triggertot=256*extradata[0]+extradata[1];
					state=READ;
				end
			end
			else if (readdata==130) begin
				comdata=readdata;	newcomdata=1; //pass it on
				byteswanted=1;//wait for next byte which is whether to trigger or not trigger on a given channel
				if (bytesread<byteswanted) state=READMORE;
				else begin
					if (extradata[0]/4 ==myid) begin //I have this channel
						trigchannels[extradata[0]%4]=~trigchannels[extradata[0]%4];//invert previous value
					end
					state=READ;
				end
			end
			else if (readdata==131) begin
				byteswanted=2;//wait for next bytes which are the data to send to SPI on the ADCs
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					SPIsenddata[15:8]=extradata[0];//0 (write) and the 7 bit address
					SPIsenddata[7:0]=extradata[1];//the bits to write to that address
					SPIsenddata[15]=1'b0;//write is 0
					SPIsend=1;
					state=SPIWAIT;
				end
			end
			else if (readdata==132) begin // send the delaycounter TDC data, if I'm the board being read out
				if (serial_passthrough) begin
					comdata=readdata;
					newcomdata=1; //pass it on
					state=READ;
				end
				else begin
					ioCountToSend = 1;
					data[0]=delaycounter;
					state=WRITE1;
				end
			end
			else if (readdata==133) begin // send the carrycounter TDC data, if I'm the board being read out
				if (serial_passthrough) begin
					comdata=readdata;
					newcomdata=1; //pass it on
					state=READ;
				end
				else begin
					ioCountToSend = 1;
					data[0]=carrycounter;
					state=WRITE1;
				end
			end
			else if (readdata==134) begin
				byteswanted=1;//wait for next byte which is the channel
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					if (extradata[0]/4 ==myid) begin //I have this channel
						gainsw[extradata[0]%4]=~gainsw[extradata[0]%4];//switch the gain of the channel
					end
					//now send to i2c
					i2c_datacounttosend=2;//how many bytes of info to send (not counting address)
					i2c_addr=8'h20; // the first mcp io expander
					i2cdata[0]=8'h12; // port a
					i2cdata[1][3:0]=gainsw; // set the low 4 bits to be correct for the gain
					i2cdata[1][7:4]=oversamp; // set the high 4 bits to be correct for the oversampling
					i2cdata[2]=0; // not used for mcp io expanders
					if (i2cstate==READ) begin
						i2cdoread = 0;
						i2cgo=1;
					end
					state=READ;
				end
			end
			else if (readdata==135) begin
				byteswanted=2;//wait for next bytes which are the serialdelaytimerwait
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					serialdelaytimerwait=50*(256*extradata[0]+extradata[1]); // 50 * amount given, so amount given in microseconds (20ns*50=1us) (except for the flipping clockbitstowait, so actually 2 us steps!)
					state=READ;
				end
			end
			else if (readdata==136) begin
				byteswanted=6;//wait for next bytes which are the stuff to send over i2c
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					//i2c_addr = 7'b0100000;// 0x20 // for all 3 pins of (last 3 digits) to GND of MCP23017
					//i2c_addr = 7'b0100001;// 0x21 // for all a pin to VCC of MCP23017
					//i2c_addr = 7'b1100000;// 0x60 // for MCP4728
					i2c_datacounttosend=extradata[0];//how many bytes of info to send (not counting address)
					i2c_addr=extradata[1]; // get address to write to
					i2cdata[0]=extradata[2];
					i2cdata[1]=extradata[3];
					i2cdata[2]=extradata[4];
					if ((extradata[5]==myid || extradata[5]==200) && i2cstate==READ) begin // only pay attention if the board is broadcast (id 200) or for my id!
						i2cdoread = 0;
						i2cgo=1;
					end
					state=READ;
				end
			end
			else if (137==readdata) begin
				//tell them to send over FT232H USB
				do_usb=~do_usb;
				comdata=readdata;
				newcomdata=1; //pass it on
				state=READ;
			end
			else if (readdata==138) begin
				byteswanted=2;//wait for next bytes which are the lockinnumtoshift
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					lockinnumtoshift = 256*extradata[0]+extradata[1];
					state=READ;
				end
			end
			else if (139==readdata) begin
				//tell them to toggle automatic rearm of the trigger
				autorearm=~autorearm;
				comdata=readdata;
				newcomdata=1; //pass it on
				state=READ;
			end
			else if (readdata==140) begin
				byteswanted=1;//wait for next byte which is the high trigger threshold (must be below this to trigger)
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					trigthresh2 = extradata[0];
					state=READ;
				end
			end
			else if (readdata==141) begin
				byteswanted=1;//wait for next byte which is the channel to toggle oversampling for
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					if (extradata[0]/4 ==myid) begin //I have this channel
						oversamp[extradata[0]%4]=~oversamp[extradata[0]%4];//switch the oversampling of the channel
					end
					//now send to i2c
					i2c_datacounttosend=2;//how many bytes of info to send (not counting address)
					i2c_addr=8'h20; // the first mcp io expander
					i2cdata[0]=8'h12; // port a
					i2cdata[1][3:0]=gainsw; // set the low 4 bits to be correct for the gain
					i2cdata[1][7:4]=oversamp; // set the high 4 bits to be correct for the oversampling
					i2cdata[2]=0; // not used for mcp io expanders
					if (i2cstate==READ) begin
						i2cdoread = 0;
						i2cgo=1;
					end
					state=READ;
				end
			end			
			else if (readdata==142) begin // send the uniqueID
				if (serial_passthrough) begin
					comdata=readdata;
					newcomdata=1; //pass it on
					state=READ;
				end
				else begin
					data[0]=chip_id[7+8*0:8*0];
					data[1]=chip_id[7+8*1:8*1];
					data[2]=chip_id[7+8*2:8*2];
					data[3]=chip_id[7+8*3:8*3];
					data[4]=chip_id[7+8*4:8*4];
					data[5]=chip_id[7+8*5:8*5];
					data[6]=chip_id[7+8*6:8*6];
					data[7]=chip_id[7+8*7:8*7];
					ioCountToSend = 8; // send 8 bytes
					state=WRITE1;
				end
			end
			else if (143==readdata) begin
				//tell them to toggle highres mode
				highres=~highres;
				comdata=readdata;
				newcomdata=1; //pass it on
				state=READ;
			end
			else if (144==readdata) begin
				//tell them to toggle using ext_trig_in
				use_ext_trig=~use_ext_trig;
				comdata=readdata;
				newcomdata=1; //pass it on
				state=READ;
			end
			else if (readdata==145) begin
				byteswanted=1;//wait for next byte which is the number of blocks to send out (for fast adc data, digitial logic analyzer data, etc.)
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					blockstosend = extradata[0];
					state=READ;
				end
			end
			else if (readdata==146) begin // send out a byte read from i2c
				byteswanted=3;//wait for next bytes which are the chip/address to read from and the board id (or all)
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					i2c_addr=extradata[0]; // get chip to read from
					i2c_datacounttosend=2;
					i2cdata[0]=extradata[1]; // get address to read from
					i2cdata[1]=0; // dummy
					if ((extradata[2]==myid || extradata[2]==200) && i2cstate==READ) begin // only pay attention if the board is broadcast (id 200) or for my id!
						i2cdoread = 1;
						i2cgo=1;
						//send message with read info (note - it won't be correct yet, since it takes time to read, so check back a little later!)
						ioCountToSend = 1;
						data[0] = i2c_datard;
						state=WRITE1;
					end
					else state=READ;
				end
			end
			else if (readdata==147) begin // send the firmware version
				if (serial_passthrough) begin
					comdata=readdata;
					newcomdata=1; //pass it on
					state=READ;
				end
				else begin
					ioCountToSend = 1;
					data[0]=5; // this is the firmware version
					state=WRITE1;
				end
			end
			
			else state=READ; // if we got some other command, just ignore it
      end
		
		SPIWAIT: begin
			newcomdata<=0; //set this back, to just send out data once
			//wait for SPIstate from oscillo to be nearly done
			if (SPIstate==3) begin 
				state=READ;
			end
		end
		
		WAITING: begin
			timeoutcounter=timeoutcounter+1;
			if (ext_data_ready) begin // can read out
				SendCount= 0;
				rdaddress = wraddress_triggerpoint - triggerpoint;// - 1;
				rdaddress2 = rdaddress;
				thecounterbit=thecounter[clockbitstowait];
				thecounterbitlockin=thecounter[clockbitstowaitlockin];
				if (lockinnumtoshift>0) begin
					lockinresult1=0;
					lockinresult2=0;
					chan2mean=0;
					chan3mean=0;
					calcmeans=1;
					state=LOCKIN1;
				end
				else begin
					if (do_usb) state=WRITE_USB_EXT1;
					else state=WRITE_EXT1;
				end
			end
			if ( timeoutcounter > 100000000 ) begin
				state=READ;//timeout!
				//ioCountToSend = 1;
				//data[0] = 8'hfb;//send message indicating timeout
				//state=WRITE1;
			end
		end
		LOCKIN1: begin
			rden = 1;
			if ( (thecounter[clockbitstowaitlockin]!=thecounterbitlockin) ) begin
			case(SendCount[ram_width+1:ram_width]) // we go through the samples 4 times
				0: begin
					// first time through we calculate the means
					chan2mean = chan2mean + ram_output3;
					chan3mean = chan3mean + ram_output4;
				end
				1: begin
					if (calcmeans) begin // do this just once - divide by the number of samples to get the average
						calcmeans=0;
						chan2mean = chan2mean/4096;
						chan3mean = chan3mean/4096;
					end
					// next time through we calculate c2 * offset c3
					// shift rdaddress2 and then accumulate
					if (SendCount[ram_width-1:0]>lockinnumtoshift && SendCount[ram_width-1:0]<(4096-lockinnumtoshift)) begin
						lockinresult2 = lockinresult2 + (ram_output3-chan2mean)*(ram_output4-chan3mean);	// accumulate the vector of chanel 2 * shifted channel 3
					end
				end
				2: begin
					// next time through we calculate c2*c3
					if (SendCount[ram_width-1:0]>lockinnumtoshift && SendCount[ram_width-1:0]<(4096-lockinnumtoshift)) begin
						lockinresult1 = lockinresult1 + (ram_output3-chan2mean)*(ram_output4-chan3mean);	// accumulate the vector of chanel 2 * channel 3	
					end
				end
				3: begin
						
				end
			endcase			
			SendCount = SendCount + 1;
			rdaddress = rdaddress + 1;
			if (SendCount[ram_width+1:ram_width]==1) rdaddress2=rdaddress-lockinnumtoshift;
			else rdaddress2=rdaddress;
			state=LOCKIN2;
			end // the counter
		end
		LOCKIN2: begin	
			state=LOCKIN3;
		end
		LOCKIN3: begin
			if ( (thecounter[clockbitstowaitlockin]==thecounterbitlockin) ) begin
			if(SendCount[ram_width+1:0]==0) begin // we're done
				ioCount = 0;
				SendCount = 0; // have to reset that top bit
				state=LOCKINWRITE1;
			end
			else begin
				state=LOCKIN1;
			end
			end // the counter
		end
		LOCKINWRITE1: begin
       if (!txBusy) begin
          if (ioCount==0) txData = lockinresult1[7+8*0:0+8*0];
          else if (ioCount==1) txData = lockinresult1[7+8*1:0+8*1];
          else if (ioCount==2) txData = lockinresult1[7+8*2:0+8*2];
          else if (ioCount==3) txData = lockinresult1[7+8*3:0+8*3];
          else if (ioCount==4) txData = lockinresult2[7+8*0:0+8*0];
          else if (ioCount==5) txData = lockinresult2[7+8*1:0+8*1];
          else if (ioCount==6) txData = lockinresult2[7+8*2:0+8*2];
          else if (ioCount==7) txData = lockinresult2[7+8*3:0+8*3];			 
			 else if (ioCount==8) txData = chan2mean[7+8*0:0+8*0];
          else if (ioCount==9) txData = chan2mean[7+8*1:0+8*1];
          else if (ioCount==10) txData = chan2mean[7+8*2:0+8*2];
          else if (ioCount==11) txData = chan2mean[7+8*3:0+8*3];
			 else if (ioCount==12) txData = chan3mean[7+8*0:0+8*0];
          else if (ioCount==13) txData = chan3mean[7+8*1:0+8*1];
          else if (ioCount==14) txData = chan3mean[7+8*2:0+8*2];
          else if (ioCount==15) txData = chan3mean[7+8*3:0+8*3];
			 else txData = 0;
          txStart = 1;
          state = LOCKINWRITE2;
        end
      end
      LOCKINWRITE2: begin
        txStart = 0;
        if (ioCount < numlockinbytes-1) begin
          ioCount = ioCount + 1;
          state = LOCKINWRITE1;
        end
		  else begin
				rdaddress = wraddress_triggerpoint - triggerpoint;// - 1;
				rdaddress2 = rdaddress;
				thecounterbit=thecounter[clockbitstowait];
				if (do_usb) state=WRITE_USB_EXT1;
				else state=WRITE_EXT1;
        end
      end
		WRITE_EXT1: begin
			timeoutcounter=timeoutcounter+1;
			rden = 1;
			//rotate through the outputs
			case(SendCount[ram_width+2:ram_width])
			0: txData<=ram_output1;
			1: txData<=ram_output2;
			2: txData<=ram_output3;
			3: txData<=ram_output4;
			4: txData<=digital_buffer1; // the digital logic analyzer buffer
			endcase
			if( (!txBusy) && (thecounter[clockbitstowait]!=thecounterbit)) begin // wait a few clock cycles				
				txStart<= 1;				
				SendCount = SendCount + (2**sendincrement);
				rdaddress = rdaddress + (2**sendincrement);
				rdaddress2 = rdaddress;
				if (nsmp>0 && SendCount[ram_width-1:0]>=nsmp) begin
					SendCount[ram_width-1:0]=0;
					SendCount[ram_width+2:ram_width] = (SendCount[ram_width+2:ram_width] + 1);
					rdaddress = wraddress_triggerpoint - triggerpoint;// - 1;
					rdaddress2 = rdaddress;
				end
				state=WRITE_EXT2;
			end
			if ( timeoutcounter > 100000000 ) begin
				rden = 0;
				state=READ;//timeout!
			end
		end
		WRITE_EXT2: begin
			if( thecounter[clockbitstowait]==thecounterbit ) begin
				txStart<= 0;			
				if(SendCount[ram_width+2:ram_width]==blockstosend) begin // it's 5 (or more) blocks including the logic analyzer info
					rden = 0;
					if (autorearm) begin
						//tell them all to prime the trigger
						get_ext_data=1;
					end
					state=READ;
				end
				else begin					
					if(SendCount[4:0]==0 && serialdelaytimer<serialdelaytimerwait) begin // every 32 bytes, 50000 is 1 ms
						serialdelaytimer=serialdelaytimer+1;
					end
					else begin
						if ( (rdaddress- wraddress_triggerpoint-64)>=0 && (rdaddress-wraddress_triggerpoint+64)<128 && (!SendCount[ram_width+2]) ) begin //update display // ignore logic analyzer info
							if (SendCount[ram_width+1:ram_width]==chanforscreen) screencolumndata[rdaddress - wraddress_triggerpoint - 64]=(63-txData[7:2]);//store most significant 6 bits
							screenwren = 1;
						end
						serialdelaytimer=0;
						state=WRITE_EXT1;
					end
				end
			end
		end
		
		WRITE_USB_EXT1: begin
			if (usb_txe_not_busy) begin
				thecounterbit=thecounter[clockbitstowait];
				usb2counter<=0;
				state=WRITE_USB_EXT2;
			end
			debug2<=1;
			rden = 1;
		end
		WRITE_USB_EXT2: begin
			debug2<=0;
			usb2counter<=usb2counter+1;
			//rotate through the outputs
			case(SendCount[ram_width+2:ram_width])
				0: usb_dataio<=ram_output1;
				1: usb_dataio<=ram_output2;
				2: usb_dataio<=ram_output3;
				3: usb_dataio<=ram_output4;
				4: usb_dataio<=digital_buffer1; // the digital logic analyzer buffer
			endcase
			if( (usb2counter>clockbitstowait) && (thecounter[clockbitstowait]!=thecounterbit)) begin // wait a few clock cycles (usb2counter was set to 0 in last state)
				SendCount = SendCount + (2**sendincrement);
				rdaddress = rdaddress + (2**sendincrement);
				rdaddress2 = rdaddress;
				if (nsmp>0 && SendCount[ram_width-1:0]>=nsmp) begin
					SendCount[ram_width-1:0]=0;
					SendCount[ram_width+2:ram_width] = (SendCount[ram_width+2:ram_width] + 1);
					rdaddress = wraddress_triggerpoint - triggerpoint;// - 1;
					rdaddress2 = rdaddress;
				end
				state=WRITE_USB_EXT3;
			end
		end
		WRITE_USB_EXT3: begin
			usb_wr<= 0;
			usb2counter<=0;
			state=WRITE_USB_EXT4;
		end
		WRITE_USB_EXT4: begin
			usb2counter=usb2counter+1;
			if( (usb2counter>clockbitstowait) && (thecounter[clockbitstowait]==thecounterbit) ) begin // wait a few clock cycles (usb2counter was set to 0 in last state)
				usb_wr<= 1;	
				if(SendCount[ram_width+2:ram_width]==blockstosend) begin // it's 5 (or more) blocks including the logic analyzer info
					rden = 0;
					if (autorearm) begin
						//tell them all to prime the trigger
						get_ext_data=1;
					end
					state=WRITE_USB_EXT5;
				end
				else begin
					usb2counter=0;
					state=WRITE_USB_EXT1;
					if ( (rdaddress- wraddress_triggerpoint-64)>=0 && (rdaddress-wraddress_triggerpoint+64)<128 && (!SendCount[ram_width+2]) ) begin //update display // ignore logic analyzer info
						if (SendCount[ram_width+1:ram_width]==chanforscreen) screencolumndata[rdaddress - wraddress_triggerpoint - 64]=(63-txData[7:2]);//store most significant 6 bits
						screenwren = 1;
					end
				end
			end
		end
		WRITE_USB_EXT5: begin
			usb_siwu=0;//this sends out the data to the PC immediately, without waiting for the latency timer (16 ms by default!)
			usb2counter<=usb2counter+1;
			if( (usb2counter>8) ) begin // wait a few clock cycles (usb2counter was set to 0 in last state)
				state=READ;
				usb_siwu=1;
			end
		end

		WAIT_ADC1: begin
			newcomdata<=0; //set this back, to just send out data once
			writeadc<=0;
			getadcdata<=1;
			//if (adcready) begin
				state=WAIT_ADC2;
			//end
		end
		WAIT_ADC2: begin
			if (adcvalid) begin
				adctestout<=adcdata;
				writeadc<=1;
				getadcdata<=0;
				if (writesamp>=(nsamp-1)) begin
					writesamp<=0;
					writebyte<=0;
					thecounterbit=thecounter[clockbitstowait];
					state<=WRITE_BYTE1;
				end
				else begin
					writesamp=writesamp+1;
					state=WAIT_ADC1;
				end
			end
		end
		WRITE_BYTE1: begin
			newcomdata<=0; //set this back, to just send out data once
			writeadc<=0;
			if(!txBusy && (thecounter[clockbitstowait]!=thecounterbit)) begin
				if (writebyte) txData=adcramdata[11:8];
				else txData=adcramdata[7:0];
				txStart=1;
				state=WRITE_BYTE2;
			end
		end
		WRITE_BYTE2: begin
			txStart=0;
			if (writebyte) writesamp=writesamp+1;
			writebyte = ~writebyte;
			if (writesamp>(nsamp-1)) state=READ;
			else state=WRITE_BYTE1;
		end
		
		//just writng out some data bytes over serial
		WRITE1: begin
       newcomdata<=0; //set this back, to just send out data once
       if (!txBusy) begin
          txData = data[ioCount];
          txStart = 1;
          state = WRITE2;
        end
      end
      WRITE2: begin
        txStart = 0;
        if (ioCount < ioCountToSend-1) begin
          ioCount = ioCount + 1;
          state = WRITE1;
        end else begin
          state = READ;
        end
      end
		
//		//just writng out some data bytes over USB
//		WRITEUSB1: begin
//		  newcomdata<=0; //set this back, to just send out data once
//        if (usb_txe_not_busy) begin
//          usb_dataio = data[ioCount];
//			 usb_wr = 1;
//          state = WRITEUSB2;
//        end
//      end
//      WRITEUSB2: begin
//        usb_wr = 0;
//        if (ioCount != LENMAX) begin
//          ioCount = ioCount + 1;
//          state = WRITEUSB1;
//        end else begin
//          ioCount = 0;
//          state = READ;
//        end
//      end
		
    endcase
	 
  end  
  
  //I2C, from https://eewiki.net/pages/viewpage.action?pageId=10125324
  always @(posedge clk) begin
   case (i2cstate)
		READ: begin
			i2c_ena<=0;
			if (i2cgo) begin
				i2cstate=I2CWAIT;
			end
		end
		I2CWAIT: begin
			if (~i2c_busy) begin
				//i2c_addr set elsewhere first
				i2c_rw=0;
				//i2c_datacounttosend set elsewhere first
				i2c_datawr = i2cdata[0];
				i2c_datacount=1;
				i2cstate=I2CSEND1;
			end
		end
		I2CSEND1: begin
			i2c_ena = 1;
			if (i2c_datacount >= i2c_datacounttosend) begin
				i2cstate=READ; //sets i2c_ena back to 0
			end
			else if (i2c_busy) begin
				i2c_datawr = i2cdata[i2c_datacount];
				if (i2cdoread) begin
					i2c_rw=1; // set to read for second byte 
				end
				i2cstate=I2CSEND2;
			end
		end
		I2CSEND2: begin
			if (~i2c_busy) begin
				//i2c_ackerror
				i2c_datacount = i2c_datacount+1;
				i2cstate=I2CSEND1;
			end
		end
	endcase
	end
  
  	//update display
	reg [5:0] columndata;
	reg [2:0] row;
	reg [6:0] column;
	reg [3:0] b;
	always @(posedge clk) begin
		if (screenaddr>1000) screenreset<=1;
		screenaddr = screenaddr + 1; // reset the screen at the beginning of the day - just once
		row=7-screenaddr[9:7];
		column=screenaddr[6:0];
		
		//if (column>44) screencolumndata[column] = 64'h0000ff;//test hack
		//else screencolumndata[column] = 64'h000022;//test hack		
		
		columndata = screencolumndata[column];//the current column, 64 bits, of screen data
		
		//now draw this row of this column
		if (columndata>=8*(row+1)) screendata = 8'hff; // e.g. if row=1, then if data is 16 and up, all on
		else if (columndata>=8*row) begin // e.g. if row=1, then if data is 8-15, set the appropriate bits, e.g. 5 -> 00011111
			screendata=8'h00; b=0;
			while (b<8) begin
				if (columndata[2:0]>b) screendata[b]=1;//7-b?
				b=b+1;
			end
		end
		else screendata = 8'h00; // e.g. if d=1, then if data is also not >7 (7 and down), all off
		
		//screendata = 8'h00;//temporarily turn off histo
		//if (column>44) screendata = 8'hff;//test hack
		
		//draws the board ID
		if (row==7 & trigDebug) begin
			if (myid>=screenaddr[6:1] && !screenaddr[0]) screendata = 8'hfa;
		end
		if (row==6 & !trigDebug) begin
			if (myid>=screenaddr[6:1] && !screenaddr[0]) screendata = 8'hfa;
		end	
	end
	
endmodule
