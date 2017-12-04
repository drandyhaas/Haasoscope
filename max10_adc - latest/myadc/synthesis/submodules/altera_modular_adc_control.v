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


module altera_modular_adc_control #(
    parameter clkdiv        = 1,
    parameter tsclkdiv      = 0,
    parameter tsclksel      = 0,
    parameter prescalar     = 0,
    parameter refsel        = 0,
    parameter device_partname_fivechar_prefix   = "10M08",
    parameter is_this_first_or_second_adc = 1,
    parameter analog_input_pin_mask = 17'h0,
    parameter hard_pwd = 0,
    parameter dual_adc_mode = 0
) (
    input           clk,
    input           rst_n,
    input           clk_in_pll_c0,
    input           clk_in_pll_locked,
    input           cmd_valid,
    input [4:0]     cmd_channel,
    input           cmd_sop,
    input           cmd_eop,
    input           sync_ready,

    output          cmd_ready,
    output          rsp_valid,
    output [4:0]    rsp_channel,
    output [11:0]   rsp_data,
    output          rsp_sop,
    output          rsp_eop,
    output          sync_valid

);

wire        clkout_adccore;
wire        eoc;
wire [11:0] dout;
wire [4:0]  chsel;
wire        soc;
wire        tsen;
wire        usr_pwd;

altera_modular_adc_control_fsm #(
    .is_this_first_or_second_adc    (is_this_first_or_second_adc),
    .dual_adc_mode                  (dual_adc_mode)    
) u_control_fsm (
    // inputs
    .clk                (clk),
    .rst_n              (rst_n),
    .clk_in_pll_locked  (clk_in_pll_locked),
    .cmd_valid          (cmd_valid),
    .cmd_channel        (cmd_channel),
    .cmd_sop            (cmd_sop),
    .cmd_eop            (cmd_eop),
    .clk_dft            (clkout_adccore),
    .eoc                (eoc),
    .dout               (dout),
    .sync_ready         (sync_ready),
    // outputs
    .rsp_valid          (rsp_valid),
    .rsp_channel        (rsp_channel),
    .rsp_data           (rsp_data),
    .rsp_sop            (rsp_sop),
    .rsp_eop            (rsp_eop),
    .cmd_ready          (cmd_ready),
    .chsel              (chsel),
    .soc                (soc),
    .usr_pwd            (usr_pwd),
    .tsen               (tsen),
    .sync_valid         (sync_valid)



);



fiftyfivenm_adcblock_top_wrapper #(
    .device_partname_fivechar_prefix (device_partname_fivechar_prefix),
    .clkdiv                          (clkdiv),
    .tsclkdiv                        (tsclkdiv),
    .tsclksel                        (tsclksel),
    .refsel                          (refsel),
    .prescalar                       (prescalar),
    .is_this_first_or_second_adc     (is_this_first_or_second_adc),
    .analog_input_pin_mask           (analog_input_pin_mask),
    .hard_pwd                        (hard_pwd)
) adc_inst (
    //.reset              (reset),
    .chsel              (chsel),                        // 5-bits channel selection.
    .soc                (soc),                          // signal Start-of-Conversion to ADC
    .eoc                (eoc),                          // signal end of conversion. Data can be latched on the positive edge of clkout_adccore after this signal becomes high.  EOC becomes low at every positive edge of the clkout_adccore signal.
    .dout               (dout),                         // 12-bits DOUT valid after EOC rise, still valid at falling edge, but not before the next EOC rising edge
    .usr_pwd            (usr_pwd),                      // User Power Down during run time.  0 = Power Up;  1 = Power Down.
    .tsen               (tsen),                         // MUST power down ADC before changing TSEN.  0 = Normal Mode; 1 = Temperature Sensing Mode.
    .clkout_adccore     (clkout_adccore),               // Output clock from the clock divider
    .clkin_from_pll_c0  (clk_in_pll_c0)               // Clock source from PLL1/3 c-counter[0]
    //.dout_ch            (dout_ch)                     // Indicate dout is for which chsel
);

endmodule
