	myadc u0 (
		.adc_pll_clock_clk      (<connected-to-adc_pll_clock_clk>),      //  adc_pll_clock.clk
		.adc_pll_locked_export  (<connected-to-adc_pll_locked_export>),  // adc_pll_locked.export
		.clock_clk              (<connected-to-clock_clk>),              //          clock.clk
		.command_valid          (<connected-to-command_valid>),          //        command.valid
		.command_channel        (<connected-to-command_channel>),        //               .channel
		.command_startofpacket  (<connected-to-command_startofpacket>),  //               .startofpacket
		.command_endofpacket    (<connected-to-command_endofpacket>),    //               .endofpacket
		.command_ready          (<connected-to-command_ready>),          //               .ready
		.reset_sink_reset_n     (<connected-to-reset_sink_reset_n>),     //     reset_sink.reset_n
		.response_valid         (<connected-to-response_valid>),         //       response.valid
		.response_channel       (<connected-to-response_channel>),       //               .channel
		.response_data          (<connected-to-response_data>),          //               .data
		.response_startofpacket (<connected-to-response_startofpacket>), //               .startofpacket
		.response_endofpacket   (<connected-to-response_endofpacket>)    //               .endofpacket
	);

