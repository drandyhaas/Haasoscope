	component myadc is
		port (
			adc_pll_clock_clk      : in  std_logic                     := 'X';             -- clk
			adc_pll_locked_export  : in  std_logic                     := 'X';             -- export
			clock_clk              : in  std_logic                     := 'X';             -- clk
			command_valid          : in  std_logic                     := 'X';             -- valid
			command_channel        : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
			command_startofpacket  : in  std_logic                     := 'X';             -- startofpacket
			command_endofpacket    : in  std_logic                     := 'X';             -- endofpacket
			command_ready          : out std_logic;                                        -- ready
			reset_sink_reset_n     : in  std_logic                     := 'X';             -- reset_n
			response_valid         : out std_logic;                                        -- valid
			response_channel       : out std_logic_vector(4 downto 0);                     -- channel
			response_data          : out std_logic_vector(11 downto 0);                    -- data
			response_startofpacket : out std_logic;                                        -- startofpacket
			response_endofpacket   : out std_logic                                         -- endofpacket
		);
	end component myadc;

	u0 : component myadc
		port map (
			adc_pll_clock_clk      => CONNECTED_TO_adc_pll_clock_clk,      --  adc_pll_clock.clk
			adc_pll_locked_export  => CONNECTED_TO_adc_pll_locked_export,  -- adc_pll_locked.export
			clock_clk              => CONNECTED_TO_clock_clk,              --          clock.clk
			command_valid          => CONNECTED_TO_command_valid,          --        command.valid
			command_channel        => CONNECTED_TO_command_channel,        --               .channel
			command_startofpacket  => CONNECTED_TO_command_startofpacket,  --               .startofpacket
			command_endofpacket    => CONNECTED_TO_command_endofpacket,    --               .endofpacket
			command_ready          => CONNECTED_TO_command_ready,          --               .ready
			reset_sink_reset_n     => CONNECTED_TO_reset_sink_reset_n,     --     reset_sink.reset_n
			response_valid         => CONNECTED_TO_response_valid,         --       response.valid
			response_channel       => CONNECTED_TO_response_channel,       --               .channel
			response_data          => CONNECTED_TO_response_data,          --               .data
			response_startofpacket => CONNECTED_TO_response_startofpacket, --               .startofpacket
			response_endofpacket   => CONNECTED_TO_response_endofpacket    --               .endofpacket
		);

