library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DelayLine is
generic (
DATA_WIDTH : natural := 20
);

port (
output: out signed ((DATA_WIDTH-1) downto 0);
a: in signed ((DATA_WIDTH-1) downto 0); 
b: in signed ((DATA_WIDTH-1) downto 0); 
START: in std_logic;
STOP: in std_logic
);
end DelayLine;

architecture rtl of DelayLine is
--SIGNAL reg: signed ((DATA_WIDTH-1) downto 0);
SIGNAL buf: signed ((DATA_WIDTH-1) downto 0);

begin
process (START,STOP,a,b)
variable s : signed ((DATA_WIDTH) downto 0);
begin
s := ('0' & a) + ('0' & b) + ('0' & START); -- if a and b are 0 and 1, start will start filling buf with 0's, I think
buf<=s((DATA_WIDTH-1) downto 0);

if (rising_edge(STOP)) then
output<=buf((DATA_WIDTH-1) downto 0); -- stop should freeze the output
end if;
end process;

end rtl;
