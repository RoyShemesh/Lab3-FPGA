library ieee;
use ieee.std_logic_1164.all;
-----------------------------------------------------------------
entity opc_decoder is
	generic( RegWidth: integer:=4 );
	port(
		opc:                                                            in  std_logic_vector(RegWidth-1 downto 0);
		st, ld, mov, done, add, sub, jmp, jc, jnc, andop, orop, xorop: out std_logic
	);
end opc_decoder;
-----------------------------------------------------------------
architecture decoder of opc_decoder is
begin
	-- R-Type
	add   <= '1' when opc = "0000" else '0'; -- also emulates NOP (add R0,R0,R0)
	sub   <= '1' when opc = "0001" else '0';
	andop <= '1' when opc = "0010" else '0';
	orop  <= '1' when opc = "0011" else '0';
	xorop <= '1' when opc = "0100" else '0';
	-- xorop <= '1' when opc = "0100" else '0';
	-- xorop <= '1' when opc = "0100" else '0';

	-- J-Type
	jmp <= '1' when opc = "0111" else '0';
	jc  <= '1' when opc = "1000" else '0'; -- includes JHS
	jnc <= '1' when opc = "1001" else '0'; -- includes JLO
	-- jnc <= '1' when opc = "1001" else '0'; 
	-- jnc <= '1' when opc = "1001" else '0'; 

	-- I-Type
	mov <= '1' when opc = "1100" else '0';
	ld  <= '1' when opc = "1101" else '0';
	st  <= '1' when opc = "1110" else '0';

	-- Special
	done <= '1' when opc = "1111" else '0';

end decoder;
