module ring_counter (clk,out_carry,carryin,carryout,delayin,start,out_delay);
input clk;
output reg [7:0] out_carry;
output reg [7:0] out_delay;
input carryin;
output carryout;
input wire [DELAY-1:0] delayin;

parameter DELAY=100; // about 13-14 per tick (10ns) // actually set in serial bdf design file
wire [DELAY-1:0] delay_line /* synthesis keep */;
output reg start;
reg freeze;
assign carryout = freeze; // set the output high when we freeze

wire freezeline;
// assign freezeline = freeze; // freeze the chain whenever we say to freeze internally
assign freezeline = carryin; // freeze the chain based on external freeze signal

//delay line
genvar i;
generate
for (i=1; i<DELAY; i=i+1)
	begin : del
		//assign delay_line [i] = delay_line[i-1+freezeline]; // when freeze is 1, it just is assigned to itself... otherwise it is assigned to it's friend from the left
		assign delay_line [i] = (freezeline) ? delay_line[i] : delay_line[i-1]; // when freeze is 1, it just is assigned to itself... otherwise it is assigned to it's friend from the left
	end
endgenerate
assign delay_line[0] = start; // we trigger the chain with the "start" command

initial begin
	start<=0;
	freeze<=0;
end

//sync them over to the input clock
integer delay_counter=0;
always @(posedge clk) begin
	if (freeze) begin
		//count until the first 0
		if (delay_line[delay_counter]) delay_counter=delay_counter+1;//keep counting
		else out_delay[7:0] = delay_counter;//found the first 0
	end
	else delay_counter=0;//just wait
end

integer counter=0;
integer delayer=0;
//integer cycles=0;
always @(posedge clk) begin
	counter = counter+1;
	if (counter==200000000) begin // every 2 seconds, reset to 0 and wait for start
		freeze=0;
		start=0;
	end
	if (counter==200000050) begin // 500 ns later, start
		start=1;
	end
	if (counter==200000050+delayer) begin // then freeze, after some delay possibly
		freeze=1;
		
//		cycles=cycles+1;
//		if (cycles==10) begin //every 3 seconds, increment the delayer time by a tick
//			delayer=delayer+1;
//			cycles=7;//wait 10 seconds before starting up the incrementing
//		end
		
	end
	if (counter==200000050+delayer+ 100000) counter=0;//do it again
end

integer delay_counter2=1;
always @(posedge clk) begin
	if (counter > 200000050+delayer + 10) begin // give it time to stop
		//count until a 1
		if (delayin[delay_counter2]) out_carry[7:0] = delay_counter2 - 150;//found a 1
		else delay_counter2=delay_counter2+1;//keep counting
	end
	else delay_counter2=1;//just wait
end

endmodule
