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


module altera_modular_adc_sequencer_csr (
    input               clk,
    input               rst_n,
    input               addr,
    input               read,
    input               write,
    input [31:0]        writedata,
    input               clr_run,

    output reg [31:0]   readdata,
    output reg          run,
    output reg          sw_clr_run,
    output              con_mode,
    output              single_mode,
    output              recab_mode
);

reg [2:0]   mode;

wire        cmd_addr;
wire        cmd_wr_en;
wire        cmd_rd_en;
wire [31:0] cmd_internal;
wire [31:0] readdata_nxt;

//--------------------------------------------------------------------------------------------//
// address decode
//--------------------------------------------------------------------------------------------//
assign cmd_addr = (addr == 1'b0);



//--------------------------------------------------------------------------------------------//
// write enable
//--------------------------------------------------------------------------------------------//
assign cmd_wr_en = cmd_addr & write;



//--------------------------------------------------------------------------------------------//
// read enable
//--------------------------------------------------------------------------------------------//
assign cmd_rd_en = cmd_addr & read;



//--------------------------------------------------------------------------------------------//
// mode register bits
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        mode <= 3'h0;
    else if (cmd_wr_en & ~run)
        mode <= writedata[3:1];
end


//--------------------------------------------------------------------------------------------//
// run register bit
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        run <= 1'b0;
    else if (clr_run)
        run <= 1'b0;
    else if (cmd_wr_en & writedata[0])
        run <= 1'b1;
end



//--------------------------------------------------------------------------------------------//
// Logic to detect SW perform a clear on the run bit
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sw_clr_run <= 1'b0;
    else if (clr_run)
        sw_clr_run <= 1'b0;
    else if (run & con_mode & cmd_wr_en & ~writedata[0])
        sw_clr_run <= 1'b1;
end



//--------------------------------------------------------------------------------------------//
// Avalon read data path
//--------------------------------------------------------------------------------------------//
assign cmd_internal = {28'h0, mode, run};
assign readdata_nxt = cmd_internal & {32{cmd_rd_en}};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        readdata <= 32'h0;
    else
        readdata <= readdata_nxt;
end



//--------------------------------------------------------------------------------------------//
// Mode decoding
//--------------------------------------------------------------------------------------------//
assign con_mode     = (mode == 3'b000);
assign single_mode  = (mode == 3'b001);
assign recab_mode   = (mode == 3'b111);



endmodule
