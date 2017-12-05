module hvsync_generator(clk, vga_h_sync, vga_v_sync, inDisplayArea, CounterX, CounterY);
input clk;
output vga_h_sync, vga_v_sync;
output inDisplayArea;
output [9:0] CounterX;
output [8:0] CounterY;

//////////////////////////////////////////////////
reg [9:0] CounterX;
reg CounterXflip;
reg [8:0] CounterY;
wire CounterXmaxed = (CounterX==767);

always @(posedge clk)
if(CounterXmaxed)
	CounterX <= 0;
else begin
	if (CounterXflip) CounterX <= CounterX + 1;
	CounterXflip <= ~CounterXflip;//goes from 0 to 1, so we only increment half the times (for 50Mhz!)
   end
	
always @(posedge clk)
if(CounterXmaxed) CounterY <= CounterY + 1;

reg vga_HS, vga_VS;
always @(posedge clk)
begin
	vga_HS <= (CounterX[9:4]==45); // change this value to move the display horizontally
	vga_VS <= (CounterY==498); // change this value to move the display vertically
end

reg inDisplayArea;
always @(posedge clk)
if(inDisplayArea==0)
	inDisplayArea <= (CounterXmaxed) && (CounterY<480);
else
	inDisplayArea <= !(CounterX==639);
	
assign vga_h_sync = ~vga_HS;
assign vga_v_sync = ~vga_VS;

endmodule
