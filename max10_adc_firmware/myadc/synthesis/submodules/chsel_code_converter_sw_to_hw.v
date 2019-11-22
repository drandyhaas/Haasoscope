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
// **   Filename       : chsel_code_converter_sw_to_hw.v
// **
// **   Description    : Translate channel code coming from software to hardware format
// **
// **   Change Log     :
// **   2014/02/07     : Initial design
// **
// *******************************************************************************************************

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// *******************************************************************************************************
// **   MODULE
// *******************************************************************************************************

module  chsel_code_converter_sw_to_hw (
    chsel_from_sw,            // 5-bits channel selection.
    chsel_to_hw               // 5-bits channel selection.
);

// *******************************************************************************************************
// **   PARAMETERS
// *******************************************************************************************************

    // Ordering Part Number 10MXX... code
    parameter           device_partname_fivechar_prefix = "10M08";   // Valid options = 04, 08, 16, 25, 40, 50

    // Some part have two ADC, instantiate which ADC?  1st or 2nd?
    parameter           is_this_first_or_second_adc = 1;             // Valid options = 1 or 2

// .......................................................................................................

    // DESCRIBE THE LOCALPARAM CONSTANT:
    // Actual Hardware map CHSEL[4:0] out of sequential order to different channel pad due to route-ability,
    // Soft IP will have S/W mapping to translate it back to sequential order from user perspective (PAD label)

    // 10M04/08/16 hardware equivalent chsel code for a particular software chsel code
    localparam          variant_08n16_hw_chsel_code_for_sw_temp_code_10001 = 5'b00000;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch00_code_00000 = 5'b00011;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch01_code_00001 = 5'b00100;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch02_code_00010 = 5'b00110;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch03_code_00011 = 5'b01010;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch04_code_00100 = 5'b01100;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch05_code_00101 = 5'b10000;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch06_code_00110 = 5'b01110;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch07_code_00111 = 5'b01101;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch08_code_01000 = 5'b00010;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch09_code_01001 = 5'b00101;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch10_code_01010 = 5'b01001;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch11_code_01011 = 5'b10001;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch12_code_01100 = 5'b01111;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch13_code_01101 = 5'b01000;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch14_code_01110 = 5'b00111;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch15_code_01111 = 5'b01011;
    localparam          variant_08n16_hw_chsel_code_for_sw_ch16_code_10000 = 5'b00001;

    // First ADC of 10M25/40/50 hardware equivalent chsel code for a particular software chsel code
    localparam          dual_first_adc_hw_chsel_code_for_sw_temp_code_10001 = 5'b00000;
    localparam          dual_first_adc_hw_chsel_code_for_sw_ch00_code_00000 = 5'b00011;
    localparam          dual_first_adc_hw_chsel_code_for_sw_ch01_code_00001 = 5'b00100;
    localparam          dual_first_adc_hw_chsel_code_for_sw_ch02_code_00010 = 5'b00110;
    localparam          dual_first_adc_hw_chsel_code_for_sw_ch03_code_00011 = 5'b01010;
    localparam          dual_first_adc_hw_chsel_code_for_sw_ch04_code_00100 = 5'b01100;
    localparam          dual_first_adc_hw_chsel_code_for_sw_ch05_code_00101 = 5'b10000;
    localparam          dual_first_adc_hw_chsel_code_for_sw_ch06_code_00110 = 5'b01110;
    localparam          dual_first_adc_hw_chsel_code_for_sw_ch07_code_00111 = 5'b01101;
    localparam          dual_first_adc_hw_chsel_code_for_sw_ch08_code_01000 = 5'b00010;

    // Second ADC of 10M25/40/50 hardware equivalent chsel code for a particular software chsel code
    // Note that: Second ADC do not support internal temperature sensor.
    // However internal temperature sensor mapping for ADC2 is later included for dual adc mode
    // When in dual adc mode, if ADC1 is operating in TSD mode, ADC2 will perform a dummy TSD mode as well
    localparam          dual_second_adc_hw_chsel_code_for_sw_temp_code_10001 = 5'b00000;
    localparam          dual_second_adc_hw_chsel_code_for_sw_ch00_code_00000 = 5'b00011;
    localparam          dual_second_adc_hw_chsel_code_for_sw_ch01_code_00001 = 5'b00101;
    localparam          dual_second_adc_hw_chsel_code_for_sw_ch02_code_00010 = 5'b01001;
    localparam          dual_second_adc_hw_chsel_code_for_sw_ch03_code_00011 = 5'b10001;
    localparam          dual_second_adc_hw_chsel_code_for_sw_ch04_code_00100 = 5'b01111;
    localparam          dual_second_adc_hw_chsel_code_for_sw_ch05_code_00101 = 5'b01000;
    localparam          dual_second_adc_hw_chsel_code_for_sw_ch06_code_00110 = 5'b00111;
    localparam          dual_second_adc_hw_chsel_code_for_sw_ch07_code_00111 = 5'b01011;
    localparam          dual_second_adc_hw_chsel_code_for_sw_ch08_code_01000 = 5'b00001;

// *******************************************************************************************************
// **   INPUTS
// *******************************************************************************************************

    input   [4:0]       chsel_from_sw;  // 5-bits channel selection number from software perspective

// *******************************************************************************************************
// **   OUTPUTS
// *******************************************************************************************************

    output  [4:0]       chsel_to_hw;    // 5-bits channel selection code to be send to ADC Hard IP

// *******************************************************************************************************
// **   EXTERNAL NET AND REGISTER DATA TYPE (with input / output / inout ports)
// *******************************************************************************************************

    reg     [4:0]       chsel_to_hw;    // 5-bits channel selection code to be send to ADC Hard IP

// *******************************************************************************************************
// **   MAIN CODE
// *******************************************************************************************************

// -------------------------------------------------------------------------------------------------------
//      1.00: Channel Mapping
// -------------------------------------------------------------------------------------------------------

    // DESCRIBE THE ALWAYS BLOCK:
    // This block execute on divided internal clock
    // Its job is mainly to determine what value to be set for the digital_out and eoc_rise
    always @(chsel_from_sw)
    begin
        // DESCRIBE THE CASE STATEMENT:
        // Output the equivalent chsel code for hardware
if  ((device_partname_fivechar_prefix == "10M04") || (device_partname_fivechar_prefix == "10M08") || (device_partname_fivechar_prefix == "10M16"))
begin
        // COMMENT FOR THIS BRANCH:
        // 10M08/04 channel mapping
        case(chsel_from_sw)
            5'b10001: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_temp_code_10001;
            5'b00000: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch00_code_00000;
            5'b00001: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch01_code_00001;
            5'b00010: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch02_code_00010;
            5'b00011: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch03_code_00011;
            5'b00100: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch04_code_00100;
            5'b00101: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch05_code_00101;
            5'b00110: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch06_code_00110;
            5'b00111: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch07_code_00111;
            5'b01000: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch08_code_01000;
            5'b01001: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch09_code_01001;
            5'b01010: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch10_code_01010;
            5'b01011: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch11_code_01011;
            5'b01100: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch12_code_01100;
            5'b01101: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch13_code_01101;
            5'b01110: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch14_code_01110;
            5'b01111: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch15_code_01111;
            5'b10000: chsel_to_hw <= variant_08n16_hw_chsel_code_for_sw_ch16_code_10000;
            default : chsel_to_hw <= 5'b11111;
        endcase
end
else
if ((is_this_first_or_second_adc == 1) &&
    ((device_partname_fivechar_prefix == "10M25") ||
     (device_partname_fivechar_prefix == "10M40") ||
     (device_partname_fivechar_prefix == "10M50")))
begin
        // COMMENT FOR THIS BRANCH:
        // First ADC of 10M25/40/50 channel mapping
        case(chsel_from_sw)
            5'b10001: chsel_to_hw <= dual_first_adc_hw_chsel_code_for_sw_temp_code_10001;
            5'b00000: chsel_to_hw <= dual_first_adc_hw_chsel_code_for_sw_ch00_code_00000;
            5'b00001: chsel_to_hw <= dual_first_adc_hw_chsel_code_for_sw_ch01_code_00001;
            5'b00010: chsel_to_hw <= dual_first_adc_hw_chsel_code_for_sw_ch02_code_00010;
            5'b00011: chsel_to_hw <= dual_first_adc_hw_chsel_code_for_sw_ch03_code_00011;
            5'b00100: chsel_to_hw <= dual_first_adc_hw_chsel_code_for_sw_ch04_code_00100;
            5'b00101: chsel_to_hw <= dual_first_adc_hw_chsel_code_for_sw_ch05_code_00101;
            5'b00110: chsel_to_hw <= dual_first_adc_hw_chsel_code_for_sw_ch06_code_00110;
            5'b00111: chsel_to_hw <= dual_first_adc_hw_chsel_code_for_sw_ch07_code_00111;
            5'b01000: chsel_to_hw <= dual_first_adc_hw_chsel_code_for_sw_ch08_code_01000;
            default : chsel_to_hw <= 5'b11111;
        endcase
end
else
if ((is_this_first_or_second_adc == 2) &&
    ((device_partname_fivechar_prefix == "10M25") ||
     (device_partname_fivechar_prefix == "10M40") ||
     (device_partname_fivechar_prefix == "10M50")))
begin
        // COMMENT FOR THIS BRANCH:
        // Second ADC of 10M25/40/50 channel mapping
        case(chsel_from_sw)
            5'b10001: chsel_to_hw <= dual_second_adc_hw_chsel_code_for_sw_temp_code_10001;
            5'b00000: chsel_to_hw <= dual_second_adc_hw_chsel_code_for_sw_ch00_code_00000;
            5'b00001: chsel_to_hw <= dual_second_adc_hw_chsel_code_for_sw_ch01_code_00001;
            5'b00010: chsel_to_hw <= dual_second_adc_hw_chsel_code_for_sw_ch02_code_00010;
            5'b00011: chsel_to_hw <= dual_second_adc_hw_chsel_code_for_sw_ch03_code_00011;
            5'b00100: chsel_to_hw <= dual_second_adc_hw_chsel_code_for_sw_ch04_code_00100;
            5'b00101: chsel_to_hw <= dual_second_adc_hw_chsel_code_for_sw_ch05_code_00101;
            5'b00110: chsel_to_hw <= dual_second_adc_hw_chsel_code_for_sw_ch06_code_00110;
            5'b00111: chsel_to_hw <= dual_second_adc_hw_chsel_code_for_sw_ch07_code_00111;
            5'b01000: chsel_to_hw <= dual_second_adc_hw_chsel_code_for_sw_ch08_code_01000;
            default : chsel_to_hw <= 5'b11111;
        endcase
end
    end // end always

// *******************************************************************************************************
// **   END OF MODULE
// *******************************************************************************************************

endmodule
