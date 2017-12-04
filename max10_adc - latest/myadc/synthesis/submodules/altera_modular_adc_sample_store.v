// (C) 2001-2015 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


module altera_modular_adc_sample_store #(
    parameter DUAL_ADC_MODE     = 0,
    parameter RSP_DATA_WIDTH    = 12
) (
    input                       clk,
    input                       rst_n,
    input [6:0]                 addr,
    input                       read,
    input                       write,
    input [31:0]                writedata,
    input                       rsp_valid,
    input [4:0]                 rsp_channel,
    input [RSP_DATA_WIDTH-1:0]  rsp_data,
    input                       rsp_sop,
    input                       rsp_eop,
    output reg [31:0]           readdata,
    output reg                  irq

);

localparam RAM_DATA_WIDTH = (DUAL_ADC_MODE == 1) ? 32 : 16;

reg                         e_eop;
reg                         s_eop;
reg [31:0]                  csr_readdata;
reg                         ram_rd_en_flp;
reg [5:0]                   slot_num;

wire                        ier_addr;
wire                        isr_addr;
wire                        ram_addr;
wire                        ier_wr_en;
wire                        isr_wr_en;
wire                        ier_rd_en;
wire                        isr_rd_en;
wire                        ram_rd_en;
wire                        set_eop;
wire [31:0]                 csr_readdata_nxt;
wire [31:0]                 ier_internal;
wire [31:0]                 isr_internal;
wire [31:0]                 readdata_nxt;
wire [RAM_DATA_WIDTH-1:0]   q_out;
wire                        irq_nxt;
wire [RAM_DATA_WIDTH-1:0]   ram_datain;
wire [RAM_DATA_WIDTH-1:0]   ram_readdata;

//--------------------------------------------------------------------------------------------//
// address decode
//--------------------------------------------------------------------------------------------//
assign ier_addr = (addr == 7'h40);
assign isr_addr = (addr == 7'h41);
assign ram_addr = (addr < 7'h40);



//--------------------------------------------------------------------------------------------//
// write enable
//--------------------------------------------------------------------------------------------//
assign ier_wr_en = ier_addr & write;
assign isr_wr_en = isr_addr & write;



//--------------------------------------------------------------------------------------------//
// read enable
//--------------------------------------------------------------------------------------------//
assign ier_rd_en = ier_addr & read;
assign isr_rd_en = isr_addr & read;
assign ram_rd_en = ram_addr & read;



//--------------------------------------------------------------------------------------------//
// interrupt enable register
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        e_eop <= 1'b1;
    else if (ier_wr_en)
        e_eop <= writedata[0];
end



//--------------------------------------------------------------------------------------------//
// interrupt status register
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        s_eop <= 1'b0;
    else if (set_eop)
        s_eop <= 1'b1;
    else if (isr_wr_en & writedata[0])
        s_eop <= 1'b0;
end



//--------------------------------------------------------------------------------------------//
// Avalon slave readdata path - read latency of 2 due to RAM's address and dataout register
//--------------------------------------------------------------------------------------------//
assign ier_internal     = {31'h0, e_eop};
assign isr_internal     = {31'h0, s_eop};
assign csr_readdata_nxt = (ier_internal & {32{ier_rd_en}}) |
                            (isr_internal & {32{isr_rd_en}});

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        csr_readdata <= 32'h0;
    else
        csr_readdata <= csr_readdata_nxt;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ram_rd_en_flp <= 1'b0;
    else
        ram_rd_en_flp <= ram_rd_en;
end

assign readdata_nxt = ram_rd_en_flp ? ram_readdata : csr_readdata;
assign ram_readdata = q_out[RAM_DATA_WIDTH-1:0]; 


generate
if (DUAL_ADC_MODE) begin
    assign ram_datain   = {4'h0, rsp_data[23:12], 4'h0, rsp_data[11:0]};
end
else begin
    assign ram_datain   = {4'h0, rsp_data};
end
endgenerate


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        readdata <= 32'h0;
    else
        readdata <= readdata_nxt;
end



//--------------------------------------------------------------------------------------------//
// RAM to store ADC sample
//--------------------------------------------------------------------------------------------//
altera_modular_adc_sample_store_ram #(
    .DATA_WIDTH (RAM_DATA_WIDTH)    
) u_ss_ram (
    .clock      (clk),
    .data       (ram_datain),
    .rdaddress  (addr[5:0]),
    .rden       (ram_rd_en),
    .wraddress  (slot_num),
    .wren       (rsp_valid),
    .q          (q_out)

);

//assign ram_datain = (DUAL_ADC_MODE == 1) ? ({8'h0, rsp_data}) : ({4'h0, rsp_data});



//--------------------------------------------------------------------------------------------//
// Sequential counter to indicate which RAM location to store ADC sample
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        slot_num <= 6'h0;
    else if (set_eop)
        slot_num <= 6'h0;
    else if (rsp_valid)
        slot_num <= slot_num + 6'h1; 
end



//--------------------------------------------------------------------------------------------//
// Set EOP status
//--------------------------------------------------------------------------------------------//
assign set_eop = rsp_valid & rsp_eop;



//--------------------------------------------------------------------------------------------//
// IRQ
//--------------------------------------------------------------------------------------------//
assign irq_nxt = e_eop & s_eop;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        irq <= 1'b0;
    else
        irq <= irq_nxt;
end



endmodule
