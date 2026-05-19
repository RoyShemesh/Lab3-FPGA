library ieee;
use ieee.std_logic_1164.all;
use work.aux_package.all;
-----------------------------------------------------------------
entity top is
	generic(
		BusWidth  : integer := 16;
		RegWidth  : integer := 4;
		AddrWidth : integer := 6
	);
	port(
		clk : in std_logic;
		rst : in std_logic;
		ena : in std_logic;

		-- Testbench interface
		TBactive         : in  std_logic;
		ITCM_tb_wr       : in  std_logic;
		ITCM_tb_in       : in  std_logic_vector(BusWidth-1 downto 0);
		ITCM_tb_addr_in  : in  std_logic_vector(AddrWidth-1 downto 0);
		DTCM_tb_wr       : in  std_logic;
		DTCM_tb_in       : in  std_logic_vector(BusWidth-1 downto 0);
		DTCM_tb_addr_in  : in  std_logic_vector(AddrWidth-1 downto 0);
		DTCM_tb_addr_out : in  std_logic_vector(AddrWidth-1 downto 0);
		DTCM_tb_out      : out std_logic_vector(BusWidth-1 downto 0);

		-- Done flag to testbench
		done : out std_logic
	);
end top;
-----------------------------------------------------------------
architecture structural of top is

	-- Control signals (Control → Datapath)
	signal IRin          : std_logic;
	signal RFout         : std_logic;
	signal RFin          : std_logic;
	signal Ain           : std_logic;
	signal Cin           : std_logic;
	signal Cout          : std_logic;
	signal ALUFN         : std_logic_vector(RegWidth-1 downto 0);
	signal RFaddr_wr_sel : std_logic_vector(1 downto 0);
	signal RFaddr_rd_sel : std_logic_vector(1 downto 0);
	signal Imm1_in       : std_logic;
	signal Imm2_in       : std_logic;
	signal PCin          : std_logic;
	signal PCsel         : std_logic_vector(1 downto 0);
	signal DTCM_out_sig  : std_logic;
	signal DTCM_addr_in  : std_logic;
	signal DTCM_wr       : std_logic;

	-- Status signals (Datapath → Control)
	signal add   : std_logic;
	signal sub   : std_logic;
	signal andop : std_logic;
	signal shl : std_logic;
	signal orop  : std_logic;
	signal xorop : std_logic;
	signal jmp   : std_logic;
	signal jc    : std_logic;
	signal jnc   : std_logic;
	signal mov   : std_logic;
	signal ld    : std_logic;
	signal st    : std_logic;
	signal done_sig : std_logic;
	signal Zflag : std_logic;
	signal Nflag : std_logic;
	signal Cflag : std_logic;

begin

	-----------------------------------------------------------------
	-- Control Unit
	-----------------------------------------------------------------
	CTRL : Control
		generic map(RegWidth => RegWidth)
		port map(
			clk           => clk,
			rst           => rst,
			ena           => ena,
			-- Status inputs from Datapath
			add           => add,
			sub           => sub,
			shl           => shl,
			andop         => andop,
			orop          => orop,
			xorop         => xorop,
			jmp           => jmp,
			jc            => jc,
			jnc           => jnc,
			mov           => mov,
			ld            => ld,
			st            => st,
			done          => done_sig,
			Zflag         => Zflag,
			Nflag         => Nflag,
			Cflag         => Cflag,
			-- Control outputs to Datapath
			IRin          => IRin,
			RFout         => RFout,
			RFin          => RFin,
			Ain           => Ain,
			Cin           => Cin,
			Cout          => Cout,
			ALUFN         => ALUFN,
			RFaddr_wr_sel => RFaddr_wr_sel,
			RFaddr_rd_sel => RFaddr_rd_sel,
			Imm1_in       => Imm1_in,
			Imm2_in       => Imm2_in,
			PCin          => PCin,
			PCsel         => PCsel,
			DTCM_out      => DTCM_out_sig,
			DTCM_addr_in  => DTCM_addr_in,
			DTCM_wr       => DTCM_wr,
			done_out      => done
		);

	-----------------------------------------------------------------
	-- Datapath
	-----------------------------------------------------------------
	DP : DataPath
		generic map(
			BusWidth  => BusWidth,
			RegWidth  => RegWidth,
			AddrWidth => AddrWidth
		)
		port map(
			clk           => clk,
			rst           => rst,
			-- Control inputs from Control Unit
			IRin          => IRin,
			RFout         => RFout,
			RFin          => RFin,
			Ain           => Ain,
			Cin           => Cin,
			Cout          => Cout,
			ALUFN         => ALUFN,
			RFaddr_wr_sel => RFaddr_wr_sel,
			RFaddr_rd_sel => RFaddr_rd_sel,
			Imm1_in       => Imm1_in,
			Imm2_in       => Imm2_in,
			PCin          => PCin,
			PCsel         => PCsel,
			DTCM_out      => DTCM_out_sig,
			DTCM_addr_in  => DTCM_addr_in,
			DTCM_wr       => DTCM_wr,
			-- Testbench interface
			TBactive         => TBactive,
			ITCM_tb_wr       => ITCM_tb_wr,
			ITCM_tb_in       => ITCM_tb_in,
			ITCM_tb_addr_in  => ITCM_tb_addr_in,
			DTCM_tb_wr       => DTCM_tb_wr,
			DTCM_tb_in       => DTCM_tb_in,
			DTCM_tb_addr_in  => DTCM_tb_addr_in,
			DTCM_tb_addr_out => DTCM_tb_addr_out,
			DTCM_tb_out      => DTCM_tb_out,
			-- Status outputs to Control Unit
			add   => add,
			sub   => sub,
			shl   => shl,
			andop => andop,
			orop  => orop,
			xorop => xorop,
			jmp   => jmp,
			jc    => jc,
			jnc   => jnc,
			mov   => mov,
			ld    => ld,
			st    => st,
			done  => done_sig,
			Zflag => Zflag,
			Nflag => Nflag,
			Cflag => Cflag
		);

end structural;