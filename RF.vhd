library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use ieee.std_logic_textio.all;
--------------------------------------------------------------
entity RF is
generic( Dwidth: integer:=16;
		 Awidth: integer:=4);
port(	clk,rst,WregEn: in std_logic;
		WregData:	in std_logic_vector(Dwidth-1 downto 0);
		WregAddr,RregAddr:
					in std_logic_vector(Awidth-1 downto 0);
		RregData: 	out std_logic_vector(Dwidth-1 downto 0);
		-- Debug ports (simulation only)
		PC_update:  in std_logic;
		PC_val:     in std_logic_vector(Dwidth-1 downto 0)
);
end RF;
--------------------------------------------------------------
architecture behav of RF is

type RegFile is array (0 to 2**Awidth-1) of 
	std_logic_vector(Dwidth-1 downto 0);
signal sysRF: RegFile;

begin			   
  process(clk,rst)
  begin
	if (rst='1') then
		sysRF(0) <= (others=>'0');   -- R[0] is constant Zero value 
	elsif (clk'event and clk='1') then
	    if (WregEn='1') then
		    -- index is type of integer so we need to use 
			-- buildin function conv_integer in order to change the type
		    -- from std_logic_vector to integer
			sysRF(conv_integer(WregAddr)) <= WregData; 
	    end if;
	end if;
  end process;
	
  RregData <= sysRF(conv_integer(RregAddr));

  -- Debug: dump all registers once per instruction (when PC advances)
  debug_rf : process(clk)
      variable l : line;
  begin
      if rising_edge(clk) and PC_update = '1' then
          write(l, string'("[RF] PC=0x")); hwrite(l, PC_val);
          write(l, string'(" t=")); write(l, now);
          write(l, string'(" |"));
          for i in 0 to 2**Awidth-1 loop
              write(l, string'(" R")); write(l, i);
              write(l, string'("=0x")); hwrite(l, sysRF(i));
              write(l, string'(" |"));
          end loop;
          writeline(output, l);
      end if;
  end process debug_rf;

end behav;
