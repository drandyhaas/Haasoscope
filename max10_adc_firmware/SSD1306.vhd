library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SSD1306 is
	port(
		PDO: out std_logic_vector(7 downto 0);		
		Clk, Rst, Bsy, Source: in std_logic;
		Trig, CD: out std_logic;		
		MADDR: out std_logic_vector(9 downto 0);
		MemDI: in std_logic_vector(7 downto 0)
	);
end SSD1306;

architecture Ar of SSD1306 is
constant AMNT_INSTRS: natural := 27;
constant CONTRAST: std_logic_vector(7 downto 0) := x"0F";
type IAR is array (0 to AMNT_INSTRS-1) of std_logic_vector(7 downto 0);
signal Instrs: IAR := (x"A8", x"3F", x"D3", x"00", x"40", x"A0", x"DA", x"12", x"81", CONTRAST, x"20", x"00", x"21", x"00", x"7F", x"22", x"00", x"07", 
x"A6", --A6 for no invert --A7 for invert
x"DB", x"40", x"A4", x"D5", x"80", x"8D", x"14", x"AF");

constant AMNT_DATA: natural := 1024;
type IDATA is array (0 to AMNT_DATA-1) of std_logic_vector(7 downto 0);
signal Datas: IDATA := ( 
x"df",x"bc",x"f3",x"5e",x"b5",x"da",x"77",x"f9",x"1f",x"02",x"1e",x"01",x"1f",x"1a",x"1d",x"3a",x"25",x"58",x"3e",x"65",x"5f",x"2c",x"31",x"ae",x"f9",x"fe",x"f5",x"fb",x"f6",x"fe",x"fd",x"de",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"1f",x"0f",x"07",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"80",x"00",x"02",x"a0",x"10",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"02",x"00",x"00",x"04",x"01",x"04",x"09",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"01",x"14",x"21",x"00",x"0a",x"01",x"04",x"02",x"10",x"45",x"12",x"05",x"0a",x"81",x"04",x"03",x"00",x"45",x"08",x"52",x"8a",x"25",x"55",
x"ff",x"bf",x"7f",x"ff",x"7f",x"ff",x"7f",x"ff",x"7f",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"7f",x"ff",x"7f",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"fe",x"fc",x"fc",x"c1",x"b6",x"eb",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"3f",x"1f",x"0f",x"07",x"07",x"01",x"0a",x"07",x"9f",x"0e",x"1f",x"3e",x"1f",x"3e",x"1f",x"1e",x"1f",x"0d",x"0f",x"0f",x"0b",x"07",x"05",x"45",x"21",x"10",x"08",x"00",x"44",x"03",x"23",x"01",x"89",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"55",x"00",x"3e",x"41",x"ba",x"45",x"2a",x"95",x"6a",x"95",x"2a",x"d1",x"4a",x"a4",x"52",x"a8",x"52",x"ad",x"42",x"2d",x"92",x"ad",x"52",x"4b",
x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"fe",x"fe",x"fe",x"fc",x"fc",x"fe",x"fc",x"fe",x"fe",x"fc",x"fc",x"d4",x"dc",x"fc",x"fe",x"fe",x"fe",x"fe",x"fe",x"fe",x"fe",x"fe",x"e0",x"00",x"04",x"0e",x"60",x"9c",x"7e",x"de",x"be",x"fe",x"fe",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"fe",x"fe",x"fa",x"f4",x"fa",x"f2",x"ed",x"f2",x"ed",x"d2",x"ed",x"da",x"f4",x"c8",x"f8",x"e8",x"e1",x"ea",x"81",x"27",x"ca",x"14",x"ab",x"94",x"2b",x"c5",x"3e",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"fc",x"63",x"04",x"db",x"a8",x"d4",x"e0",x"dc",x"f0",x"ee",x"f0",x"fe",x"f1",x"6c",x"f5",x"78",x"3e",x"b9",x"5c",x"1f",x"ae",x"4f",x"43",x"c1",x"00",x"e0",x"10",x"a0",x"58",x"84",x"32",x"cc",x"23",x"5c",x"a2",x"55",x"2a",x"d5",x"6a",
x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"fd",x"c0",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"c0",x"80",x"80",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"a0",x"50",x"a8",x"04",x"0a",x"01",x"0a",x"45",x"17",x"5f",x"7f",x"f2",x"a5",x"8a",x"25",x"5a",x"2b",x"cb",x"07",x"43",x"87",x"e3",x"d3",x"d3",x"e9",x"e0",x"e0",x"e0",x"c0",x"80",x"10",x"e0",x"50",x"c0",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"02",x"40",x"85",x"50",x"82",x"75",x"97",x"6d",x"b7",x"ff",x"ff",x"7f",x"1f",x"00",x"00",x"00",x"00",x"00",x"80",x"00",x"a0",x"40",x"90",x"6a",x"91",
x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"57",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"02",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"02",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"03",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"07",x"37",x"0f",x"3f",x"8f",x"57",x"4f",x"17",x"eb",x"d7",x"25",x"db",x"4e",x"bf",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"fc",x"05",x"1f",x"7a",x"85",x"28",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"85",x"71",x"8f",x"75",x"db",x"7f",x"db",x"7f",x"ff",x"ff",x"ff",x"fc",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"50",
x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"7f",x"7f",x"7f",x"7f",x"7f",x"7f",x"7f",x"7f",x"3f",x"7f",x"3f",x"3f",x"3f",x"3f",x"7f",x"07",x"2b",x"07",x"d1",x"3e",x"4b",x"34",x"03",x"54",x"2e",x"3d",x"d3",x"2d",x"13",x"0b",x"27",x"17",x"07",x"17",x"07",x"6f",x"df",x"af",x"ff",x"3f",x"7f",x"7f",x"7f",x"7f",x"7f",x"7f",x"7f",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"f8",x"f7",x"f8",x"be",x"fd",x"de",x"fe",x"ef",x"ef",x"f7",x"f3",x"f0",x"e1",x"c7",x"17",x"7f",x"57",x"af",x"5f",x"2f",x"1f",x"2f",x"5f",x"17",x"2f",x"97",x"2b",x"15",x"0a",x"35",x"03",x"70",x"45",x"62",x"51",x"f5",x"d8",x"f7",x"fd",x"ff",x"ff",x"fe",x"fc",x"f8",x"f0",x"c0",x"80",x"00",x"03",x"07",x"0f",x"0f",x"3f",x"fe",x"f8",x"78",x"00",x"0a",x"14",x"01",
x"fd",x"db",x"f5",x"ff",x"ff",x"f5",x"df",x"f5",x"ea",x"ff",x"ed",x"fb",x"fe",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ef",x"ff",x"fe",x"df",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff",x"fe",x"fd",x"fa",x"f7",x"cd",x"ba",x"57",x"ab",x"5c",x"8b",x"76",x"89",x"36",x"49",x"a7",x"18",x"e7",x"c9",x"f6",x"e1",x"da",x"f5",x"f2",x"fd",x"f8",x"fa",x"fc",x"fd",x"fe",x"fc",x"ff",x"fe",x"ff",x"fe",x"ff",x"ff",x"fe",x"fd",x"7e",x"fe",x"7a",x"bc",x"7a",x"7c",x"f5",x"f4",x"c4",x"c4",x"80",x"04",x"04",x"0e",x"1c",x"3c",x"fd",x"fc",x"fa",x"f5",x"e0",x"c6",x"09",x"12",x"25",x"94",x"20",x"56",x"89",x"24",
x"f7",x"5f",x"ff",x"fb",x"57",x"fd",x"57",x"fa",x"6f",x"bb",x"f7",x"5d",x"b7",x"ed",x"fa",x"ef",x"f5",x"ff",x"fa",x"ff",x"fb",x"fd",x"fe",x"fb",x"fd",x"f7",x"7e",x"fd",x"f7",x"fb",x"ed",x"ff",x"fd",x"ff",x"fd",x"ff",x"fd",x"fe",x"f5",x"fa",x"f7",x"fb",x"fe",x"fd",x"ff",x"fb",x"fd",x"cb",x"dd",x"da",x"df",x"cd",x"ef",x"a7",x"f3",x"b3",x"f3",x"6b",x"d9",x"2d",x"f4",x"aa",x"de",x"6b",x"be",x"75",x"df",x"25",x"fe",x"a1",x"5e",x"a3",x"5d",x"e2",x"1f",x"e5",x"5a",x"ab",x"56",x"ad",x"b2",x"4f",x"b0",x"0f",x"00",x"1e",x"00",x"0d",x"0a",x"a4",x"06",x"42",x"03",x"a2",x"01",x"91",x"00",x"a8",x"80",x"50",x"8a",x"00",x"94",x"00",x"48",x"00",x"0a",x"00",x"00",x"24",x"00",x"00",x"10",x"00",x"52",x"2a",x"82",x"6c",x"92",x"44",x"92",x"28",x"54",x"83",x"34",x"ca",x"15",x"40"
);

type PStates is (Init, Draw);
type SStates is (BusyWaitA, BusyWaitB, Writing, Done);

signal SPISt: SStates := Done;
signal PSt: PStates := Init;
signal PInstr: unsigned(7 downto 0);
signal MemAddr: unsigned(9 downto 0);

begin
	process(Clk, Rst, Bsy, Source,MemAddr) -- ACH added MemAddr
	begin
		MADDR <= std_logic_vector(MemAddr);
		
		if(Rst = '0') then
			PSt <= Init;
			SPISt <= Done;
			PInstr <= (others => '0');
		elsif(rising_edge(Clk)) then
			if(PSt = Init) then
				CD <= '0';
				if(SPISt = Done) then
					PDO <= (Instrs(to_integer(PInstr)));
					Trig <= '1';
					SPISt <= BusyWaitA;
				elsif(SPISt = BusyWaitA) then
					if(Bsy = '1') then
						PInstr <= PInstr + 1;
						SPISt <= Writing;
						Trig <= '0';
					end if;
				else
					if(Bsy = '0') then
						SPISt <= Done;
						if(PInstr = AMNT_INSTRS) then
							PSt <= Draw;
							PInstr <= (others => '0');
							MemAddr <= b"1111111111";
						end if;
					end if;
				end if;
			else --Draw
				CD <= '1';
				
				if(SPISt = Done) then
					
					--if (MemAddr>150) then PDO <= x"f0";
					--else PDO <= x"55";
					--end if;
					
					if (Source = '0') then PDO <= Datas(to_integer(MemAddr));					
					else PDO <= MemDI;
					end if;
					
					Trig <= '1';
					SPISt <= BusyWaitA;
				elsif(SPISt = BusyWaitA) then
					if(Bsy = '1') then
						MemAddr <= MemAddr - 1;
						PInstr <= PInstr + 1;
						SPISt <= Writing;
						Trig <= '0';
					end if;
				else
					if(Bsy = '0') then SPISt <= Done; end if;
				end if;
			end if;
		end if;
	end process;
end Ar;
