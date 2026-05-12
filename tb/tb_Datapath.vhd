library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
-----------------------------------------------------------------
-- Datapath testbench
-- Loads ITCM/DTCM from files, manually drives control signals,
-- and dumps DTCM result to DTCMcontent.txt.
-- Working directory must be the LAB3 root.
-----------------------------------------------------------------
entity tb_Datapath is
end tb_Datapath;

architecture sim of tb_Datapath is

	constant BusWidth   : integer := 16;
	constant RegWidth   : integer := 4;
	constant AddrWidth  : integer := 6;
	constant MEM_DEPTH  : integer := 64;
	constant CLK_PERIOD : time    := 10 ns;

	signal clk : std_logic := '0';
	signal rst : std_logic := '1';

	-- Control inputs
	signal IRin          : std_logic := '0';
	signal RFout         : std_logic := '0';
	signal RFin          : std_logic := '0';
	signal Ain           : std_logic := '0';
	signal Cin           : std_logic := '0';
	signal Cout          : std_logic := '0';
	signal ALUFN         : std_logic_vector(RegWidth-1 downto 0)  := (others => '0');
	signal RFaddr_wr_sel : std_logic_vector(1 downto 0)           := "00";
	signal RFaddr_rd_sel : std_logic_vector(1 downto 0)           := "00";
	signal Imm1_in       : std_logic := '0';
	signal Imm2_in       : std_logic := '0';
	signal PCin          : std_logic := '0';
	signal PCsel         : std_logic_vector(1 downto 0)           := "00";
	signal DTCM_out      : std_logic := '0';
	signal DTCM_addr_in  : std_logic := '0';
	signal DTCM_wr       : std_logic := '0';

	-- Testbench memory interface
	signal TBactive         : std_logic := '1';
	signal ITCM_tb_wr       : std_logic := '0';
	signal ITCM_tb_in       : std_logic_vector(BusWidth-1  downto 0) := (others => '0');
	signal ITCM_tb_addr_in  : std_logic_vector(AddrWidth-1 downto 0) := (others => '0');
	signal DTCM_tb_wr       : std_logic := '0';
	signal DTCM_tb_in       : std_logic_vector(BusWidth-1  downto 0) := (others => '0');
	signal DTCM_tb_addr_in  : std_logic_vector(AddrWidth-1 downto 0) := (others => '0');
	signal DTCM_tb_addr_out : std_logic_vector(AddrWidth-1 downto 0) := (others => '0');
	signal DTCM_tb_out      : std_logic_vector(BusWidth-1  downto 0);

	-- Status outputs
	signal add   : std_logic;
	signal sub   : std_logic;
	signal andop : std_logic;
	signal orop  : std_logic;
	signal xorop : std_logic;
	signal jmp   : std_logic;
	signal jc    : std_logic;
	signal jnc   : std_logic;
	signal mov   : std_logic;
	signal ld    : std_logic;
	signal st    : std_logic;
	signal done  : std_logic;
	signal Zflag : std_logic;
	signal Nflag : std_logic;
	signal Cflag : std_logic;

begin

	clk <= not clk after CLK_PERIOD / 2;

	DUT : entity work.Datapath
		generic map(BusWidth => BusWidth, RegWidth => RegWidth, AddrWidth => AddrWidth)
		port map(
			clk              => clk,
			rst              => rst,
			IRin             => IRin,
			RFout            => RFout,
			RFin             => RFin,
			Ain              => Ain,
			Cin              => Cin,
			Cout             => Cout,
			ALUFN            => ALUFN,
			RFaddr_wr_sel    => RFaddr_wr_sel,
			RFaddr_rd_sel    => RFaddr_rd_sel,
			Imm1_in          => Imm1_in,
			Imm2_in          => Imm2_in,
			PCin             => PCin,
			PCsel            => PCsel,
			DTCM_out         => DTCM_out,
			DTCM_addr_in     => DTCM_addr_in,
			DTCM_wr          => DTCM_wr,
			TBactive         => TBactive,
			ITCM_tb_wr       => ITCM_tb_wr,
			ITCM_tb_in       => ITCM_tb_in,
			ITCM_tb_addr_in  => ITCM_tb_addr_in,
			DTCM_tb_wr       => DTCM_tb_wr,
			DTCM_tb_in       => DTCM_tb_in,
			DTCM_tb_addr_in  => DTCM_tb_addr_in,
			DTCM_tb_addr_out => DTCM_tb_addr_out,
			DTCM_tb_out      => DTCM_tb_out,
			add              => add,
			sub              => sub,
			andop            => andop,
			orop             => orop,
			xorop            => xorop,
			jmp              => jmp,
			jc               => jc,
			jnc              => jnc,
			mov              => mov,
			ld               => ld,
			st               => st,
			done             => done,
			Zflag            => Zflag,
			Nflag            => Nflag,
			Cflag            => Cflag
		);

	process
		file     itcm_init   : text open read_mode  is "ITCMinit.txt";
		file     dtcm_init   : text open read_mode  is "DTCMinit.txt";
		file     dtcm_result : text open write_mode is "DTCMcontent.txt";
		variable l           : line;
		variable data_v      : std_logic_vector(BusWidth-1 downto 0);
		variable addr_i      : integer;
	begin

		-- ---- Reset ----
		TBactive <= '1';
		rst      <= '1';
		wait for 2 * CLK_PERIOD;
		rst <= '0';

		-- ---- Load ITCM ----
		report "Loading ITCM from ITCMinit.txt";
		ITCM_tb_wr <= '1';
		addr_i := 0;
		while not endfile(itcm_init) loop
			readline(itcm_init, l);
			read(l, data_v);
			ITCM_tb_in      <= data_v;
			ITCM_tb_addr_in <= std_logic_vector(to_unsigned(addr_i, AddrWidth));
			wait until rising_edge(clk);
			addr_i := addr_i + 1;
		end loop;
		ITCM_tb_wr <= '0';

		-- ---- Load DTCM ----
		report "Loading DTCM from DTCMinit.txt";
		DTCM_tb_wr <= '1';
		addr_i := 0;
		while not endfile(dtcm_init) loop
			readline(dtcm_init, l);
			read(l, data_v);
			DTCM_tb_in      <= data_v;
			DTCM_tb_addr_in <= std_logic_vector(to_unsigned(addr_i, AddrWidth));
			wait until rising_edge(clk);
			addr_i := addr_i + 1;
		end loop;
		DTCM_tb_wr <= '0';
		TBactive   <= '0';

		-- ---- Manually drive a FETCH cycle ----
		-- FETCH: IRin=1, PCin=1, PCsel="00" → latch instruction from ProgMem, PC←PC+1
		report "FETCH";
		IRin  <= '1';
		PCin  <= '1';
		PCsel <= "00";
		wait until rising_edge(clk);
		IRin  <= '0';
		PCin  <= '0';
		wait for 1 ns;
		report "After FETCH: add="  & std_logic'image(add)
		                 & " sub="  & std_logic'image(sub)
		                 & " mov="  & std_logic'image(mov)
		                 & " ld="   & std_logic'image(ld)
		                 & " st="   & std_logic'image(st)
		                 & " jmp="  & std_logic'image(jmp)
		                 & " done=" & std_logic'image(done);

		-- ---- Example: manually drive R-type execution (add/sub/and/or/xor) ----
		-- Step R1: RFout=1, Ain=1, RFaddr_rd_sel="01" (read rb → A_reg)
		report "R1: read rb → A_reg";
		RFout         <= '1';
		Ain           <= '1';
		RFaddr_rd_sel <= "01";
		wait until rising_edge(clk);
		RFout <= '0'; Ain <= '0';

		-- Step R2: RFout=1, Cin=1, RFaddr_rd_sel="00" (read rc), ALUFN=opcode
		report "R2: read rc, ALU compute → C_reg";
		RFout         <= '1';
		Cin           <= '1';
		RFaddr_rd_sel <= "00";
		ALUFN         <= "0000"; -- ADD
		wait until rising_edge(clk);
		RFout <= '0'; Cin <= '0';

		-- Step R3: Cout=1, RFin=1, RFaddr_wr_sel="10" (write ra ← C_reg)
		report "R3: write result to RF[ra]";
		Cout          <= '1';
		RFin          <= '1';
		RFaddr_wr_sel <= "10";
		wait until rising_edge(clk);
		Cout <= '0'; RFin <= '0';
		wait for 1 ns;
		report "Zflag=" & std_logic'image(Zflag)
		     & " Nflag=" & std_logic'image(Nflag)
		     & " Cflag=" & std_logic'image(Cflag);

		-- ---- Dump DTCM contents to DTCMcontent.txt ----
		report "Dumping DTCM to DTCMcontent.txt";
		TBactive <= '1';
		for i in 0 to MEM_DEPTH-1 loop
			DTCM_tb_addr_out <= std_logic_vector(to_unsigned(i, AddrWidth));
			wait until rising_edge(clk);
			wait for 1 ns;
			write(l, DTCM_tb_out);
			writeline(dtcm_result, l);
		end loop;

		report "Datapath TB complete." severity note;
		wait;
	end process;

end sim;