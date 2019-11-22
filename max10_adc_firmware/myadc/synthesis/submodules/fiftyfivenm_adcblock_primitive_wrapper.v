// (C) 2001-2018 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// *******************************************************************************************************
// **   Filename       : fiftyfivenm_adcblock_primitive_wrapper.v
// **
// **   Description    : The lowest layer of the ADC Mega Function code that instantiate the ADC primitive
// **                    The purpose mirror each input/output register from ADC hard block to soft ip
// **                    to be clocked by clf_dft signal to close timing for the path between soft and hard blocks.
// **   Change Log     :
// **   01/17/2014     : Initial design
// **
// *******************************************************************************************************

// *******************************************************************************************************
// **   DEFINES
// *******************************************************************************************************
// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

//`define DEBUG_AND_DEVELOPMENT 1

// *******************************************************************************************************
// **   TOP MODULE
// *******************************************************************************************************
module fiftyfivenm_adcblock_primitive_wrapper(
    //reset,
    chsel,               // 5-bits channel selection.
    soc,                 // signal Start-of-Conversion to ADC
    eoc,                 // signal end of conversion. Data can be latched on the positive edge of clk_dft after this signal becomes high.  EOC becomes low at every positive edge of the clk_dft signal.
    dout,                // 12-bits DOUT valid after EOC rise, still valid at falling edge, but not before the next EOC rising edge
    usr_pwd,             // User Power Down during run time.  0 = Power Up;  1 = Power Down.
    tsen,                // 0 = Normal Mode; 1 = Temperature Sensing Mode.
    clkout_adccore,      // Output clock from the clock divider
    clkin_from_pll_c0    // Clock source from PLL1 c-counter[0] at BL corner or PLL3 c-counter[0] at TL corner
);

// *******************************************************************************************************
// **   PARAMETERS
// *******************************************************************************************************

// -------------------------------------------------------------------------------------------------------
//      WRAPPED PARAMETERS USED BY fiftyfivenm_adcblock
// -------------------------------------------------------------------------------------------------------

    // 3-bits 1st stage clock divider.
    // 0..5 = DIV by 1/2/10/20/40/80;
    // 6..7 = invalid
    parameter           clkdiv    = 1;
    
    // 2nd stage clock divider.
    // 0 = DIV by 10;
    // 1 = DIV by 20
    parameter           tsclkdiv  = 0;
    
    // 0 = Use 1st stage clock divider when TSEN.
    // 1 = Use 2nd stage clock divider when TSEN.
    parameter           tsclksel  = 0;
    
    // 2-bits To enable the R ladder for the prescalar input channels.
    // 00 = disable prescalar for CH8 and CH16 (CH8 for device with 2nd ADC)
    // 01 = enable prescalar for CH8 only
    // 10 = enable prescalar for CH16 only (CH8 for device with 2nd ADC)
    // 11 = enable prescalar for CH8 and CH16 (CH8 for device with 2nd ADC)
    // please note that this is not supported in VR mode
    parameter           prescalar = 0;
    
    // Reference voltage selection for ADC.
    // 0 = external;
    // 1 = internal VCCADC_2P5
    parameter           refsel    = 0;
       
    // Ordering Part Number 10MXX... code
    parameter           device_partname_fivechar_prefix = "10M08";      // Valid options = 04, 08, 16, 25, 40, 50
    
    // Some part have two ADC, instantiate which ADC?  1st or 2nd?
    parameter           is_this_first_or_second_adc = 1;    // Valid options = 1 or 2
    
    // is_using_dedicated_analog_input_pin_only? -> removed, replaced with analog_input_pin_mask
    //parameter           is_using_dedicated_analog_input_pin_only = 0;

    // 16 bits to indicate whether each of the dual purpose analog input pin (ADCIN) is in use or not.
    // 1 bit to indicate whether dedicated analog input pin (ANAIN) is in use or not (bit 16) 
    parameter           analog_input_pin_mask = 17'h0;
    
    // Power Down. Use to disable the ADC during compilation time if no ADC is in use.
    parameter           hard_pwd = 0;
    
    // Logic simulation parameters which only affects simulation behavior
    parameter           enable_usr_sim = 0;
    parameter           reference_voltage_sim = 65536;
    parameter           simfilename_ch0 = "simfilename_ch0";
    parameter           simfilename_ch1 = "simfilename_ch1";
    parameter           simfilename_ch2 = "simfilename_ch2";
    parameter           simfilename_ch3 = "simfilename_ch3";
    parameter           simfilename_ch4 = "simfilename_ch4";
    parameter           simfilename_ch5 = "simfilename_ch5";
    parameter           simfilename_ch6 = "simfilename_ch6";
    parameter           simfilename_ch7 = "simfilename_ch7";
    parameter           simfilename_ch8 = "simfilename_ch8";
    parameter           simfilename_ch9 = "simfilename_ch9";
    parameter           simfilename_ch10 = "simfilename_ch10";
    parameter           simfilename_ch11 = "simfilename_ch11";
    parameter           simfilename_ch12 = "simfilename_ch12";
    parameter           simfilename_ch13 = "simfilename_ch13";
    parameter           simfilename_ch14 = "simfilename_ch14";
    parameter           simfilename_ch15 = "simfilename_ch15";
    parameter           simfilename_ch16 = "simfilename_ch16";


// *******************************************************************************************************
// **   INPUTS
// *******************************************************************************************************

    //input               reset;

    input               clkin_from_pll_c0;  // Clock source from PLL1 c-counter[0] at BL corner or PLL3 c-counter[0] at TL corner

    input               soc;        // signal Start-of-Conversion to ADC
    input               usr_pwd;    // User Power Down during run time.  0 = Power Up;  1 = Power Down.
    input               tsen;       // 0 = Normal Mode; 1 = Temperature Sensing Mode.
    input   [4:0]       chsel;      // 5-bits channel selection.

    //reg                 reg_clk_dft_soc;
    //reg     [4:0]       reg_clk_dft_chsel;

// *******************************************************************************************************
// **   OUTPUTS
// *******************************************************************************************************

    output              clkout_adccore;
    output              eoc;

    output  [11:0]      dout;
    wire    [11:0]      wire_from_adc_dout;
    //reg     [11:0]      reg_clk_dft_dout;

// *******************************************************************************************************
// **   OUTPUTS ASSIGNMENTS
// *******************************************************************************************************

    //assign       dout = reg_clk_dft_dout;
    assign       dout = wire_from_adc_dout;

// *******************************************************************************************************
// **   INITIALIZATION
// *******************************************************************************************************

// *******************************************************************************************************
// **   MAIN CODE
// *******************************************************************************************************

// -------------------------------------------------------------------------------------------------------
//      1.00: Instantiate ADC Block primitive
// -------------------------------------------------------------------------------------------------------
`ifdef DEBUG_AND_DEVELOPMENT
    fiftyfivenm_adcblock_emulation primitive_instance(
`else
    fiftyfivenm_adcblock primitive_instance(
`endif
        //.chsel            (reg_clk_dft_chsel),
        //.soc              (reg_clk_dft_soc),
        .chsel            (chsel),
        .soc              (soc),
        .eoc              (eoc),
        .dout             (wire_from_adc_dout),
        .usr_pwd          (usr_pwd),
        .tsen             (tsen),
        .clk_dft          (clkout_adccore),
        .clkin_from_pll_c0(clkin_from_pll_c0)
    );
    defparam           primitive_instance.clkdiv                          = clkdiv;
    defparam           primitive_instance.tsclkdiv                        = tsclkdiv;
    defparam           primitive_instance.tsclksel                        = tsclksel;
    defparam           primitive_instance.prescalar                       = prescalar;
    defparam           primitive_instance.refsel                          = refsel;
    defparam           primitive_instance.device_partname_fivechar_prefix = device_partname_fivechar_prefix;
    defparam           primitive_instance.is_this_first_or_second_adc     = is_this_first_or_second_adc;
    defparam           primitive_instance.analog_input_pin_mask           = analog_input_pin_mask;
    defparam           primitive_instance.pwd                             = hard_pwd;
    defparam           primitive_instance.enable_usr_sim                  = enable_usr_sim;
    defparam           primitive_instance.reference_voltage_sim           = reference_voltage_sim;
    defparam           primitive_instance.simfilename_ch0                 = simfilename_ch0;
    defparam           primitive_instance.simfilename_ch1                 = simfilename_ch1;
    defparam           primitive_instance.simfilename_ch2                 = simfilename_ch2;
    defparam           primitive_instance.simfilename_ch3                 = simfilename_ch3;
    defparam           primitive_instance.simfilename_ch4                 = simfilename_ch4;
    defparam           primitive_instance.simfilename_ch5                 = simfilename_ch5;
    defparam           primitive_instance.simfilename_ch6                 = simfilename_ch6;
    defparam           primitive_instance.simfilename_ch7                 = simfilename_ch7;
    defparam           primitive_instance.simfilename_ch8                 = simfilename_ch8;
    defparam           primitive_instance.simfilename_ch9                 = simfilename_ch9;
    defparam           primitive_instance.simfilename_ch10                = simfilename_ch10;
    defparam           primitive_instance.simfilename_ch11                = simfilename_ch11;
    defparam           primitive_instance.simfilename_ch12                = simfilename_ch12;
    defparam           primitive_instance.simfilename_ch13                = simfilename_ch13;
    defparam           primitive_instance.simfilename_ch14                = simfilename_ch14;
    defparam           primitive_instance.simfilename_ch15                = simfilename_ch15;
    defparam           primitive_instance.simfilename_ch16                = simfilename_ch16;

// -------------------------------------------------------------------------------------------------------
//      2.00: Clock the registers with ADC Clock source
// -------------------------------------------------------------------------------------------------------

    // DESCRIBE THE ALWAYS BLOCK:
    // The purpose is to clock the registers using clk_dft signal for timing closure
    // ADC primitive signals type
    // Type  Sync: chsel, soc, eoc, dout, clk_dft
    // Type Async: usr_pwd, tsen
    // Signals need a register clocked by clk_dft: chsel, dout, soc
    //always @ (posedge clkout_adccore or posedge reset)
    //begin
    //    if (reset)
    //    begin
    //        // Reset signal asserted
    //        reg_clk_dft_soc     <= 0;
    //        reg_clk_dft_chsel   <= 0;
    //        reg_clk_dft_dout    <= 0;
    //    end
    //    else
    //    begin
    //        reg_clk_dft_soc     <= soc;
    //        reg_clk_dft_chsel   <= chsel;
    //        reg_clk_dft_dout    <= wire_from_adc_dout;
    //    end //end-if        
    //end

// *******************************************************************************************************
// **   END OF MODULE
// *******************************************************************************************************

endmodule

