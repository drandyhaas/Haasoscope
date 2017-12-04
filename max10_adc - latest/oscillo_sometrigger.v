module oscillo(clk, RxD, TxD, clk_flash, data_flash);
input clk;
input RxD;
output TxD;
input clk_flash;
input [7:0] data_flash;
reg startAcquisition;
wire AcquisitionStarted;

always @(posedge clk)
if(~startAcquisition)  startAcquisition <= RxD;
else if(AcquisitionStarted)  startAcquisition <= 0;

reg startAcquisition1; always @(posedge clk_flash) startAcquisition1 <= startAcquisition ;
reg startAcquisition2; always @(posedge clk_flash) startAcquisition2 <= startAcquisition1;

reg Acquiring;
always @(posedge clk_flash)
if(~Acquiring)  Acquiring <= startAcquisition2;
else if(&wraddress)  Acquiring <= 0;

reg [8:0] wraddress;
always @(posedge clk_flash) if(Acquiring) wraddress <= wraddress + 1;

reg Acquiring1; always @(posedge clk) Acquiring1 <= Acquiring;
reg Acquiring2; always @(posedge clk) Acquiring2 <= Acquiring1;
assign AcquisitionStarted = Acquiring2;

reg [8:0] rdaddress;
reg Sending;
wire TxD_busy;

always @(posedge clk)
if(~Sending)  Sending <= AcquisitionStarted;
else if(~TxD_busy) begin
  rdaddress <= rdaddress + 1;
  if(&rdaddress) Sending <= 0;
end

wire TxD_start = ~TxD_busy & Sending;
wire rden = TxD_start;

wire [7:0] ram_output;
async_transmitter async_txd(.clk(clk), .TxD(TxD), .TxD_start(TxD_start), .TxD_busy(TxD_busy), .TxD_data(ram_output));

///////////////////////////////////////////////////////////////////
reg [7:0] data_flash_reg; always @(posedge clk_flash) data_flash_reg <= data_flash;

LPM_RAM_DP #(.LPM_WIDTH(8), .LPM_WIDTHAD(9)) ram_flash (
  .data(data_flash_reg), .wraddress(wraddress), .wren(Acquiring), .wrclock(clk_flash),
  .q(ram_output), .rdaddress(rdaddress), .rden(rden), .rdclock(clk)
);

endmodule
