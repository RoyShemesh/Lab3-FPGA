library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;          
use ieee.std_logic_textio.all;
-----------------------------------------------------------------
entity PC is
	generic( BusWidth: integer := 16 );
	port(
		clk   : in  std_logic;
		rst   : in  std_logic;
		PCin  : in  std_logic;
		PC_next  : in  std_logic_vector(BusWidth-1 downto 0);
		PCout : out std_logic_vector(BusWidth-1 downto 0)
	);
end PC;
-----------------------------------------------------------------
architecture arch of PC is
	signal PC_reg : std_logic_vector(BusWidth-1 downto 0);
begin

	process(clk, rst)
	begin
		if rst = '1' then
			PC_reg <= (others => '0');
		elsif rising_edge(clk) then
			if PCin = '1' then
				PC_reg <= PC_next;
			end if;
		end if;
	end process;

	PCout <= PC_reg;

----------------------DEBUG------------
-- process(PC_reg)
--         variable row : line;
--     begin
--         if now > 0 ps then
--             write(row, string'("PC Update at "));
--             write(row, now); 
--             write(row, string'(": New Value = 0x"));
--             hwrite(row, PC_reg); 
--             writeline(output, row);
--         end if;
--     end process;

end arch;
