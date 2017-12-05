module pong(clk, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, PaddlePosition);
input clk;
input [7:0] PaddlePosition;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

hvsync_generator syncgen(.clk(clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
  .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

/////////////////////////////////////////////////////////////////
wire border = (CounterX[9:3]==0) || (CounterX[9:3]==79) || (CounterY[8:3]==0) || (CounterY[8:3]==59);
wire[10:0] PaddlePosition2 = (PaddlePosition-49)*80;
wire paddle = (CounterX>=PaddlePosition2+8) && (CounterX<=PaddlePosition2+120) && (CounterY[8:4]==27);
wire BouncingObject = border | paddle; // active if the border or paddle is redrawing itself

/////////////////////////////////////////////////////////////////
parameter Nballs = 15;
wire [Nballs:0] inball;
reg [Nballs:0] inotherball;
wire [9:0] ballX [Nballs:0];
wire [8:0] ballY [Nballs:0];
wire [8:0] ballspeed [Nballs:0];
wire [8:0] ballmass [Nballs:0];

generate
  genvar i;
  for (i=0; i<Nballs; i=i+1) begin : dff
    mball #(.startX(20+((131*i)%600)), .startY(29+((7*i)%440)), .pballmass(1), .pballspeed(1)) ball_i (.clk(clk), 
	    .BouncingObject(BouncingObject), .inotherball(inotherball[i]), 
       .CounterX(CounterX), .CounterY(CounterY), .ballX(ballX[i]), .ballY(ballY[i]), 
		 .inball(inball[i]), .ballspeed(ballspeed[i]), .ballmass(ballmass[i]) );
  end
endgenerate

/////////////////////////////////////////////////////////////////
wire inaball = (inball!=0);
wire R = BouncingObject | inaball | (CounterX[3] ^ CounterY[3]);
wire G = BouncingObject | inaball;
wire B = BouncingObject | inaball;

reg [Nballs:0] iball;
reg [Nballs:0] jball;
always @(posedge clk) begin
   for (iball=0; iball<Nballs; iball=iball+1) begin
	   inotherball[iball] = 0;
	   for (jball=0; jball<Nballs; jball=jball+1) begin
		   if (inball[iball] & iball!=jball & inball[jball]) inotherball[iball] = 1;//ballmass[jball]*ballspeed[jball];
	   end
	end
end

reg vga_R, vga_G, vga_B;
always @(posedge clk) begin
	vga_R <= R & inDisplayArea;
	vga_G <= G & inDisplayArea;
	vga_B <= B & inDisplayArea;
end

endmodule
