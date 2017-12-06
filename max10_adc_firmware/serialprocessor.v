// from http://www.sparxeng.com/blog/software/communicating-with-your-cyclone-ii-fpga-over-serial-port-part-3-number-crunching

module processor(clk, rxReady, rxData, txBusy, txStart, txData, readdata, get_ext_data, ext_data_ready, wraddress_triggerpoint, rden, rdaddress, ram_output1, ram_output2, ram_output3, ram_output4,
newcomdata,comdata,led1,led2,led3,serial_passthrough,master_clock, imthelast,imthefirst,rollingtrigger,trigDebug, 
adcdata,adcready,getadcdata,getadcadr,adcvalid,adcreset,adcramdata,writesamp,writeadc,adctestout,
triggerpoint,downsample, screendata,screenwren,screenaddr,screenreset,trigthresh,trigchannels,triggertype,triggertot,
SPIsend,SPIsenddata,delaycounter,carrycounter,ledbase,SPIstate,offset,gainsw,led4,
i2c_ena,i2c_addr,i2c_rw,i2c_datawr,i2c_datard,i2c_busy,i2c_ackerror,   usb_clk60,usb_dataio,usb_txe_busy,usb_wr,
rdaddress2,trigthresh2);
   input clk;
	input[7:0] rxData;
   input rxReady;
   input txBusy;
   output reg txStart;
   output reg[7:0] txData;
   output reg[7:0] readdata;//first byte we got
   output reg led1,led2,led3,led4,ledbase;
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
	output reg [4:0] downsample;
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
	
	output reg i2c_ena;
	output reg [6:0] i2c_addr;
	output reg i2c_rw;
	output reg [7:0] i2c_datawr;
	input [7:0] i2c_datard;
	input i2c_busy;
	input i2c_ackerror;
	reg [7:0] i2cdata[8];//up to 8 bytes of data to send
	reg [3:0] i2c_datacounttosend,i2c_datacount;

  localparam READ=0, SOLVING=1, WAITING=2, WRITE_EXT1=3, WRITE_EXT2=4, WAIT_ADC1=5, WAIT_ADC2=6, WRITE_BYTE1=7, WRITE_BYTE2=8, READMORE=9, 
	WRITE1=10, WRITE2=11,SPIWAIT=12,I2CWAIT=13,I2CSEND1=14,I2CSEND2=15,WRITEUSB1=16,WRITEUSB2=17, LOCKIN1=18,LOCKIN2=19,LOCKIN3=20,LOCKINWRITE1=21,LOCKINWRITE2=22;
  integer state;

  reg [7:0] myid;
  reg [7:0] extradata[10];//to store command extra data, like arguemnts (up to 10 bytes)
  reg [ram_width+1:0] SendCount;
  integer nsamp = 6;
  input [11:0] adcramdata;
  reg writebyte;//whether we're sending the first or second byte (since it's 12 bits from the Max10 ADC)
  integer bytesread, byteswanted;
  reg thecounterbit, thecounterbitlockin;
  integer clockbitstowait=5, clockbitstowaitlockin=3; //wait 2^clockbitstowait (8?) ticks before sending each data byte
  reg [3:0] sendincrement = 0; //skip 2**sendincrement bytes each time
  reg [ram_width-1:0] samplestosend = 0;
  reg [7:0] chanforscreen=0;
  reg autorearm=0;
 
	reg do_usb=0;
	input usb_clk60;
	output reg [7:0] usb_dataio;
	input usb_txe_busy;
	output reg usb_wr;
  
  //TODO: use memory bits for this, not register space??
  reg [5:0] screencolumndata [128]; //all the screen data, 128 columns of (8 rows of 8 dots)
  
  //For writing out data in WRITE1,2
  localparam LEN = 1;//number of bytes to write out
  localparam LENMAX = LEN - 1;
  integer ioCount;
  reg[7:0] data[0:LENMAX];
  
  //For lockin calculations
  reg [7:0] numlockinbytes=16;//number of bytes of info to send for lockin info
  integer lockinresult1;
  integer lockinresult2;
  reg [15:0] lockinnumtoshift = 0;
  integer chan2mean, chan3mean;
  reg calcmeans;
  
  initial begin
    state<=READ;
	 myid<=200;
	 master_clock<=2'b00;//start as my own master
	 imthelast<=0;//probably not last
	 rollingtrigger<=1;
	 triggerpoint<=(2**(ram_width-2));// 1/4 of the screen
	 downsample<=1;
	 serial_passthrough<=0;
	 ledbase<=1;
	 gainsw[0]<=0;//1 is for 1k resistor (gain 2), 0 is for 100 Ohm resistor (gain .2)
	 gainsw[1]<=0;
	 gainsw[2]<=0;
	 gainsw[3]<=0;
  end
  
  assign imthefirst = (myid==0);
  
  integer thecounter;
  integer theoldcounter;
  //set the LEDs to indicate my ID
  always @(posedge clk) begin
	thecounter<=thecounter+1;
	
	if (state==READ) led4<=1;
	else led4<=0;
  
   if ( imthelast & thecounter[26]==1'b1 ) begin //flash every few seconds
		led1<=0;		led2<=0;		led3<=0;//all on
	end
	else if (txStart) begin
	//if (trigDebug) begin		
		led1<=0;		led2<=0;		led3<=0;//all on
	end
	else if (myid==0) begin	   
		led1<=1;		led2<=1;		led3<=1;//all off
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
		led1<=1;		led2<=1;		led3<=1;
	end
  end
  
  
   //reg [7:0] PWMoffset = 23; //9.1%  *256;
	reg [7:0] PWMoffset0 = 58; //22.7% *256;
	reg [7:0] PWMoffset1 = 58; //22.7% *256;
	reg [7:0] PWMoffset2 = 58; //22.7% *256;
	reg [7:0] PWMoffset3 = 58; //22.7% *256;
	reg [7:0] pwmcounter;
	//For 1k and 0.1uF, freq=1.6kHz
	//For 1k and 1uF, freq=160Hz
	integer PWMratecounter=0;
	integer PWMrate=2;//how fast we count the pwm clock
   always @(posedge clk) begin
		if (PWMratecounter>=PWMrate) begin
			pwmcounter <= pwmcounter + 1'b1;  // free-running counter
			PWMratecounter=0;
		end
		else PWMratecounter=PWMratecounter+1;
	end
	assign offset[0] = (PWMoffset0 > pwmcounter);  // comparators
	assign offset[1] = (PWMoffset1 > pwmcounter);  // comparators
	assign offset[2] = (PWMoffset2 > pwmcounter);  // comparators
	assign offset[3] = (PWMoffset3 > pwmcounter);  // comparators
  
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
		  i2c_ena<=0;
        if (rxReady) begin
			 readdata = rxData;
          state = SOLVING;
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
					theoldcounter=thecounter;//start the clock
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
			
			else if (100==readdata) begin
				//tell them all to prime the trigger
				get_ext_data=1;
				comdata=readdata;
				newcomdata=1; //pass it on
				state=READ;
			end
			
			else if (101==readdata) begin
				//tell them all to roll the trigger
				rollingtrigger=1;
				comdata=readdata;
				newcomdata=1; //pass it on
				state=READ;
			end
			else if (102==readdata) begin
				//tell them all to not roll the trigger
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
					samplestosend=256*extradata[0]+extradata[1];
					if (triggerpoint>(samplestosend-5)) triggerpoint=samplestosend/2;
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
					ioCount = 0;
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
					ioCount = 0;
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
					state=READ;
				end
			end
			else if (readdata==135) begin
				byteswanted=2;//wait for next bytes which are the channel and PWM
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					if (extradata[0]/4 ==myid) begin //I have this channel
						if (extradata[0]%4==0) PWMoffset0 = extradata[1];//set the PWM value for the channel (fraction of 256 of which to be on for, *3.3V)
						if (extradata[0]%4==1) PWMoffset1 = extradata[1];
						if (extradata[0]%4==2) PWMoffset2 = extradata[1];
						if (extradata[0]%4==3) PWMoffset3 = extradata[1];
					end
					state=READ;
				end
			end
			else if (readdata==136) begin
				byteswanted=5;//wait for next bytes which are the stuff to send over i2c
				comdata=readdata;
				newcomdata=1; //pass it on
				if (bytesread<byteswanted) state=READMORE;
				else begin
					//i2c_addr = 7'b0100000;// 0x20 // for all 3 pins of (last 3 digits) to GND of MCP23017
					//i2c_addr = 7'b0100111;// 0x27 // for all 3 pins (last 3 digits) to VCC of MCP23017
					//i2c_addr = 7'b1100000;// 0x60 // for MCP4728
					i2c_datacounttosend=extradata[0];//how many bytes of info to send (not counting address)
					i2c_addr=extradata[1]; // get address to write to
					//send over i2c!
					i2cdata[0]=extradata[2];
					i2cdata[1]=extradata[3];
					i2cdata[2]=extradata[4];
					//i2cdata[3]=extradata[5];
					//i2cdata[4]=extradata[6];
					//i2cdata[5]=extradata[7];
					//i2cdata[6]=extradata[8];
					//i2cdata[7]=extradata[9];
					state=I2CWAIT;
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
					state=WRITE_EXT1;
				end
			end
			if ( (thecounter-theoldcounter) > 100000000 ) begin
				//state=READ;//timeout!
				ioCount = 0;
				data[0] = 8'hfb;//send message indicating timeout
				if (do_usb) state=WRITEUSB1;
				else state=WRITE1;
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
			if(SendCount==0) begin 
				ioCount = 0;
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
				state=WRITE_EXT1;
        end
      end
		WRITE_EXT1: begin
			rden = 1;
			if( (!txBusy||do_usb) && (!usb_txe_busy||!do_usb) && (thecounter[clockbitstowait]!=thecounterbit)) begin // wait a few clock cycles??
				//rotate through the 4 outputs
				case(SendCount[ram_width+1:ram_width])
				0: begin
					txData<=ram_output1;
					usb_dataio<=ram_output1;	
				end
				1: begin
					txData<=ram_output2;
					usb_dataio<=ram_output2;	
				end
				2: begin
					txData<=ram_output3;
					usb_dataio<=ram_output3;	
				end
				3: begin
					txData<=ram_output4;
					usb_dataio<=ram_output4;	
				end
				endcase
				if (do_usb) usb_wr<= 1; else txStart<= 1;				
				SendCount = SendCount + (2**sendincrement);
				rdaddress = rdaddress + (2**sendincrement);
				rdaddress2 = rdaddress;
				if (samplestosend>0 && SendCount[ram_width-1:0]>=samplestosend) begin
					SendCount[ram_width-1:0]=0;
					SendCount[ram_width+1:ram_width] = (SendCount[ram_width+1:ram_width] + 1);
					rdaddress = wraddress_triggerpoint - triggerpoint;// - 1;
					rdaddress2 = rdaddress;
				end
				state=WRITE_EXT2;
			end
			if ( (thecounter-theoldcounter) > 100000000 ) begin
				rden = 0;
				state=READ;//timeout!
			end
		end
		WRITE_EXT2: begin
			if( !do_usb || (thecounter[clockbitstowait]==thecounterbit) ) begin // wait a few clock cycles in usb mode??
				if (do_usb) usb_wr<= 0; else txStart<= 0;			
				if(SendCount==0) begin 
					rden = 0;
					if (autorearm) begin
						//tell them all to prime the trigger
						get_ext_data=1;
					end
					state=READ;
				end
				else begin
					if ( (rdaddress- wraddress_triggerpoint-64)>=0 && (rdaddress-wraddress_triggerpoint+64)<128 ) begin //update display // - triggerpoint ??
						if (SendCount[ram_width+1:ram_width]==chanforscreen) screencolumndata[rdaddress - wraddress_triggerpoint - 64]=(63-txData[7:2]);//store most significant 6 bits
						screenwren = 1;
					end
					state=WRITE_EXT1;
				end
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
        if (ioCount != LENMAX) begin
          ioCount = ioCount + 1;
          state = WRITE1;
        end else begin
          ioCount = 0;
          state = READ;
        end
      end
		
		//just writng out some data bytes over USB
		WRITEUSB1: begin
		  newcomdata<=0; //set this back, to just send out data once
        if (!usb_txe_busy) begin
          usb_dataio = data[ioCount];
			 usb_wr = 1;
          state = WRITEUSB2;
        end
      end
      WRITEUSB2: begin
        usb_wr = 0;
        if (ioCount != LENMAX) begin
          ioCount = ioCount + 1;
          state = WRITEUSB1;
        end else begin
          ioCount = 0;
          state = READ;
        end
      end

		//I2C, from https://eewiki.net/pages/viewpage.action?pageId=10125324
		I2CWAIT: begin
			newcomdata<=0; //set this back, to just send out data once
			if (~i2c_busy) begin
				//i2c_addr set elsewhere first
				i2c_rw = 0;
				i2c_datawr = i2cdata[0];
				//i2c_datacounttosend set elsewhere first
				i2c_datacount=1;
				//i2c_datard = 
				state=I2CSEND1;
			end
		end
		I2CSEND1: begin
			i2c_ena = 1;
			if (i2c_datacount >= i2c_datacounttosend) begin
				state=READ; //sets i2c_ena back to 0
			end
			else if (i2c_busy) begin
				i2c_datawr = i2cdata[i2c_datacount];
				state=I2CSEND2;
			end
		end
		I2CSEND2: begin
			if (~i2c_busy) begin
				//i2c_ackerror
				i2c_datacount = i2c_datacount+1;
				state=I2CSEND1;
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
