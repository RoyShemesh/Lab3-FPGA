library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;          
use ieee.std_logic_textio.all;
-----------------------------------------------------------------
-- Computes the next PC value:
--   PCsel="00" : next_pc = PC_current + 1                        (sequential)
--   PCsel="01" : next_pc = PC_current + 1 + sign_ext(jmp_offset) (jump taken)
--   PCsel="10" : next_pc = 0...0                                  (zero / init)
-----------------------------------------------------------------
entity PC_Mux is
	generic( BusWidth      : integer := 16;
	         DoubleRegWidth : integer := 8 );
	port(
		PC_current : in  std_logic_vector(BusWidth-1 downto 0);
		PCsel      : in  std_logic_vector(1 downto 0);
		jmp_offset : in  std_logic_vector(DoubleRegWidth-1 downto 0);
		
		next_pc    : out std_logic_vector(BusWidth-1 downto 0)
	);
end PC_Mux;
-----------------------------------------------------------------
architecture arch of PC_Mux is
	signal PC_plus1   : std_logic_vector(BusWidth-1 downto 0);
	signal offset_ext : std_logic_vector(BusWidth-1 downto 0);
begin

	-- PC + 1
	PC_plus1 <= PC_current + 1;

	-- Sign-extend 8-bit offset to 16 bits
	offset_ext <= (BusWidth-1 downto DoubleRegWidth => jmp_offset(DoubleRegWidth-1))
	              & jmp_offset;

	with PCsel select
		next_pc <= PC_plus1                  when "00",
		           PC_current + offset_ext    when "01",
		           (others => '0')           when others;



	---------------------DEBUG--------
	process(PC_current, PCsel, jmp_offset)
        variable row : line;
    begin
        if now > 0 ps then
            write(row, string'("[PC_Mux] Time: "));
            write(row, now);
            write(row, string'(" | PC_curr: 0x"));
            hwrite(row, PC_current);
            write(row, string'(" | PCsel: "));
            write(row, PCsel);
            write(row, string'(" | Offset: "));
            write(row, jmp_offset);
            writeline(output, row);
        end if;
    end process;
	
end arch;
