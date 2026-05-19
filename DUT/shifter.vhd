LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.aux_package.all;
-------------------------------------
ENTITY SHIFTER IS
  GENERIC (n : INTEGER := 16;
		   k : integer := 4;   -- k=log2(n)
		   m : integer := 8	); -- m=2^(k-1)
  PORT (    Y_i: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
			X_i: IN STD_LOGIC_VECTOR (k-1 DOWNTO 0);
			ALUFN_i : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
            ALUout_o: OUT STD_LOGIC_VECTOR(n-1 downto 0);
			Cflag_o: OUT STD_LOGIC
			);
END SHIFTER;
--------------------------------------------------------------
ARCHITECTURE dataflow OF SHIFTER IS
	type matrix IS array (0 TO K) OF STD_LOGIC_VECTOR(n-1 downto 0);
	signal s : matrix;
	signal initial_y :STD_LOGIC_VECTOR(n-1 DOWNTO 0);
	signal shifted_o :STD_LOGIC_VECTOR(n-1 DOWNTO 0);
	signal raw_carry : STD_LOGIC;

BEGIN
	
	
	side_input: for i in 0 to n-1 generate
		initial_y(i) <= Y_i(i) when ALUFN_i(0) ='0' else Y_i(n-1-i);
	end generate;
	
	WITH ALUFN_i select
			s(0) <=  initial_y       WHEN "000",
					 initial_y	     WHEN "001",
					 (others => '0') WHEN others;
	
	stages: FOR i in 0 to k-1 generate
		bits: for j in 0 to n-1 generate
			upper_bits: if j >= 2**i generate
						s(i+1)(j) <= s(i)(j) when X_i(i) = '0' else s(i)(j-2**i);
					end generate;
			
			lower_bits: if j < 2**i generate
						s(i+1)(j) <= s(i)(j) when X_i(i) = '0' else '0';
					end generate;
					  
		END generate bits;
	END generate stages;
	
	shifted_o <= s(k);
	
	gen_output : for i in 0 to n-1 generate
		ALUout_o(i) <= shifted_o(i) when ALUFN_i(0) = '0' else shifted_o(n-1-i);
	end generate;
	raw_carry <= Y_i(n-1) when ALUFN_i(0) = '0' else Y_i(0);
	Cflag_o <= raw_carry when ALUFN_i(2 DOWNTO 1) = "00" else '0';
END dataflow;