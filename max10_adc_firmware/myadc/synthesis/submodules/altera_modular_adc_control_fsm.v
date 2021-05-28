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


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module altera_modular_adc_control_fsm #(
    parameter is_this_first_or_second_adc = 1,
    parameter dual_adc_mode = 0
) (
    input               clk, 
    input               rst_n,
    input               clk_in_pll_locked,
    input               cmd_valid,
    input [4:0]         cmd_channel,
    input               cmd_sop,
    input               cmd_eop,
    input               clk_dft,
    input               eoc,
    input [11:0]        dout,
    input               sync_ready,

    output reg          rsp_valid,
    output reg [4:0]    rsp_channel,
    output reg [11:0]   rsp_data,
    output reg          rsp_sop,
    output reg          rsp_eop,
    output reg          cmd_ready,
    output reg [4:0]    chsel,
    output reg          soc,
    output reg          usr_pwd,
    output reg          tsen,
    output reg          sync_valid

);

reg [4:0]   ctrl_state;
reg [4:0]   ctrl_state_nxt;
reg         clk_dft_synch_dly;
reg         eoc_synch_dly;
reg [4:0]   chsel_nxt;
reg         soc_nxt;
reg         usr_pwd_nxt;
reg         tsen_nxt;
reg         prev_cmd_is_ts;
reg         cmd_fetched;
reg         pend;
reg [4:0]   cmd_channel_dly;
reg         cmd_sop_dly;
reg         cmd_eop_dly;
reg [7:0]   int_timer;
reg [17:0]  avrg_sum;
reg         avrg_cnt_done;
reg         frst_64_ptr_done;
reg         conv_dly1_s_flp;
reg [11:0]  dout_flp;
reg [4:0]   prev_ctrl_state;
reg [4:0]   sync_ctrl_state;
reg [4:0]   sync_ctrl_state_nxt;

wire        clk_dft_synch;
wire        eoc_synch;
wire        clk_dft_lh;
wire        clk_dft_hl;
wire        eoc_hl;
wire        cmd_is_rclb;
wire        cmd_is_ts;
wire        arc_conv_conv_dly1;
wire        arc_sync1_conv_dly1;
wire        arc_wait_pend_wait_pend_dly1;
wire        arc_sync1_wait_pend_dly1;
wire        arc_to_conv;
wire        arc_to_avrg_cnt;
wire        load_rsp;
wire        load_cmd_ready;
wire        arc_getcmd_w_pwrdwn;
wire        arc_getcmd_pwrdwn;
wire        load_cmd_fetched;
wire        load_int_timer;
wire        incr_int_timer;
wire        arc_out_from_pwrup_soc;
wire        clr_cmd_fetched;
wire        adc_change_mode;
wire        add_avrg_sum;
wire        add_avrg_sum_run;
wire        clear_avrg_sum;
wire        clear_avrg_cnt_done;
wire        set_frst_64_ptr_done;
wire        clear_frst_64_ptr_done;
wire [11:0] fifo_q;
wire        fifo_sclr;
wire        fifo_rdreq;
wire        fifo_wrreq;
wire        putresp_s;
wire        putresp_pend_s;
wire        pwrdwn_s;
wire        pwrdwn_tsen_s;
wire        avrg_cnt_s;
wire        wait_pend_dly1_s;
wire        conv_dly1_s;
wire        conv_s;
wire        putresp_dly3_s;
wire        load_dout;
wire        avrg_enable;
wire [11:0] rsp_data_nxt;

localparam [4:0]    IDLE                = 5'b00000;
localparam [4:0]    PWRDWN              = 5'b00001;
localparam [4:0]    PWRDWN_TSEN         = 5'b00010;
localparam [4:0]    PWRDWN_DONE         = 5'b00011;
localparam [4:0]    PWRUP_CH            = 5'b00100;
localparam [4:0]    PWRUP_SOC           = 5'b00101;
localparam [4:0]    WAIT                = 5'b00110;
localparam [4:0]    GETCMD              = 5'b00111;
localparam [4:0]    GETCMD_W            = 5'b01000;
localparam [4:0]    PRE_CONV            = 5'b01001;
localparam [4:0]    CONV                = 5'b01010; // Drive chsel. Get out of this state when falling edge of EOC detected (DOUT is ready for sample)
                                                    // Read averaging fifo.
                                                    // Capture DOUT into dout internal buffer register (dout_flp) 
localparam [4:0]    CONV_DLY1           = 5'b01011; // Additional state for processing when DOUT is ready. Perform averaging calculation (adds and minus operation). 
localparam [4:0]    PUTRESP             = 5'b01100; // Load response
localparam [4:0]    PUTRESP_DLY1        = 5'b01101;
localparam [4:0]    PUTRESP_DLY2        = 5'b01110;
localparam [4:0]    PUTRESP_DLY3        = 5'b01111;
localparam [4:0]    WAIT_PEND           = 5'b10000; // Get out of this state when falling edge of EOC detected (DOUT is ready for sample)
                                                    // Read averaging fifo.
                                                    // Capture DOUT into dout internal buffer register (dout_flp) 
localparam [4:0]    WAIT_PEND_DLY1      = 5'b10001; // Additional state for processing when DOUT is ready. Perform averaging calculation (adds and minus operation).
localparam [4:0]    PUTRESP_PEND        = 5'b10010; // Load response
localparam [4:0]    AVRG_CNT            = 5'b10011;
localparam [4:0]    SYNC1               = 5'b10100; // Allocates 1 soft ip clock mismatch due to asynchronous between soft ip clock and ADC clock domain

localparam [7:0]    NUM_AVRG_POINTS     = 8'd64;

//--------------------------------------------------------------------------------------------//
// Double Synchronize control signal from ADC hardblock
//--------------------------------------------------------------------------------------------//
altera_std_synchronizer #(
    .depth    (2)
) u_clk_dft_synchronizer (
    .clk        (clk),
    .reset_n    (rst_n),
    .din        (clk_dft),
    .dout       (clk_dft_synch)
);

altera_std_synchronizer #(
    .depth    (2)
) u_eoc_synchronizer (
    .clk        (clk),
    .reset_n    (rst_n),
    .din        (eoc),
    .dout       (eoc_synch)
);



//--------------------------------------------------------------------------------------------//
// Edge detection for both synchronized clk_dft and eoc
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_dft_synch_dly   <= 1'b0;
        eoc_synch_dly       <= 1'b0;
    end
    else begin
        clk_dft_synch_dly   <= clk_dft_synch;
        eoc_synch_dly       <= eoc_synch;
    end
end

assign clk_dft_lh   = clk_dft_synch & ~clk_dft_synch_dly;
assign clk_dft_hl   = ~clk_dft_synch & clk_dft_synch_dly;
assign eoc_hl       = ~eoc_synch & eoc_synch_dly;


//--------------------------------------------------------------------------------------------//
// Dual ADC
//--------------------------------------------------------------------------------------------//

generate
if (dual_adc_mode == 1) begin

    // Buffer up ctrl_state
    // To be used when both ADC is out of sync
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            prev_ctrl_state   <= IDLE;
        else
            prev_ctrl_state   <= ctrl_state;
    end

    // Buffer up ctrl_state
    // To be used when both ADC mismatches by 1 soft ip clock
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sync_ctrl_state   <= IDLE;
        else
            sync_ctrl_state   <= sync_ctrl_state_nxt;
    end

end
else begin

    always @* begin
        prev_ctrl_state = 5'h0;
        sync_ctrl_state = 5'h0;
    end

end
endgenerate



//--------------------------------------------------------------------------------------------//
// Main FSM
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ctrl_state   <= IDLE;
    else
        ctrl_state   <= ctrl_state_nxt;
end


always @* begin

    // Default assignment, perform assignment only at relevant state
    sync_ctrl_state_nxt = sync_ctrl_state;
    sync_valid          = 1'b0;

    case (ctrl_state)
        IDLE: begin
            if (clk_in_pll_locked)
                ctrl_state_nxt = PWRDWN;
            else
                ctrl_state_nxt = IDLE;
        end

        PWRDWN: begin
            if (int_timer[6])
                ctrl_state_nxt = PWRDWN_TSEN;
            else
                ctrl_state_nxt = PWRDWN;
        end

        PWRDWN_TSEN: begin
            if (int_timer[7])
                ctrl_state_nxt = PWRDWN_DONE;
            else
                ctrl_state_nxt = PWRDWN_TSEN;
        end

        PWRDWN_DONE: begin
            if (dual_adc_mode == 1) begin
                if (clk_dft_lh) begin
                    if (sync_ready)
                        ctrl_state_nxt = PWRUP_CH;
                    else
                        ctrl_state_nxt = SYNC1;
                end
                else begin
                    ctrl_state_nxt = PWRDWN_DONE;
                end

                if (clk_dft_lh) begin
                    sync_ctrl_state_nxt = PWRUP_CH;
                    sync_valid          = 1'b1;
                end
                
            end
            else begin
                if (clk_dft_lh)
                    ctrl_state_nxt = PWRUP_CH;
                else
                    ctrl_state_nxt = PWRDWN_DONE;
            end
        end

        PWRUP_CH: begin
            if (dual_adc_mode == 1) begin
                if (clk_dft_hl) begin
                    if (sync_ready)
                        ctrl_state_nxt = PWRUP_SOC;
                    else
                        ctrl_state_nxt = SYNC1;
                end
                else begin
                    ctrl_state_nxt = PWRUP_CH;
                end

                if (clk_dft_hl) begin
                    sync_ctrl_state_nxt = PWRUP_SOC;
                    sync_valid          = 1'b1;
                end

            end
            else begin
                if (clk_dft_hl)
                    ctrl_state_nxt = PWRUP_SOC;
                else
                    ctrl_state_nxt = PWRUP_CH;
            end
        end

        PWRUP_SOC: begin
            if (dual_adc_mode == 1) begin
                if (eoc_hl) begin
                    if (sync_ready) begin
                        if (cmd_fetched & ~cmd_is_rclb)
                            ctrl_state_nxt = CONV;
                        else if (cmd_fetched & cmd_is_rclb)
                            ctrl_state_nxt = PUTRESP;
                        else if (cmd_valid)
                            ctrl_state_nxt = GETCMD;
                        else
                            ctrl_state_nxt = WAIT;
                    end
                    else begin
                        ctrl_state_nxt = SYNC1;
                    end
                end
                else begin
                    ctrl_state_nxt = PWRUP_SOC;
                end

                if (eoc_hl) begin
                    if (cmd_fetched & ~cmd_is_rclb)
                        sync_ctrl_state_nxt = CONV;
                    else if (cmd_fetched & cmd_is_rclb)
                        sync_ctrl_state_nxt = PUTRESP;
                    else if (cmd_valid)
                        sync_ctrl_state_nxt = GETCMD;
                    else
                        sync_ctrl_state_nxt = WAIT;

                    sync_valid  = 1'b1;
                end

            end
            else begin
                if (cmd_fetched & ~cmd_is_rclb & eoc_hl)
                    ctrl_state_nxt = CONV;
                else if (cmd_fetched & cmd_is_rclb & eoc_hl)
                    ctrl_state_nxt = PUTRESP;
                else if (cmd_valid & eoc_hl)
                    ctrl_state_nxt = GETCMD;
                else if (eoc_hl)
                    ctrl_state_nxt = WAIT;
                else
                    ctrl_state_nxt = PWRUP_SOC;
            end
        end

        SYNC1: begin
            if (sync_ready)
                ctrl_state_nxt = sync_ctrl_state;   // mismatches by 1 soft ip clock, proceed to next state
            else
                ctrl_state_nxt = prev_ctrl_state;   // Both ADC is out of sync, go back to previous state

            sync_valid  = 1'b1;

        end
        
        WAIT: begin
            if (cmd_valid)
                ctrl_state_nxt = GETCMD_W;
            else
                ctrl_state_nxt = WAIT;
        end

        GETCMD_W: begin
            if (cmd_is_rclb | adc_change_mode)
                ctrl_state_nxt = PWRDWN;
            else
                ctrl_state_nxt = PRE_CONV;
        end

        PRE_CONV: begin
            if (dual_adc_mode == 1) begin
                if (eoc_hl) begin
                    if (sync_ready)
                        ctrl_state_nxt = CONV;
                    else
                        ctrl_state_nxt = SYNC1;
                end
                else begin
                    ctrl_state_nxt = PRE_CONV;
                end

                if (eoc_hl) begin
                    sync_ctrl_state_nxt = CONV;
                    sync_valid          = 1'b1;
                end

            end
            else begin
                if (eoc_hl)
                    ctrl_state_nxt = CONV;
                else
                    ctrl_state_nxt = PRE_CONV;
            end
        end

        GETCMD: begin
            if ((cmd_is_rclb | adc_change_mode) & ~pend)
                ctrl_state_nxt = PWRDWN;
            else if ((cmd_is_rclb | adc_change_mode) & pend)
                ctrl_state_nxt = WAIT_PEND;
            else
                ctrl_state_nxt = CONV;
        end

        CONV: begin
            if (dual_adc_mode == 1) begin
                if (eoc_hl) begin
                    if (sync_ready) begin
                        if (avrg_enable & ~avrg_cnt_done)
                            ctrl_state_nxt = AVRG_CNT;
                        else
                            ctrl_state_nxt = CONV_DLY1;
                    end
                    else begin
                        ctrl_state_nxt = SYNC1;
                    end
                end
                else begin
                    ctrl_state_nxt = CONV;
                end

                if (eoc_hl) begin
                    if (avrg_enable & ~avrg_cnt_done)
                        sync_ctrl_state_nxt = AVRG_CNT;
                    else 
                        sync_ctrl_state_nxt = CONV_DLY1;

                    sync_valid  = 1'b1;
                end

            end
            else begin
                if (eoc_hl & avrg_enable & ~avrg_cnt_done)
                    ctrl_state_nxt = AVRG_CNT;
                else if (eoc_hl)
                    ctrl_state_nxt = CONV_DLY1;
                else
                    ctrl_state_nxt = CONV;
            end
        end
        
        AVRG_CNT: begin
            ctrl_state_nxt = CONV;
        end
        
        CONV_DLY1: begin
            ctrl_state_nxt = PUTRESP;
        end

        PUTRESP: begin
            ctrl_state_nxt = PUTRESP_DLY1;
        end
        
        PUTRESP_DLY1: begin
            ctrl_state_nxt = PUTRESP_DLY2;
        end
        
        PUTRESP_DLY2: begin
            ctrl_state_nxt = PUTRESP_DLY3;
        end

        PUTRESP_DLY3: begin
            if (cmd_valid)
                ctrl_state_nxt = GETCMD;
            else if (pend)
                ctrl_state_nxt = WAIT_PEND;
            else
                ctrl_state_nxt = WAIT;
        end

        WAIT_PEND: begin
            if (dual_adc_mode == 1) begin
                if (eoc_hl) begin
                    if (sync_ready)
                        ctrl_state_nxt = WAIT_PEND_DLY1;
                    else
                        ctrl_state_nxt = SYNC1;
                end
                else begin
                    ctrl_state_nxt = WAIT_PEND;
                end

                if (eoc_hl) begin
                    sync_ctrl_state_nxt = WAIT_PEND_DLY1;
                    sync_valid          = 1'b1;
                end

            end
            else begin
                if (eoc_hl)
                    ctrl_state_nxt = WAIT_PEND_DLY1;
                else
                    ctrl_state_nxt = WAIT_PEND;
            end
        end
        
        WAIT_PEND_DLY1: begin
            ctrl_state_nxt = PUTRESP_PEND;
        end
        
        PUTRESP_PEND: begin
            if (cmd_valid)
                ctrl_state_nxt = GETCMD;
            else
                ctrl_state_nxt = WAIT;
        end

        default: begin
            ctrl_state_nxt = IDLE;
        end

    endcase
end



//--------------------------------------------------------------------------------------------//
// ADC control signal generation from FSM
//--------------------------------------------------------------------------------------------//
always @* begin
    chsel_nxt       = chsel;
    soc_nxt         = soc;
    usr_pwd_nxt     = usr_pwd;
    tsen_nxt        = tsen;

    case (ctrl_state_nxt)
        IDLE: begin
            chsel_nxt   = 5'b11110;
            soc_nxt     = 1'b0;
            usr_pwd_nxt = 1'b1;
            tsen_nxt    = 1'b0;
        end

        PWRDWN: begin
            chsel_nxt   = chsel;
            soc_nxt     = 1'b0;
            usr_pwd_nxt = 1'b1;
            tsen_nxt    = tsen;
        end

        PWRDWN_TSEN: begin
            //chsel_nxt   = chsel;
            soc_nxt     = 1'b0;
            usr_pwd_nxt = 1'b1;
            if (cmd_fetched & cmd_is_ts)        // Transition to TS mode
                tsen_nxt    = 1'b1;
            else if (cmd_fetched & cmd_is_rclb) // In recalibration mode, maintain previous TSEN setting
                tsen_nxt    = tsen;
            else
                tsen_nxt    = 1'b0;             // Transition to Normal mode
            
            // Case:496977 
            // Ensure the right chsel during power up sequence (voltage sensing mode vs temperature sensing mode)
            if (cmd_fetched & (cmd_is_ts | (cmd_is_rclb & tsen)))   // Set channel select to TSD channel if transition to TS mode or recalibration on TS mode
                chsel_nxt   = 5'b10001;
            else
                chsel_nxt   = 5'b11110;                                // Set channel select to dummy channel for voltage sensing mode (just like the original design)
        end

        PWRDWN_DONE: begin
            chsel_nxt   = chsel;
            soc_nxt     = 1'b0;
            usr_pwd_nxt = 1'b0;
            tsen_nxt    = tsen;
        end

        PWRUP_CH: begin
            //chsel_nxt   = 5'b11110;
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = 1'b0;
            tsen_nxt    = tsen;
        end

        PWRUP_SOC: begin
            chsel_nxt   = chsel;
            soc_nxt     = 1'b1;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end

        SYNC1: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end

        WAIT: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end

        GETCMD_W: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end

        PRE_CONV: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end

        GETCMD: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end

        CONV: begin
            chsel_nxt   = cmd_channel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end
        
        AVRG_CNT: begin
            chsel_nxt   = cmd_channel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end
        
        CONV_DLY1: begin
            chsel_nxt   = cmd_channel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end

        PUTRESP: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end
        
        PUTRESP_DLY1: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end

        PUTRESP_DLY2: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end
        
        PUTRESP_DLY3: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end

        WAIT_PEND: begin
            //chsel_nxt   = chsel;
            if (tsen)
                chsel_nxt   = chsel;         
            else                             
                chsel_nxt   = 5'b11110;     // The reason for this change is to support ADC's simulation model (case:226093).
                                            // During the final sampling cycle which meant to complete the pending ADC sampling (ADC output is one cycle delay in nature),
                                            // we assign a dummy channel value instead of maintaining the previous channel value. Functionally, it does not matter. 
                                            // But it does matter to simulation model where it keep popping up the expected value from user's simulation file based on current channel value.
                                            // This will avoid the simulation model from incorrectly popping out the value from previous channel twice during ADC mode transition.
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end
        
        WAIT_PEND_DLY1: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end

        PUTRESP_PEND: begin
            chsel_nxt   = chsel;
            soc_nxt     = soc;
            usr_pwd_nxt = usr_pwd;
            tsen_nxt    = tsen;
        end
        
        default: begin
            chsel_nxt   = 5'bx;
            soc_nxt     = 1'bx;
            usr_pwd_nxt = 1'bx;
            tsen_nxt    = 1'bx;
        end

    endcase
end



always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        chsel       <= 5'b11110;
        soc         <= 1'b0;
        usr_pwd     <= 1'b1;
        tsen        <= 1'b0;
    end
    else begin
        chsel       <= chsel_nxt;
        soc         <= soc_nxt;
        usr_pwd     <= usr_pwd_nxt;
        tsen        <= tsen_nxt;

    end
end



//--------------------------------------------------------------------------------------------//
// Control signal from FSM arc transition
//--------------------------------------------------------------------------------------------//
// These 3 events indicate DOUT from ADC hardblock is ready to be consumed.
assign arc_conv_conv_dly1               = (ctrl_state == CONV) & (ctrl_state_nxt == CONV_DLY1);
assign arc_wait_pend_wait_pend_dly1     = (ctrl_state == WAIT_PEND) & (ctrl_state_nxt == WAIT_PEND_DLY1);
assign arc_to_avrg_cnt                  = ((ctrl_state == CONV) & (ctrl_state_nxt == AVRG_CNT)) | ((ctrl_state == SYNC1) & (ctrl_state_nxt == AVRG_CNT));

// CONV to CONV_DLY1 can also be trasition from SYNC1 in dual adc mode 
// WAIT_PEND to WAIT_PEND_DLY1 can also be trasition from SYNC1 in dual adc mode 
assign arc_sync1_conv_dly1              = (ctrl_state == SYNC1) & (ctrl_state_nxt == CONV_DLY1);        // prev_ctrl_state is guaranteed by design to be CONV
assign arc_sync1_wait_pend_dly1         = (ctrl_state == SYNC1) & (ctrl_state_nxt == WAIT_PEND_DLY1);   // prev_ctrl_state is guaranteed by design to be WAIT_PEND


//--------------------------------------------------------------------------------------------//
// Control signal from FSM current state
//--------------------------------------------------------------------------------------------//
assign putresp_s        = (ctrl_state == PUTRESP);
assign putresp_pend_s   = (ctrl_state == PUTRESP_PEND);
assign pwrdwn_s         = (ctrl_state == PWRDWN);
assign pwrdwn_tsen_s    = (ctrl_state == PWRDWN_TSEN);
assign avrg_cnt_s       = (ctrl_state == AVRG_CNT);
assign wait_pend_dly1_s = (ctrl_state == WAIT_PEND_DLY1);
assign conv_dly1_s      = (ctrl_state == CONV_DLY1);
assign conv_s           = (ctrl_state == CONV);
assign putresp_dly3_s   = (ctrl_state == PUTRESP_DLY3);



// Load Response when
// 1) In putresp state and there is pending response
// 2) In putresp_pend state
assign load_rsp                     = (putresp_s & ~cmd_is_rclb & pend) | putresp_pend_s;
assign load_dout                    = ((arc_conv_conv_dly1 | arc_sync1_conv_dly1) & ~cmd_is_rclb & pend) | arc_wait_pend_wait_pend_dly1 | arc_sync1_wait_pend_dly1 | ((int_timer != 8'h0) & arc_to_avrg_cnt);
assign load_cmd_ready               = putresp_s;
assign arc_to_conv                  = (ctrl_state != CONV) & (ctrl_state != AVRG_CNT) & ~((ctrl_state == SYNC1) & (prev_ctrl_state == CONV)) & (ctrl_state_nxt == CONV);

assign arc_getcmd_w_pwrdwn          = (ctrl_state == GETCMD_W) & (ctrl_state_nxt == PWRDWN);
assign arc_getcmd_pwrdwn            = (ctrl_state == GETCMD) & (ctrl_state_nxt == PWRDWN);
assign load_cmd_fetched             = arc_getcmd_w_pwrdwn | arc_getcmd_pwrdwn;
assign load_int_timer               = arc_getcmd_w_pwrdwn | arc_getcmd_pwrdwn | arc_to_conv; // arc_to_conv is added for averaging
assign incr_int_timer               = pwrdwn_s | pwrdwn_tsen_s | avrg_cnt_s; 

assign arc_out_from_pwrup_soc       = ((ctrl_state == PWRUP_SOC) & (ctrl_state_nxt != PWRUP_SOC) & (ctrl_state_nxt != SYNC1)) |
                                        ((ctrl_state == SYNC1) & (prev_ctrl_state == PWRUP_SOC) & (ctrl_state_nxt != PWRUP_SOC));
assign clr_cmd_fetched              = arc_out_from_pwrup_soc;


//--------------------------------------------------------------------------------------------//
// Control signal required by FSM
//--------------------------------------------------------------------------------------------//
assign cmd_is_rclb      = (cmd_channel == 5'b11111);
assign cmd_is_ts        = (cmd_channel == 5'b10001);
assign adc_change_mode  = (~prev_cmd_is_ts & cmd_is_ts) | (prev_cmd_is_ts & ~cmd_is_ts);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        prev_cmd_is_ts  <= 1'b0;
    else if (load_cmd_ready & ~cmd_is_rclb)
        prev_cmd_is_ts  <= cmd_is_ts;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cmd_fetched  <= 1'b0;
    else if (load_cmd_fetched)
        cmd_fetched  <= 1'b1;
    else if (clr_cmd_fetched)
        cmd_fetched  <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        conv_dly1_s_flp <= 1'b0;
    else
        conv_dly1_s_flp <= conv_dly1_s;
end

// Using conv_dly1_s_flp instead of (ctrl_state == PUTRESP) to set the pend flag
// This is to cover cases where during recalibration the state can go from PWRUP_SOC to PUTRESP directly 
// In averaging pend is set at pt 63, leaving pt 64 to be captured at WAIT PEND state (consistent with non-averaging)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        pend <= 1'b0;
    else if (conv_dly1_s_flp)
        pend <= 1'b1;
    else if (wait_pend_dly1_s)
        pend <= 1'b0;

end


//------------------------------------------------------------------------------------------------------------------//
// Register the DOUT bus from ADC hardblock
// This eliminates sampling invalid DOUT bus (validity of DOUT bus is limited by TDAC timing spec of ADC hardblock) 
// if latency of load_rsp increases in future
// Example: Previously DOUT is consumed by the design 2 clocks from falling edge of EOC
//          Without this register, to support averaging, DOUT is consumed by the design 4 clocks from falling edge of EOC
//          (additional 2 clocks for RAM accesses) 
//------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        dout_flp <= 12'd0;
    else if (load_dout) 
        dout_flp <= dout;
end


//--------------------------------------------------------------------------------------------//
// Internal timer to ensure soft power down stays at least for 1us
// Also used as AVRG counter
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        int_timer <= 8'h0;
    else if (load_int_timer)
        int_timer <= 8'h0;
    else if (incr_int_timer)
        int_timer <= int_timer + 8'h1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        avrg_cnt_done <= 1'b0;
    else if ((int_timer == (NUM_AVRG_POINTS - 8'd1)) & conv_s)
        avrg_cnt_done <= 1'b1;
    else if (clear_avrg_cnt_done)
        avrg_cnt_done <= 1'b0;
end

assign clear_avrg_cnt_done = putresp_dly3_s & ~cmd_valid; // Restart 64 point sampling if continuous sample is broken  

//--------------------------------------------------------------------------------------------//
// Store up CMD information due to 
// Resp is always one clk_dft later from current cmd (ADC hardblock characteristic)
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cmd_channel_dly <= 5'h0;
        cmd_sop_dly     <= 1'b0;
        cmd_eop_dly     <= 1'b0;
    end
    else if (load_cmd_ready) begin
        cmd_channel_dly <= cmd_channel;
        cmd_sop_dly     <= cmd_sop;
        cmd_eop_dly     <= cmd_eop;
    end
end



//--------------------------------------------------------------------------------------------//
// Averaging logic 
// 
//--------------------------------------------------------------------------------------------//
// Only temperature sensing mode has averaging feature
assign avrg_enable = cmd_is_ts;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        avrg_sum    <= 18'h0;
    else if (clear_avrg_sum)
        avrg_sum    <= 18'h0;
    else if (add_avrg_sum_run)
        avrg_sum  <= (avrg_sum - fifo_q) + {6'h0, dout_flp};
    else if (add_avrg_sum)
        avrg_sum  <= avrg_sum + {6'h0, dout_flp};
end

assign add_avrg_sum     = ((int_timer != 8'h0) & avrg_cnt_s) |  // when int_timer == 0 the DOUT is not yet ready (ADC hard block introduce one ADC clock delay in the ADC output) 
                            (conv_dly1_s & avrg_enable & pend) |    // cover averaging pt 64 and beyond (in back 2 back TS scenario)
                            (conv_dly1_s & avrg_enable & ~pend & ~frst_64_ptr_done) | // cover averaging pt 63
                            (wait_pend_dly1_s & prev_cmd_is_ts); // cover averaging pt 64 and beyond (in switching between ts to non-ts scenario)

assign add_avrg_sum_run = set_frst_64_ptr_done & frst_64_ptr_done;

assign clear_avrg_sum           = ~avrg_cnt_done & putresp_pend_s;  // Restart 64 point sampling if continuous sample is broken
                                                                    // Not avrg_cnt_done is to ensure put response pending state is caused by broken continuous sampling

assign set_frst_64_ptr_done     = (wait_pend_dly1_s & prev_cmd_is_ts) | // set at averaging pt 64 and beyond (where next conversion is non-ts)
                                    (conv_dly1_s & avrg_enable & pend); // set at averaging pt 64 and beyond (where next conversion is ts)
                                                                        // No harm to set this signal beyond pt 64

assign clear_frst_64_ptr_done   = clear_avrg_sum;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        frst_64_ptr_done <= 1'b0;
    else if (set_frst_64_ptr_done)
        frst_64_ptr_done <= 1'b1;
    else if (clear_frst_64_ptr_done)
        frst_64_ptr_done <= 1'b0;
end

assign fifo_sclr    = clear_avrg_sum;
assign fifo_rdreq   = (((arc_wait_pend_wait_pend_dly1 | arc_sync1_wait_pend_dly1) & prev_cmd_is_ts) | ((arc_conv_conv_dly1 | arc_sync1_conv_dly1) & avrg_enable & pend)) & frst_64_ptr_done;
assign fifo_wrreq   = ((int_timer != 8'h0) & avrg_cnt_s) |
                        (conv_dly1_s & avrg_enable & pend) |
                        (conv_dly1_s & avrg_enable & ~pend & ~frst_64_ptr_done) |
                        (wait_pend_dly1_s & prev_cmd_is_ts);

altera_modular_adc_control_avrg_fifo ts_avrg_fifo (
    .clock      (clk),
    .data       (dout_flp),
    .rdreq      (fifo_rdreq),
    .wrreq      (fifo_wrreq),
    .sclr       (fifo_sclr),
    .empty      (),
    .full       (),
    .q          (fifo_q)
);




//--------------------------------------------------------------------------------------------//
// Avalon ST response interface output register
// Avalon ST command interface output register (cmd_ready)
//--------------------------------------------------------------------------------------------//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rsp_valid   <= 1'b0;
        rsp_channel <= 5'h0;
        rsp_data    <= 12'h0;
        rsp_sop     <= 1'b0;
        rsp_eop     <= 1'b0;
    end
    else if (load_rsp) begin
        rsp_valid   <= 1'b1;
        rsp_channel <= cmd_channel_dly;
        rsp_data    <= rsp_data_nxt;
        rsp_sop     <= cmd_sop_dly;
        rsp_eop     <= cmd_eop_dly;
    end 
    else begin
        rsp_valid   <= 1'b0;
        rsp_channel <= 5'h0;
        rsp_data    <= 12'h0;
        rsp_sop     <= 1'b0;
        rsp_eop     <= 1'b0;
    end
end

generate
if (is_this_first_or_second_adc == 2) begin
    assign rsp_data_nxt = prev_cmd_is_ts ? 12'h0 : dout_flp;    // For ADC2, mask out TSD value since TSD is not supported in ADC2
end
else begin
    assign rsp_data_nxt = prev_cmd_is_ts ? avrg_sum[17:6] : dout_flp;
end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cmd_ready   <= 1'b0;
    else if (load_cmd_ready)
        cmd_ready   <= 1'b1;
    else
        cmd_ready   <= 1'b0;
end

endmodule
