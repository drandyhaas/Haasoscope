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


module altera_modular_adc_sequencer #(
    parameter   DUAL_ADC_MODE   = 0,
    parameter   CSD_LENGTH      = 64,
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
    parameter   CSD_SLOT_63     = 5'h0,
    parameter   CSD_SLOT_0_ADC2     = 5'h0,
    parameter   CSD_SLOT_1_ADC2     = 5'h0,
    parameter   CSD_SLOT_2_ADC2     = 5'h0,
    parameter   CSD_SLOT_3_ADC2     = 5'h0,
    parameter   CSD_SLOT_4_ADC2     = 5'h0,
    parameter   CSD_SLOT_5_ADC2     = 5'h0,
    parameter   CSD_SLOT_6_ADC2     = 5'h0,
    parameter   CSD_SLOT_7_ADC2     = 5'h0,
    parameter   CSD_SLOT_8_ADC2     = 5'h0,
    parameter   CSD_SLOT_9_ADC2     = 5'h0,
    parameter   CSD_SLOT_10_ADC2    = 5'h0,
    parameter   CSD_SLOT_11_ADC2    = 5'h0,
    parameter   CSD_SLOT_12_ADC2    = 5'h0,
    parameter   CSD_SLOT_13_ADC2    = 5'h0,
    parameter   CSD_SLOT_14_ADC2    = 5'h0,
    parameter   CSD_SLOT_15_ADC2    = 5'h0,
    parameter   CSD_SLOT_16_ADC2    = 5'h0,
    parameter   CSD_SLOT_17_ADC2    = 5'h0,
    parameter   CSD_SLOT_18_ADC2    = 5'h0,
    parameter   CSD_SLOT_19_ADC2    = 5'h0,
    parameter   CSD_SLOT_20_ADC2    = 5'h0,
    parameter   CSD_SLOT_21_ADC2    = 5'h0,
    parameter   CSD_SLOT_22_ADC2    = 5'h0,
    parameter   CSD_SLOT_23_ADC2    = 5'h0,
    parameter   CSD_SLOT_24_ADC2    = 5'h0,
    parameter   CSD_SLOT_25_ADC2    = 5'h0,
    parameter   CSD_SLOT_26_ADC2    = 5'h0,
    parameter   CSD_SLOT_27_ADC2    = 5'h0,
    parameter   CSD_SLOT_28_ADC2    = 5'h0,
    parameter   CSD_SLOT_29_ADC2    = 5'h0,
    parameter   CSD_SLOT_30_ADC2    = 5'h0,
    parameter   CSD_SLOT_31_ADC2    = 5'h0,
    parameter   CSD_SLOT_32_ADC2    = 5'h0,
    parameter   CSD_SLOT_33_ADC2    = 5'h0,
    parameter   CSD_SLOT_34_ADC2    = 5'h0,
    parameter   CSD_SLOT_35_ADC2    = 5'h0,
    parameter   CSD_SLOT_36_ADC2    = 5'h0,
    parameter   CSD_SLOT_37_ADC2    = 5'h0,
    parameter   CSD_SLOT_38_ADC2    = 5'h0,
    parameter   CSD_SLOT_39_ADC2    = 5'h0,
    parameter   CSD_SLOT_40_ADC2    = 5'h0,
    parameter   CSD_SLOT_41_ADC2    = 5'h0,
    parameter   CSD_SLOT_42_ADC2    = 5'h0,
    parameter   CSD_SLOT_43_ADC2    = 5'h0,
    parameter   CSD_SLOT_44_ADC2    = 5'h0,
    parameter   CSD_SLOT_45_ADC2    = 5'h0,
    parameter   CSD_SLOT_46_ADC2    = 5'h0,
    parameter   CSD_SLOT_47_ADC2    = 5'h0,
    parameter   CSD_SLOT_48_ADC2    = 5'h0,
    parameter   CSD_SLOT_49_ADC2    = 5'h0,
    parameter   CSD_SLOT_50_ADC2    = 5'h0,
    parameter   CSD_SLOT_51_ADC2    = 5'h0,
    parameter   CSD_SLOT_52_ADC2    = 5'h0,
    parameter   CSD_SLOT_53_ADC2    = 5'h0,
    parameter   CSD_SLOT_54_ADC2    = 5'h0,
    parameter   CSD_SLOT_55_ADC2    = 5'h0,
    parameter   CSD_SLOT_56_ADC2    = 5'h0,
    parameter   CSD_SLOT_57_ADC2    = 5'h0,
    parameter   CSD_SLOT_58_ADC2    = 5'h0,
    parameter   CSD_SLOT_59_ADC2    = 5'h0,
    parameter   CSD_SLOT_60_ADC2    = 5'h0,
    parameter   CSD_SLOT_61_ADC2    = 5'h0,
    parameter   CSD_SLOT_62_ADC2    = 5'h0,
    parameter   CSD_SLOT_63_ADC2    = 5'h0
) (
    input           clk,
    input           rst_n,
    input           addr,
    input           read,
    input           write,
    input [31:0]    writedata,
    input           cmd_ready,
    input           cmd_ready_2,

    output [31:0]   readdata,
    output          cmd_valid,
    output [4:0]    cmd_channel,
    output          cmd_sop,
    output          cmd_eop,
    output          cmd_valid_2,
    output [4:0]    cmd_channel_2,
    output          cmd_sop_2,
    output          cmd_eop_2

);

wire        clr_run;
wire        clr_run_2;
wire        run;
wire        sw_clr_run;
wire        con_mode;
wire        single_mode;
wire        recab_mode;

function integer clog2;
    input [31:0] value;  // Input variable
    if (value == 32'h0) begin
       clog2 = 1;
    end
    else begin
        for (clog2=0; value>0; clog2=clog2+1) 
            value = value>>'d1;
    end
endfunction


localparam CSD_ASIZE = clog2(CSD_LENGTH - 1);

//--------------------------------------------------------------------------------------------//
// CSR block instantiation
//--------------------------------------------------------------------------------------------//
altera_modular_adc_sequencer_csr u_seq_csr (
    // inputs
    .clk            (clk),
    .rst_n          (rst_n),
    .addr           (addr),
    .read           (read),
    .write          (write),
    .writedata      (writedata),
    .clr_run        (clr_run),      // clr_run and clr_run_2 shall assert/de-assert at the same cycle (design requirement)
                                    // therefore, only one of them is feed back into csr block
    // outputs        
    .readdata       (readdata),
    .run            (run),
    .sw_clr_run     (sw_clr_run),
    .con_mode       (con_mode),
    .single_mode    (single_mode),
    .recab_mode     (recab_mode)

);



//--------------------------------------------------------------------------------------------//
// Sequencer control block instantiation
//--------------------------------------------------------------------------------------------//
altera_modular_adc_sequencer_ctrl #(
    .CSD_LENGTH    (CSD_LENGTH),
    .CSD_ASIZE     (CSD_ASIZE),
    .CSD_SLOT_0    (CSD_SLOT_0),
    .CSD_SLOT_1    (CSD_SLOT_1),
    .CSD_SLOT_2    (CSD_SLOT_2),
    .CSD_SLOT_3    (CSD_SLOT_3),
    .CSD_SLOT_4    (CSD_SLOT_4),
    .CSD_SLOT_5    (CSD_SLOT_5),
    .CSD_SLOT_6    (CSD_SLOT_6),
    .CSD_SLOT_7    (CSD_SLOT_7),
    .CSD_SLOT_8    (CSD_SLOT_8),
    .CSD_SLOT_9    (CSD_SLOT_9),
    .CSD_SLOT_10   (CSD_SLOT_10),
    .CSD_SLOT_11   (CSD_SLOT_11),
    .CSD_SLOT_12   (CSD_SLOT_12),
    .CSD_SLOT_13   (CSD_SLOT_13),
    .CSD_SLOT_14   (CSD_SLOT_14),
    .CSD_SLOT_15   (CSD_SLOT_15),
    .CSD_SLOT_16   (CSD_SLOT_16),
    .CSD_SLOT_17   (CSD_SLOT_17),
    .CSD_SLOT_18   (CSD_SLOT_18),
    .CSD_SLOT_19   (CSD_SLOT_19),
    .CSD_SLOT_20   (CSD_SLOT_20),
    .CSD_SLOT_21   (CSD_SLOT_21),
    .CSD_SLOT_22   (CSD_SLOT_22),
    .CSD_SLOT_23   (CSD_SLOT_23),
    .CSD_SLOT_24   (CSD_SLOT_24),
    .CSD_SLOT_25   (CSD_SLOT_25),
    .CSD_SLOT_26   (CSD_SLOT_26),
    .CSD_SLOT_27   (CSD_SLOT_27),
    .CSD_SLOT_28   (CSD_SLOT_28),
    .CSD_SLOT_29   (CSD_SLOT_29),
    .CSD_SLOT_30   (CSD_SLOT_30),
    .CSD_SLOT_31   (CSD_SLOT_31),
    .CSD_SLOT_32   (CSD_SLOT_32),
    .CSD_SLOT_33   (CSD_SLOT_33),
    .CSD_SLOT_34   (CSD_SLOT_34),
    .CSD_SLOT_35   (CSD_SLOT_35),
    .CSD_SLOT_36   (CSD_SLOT_36),
    .CSD_SLOT_37   (CSD_SLOT_37),
    .CSD_SLOT_38   (CSD_SLOT_38),
    .CSD_SLOT_39   (CSD_SLOT_39),
    .CSD_SLOT_40   (CSD_SLOT_40),
    .CSD_SLOT_41   (CSD_SLOT_41),
    .CSD_SLOT_42   (CSD_SLOT_42),
    .CSD_SLOT_43   (CSD_SLOT_43),
    .CSD_SLOT_44   (CSD_SLOT_44),
    .CSD_SLOT_45   (CSD_SLOT_45),
    .CSD_SLOT_46   (CSD_SLOT_46),
    .CSD_SLOT_47   (CSD_SLOT_47),
    .CSD_SLOT_48   (CSD_SLOT_48),
    .CSD_SLOT_49   (CSD_SLOT_49),
    .CSD_SLOT_50   (CSD_SLOT_50),
    .CSD_SLOT_51   (CSD_SLOT_51),
    .CSD_SLOT_52   (CSD_SLOT_52),
    .CSD_SLOT_53   (CSD_SLOT_53),
    .CSD_SLOT_54   (CSD_SLOT_54),
    .CSD_SLOT_55   (CSD_SLOT_55),
    .CSD_SLOT_56   (CSD_SLOT_56),
    .CSD_SLOT_57   (CSD_SLOT_57),
    .CSD_SLOT_58   (CSD_SLOT_58),
    .CSD_SLOT_59   (CSD_SLOT_59),
    .CSD_SLOT_60   (CSD_SLOT_60),
    .CSD_SLOT_61   (CSD_SLOT_61),
    .CSD_SLOT_62   (CSD_SLOT_62),
    .CSD_SLOT_63   (CSD_SLOT_63)
) u_seq_ctrl (
    // inputs
    .clk            (clk),
    .rst_n          (rst_n),
    .run            (run),
    .sw_clr_run     (sw_clr_run),
    .con_mode       (con_mode),
    .single_mode    (single_mode),
    .recab_mode     (recab_mode),
    .cmd_ready      (cmd_ready),
    // outputs
    .cmd_valid      (cmd_valid),
    .cmd_channel    (cmd_channel),
    .cmd_sop        (cmd_sop),
    .cmd_eop        (cmd_eop),
    .clr_run        (clr_run)
);

generate
if (DUAL_ADC_MODE == 1) begin

altera_modular_adc_sequencer_ctrl #(
    .CSD_LENGTH    (CSD_LENGTH),
    .CSD_ASIZE     (CSD_ASIZE),
    .CSD_SLOT_0    (CSD_SLOT_0_ADC2),
    .CSD_SLOT_1    (CSD_SLOT_1_ADC2),
    .CSD_SLOT_2    (CSD_SLOT_2_ADC2),
    .CSD_SLOT_3    (CSD_SLOT_3_ADC2),
    .CSD_SLOT_4    (CSD_SLOT_4_ADC2),
    .CSD_SLOT_5    (CSD_SLOT_5_ADC2),
    .CSD_SLOT_6    (CSD_SLOT_6_ADC2),
    .CSD_SLOT_7    (CSD_SLOT_7_ADC2),
    .CSD_SLOT_8    (CSD_SLOT_8_ADC2),
    .CSD_SLOT_9    (CSD_SLOT_9_ADC2),
    .CSD_SLOT_10   (CSD_SLOT_10_ADC2),
    .CSD_SLOT_11   (CSD_SLOT_11_ADC2),
    .CSD_SLOT_12   (CSD_SLOT_12_ADC2),
    .CSD_SLOT_13   (CSD_SLOT_13_ADC2),
    .CSD_SLOT_14   (CSD_SLOT_14_ADC2),
    .CSD_SLOT_15   (CSD_SLOT_15_ADC2),
    .CSD_SLOT_16   (CSD_SLOT_16_ADC2),
    .CSD_SLOT_17   (CSD_SLOT_17_ADC2),
    .CSD_SLOT_18   (CSD_SLOT_18_ADC2),
    .CSD_SLOT_19   (CSD_SLOT_19_ADC2),
    .CSD_SLOT_20   (CSD_SLOT_20_ADC2),
    .CSD_SLOT_21   (CSD_SLOT_21_ADC2),
    .CSD_SLOT_22   (CSD_SLOT_22_ADC2),
    .CSD_SLOT_23   (CSD_SLOT_23_ADC2),
    .CSD_SLOT_24   (CSD_SLOT_24_ADC2),
    .CSD_SLOT_25   (CSD_SLOT_25_ADC2),
    .CSD_SLOT_26   (CSD_SLOT_26_ADC2),
    .CSD_SLOT_27   (CSD_SLOT_27_ADC2),
    .CSD_SLOT_28   (CSD_SLOT_28_ADC2),
    .CSD_SLOT_29   (CSD_SLOT_29_ADC2),
    .CSD_SLOT_30   (CSD_SLOT_30_ADC2),
    .CSD_SLOT_31   (CSD_SLOT_31_ADC2),
    .CSD_SLOT_32   (CSD_SLOT_32_ADC2),
    .CSD_SLOT_33   (CSD_SLOT_33_ADC2),
    .CSD_SLOT_34   (CSD_SLOT_34_ADC2),
    .CSD_SLOT_35   (CSD_SLOT_35_ADC2),
    .CSD_SLOT_36   (CSD_SLOT_36_ADC2),
    .CSD_SLOT_37   (CSD_SLOT_37_ADC2),
    .CSD_SLOT_38   (CSD_SLOT_38_ADC2),
    .CSD_SLOT_39   (CSD_SLOT_39_ADC2),
    .CSD_SLOT_40   (CSD_SLOT_40_ADC2),
    .CSD_SLOT_41   (CSD_SLOT_41_ADC2),
    .CSD_SLOT_42   (CSD_SLOT_42_ADC2),
    .CSD_SLOT_43   (CSD_SLOT_43_ADC2),
    .CSD_SLOT_44   (CSD_SLOT_44_ADC2),
    .CSD_SLOT_45   (CSD_SLOT_45_ADC2),
    .CSD_SLOT_46   (CSD_SLOT_46_ADC2),
    .CSD_SLOT_47   (CSD_SLOT_47_ADC2),
    .CSD_SLOT_48   (CSD_SLOT_48_ADC2),
    .CSD_SLOT_49   (CSD_SLOT_49_ADC2),
    .CSD_SLOT_50   (CSD_SLOT_50_ADC2),
    .CSD_SLOT_51   (CSD_SLOT_51_ADC2),
    .CSD_SLOT_52   (CSD_SLOT_52_ADC2),
    .CSD_SLOT_53   (CSD_SLOT_53_ADC2),
    .CSD_SLOT_54   (CSD_SLOT_54_ADC2),
    .CSD_SLOT_55   (CSD_SLOT_55_ADC2),
    .CSD_SLOT_56   (CSD_SLOT_56_ADC2),
    .CSD_SLOT_57   (CSD_SLOT_57_ADC2),
    .CSD_SLOT_58   (CSD_SLOT_58_ADC2),
    .CSD_SLOT_59   (CSD_SLOT_59_ADC2),
    .CSD_SLOT_60   (CSD_SLOT_60_ADC2),
    .CSD_SLOT_61   (CSD_SLOT_61_ADC2),
    .CSD_SLOT_62   (CSD_SLOT_62_ADC2),
    .CSD_SLOT_63   (CSD_SLOT_63_ADC2)
) u_seq_ctrl_adc2 (
    // inputs
    .clk            (clk),
    .rst_n          (rst_n),
    .run            (run),
    .sw_clr_run     (sw_clr_run),
    .con_mode       (con_mode),
    .single_mode    (single_mode),
    .recab_mode     (recab_mode),
    .cmd_ready      (cmd_ready_2),
    // outputs
    .cmd_valid      (cmd_valid_2),
    .cmd_channel    (cmd_channel_2),
    .cmd_sop        (cmd_sop_2),
    .cmd_eop        (cmd_eop_2),
    .clr_run        (clr_run_2)         // clr_run_2 shall assert/de-assert at the same cycle as clr_run
);

end
else begin

assign cmd_valid_2      = 1'b0;
assign cmd_channel_2    = 5'h0;
assign cmd_sop_2        = 1'b0;
assign cmd_eop_2        = 1'b0;

end
endgenerate

endmodule
