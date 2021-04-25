library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPI is
	generic(
		BitWidth: natural := 8;
		Prescaler: natural := 0;
		Master: std_logic := '1';
		CPHA: std_logic := '1'; --Rising edge = 1, Falling edge = 0
		CPOL: std_logic := '0' --Idle high = 1, Idle low = 0
	);
	port(
		ClkO, DO, CS, Bsy: out std_logic;
		ClkI, DI, Rst, Trig: in std_logic;
		PDI: in std_logic_vector(BitWidth-1 downto 0); --Parallel data in
		PDO: out std_logic_vector(BitWidth-1 downto 0) --Parallel data out
	);
end SPI;

architecture A of SPI is
	constant CSTog: std_logic := '1';
	type States is (CSLow, CSHigh, DShift);
	signal State: States := CSHigh;
	signal DataI, DataO: std_logic_vector(BitWidth-1 downto 0);
	signal Presc: unsigned(7 downto 0);
	signal ClkOv: std_logic;
	signal DCnt: unsigned(4 downto 0) := to_unsigned(BitWidth, 5);
	signal TA, TAA: std_logic := '0';
	
	begin	
	process(ClkI, DI, Rst, ClkOv)
	begin
		if(Rst = '0') then
			State <= CSHigh;
			CS <= '1';
			DO <= '0';
			ClkO <= '0';
			TA <= '0';
			TAA <= '0';
		elsif(rising_edge(ClkI)) then
			TAA <= TA;
			TA <= Trig;
			
			--Rising edge
			if(TAA = '0' and TA = '1') then
				DataO <= PDI;
				State <= CSLow;
			end if;
		
			if(Presc(Prescaler) = '1') then
			Presc <= (others => '0');
				if(Master = '1') then					
					case State is
						when CSHigh => 
							Bsy <= '0';
							
							--if(CSTog = '1') then CS <= '1'; end if; -- ACH
							CS <= '1';
							
							DCnt <= to_unsigned(BitWidth, 5);
							DO <= '0';
							ClkOv <= '0';
						when CSLow =>
							Bsy <= '1';
							State <= DShift;
							CS <= '0';
							DO <= DataO(7);
						when DShift =>
							if(DCnt = "000") then
								State <= CSHigh;
								PDO <= DataI;
							end if;
							
							if(ClkOv = CPHA) then
								DO <= DataO(to_integer(DCnt-1));
							else
								DataI(7 downto 0) <= DataI(6 downto 0) & DI;
								DCnt <= DCnt - 1;
							end if;
							ClkOv <= not ClkOv;
					end case;
				else --Slave not yet implemented!
				end if;
			else
				Presc <= Presc + 1;
			end if;
		end if;
		ClkO <= ClkOv xor CPOL;
	end process;
end A;