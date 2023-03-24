module oscillo(clk, startTrigger, clk_flash, data_flash1, data_flash2, data_flash3, data_flash4, pwr1, pwr2, shdn_out, spen_out, trig_in, trig_out, rden, rdaddress, 
data_ready, wraddress_triggerpoint, imthelast, imthefirst,rollingtrigger,trigDebug,triggerpoint,downsample,
trigthresh,trigchannels,triggertype,triggertot,format_sdin_out,div_sclk_out,outsel_cs_out,clk_spi,SPIsend,SPIsenddata,
wraddress,Acquiring,SPIstate,clk_flash2,trigthreshtwo,dout1,dout2,dout3,dout4,highres,ext_trig_in,use_ext_trig, nsmp, trigout, spareright, spareleft,
delaycounter,ext_trig_delay, noselftrig, nselftrigcoincidentreq, selftrigtempholdtime, allowsamechancoin,
trigratecounter,trigratecountreset);
input clk,clk_spi;
input startTrigger;
input [1:0] trig_in;
output reg [1:0] trig_out;
output reg pwr1=0;//to power up adc, set low
output reg pwr2=0;//to power up adc, set low
output reg shdn_out=0;//Active-High Power-Down. If SPEN is high (parallel programming mode), a register reset is initiated on the falling edge of SHDN.
output reg spen_out=0;//Active-Low SPI Enable. Drive high to enable parallel programming mode.
output reg format_sdin_out=0;//0=2's complement, 1=offset binary, unconnected=gray code
output reg div_sclk_out=0;//0=divide clock by 1, 1=divide clock by 2, unconnected=divide clock by 4
output reg outsel_cs_out=1;//0=CMOS (dual bus), 1=MUX CMOS (channel A data bus), unconnected=MUX CMOS (channel b data bus)
input clk_flash, clk_flash2;
input [7:0] data_flash1, data_flash2, data_flash3, data_flash4;
output reg [7:0] dout1, dout2, dout3, dout4;
parameter ram_width=10;
output reg[ram_width-1:0] wraddress_triggerpoint;
reg[ram_width-1:0] wraddress_triggerpoint2;//to pass timing (need to send to slow clk domain)
input wire [ram_width-1:0] rdaddress;
input wire rden;//read enable
output reg data_ready=0;
input wire imthelast, imthefirst;
input wire rollingtrigger;
output reg trigDebug=1;
input [7:0] trigthresh, trigthreshtwo;
input [3:0] trigchannels;
input [ram_width-1:0] triggerpoint;
input [7:0] downsample; // only record 1 out of every 2^downsample samples
reg [7:0] downsample2; // to pass timing
input [3:0] triggertype;
reg [3:0] triggertype2; // to pass timing
input [ram_width:0] triggertot; // the top bit says whether to do check every sample or only according to downsample
input highres;
parameter maxhighres=5;
reg [7+maxhighres:0] highres1, highres2, highres3, highres4;
input ext_trig_in, use_ext_trig;
input [ram_width-1:0] nsmp;
reg [ram_width-1:0] nsmp2; // to pass timing
input [4:0] ext_trig_delay; // clk ticks to delay ext trigger by
input noselftrig; 
input [1:0] nselftrigcoincidentreq; // number of self trig channels required to be fired simultaneously
input [7:0] selftrigtempholdtime; // how long to fire a channel for
input allowsamechancoin; // whether to allow same channel, firing in the past, to count as coincidence

output reg [3:0] trigout;
output wire spareright;
input wire spareleft;

reg [31:0] SPIcounter=0;//clock counter for SPI
input [15:0] SPIsenddata;//the bits to send
input SPIsend;//start sending
reg [3:0] SPIsendcounter;//which bit to send
localparam SPI0=0, SPI1=1, SPI2=2, SPI3=3;
output reg[3:0] SPIstate=SPI0;
always @(posedge clk_spi) begin
if (!spen_out) begin // we're in SPI mode
SPIcounter=SPIcounter+1;
case (SPIstate)
	SPI0: begin // this is the beginning
		if (SPIsend) begin
			SPIcounter=0;
			outsel_cs_out=1;//start high
			div_sclk_out=1;
			SPIsendcounter=4'b1111;
			SPIstate=SPI1;
		end
	end
	SPI1: begin
		if (SPIcounter[2]) begin // start of sending, note that we wait a full tick (was 4)
			div_sclk_out=0;
			outsel_cs_out=0;//start sending
			format_sdin_out=SPIsenddata[SPIsendcounter];//the data
			SPIsendcounter=SPIsendcounter-4'b001;//keep track of how many bits we've sent
			SPIstate=SPI2;
		end
	end
	SPI2: begin
		if (!SPIcounter[2]) begin // sending data on rising edge, note that we wait a full tick
			div_sclk_out=1;
			if (SPIsendcounter==4'b1111) SPIstate=SPI3; //done
			else SPIstate=SPI1;//send next bit
		end
	end
	SPI3: begin
		if (SPIcounter[2]) begin // done sending, note that we wait a full tick
			outsel_cs_out=1;//back to high
			div_sclk_out=0;
			SPIstate=SPI0;
		end
	end
endcase
end // SPI mode
end // clk_spi posedge

reg Threshold1[3:0], Threshold2[3:0];
reg [ram_width:0] Threshold3[3:0];//keep track of the counter time it was above/below threshold for 
reg selftrigtemp[3:0];
reg Trigger;
reg AcquiringAndTriggered=0;
reg HaveFullData=0;
integer i;
initial begin
	Threshold3[0]=0;
	Threshold3[1]=0;
	Threshold3[2]=0;
	Threshold3[3]=0;
end
reg [ram_width-1:0] samplecount=0;
output reg [ram_width-1:0] wraddress;
output reg Acquiring;
reg PreOrPostAcquiring;

reg [7:0] data_flash1_reg; always @(posedge clk_flash) data_flash1_reg <= data_flash1;
reg [7:0] data_flash2_reg; always @(posedge clk_flash) data_flash2_reg <= data_flash2; // no multiplexing
//reg [7:0] data_flash2_reg; always @(negedge clk_flash) data_flash2_reg <= data_flash1; // for multiplexing

reg [7:0] data_flash3_reg_temp; always @(posedge clk_flash2) data_flash3_reg_temp <= data_flash3;
reg [7:0] data_flash4_reg_temp; always @(posedge clk_flash2) data_flash4_reg_temp <= data_flash4; // no multiplexing
//reg [7:0] data_flash4_reg_temp; always @(negedge clk_flash2) data_flash4_reg_temp <= data_flash3; // for multiplexing

//pipelines the reading in from clk2 to clk1, so we have a full clk1 cycle for calculations below
reg [7:0] data_flash3_reg; always @(posedge clk_flash) data_flash3_reg <= data_flash3_reg_temp;
reg [7:0] data_flash4_reg; always @(posedge clk_flash) data_flash4_reg <= data_flash4_reg_temp; // no multiplexing
//reg [7:0] data_flash4_reg; always @(negedge clk_flash) data_flash4_reg <= data_flash3_reg_temp; // for multiplexing

always @(posedge clk_flash) begin
	i=0;
	while (i<4) begin
		//if (trigchannels[i]) begin // always calculate the trigger, for output, even if we won't self-trigger on it
		
			// above threshold now?
			if (i==0) Threshold1[i] <= (data_flash1_reg>=trigthresh && data_flash1_reg<=trigthreshtwo);
			if (i==1) Threshold1[i] <= (data_flash2_reg>=trigthresh && data_flash2_reg<=trigthreshtwo);
			if (i==2) Threshold1[i] <= (data_flash3_reg>=trigthresh && data_flash3_reg<=trigthreshtwo);
			if (i==3) Threshold1[i] <= (data_flash4_reg>=trigthresh && data_flash4_reg<=trigthreshtwo);
			Threshold2[i] <= Threshold1[i]; // was above threshold?
			
			if (triggertype2[0]) begin // if positive edge, trigger! (possibly after demanding a timeout)
				if (triggertot[ram_width-1:0]) begin
					selftrigtemp[i] = 0;//assume we are not firing
					if (Threshold3[i]) begin
						if (triggertot[ram_width]) begin // only check every 2^downsample samples
							if (downsamplego) begin
								if (Threshold1[i]) Threshold3[i] <= Threshold3[i]+1; // keep track of how long it's been above threshold
								else Threshold3[i] <= 0; // reset once it goes below threshold
							end
						end
						else begin // check every sample
							if (Threshold1[i]) Threshold3[i] <= Threshold3[i]+1; // keep track of how long it's been above threshold
							else Threshold3[i] <= 0; // reset once it goes below threshold
						end
						if (Threshold3[i]>triggertot[ram_width-1:0]) begin //fired!
							selftrigtemp[i] = 1;
							Threshold3[i] <= 0; // reset once it fires
						end
					end
					else if (Threshold1[i] & ~Threshold2[i]) begin // got a positive edge
						Threshold3[i] <= 1; // start counting						
					end
				end
				else selftrigtemp[i] <= (Threshold1[i] & ~Threshold2[i]);// got a positive edge, just trigger
			end
			
			else begin // if negative edge, trigger! (possibly after demanding a timeout)				
				if (triggertot[ram_width-1:0]) begin
					selftrigtemp[i] = 0;//assume we are not firing
					if (Threshold3[i]) begin					
						if (triggertot[ram_width]) begin // only check every 2^downsample samples
							if (downsamplego) begin
								if (~Threshold1[i]) Threshold3[i] <= Threshold3[i]+1; // keep track of how long it's been below threshold
								else Threshold3[i] <= 0; // reset once it goes above threshold
							end
						end
						else begin // check every sample
							if (~Threshold1[i]) Threshold3[i] <= Threshold3[i]+1; // keep track of how long it's been below threshold
							else Threshold3[i] <= 0; // reset once it goes above threshold
						end						
						if (Threshold3[i]>triggertot[ram_width-1:0]) begin //fired!
							selftrigtemp[i] = 1;
							Threshold3[i] <= 0; // reset once it fires
						end
					end
					else if (~Threshold1[i] & Threshold2[i]) begin // got a negative edge
						Threshold3[i] <= 1; // start counting						
					end
				end
				else selftrigtemp[i] <= (~Threshold1[i] & Threshold2[i]);// got a negative edge, just trigger
			end
			
		//end // if (trigchannels[i])
		i=i+1;
	end
end

reg[12:0] ext_trig_in_delay_bits=0;
reg ext_trig_in_delayed;
always @(posedge clk_flash) begin
	ext_trig_in_delayed <= ext_trig_in_delay_bits[ext_trig_delay];
	ext_trig_in_delay_bits <= {ext_trig_in_delay_bits[12-1:0], ext_trig_in};
end

reg[31:0] thecounter; // counter for the rolling trigger
reg[1:0] nselftrigstemp[4]; // number of self trig channels fired, other than this one
reg[7:0] selftrigtemphold[4]; // will keep track of which channel have fired
always @(posedge clk_flash) begin
	if (Trigger) thecounter<=0; else thecounter<=thecounter+1;
	i=0;
	while (i<4) begin
		if (selftrigtemp[i]) selftrigtemphold[i]<=selftrigtempholdtime; // trigger has fired
		else if (selftrigtemphold[i]>0 && downsamplego) selftrigtemphold[i]<=selftrigtemphold[i]-1; // count down (paying attention to downsample) so the trigger stops firing after selftrigtempholdtime
		if (allowsamechancoin) nselftrigstemp[i] <= (trigchannels[(i)%4]&&selftrigtemphold[(i)%4]>0) + (trigchannels[(i+1)%4]&&selftrigtemphold[(i+1)%4]>0) + (trigchannels[(i+2)%4]&&selftrigtemphold[(i+2)%4]>0) + (trigchannels[(i+3)%4]&&selftrigtemphold[(i+3)%4]>0);
		else nselftrigstemp[i] <= (trigchannels[(i+1)%4]&&selftrigtemphold[(i+1)%4]>0) + (trigchannels[(i+2)%4]&&selftrigtemphold[(i+2)%4]>0) + (trigchannels[(i+3)%4]&&selftrigtemphold[(i+3)%4]>0);
		i=i+1;
	end
end
wire selfedgetrig; // currently on an edge
assign selfedgetrig = (trigchannels[0]&&selftrigtemp[0]&&nselftrigstemp[0]>=nselftrigcoincidentreq)||
							 (trigchannels[1]&&selftrigtemp[1]&&nselftrigstemp[1]>=nselftrigcoincidentreq)||
							 (trigchannels[2]&&selftrigtemp[2]&&nselftrigstemp[2]>=nselftrigcoincidentreq)||
							 (trigchannels[3]&&selftrigtemp[3]&&nselftrigstemp[3]>=nselftrigcoincidentreq);
wire selftrig; //trigger is an OR of all the channels which are active // also trigger every second or so (rolling)
assign selftrig = selfedgetrig || (rollingtrigger&thecounter>=25000000) || (use_ext_trig&ext_trig_in_delayed);

// trigger rate counter stuff
output reg[31:0] trigratecounter=0;
input trigratecountreset;
reg [7:0] selfedgetrigdeadtime=0; // to keep track of deadtime for the trigger rate counter
always @(posedge clk_flash) begin
	if (selfedgetrig && selfedgetrigdeadtime==0) begin // only count it if the counter is not dead because a trigger fired recently
		trigratecounter = trigratecounter+1;
		selfedgetrigdeadtime<=selftrigtempholdtime; // trigger has fired, start counting down deadtime, from selftrigtempholdtime (same as used for coincidence trigger)
	end
	if (selfedgetrigdeadtime>0 && downsamplego) selfedgetrigdeadtime<=selfedgetrigdeadtime-1; // count down deadtime (paying attention to downsample) so the trigger stops being dead after selftrigtempholdtime
	if (trigratecountreset) trigratecounter=0;
end
// end trigger rate counter stuff

always @(posedge clk_flash)
if (noselftrig) Trigger = trig_in[1]; // just trigger if we get a trigger in towards to right
else if (imthefirst & imthelast) Trigger = selftrig; // we trigger if we triggered ourselves
else if (imthefirst) Trigger = selftrig||trig_in[1]; // we trigger if we triggered ourselves, or got a trigger in towards the right
else if (imthelast) Trigger = selftrig||trig_in[0]; // we trigger if we triggered ourselves, or got a trigger in towards the left
else Trigger = selftrig||trig_in[0]||trig_in[1]; // we trigger if we triggered ourselves, or got a trigger from the left or right

always @(posedge clk_flash)
if (noselftrig) trig_out[0] = 0; // we don't trigger out to the left
else if (imthefirst) trig_out[0] = selftrig; // we trigger out to the left if we triggered ourselves
else trig_out[0] = trig_in[0]||selftrig; // we trigger out to the left if we got a trig in towards the left, or we triggered ourselves

always @(posedge clk_flash)
if (noselftrig) trig_out[1] = trig_in[1]; // we trigger out to the right if we got a trig in towards the right
else if (imthelast) trig_out[1] = selftrig; // we trigger out to the right if we triggered ourselves
else trig_out[1] = trig_in[1]||selftrig; // we trigger out to the right if we got a trig in towards the right, or we triggered ourselves

reg Ttrig[4]; // whether to fire each of the 4 trigger bits
reg[3:0] Tcounter[4]; // counters for the output trigger bits (to hold them high for a while after a trigger)
reg[7:0] Tcounter_test_countdown; // use for sending 50 test triggers
output reg[7:0] delaycounter;
reg[7:0] spareleftcounter;
always @(posedge clk_flash) begin
	if (spareleft) begin
		if (spareleftcounter<205) begin
			spareleftcounter<=spareleftcounter+1; // delays for 205 ticks, to wait for trigger board to be ready for counting (it was waiting for all normal triggers from all boards to cease)
			Ttrig[0]<=0; Ttrig[1]<=0; Ttrig[2]<=0; Ttrig[3]<=0; // no pulses yet
			Tcounter[0]<=0; Tcounter[1]<=0; Tcounter[2]<=0; Tcounter[3]<=0; //reset trig counters
		end
		else begin
			Ttrig[0] <= (Tcounter_test_countdown!=0); // for calibration (clock skew) we fire trigger 0
			if (Tcounter_test_countdown) Tcounter_test_countdown <= Tcounter_test_countdown-1;
		end
	end
	else begin
		i=0; while (i<4) begin
			if (selftrigtemp[i]) Tcounter[i]<=4; // will count down from 4 to send the trigger out once
			else if (Tcounter[i]) Tcounter[i]<=Tcounter[i]-1;
			Ttrig[i] <= (Tcounter[i]>0);
			i=i+1;
		end
		Tcounter_test_countdown <= 219; // should give 54 or 55 pulses (depending on when spareleft fires)
		spareleftcounter<=0;
	end
end
reg[1:0] Pulsecounter=0;
reg[3:0] trig_ext_out=4'd0;
always @(posedge clk_flash) begin
	if (noselftrig) trigout[0]<=(Ttrig[Pulsecounter]);
	else begin
		if (Trigger) begin
			trig_ext_out<=4'd10;//time to fire trig_ext_out for (max 15)
			trigout[0]<=1'b1;
		end
		else if (trig_ext_out>4'd0) begin
			trig_ext_out<=trig_ext_out-4'd1;
			trigout[0]<=1'b1;
		end
		else trigout[0]<=1'b0;
	end
	Pulsecounter<=Pulsecounter+1; // for iterating through the trigger bins
end
assign spareright = spareleft; // pass the calibration signal along to the right

reg startAcquisition;//ready to trigger?
always @(posedge clk) begin
	if(~startAcquisition) startAcquisition <= startTrigger; // an input to the module
	else if(AcquiringAndTriggered2) startAcquisition <= 0;
	//assign trigDebug = startAcquisition;
end
reg startAcquisition1; always @(posedge clk_flash) startAcquisition1 <= startAcquisition;
reg startAcquisition2; always @(posedge clk_flash) startAcquisition2 <= startAcquisition1;

localparam INIT=0, PREACQ=1, WAITING=2, POSTACQ=3;
reg[2:0] state=INIT;
reg [23:0] downsamplecounter;//max downsample is 22
reg [maxhighres:0] highrescounter;//for counting highres
wire downsamplego;
assign downsamplego = downsamplecounter[downsample2] || downsample2==0; // pay attention to sample when downsamplego is true
always @(posedge clk_flash) begin
	nsmp2<=nsmp;//to pass timing
	triggertype2<=triggertype;//to pass timing
	downsample2<=downsample;//to pass timing
	
	case (state)
	INIT: begin // this is the beginning... wait for the go-ahead to start acquiring the pre-trigger samples
		if (startAcquisition2) begin
			samplecount <= 0;
			Acquiring <= 1; // start acquiring?
			HaveFullData <= 0;
			PreOrPostAcquiring <= 1; // preacquiring
			downsamplecounter=1;
			highrescounter=0;
			highres1=0;
			highres2=0;
			highres3=0;
			highres4=0;
			state=PREACQ;
		end
	end
	PREACQ: begin // pre-trigger bytes acquired already?
		if( (samplecount==triggerpoint) ) begin
			PreOrPostAcquiring <= 0;
			state=WAITING;
		end
	end
	WAITING: begin
		if(Trigger) begin // now we wait for the trigger, and then record the triggerpoint
			AcquiringAndTriggered <= 1; // Trigger? Start getting the rest of the bytes
			PreOrPostAcquiring <= 1;
			wraddress_triggerpoint2 <= wraddress; // keep track of where the trigger happened
			state=POSTACQ;
		end
	end
	POSTACQ: begin
		if(samplecount==nsmp2) begin // got the rest of the bytes? then stop acquiring
			Acquiring <= 0;
			AcquiringAndTriggered <= 0;
			HaveFullData <= 1;
			PreOrPostAcquiring <= 0;
			state=INIT;
		end
	end
	endcase
	
	downsamplecounter=downsamplecounter+1;
	if (highres) begin // doing highres mode (averaging over samples within each downsample)
		highrescounter=highrescounter+1;
		highres1=highres1+data_flash1_reg;
		highres2=highres2+data_flash2_reg;
		highres3=highres3+data_flash3_reg;
		highres4=highres4+data_flash4_reg;
		if (downsamplego || highrescounter[maxhighres]) begin
			highrescounter=0;
			if (downsample2>maxhighres) begin			
				dout1=highres1>>maxhighres;
				dout2=highres2>>maxhighres;
				dout3=highres3>>maxhighres;
				dout4=highres4>>maxhighres;
			end
			else begin
				dout1=highres1>>downsample2;
				dout2=highres2>>downsample2;
				dout3=highres3>>downsample2;
				dout4=highres4>>downsample2;
			end
			highres1=0;
			highres2=0;
			highres3=0;
			highres4=0;
		end
	end
	else begin // not highres mode, just copy in the data
		dout1=data_flash1_reg;
		dout2=data_flash2_reg;
		dout3=data_flash3_reg;
		dout4=data_flash4_reg;
	end
	if (downsamplego) begin // increment the write address (store new data) every 1/2^downsample samples
		downsamplecounter=1;
		if(Acquiring) wraddress <= wraddress + 1;
		if(PreOrPostAcquiring) samplecount <= samplecount + 1;
	end
end

// go from flash clock to fpga main clock domain
reg AcquiringAndTriggered1; always @(posedge clk) AcquiringAndTriggered1 <= AcquiringAndTriggered;
reg AcquiringAndTriggered2; always @(posedge clk) AcquiringAndTriggered2 <= AcquiringAndTriggered1;
reg HaveFullData1; always @(posedge clk) HaveFullData1 <= HaveFullData;
reg HaveFullData2; always @(posedge clk) HaveFullData2 <= HaveFullData1;

always @(posedge clk) begin
	wraddress_triggerpoint=wraddress_triggerpoint2; // sends to slow clk domain
	if (startAcquisition) data_ready=0; // waiting for trigger
	else if (HaveFullData2) data_ready=1; // ready to read out
end

endmodule
