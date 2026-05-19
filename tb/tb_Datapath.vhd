library ieee;
use ieee.std_logic_1164.all;
-----------------------------------------------------------------
-- Datapath testbench
-- Writes instructions directly into ITCM, manually drives control
-- signals, and tests ADD and XOR R-type instructions.
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
	signal shl   : std_logic;
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
			shl              => shl,
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
	begin

		-- ---- Reset ----
		TBactive <= '1';
		rst      <= '1';
		wait for 2 * CLK_PERIOD;
		rst <= '0';

		-- [0] MOV R1, #0xFF  opc=1100 ra=0001 imm8=1111_1111  -> 1100_0001_1111_1111
		-- [1] MOV R2, #1     opc=1100 ra=0010 imm8=0000_0001  -> 1100_0010_0000_0001
		-- [2] ADD R0, R1, R2 opc=0000 ra=0000 rb=0001 rc=0010 -> 0000_0000_0001_0010
		-- [3] XOR R3, R1, R2 opc=0100 ra=0011 rb=0001 rc=0010 -> 0100_0011_0001_0010
		report "Loading ITCM with test instructions";
		ITCM_tb_wr <= '1';

		ITCM_tb_in <= "1100000111111111"; ITCM_tb_addr_in <= "000000"; -- [0] MOV R1, #0xFF
		wait until rising_edge(clk);
		ITCM_tb_in <= "1100001000000001"; ITCM_tb_addr_in <= "000001"; -- [1] MOV R2, #1
		wait until rising_edge(clk);
		ITCM_tb_in <= "0000000000010010"; ITCM_tb_addr_in <= "000010"; -- [2] ADD R0, R1, R2
		wait until rising_edge(clk);
		ITCM_tb_in <= "0100001100010010"; ITCM_tb_addr_in <= "000011"; -- [3] XOR R3, R1, R2
		wait until rising_edge(clk);

		ITCM_tb_wr <= '0';
		TBactive   <= '0';

		-- ---- MOV R1, #0xFF  ->  R1 = sign_ext(0xFF) = 0xFFFF ----
		report "FETCH: MOV R1, #0xFF";
		IRin <= '1'; PCin <= '1'; PCsel <= "00";
		wait until rising_edge(clk);
		IRin <= '0'; PCin <= '0';

		report "MOV: imm8 -> R1";
		Imm1_in <= '1'; RFin <= '1'; RFaddr_wr_sel <= "10"; -- wr_sel=10 -> ra = R1
		wait until rising_edge(clk);
		Imm1_in <= '0'; RFin <= '0';

		-- ---- MOV R2, #1  ->  R2 = 0x0001 ----
		report "FETCH: MOV R2, #1";
		IRin <= '1'; PCin <= '1'; PCsel <= "00";
		wait until rising_edge(clk);
		IRin <= '0'; PCin <= '0';

		report "MOV: imm8 -> R2";
		Imm1_in <= '1'; RFin <= '1'; RFaddr_wr_sel <= "10"; -- wr_sel=10 -> ra = R2
		wait until rising_edge(clk);
		Imm1_in <= '0'; RFin <= '0';

		-- ---- Test 1: ADD R0, R1, R2 ----
		-- R1=0xFFFF + R2=0x0001 = 0x0000  ->  Z=1, N=0, C=1
		report "--- Test 1: ADD R0, R1, R2 ---";
		report "FETCH: ADD R0, R1, R2";
		IRin <= '1'; PCin <= '1'; PCsel <= "00";
		wait until rising_edge(clk);
		IRin <= '0'; PCin <= '0';

		report "ADD R1: RF[rb=R1] -> A_reg";
		RFout <= '1'; Ain <= '1'; RFaddr_rd_sel <= "01"; -- rd_sel=01 -> rb = R1
		wait until rising_edge(clk);
		RFout <= '0'; Ain <= '0';

		report "ADD R2: RF[rc=R2] + A_reg -> C_reg";
		RFout <= '1'; Cin <= '1'; RFaddr_rd_sel <= "00"; ALUFN <= "0000"; -- ADD
		wait until rising_edge(clk);
		RFout <= '0'; Cin <= '0';

		report "ADD R3: C_reg -> RF[ra=R0]";
		Cout <= '1'; RFin <= '1'; RFaddr_wr_sel <= "10"; -- wr_sel=10 -> ra = R0
		wait until rising_edge(clk);
		Cout <= '0'; RFin <= '0';
		wait for 1 ns;

		-- ---- Test 2: XOR R3, R1, R2 ----
		-- R1=0xFFFF XOR R2=0x0001 = 0xFFFE  ->  Z=0, N=1, C=0
		report "--- Test 2: XOR R3, R1, R2 ---";
		report "FETCH: XOR R3, R1, R2";
		IRin <= '1'; PCin <= '1'; PCsel <= "00";
		wait until rising_edge(clk);
		IRin <= '0'; PCin <= '0';

		report "XOR R1: RF[rb=R1] -> A_reg";
		RFout <= '1'; Ain <= '1'; RFaddr_rd_sel <= "01"; -- rd_sel=01 -> rb = R1
		wait until rising_edge(clk);
		RFout <= '0'; Ain <= '0';

		report "XOR R2: RF[rc=R2] XOR A_reg -> C_reg";
		RFout <= '1'; Cin <= '1'; RFaddr_rd_sel <= "00"; ALUFN <= "0100"; -- XOR
		wait until rising_edge(clk);
		RFout <= '0'; Cin <= '0';

		report "XOR R3: C_reg -> RF[ra=R3]";
		Cout <= '1'; RFin <= '1'; RFaddr_wr_sel <= "10"; -- wr_sel=10 -> ra = R3
		wait until rising_edge(clk);
		Cout <= '0'; RFin <= '0';
		wait for 1 ns;
		report "Datapath TB complete." severity note;
		wait;
	end process;

end sim;
