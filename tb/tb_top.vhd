library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.aux_package.all;
-----------------------------------------------------------------
-- Full-system testbench (Control + Datapath via top)
-- Working directory must be the LAB3 root so that
-- ITCMinit.txt, DTCMinit.txt, and DTCMcontent.txt are found.
-----------------------------------------------------------------
entity tb_top is
end tb_top;

architecture sim of tb_top is

	constant BusWidth   : integer := 16;
	constant RegWidth   : integer := 4;
	constant AddrWidth  : integer := 6;
	constant MEM_DEPTH  : integer := 64;
	constant CLK_PERIOD : time    := 10 ns;

	signal clk              : std_logic := '0';
	signal rst              : std_logic := '1';
	signal ena              : std_logic := '0';
	signal TBactive         : std_logic := '1';
	signal ITCM_tb_wr       : std_logic := '0';
	signal ITCM_tb_in       : std_logic_vector(BusWidth-1  downto 0) := (others => '0');
	signal ITCM_tb_addr_in  : std_logic_vector(AddrWidth-1 downto 0) := (others => '0');
	signal DTCM_tb_wr       : std_logic := '0';
	signal DTCM_tb_in       : std_logic_vector(BusWidth-1  downto 0) := (others => '0');
	signal DTCM_tb_addr_in  : std_logic_vector(AddrWidth-1 downto 0) := (others => '0');
	signal DTCM_tb_addr_out : std_logic_vector(AddrWidth-1 downto 0) := (others => '0');
	signal DTCM_tb_out      : std_logic_vector(BusWidth-1  downto 0);
	signal done             : std_logic;

begin

	clk <= not clk after CLK_PERIOD / 2;

	DUT : entity work.top generic map(BusWidth => BusWidth, RegWidth => RegWidth, AddrWidth => AddrWidth)
		port map(
			clk              => clk,
			rst              => rst,
			ena              => ena,
			TBactive         => TBactive,
			ITCM_tb_wr       => ITCM_tb_wr,
			ITCM_tb_in       => ITCM_tb_in,
			ITCM_tb_addr_in  => ITCM_tb_addr_in,
			DTCM_tb_wr       => DTCM_tb_wr,
			DTCM_tb_in       => DTCM_tb_in,
			DTCM_tb_addr_in  => DTCM_tb_addr_in,
			DTCM_tb_addr_out => DTCM_tb_addr_out,
			DTCM_tb_out      => DTCM_tb_out,
			done             => done
		);

	process
		file     itcm_init   : text open read_mode  is "C:/Users/sheme/OneDrive/Desktop/UNI/3rd year/ARCH LAB/LAB3/Lab3-FPGA/SW-QA/Ex6/bin/ITCMinit.txt";
		file     dtcm_init   : text open read_mode  is "C:/Users/sheme/OneDrive/Desktop/UNI/3rd year/ARCH LAB/LAB3/Lab3-FPGA/SW-QA/Ex6/bin/DTCMinit.txt";
		file     dtcm_result : text open write_mode is "C:/Users/sheme/OneDrive/Desktop/UNI/3rd year/ARCH LAB/LAB3/Lab3-FPGA/tb/DTCMcontent6.txt";
		variable l           : line;
		variable data_v      : std_logic_vector(BusWidth-1 downto 0);
		variable addr_i      : integer;
	begin

		-- ---- Phase 1: Load Program Memory (ITCM) ----
		report "Phase 1: Loading ITCM from ITCMinit.txt";
		TBactive    <= '1';
		ITCM_tb_wr  <= '1';
		addr_i := 0;
		while not endfile(itcm_init) loop
			readline(itcm_init, l);
			hread(l, data_v);
			ITCM_tb_in      <= data_v;
			ITCM_tb_addr_in <= std_logic_vector(to_unsigned(addr_i, AddrWidth));
			wait until rising_edge(clk);
			addr_i := addr_i + 1;
		end loop;
		ITCM_tb_wr <= '0';

		-- ---- Phase 2: Load Data Memory (DTCM) ----
		report "Phase 2: Loading DTCM from DTCMinit.txt";
		DTCM_tb_wr <= '1';
		addr_i := 0;
		while not endfile(dtcm_init) loop
			readline(dtcm_init, l);
			hread(l, data_v);
			DTCM_tb_in      <= data_v;
			DTCM_tb_addr_in <= std_logic_vector(to_unsigned(addr_i, AddrWidth));
			wait until rising_edge(clk);
			addr_i := addr_i + 1;
		end loop;
		DTCM_tb_wr <= '0';

		-- ---- Phase 3: Run the CPU ----
		report "Phase 3: Running CPU";
		TBactive <= '0';
		rst      <= '1';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		rst <= '0';
		ena <= '1';

		wait until done = '1';
		wait until rising_edge(clk);
		ena <= '0';
		report "CPU finished (done=1)";

		-- ---- Phase 4: Dump DTCM to DTCMcontent.txt ----
		report "Phase 4: Reading DTCM into DTCMcontent.txt";
		TBactive <= '1';
		for i in 0 to MEM_DEPTH-2 loop
			DTCM_tb_addr_out <= std_logic_vector(to_unsigned(i, AddrWidth));
			wait until rising_edge(clk);
			wait for 1 ns;
			hwrite(l, DTCM_tb_out);
			writeline(dtcm_result, l);
		end loop;

		report "Simulation complete. Results in DTCMcontent.txt." severity note;
		wait;
	end process;

end sim;