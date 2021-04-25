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


module altera_modular_adc_sequencer_ctrl #(
    parameter   CSD_LENGTH      = 64,
    parameter   CSD_ASIZE       = 6,
    parameter   CSD_SLOT_0      = 5'h0,
    parameter   CSD_SLOT_1      = 5'h0,
    parameter   CSD_SLOT_2      = 5'h0,
    parameter   CSD_SLOT_3      = 5'h0,
    parameter   CSD_SLOT_4      = 5'h0,
    parameter   CSD_SLOT_5      = 5'h0,
    parameter   CSD_SLOT_6      = 5'h0,
    parameter   CSD_SLOT_7      = 5'h0,
    parameter   CSD_SLOT_8      = 5'h0,
    parameter   CSD_SLOT_9      = 5'h0,
    parameter   CSD_SLOT_10     = 5'h0,
    parameter   CSD_SLOT_11     = 5'h0,
    parameter   CSD_SLOT_12     = 5'h0,
    parameter   CSD_SLOT_13     = 5'h0,
    parameter   CSD_SLOT_14     = 5'h0,
    parameter   CSD_SLOT_15     = 5'h0,
    parameter   CSD_SLOT_16     = 5'h0,
    parameter   CSD_SLOT_17     = 5'h0,
    parameter   CSD_SLOT_18     = 5'h0,
    parameter   CSD_SLOT_19     = 5'h0,
    parameter   CSD_SLOT_20     = 5'h0,
    parameter   CSD_SLOT_21     = 5'h0,
    parameter   CSD_SLOT_22     = 5'h0,
    parameter   CSD_SLOT_23     = 5'h0,
    parameter   CSD_SLOT_24     = 5'h0,
    parameter   CSD_SLOT_25     = 5'h0,
    parameter   CSD_SLOT_26     = 5'h0,
    parameter   CSD_SLOT_27     = 5'h0,
    parameter   CSD_SLOT_28     = 5'h0,
    parameter   CSD_SLOT_29     = 5'h0,
    parameter   CSD_SLOT_30     = 5'h0,
    parameter   CSD_SLOT_31     = 5'h0,
    parameter   CSD_SLOT_32     = 5'h0,
    parameter   CSD_SLOT_33     = 5'h0,
    parameter   CSD_SLOT_34     = 5'h0,
    parameter   CSD_SLOT_35     = 5'h0,
    parameter   CSD_SLOT_36     = 5'h0,
    parameter   CSD_SLOT_37     = 5'h0,
    parameter   CSD_SLOT_38     = 5'h0,
    parameter   CSD_SLOT_39     = 5'h0,
    parameter   CSD_SLOT_40     = 5'h0,
    parameter   CSD_SLOT_41     = 5'h0,
    parameter   CSD_SLOT_42     = 5'h0,
    parameter   CSD_SLOT_43     = 5'h0,
    parameter   CSD_SLOT_44     = 5'h0,
    parameter   CSD_SLOT_45     = 5'h0,
    parameter   CSD_SLOT_46     = 5'h0,
    parameter   CSD_SLOT_47     = 5'h0,
    parameter   CSD_SLOT_48     = 5'h0,
    parameter   CSD_SLOT_49     = 5'h0,
    parameter   CSD_SLOT_50     = 5'h0,
    parameter   CSD_SLOT_51     = 5'h0,
    parameter   CSD_SLOT_52     = 5'h0,
    parameter   CSD_SLOT_53     = 5'h0,
    parameter   CSD_SLOT_54     = 5'h0,
    parameter   CSD_SLOT_55     = 5'h0,
    parameter   CSD_SLOT_56     = 5'h0,
    parameter   CSD_SLOT_57     = 5'h0,
    parameter   CSD_SLOT_58     = 5'h0,
    parameter   CSD_SLOT_59     = 5'h0,
    parameter   CSD_SLOT_60     = 5'h0,
    parameter   CSD_SLOT_61     = 5'h0,
    parameter   CSD_SLOT_62     = 5'h0,
    parameter   CSD_SLOT_63     = 5'h0
) (
    input               clk,
    input               rst_n,
    input               run,
    input               sw_clr_run,
    input               con_mode,
    input               single_mode,
    input               recab_mode,
    input               cmd_ready,

    output reg          cmd_valid,
    output reg [4:0]    cmd_channel,
    output reg          cmd_sop,
    output reg          cmd_eop,
    output reg          clr_run
);

reg                     seq_state;
reg                     seq_state_nxt;
reg [CSD_ASIZE-1:0]     slot_sel;
reg [CSD_ASIZE-1:0]     slot_sel_nxt;
reg                     valid_req;

wire [4:0]      csd[0:63];
wire [4:0]      csdmem[0:CSD_LENGTH-1];
wire            last_slot;
wire            done;
wire            done_con;
wire            done_single;
wire            valid_mode;
wire [4:0]      cmd_channel_nxt;
wire            cmd_sop_nxt;
wire            cmd_eop_nxt;

localparam          IDLE        = 1'b0;
localparam          READY       = 1'b1;


//--------------------------------------------------------------------------------------------//
// Assign conversion sequence data parameter into a temporary array
//--------------------------------------------------------------------------------------------//
assign csd[0] = CSD_SLOT_0;
assign csd[1] = CSD_SLOT_1;
assign csd[2] = CSD_SLOT_2;
assign csd[3] = CSD_SLOT_3;
assign csd[4] = CSD_SLOT_4;
assign csd[5] = CSD_SLOT_5;
assign csd[6] = CSD_SLOT_6;
assign csd[7] = CSD_SLOT_7;
assign csd[8] = CSD_SLOT_8;
assign csd[9] = CSD_SLOT_9;
assign csd[10] = CSD_SLOT_10;
assign csd[11] = CSD_SLOT_11;
assign csd[12] = CSD_SLOT_12;
assign csd[13] = CSD_SLOT_13;
assign csd[14] = CSD_SLOT_14;
assign csd[15] = CSD_SLOT_15;
assign csd[16] = CSD_SLOT_16;
assign csd[17] = CSD_SLOT_17;
assign csd[18] = CSD_SLOT_18;
assign csd[19] = CSD_SLOT_19;
assign csd[20] = CSD_SLOT_20;
assign csd[21] = CSD_SLOT_21;
assign csd[22] = CSD_SLOT_22;
assign csd[23] = CSD_SLOT_23;
assign csd[24] = CSD_SLOT_24;
assign csd[25] = CSD_SLOT_25;
assign csd[26] = CSD_SLOT_26;
assign csd[27] = CSD_SLOT_27;
assign csd[28] = CSD_SLOT_28;
assign csd[29] = CSD_SLOT_29;
assign csd[30] = CSD_SLOT_30;
assign csd[31] = CSD_SLOT_31;
assign csd[32] = CSD_SLOT_32;
assign csd[33] = CSD_SLOT_33;
assign csd[34] = CSD_SLOT_34;
assign csd[35] = CSD_SLOT_35;
assign csd[36] = CSD_SLOT_36;
assign csd[37] = CSD_SLOT_37;
assign csd[38] = CSD_SLOT_38;
assign csd[39] = CSD_SLOT_39;
assign csd[40] = CSD_SLOT_40;
assign csd[41] = CSD_SLOT_41;
assign csd[42] = CSD_SLOT_42;
assign csd[43] = CSD_SLOT_43;
assign csd[44] = CSD_SLOT_44;
assign csd[45] = CSD_SLOT_45;
assign csd[46] = CSD_SLOT_46;
assign csd[47] = CSD_SLOT_47;
assign csd[48] = CSD_SLOT_48;
assign csd[49] = CSD_SLOT_49;
assign csd[50] = CSD_SLOT_50;
assign csd[51] = CSD_SLOT_51;
assign csd[52] = CSD_SLOT_52;
assign csd[53] = CSD_SLOT_53;
assign csd[54] = CSD_SLOT_54;
assign csd[55] = CSD_SLOT_55;
assign csd[56] = CSD_SLOT_56;
assign csd[57] = CSD_SLOT_57;
assign csd[58] = CSD_SLOT_58;
assign csd[59] = CSD_SLOT_59;
assign csd[60] = CSD_SLOT_60;
assign csd[61] = CSD_SLOT_61;
assign csd[62] = CSD_SLOT_62;
assign csd[63] = CSD_SLOT_63;



//--------------------------------------------------------------------------------------------//
// Assign valid conversion sequence data parameter into an array
//--------------------------------------------------------------------------------------------//
genvar i;
generate
    for (i=0; i<CSD_LENGTH; i=i+1) begin : assign_csdmem
        assign csdmem[i] = csd[i];
    end
endgenerate



//--------------------------------------------------------------------------------------------//
// Sequncer FSM
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        seq_state   <= IDLE;
    else
        seq_state   <= seq_state_nxt;
end

always @* begin
    case (seq_state)
        IDLE: begin
            clr_run         = 1'b0;
            slot_sel_nxt    = {CSD_ASIZE{1'b0}};

            if (run & valid_mode) begin
                seq_state_nxt   = READY;
                valid_req       = 1'b1;
            end
            else begin
                seq_state_nxt   = IDLE;
                valid_req       = 1'b0;
            end
        end

        READY: begin
            if (cmd_ready & (recab_mode | done)) begin
                seq_state_nxt   = IDLE;
                valid_req       = 1'b0;
                slot_sel_nxt    = {CSD_ASIZE{1'b0}};
                clr_run         = 1'b1;
            end
            else if (cmd_ready) begin
                seq_state_nxt   = READY;
                valid_req       = 1'b1;
                clr_run         = 1'b0;

                if (last_slot)
                    slot_sel_nxt    = {CSD_ASIZE{1'b0}};
                else
                    slot_sel_nxt    = slot_sel + {{(CSD_ASIZE-1){1'b0}}, 1'b1};

            end
            else begin
                seq_state_nxt   = READY;
                valid_req       = 1'b0;
                slot_sel_nxt    = slot_sel;
                clr_run         = 1'b0;
            end
        end
        
        default: begin
            seq_state_nxt   = IDLE;
            valid_req       = 1'b0;
            slot_sel_nxt    = {CSD_ASIZE{1'b0}};
            clr_run         = 1'b0;
        end

    endcase
end



//--------------------------------------------------------------------------------------------//
// Counter for slot selector
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        slot_sel <= {CSD_ASIZE{1'b0}};
    else
        slot_sel <= slot_sel_nxt;
end



//--------------------------------------------------------------------------------------------//
// Misc logic to detect sequence complete
//--------------------------------------------------------------------------------------------//
assign last_slot        = (slot_sel == (CSD_LENGTH-1));
assign done_single      = single_mode & last_slot;
assign done_con         = last_slot & sw_clr_run;
assign done             = done_con | done_single;
assign valid_mode       = con_mode | single_mode | recab_mode;
assign cmd_channel_nxt  = recab_mode ? 5'h1f : csdmem[slot_sel_nxt];
assign cmd_sop_nxt      = recab_mode ? 1'b1 : (slot_sel_nxt == {CSD_ASIZE{1'b0}});
assign cmd_eop_nxt      = recab_mode ? 1'b1 : (slot_sel_nxt == (CSD_LENGTH-1));



//--------------------------------------------------------------------------------------------//
// Output register for Avalon ST Command Interface
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cmd_valid       <= 1'b0;
        cmd_channel     <= 5'h0;
        cmd_sop         <= 1'b0;
        cmd_eop         <= 1'b0;
    end
    else if (valid_req) begin
        cmd_valid       <= 1'b1;
        cmd_channel     <= cmd_channel_nxt;
        cmd_sop         <= cmd_sop_nxt;
        cmd_eop         <= cmd_eop_nxt;
    end
    else if (cmd_ready) begin
        cmd_valid       <= 1'b0;
        cmd_channel     <= 5'h0;
        cmd_sop         <= 1'b0;
        cmd_eop         <= 1'b0;
    end
end


endmodule
