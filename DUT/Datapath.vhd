library ieee;
use ieee.std_logic_1164.all;
use work.aux_package.all;
-----------------------------------------------------------------
entity Datapath is
	generic(
		BusWidth  : integer := 16;
		RegWidth  : integer := 4;
		AddrWidth : integer := 6
	);
	port(
		clk : in std_logic;
		rst : in std_logic;

		-- Control signals from Control Unit
		IRin          : in std_logic;                          -- latch instruction into IR
		RFout         : in std_logic;                          -- RF drives BUS
		RFin          : in std_logic;                          -- BUS writes into RF
		Ain           : in std_logic;                          -- BUS loads REG-A
		Cin           : in std_logic;                          -- ALU result loads REG-C
		Cout          : in std_logic;                          -- REG-C drives BUS
		ALUFN         : in std_logic_vector(RegWidth-1 downto 0);
		RFaddr_wr_sel : in std_logic_vector(1 downto 0);       -- selects ra/rb/rc as RF write addr
		RFaddr_rd_sel : in std_logic_vector(1 downto 0);       -- selects ra/rb/rc as RF read addr
		Imm1_in       : in std_logic;                          -- sign_ext(imm8) drives BUS  IR[7:0]
		Imm2_in       : in std_logic;                          -- sign_ext(imm4) drives BUS  IR[3:0]
		PCin          : in std_logic;                          -- PC load enable
		PCsel         : in std_logic_vector(1 downto 0);       -- next PC select
		DTCM_out      : in std_logic;                          -- DTCM data drives BUS
		DTCM_addr_in  : in std_logic;                          -- latch BUS as DTCM write address (ST only)
		DTCM_wr       : in std_logic;                          -- write BUS into DTCM

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

		-- Status signals to Control Unit
		add   : out std_logic;
		sub   : out std_logic;
		andop : out std_logic;
		orop  : out std_logic;
		xorop : out std_logic;
		-- xorop : out std_logic;
		-- xorop : out std_logic;
		jmp   : out std_logic;
		jc    : out std_logic;
		jnc   : out std_logic;
		-- jnc   : out std_logic;
		-- jnc   : out std_logic;
		mov   : out std_logic;
		ld    : out std_logic;
		st    : out std_logic;
		done  : out std_logic;
		Zflag : out std_logic;
		Nflag : out std_logic;
		Cflag : out std_logic
	);
end Datapath;
-----------------------------------------------------------------
architecture structural of Datapath is

	-- Main Bus
	signal BUS_sig : std_logic_vector(BusWidth-1 downto 0);

	-- PC
	signal PC_out  : std_logic_vector(BusWidth-1 downto 0);
	signal PC_next : std_logic_vector(BusWidth-1 downto 0);

	-- Instruction word from ProgMem 
	signal instr_data : std_logic_vector(BusWidth-1 downto 0);

	-- IR outputs
	signal opc_sig   : std_logic_vector(RegWidth-1 downto 0);
	signal imm8_sig  : std_logic_vector(2*RegWidth-1 downto 0); -- IR[7:0]
	signal imm4_sig  : std_logic_vector(RegWidth-1 downto 0);   -- IR[3:0]
	signal RFaddr_wr : std_logic_vector(RegWidth-1 downto 0);
	signal RFaddr_rd : std_logic_vector(RegWidth-1 downto 0);

	-- Sign-extended immediates
	signal imm8_ext : std_logic_vector(BusWidth-1 downto 0);
	signal imm4_ext : std_logic_vector(BusWidth-1 downto 0);

	-- Register File
	signal RF_data_out : std_logic_vector(BusWidth-1 downto 0);

	-- ALU registers and result
	signal A_reg   : std_logic_vector(BusWidth-1 downto 0);
	signal C_reg   : std_logic_vector(BusWidth-1 downto 0);
	signal ALU_out : std_logic_vector(BusWidth-1 downto 0);

	-- ALU flag outputs (combinational) and their latched copies.
	-- The latched versions are what the FSM sees for JC/JNC; they are
	signal Zflag_alu : std_logic;
	signal Nflag_alu : std_logic;
	signal Cflag_alu : std_logic;
	signal Zflag_reg : std_logic;
	signal Nflag_reg : std_logic;
	signal Cflag_reg : std_logic;

	-- DTCM
	signal DTCM_addr_reg : std_logic_vector(AddrWidth-1 downto 0);
	signal DTCM_data_out : std_logic_vector(BusWidth-1 downto 0);
	signal DTCM_waddr    : std_logic_vector(AddrWidth-1 downto 0);
	signal DTCM_raddr    : std_logic_vector(AddrWidth-1 downto 0);
	signal DTCM_wdata    : std_logic_vector(BusWidth-1 downto 0);
	signal DTCM_wen      : std_logic;

begin

	-----------------------------------------------------------------
	-- PC_Mux: computes next PC value
	-- PCsel="00" → PC+1, "01" → PC+1+offset, "10" → 0
	-----------------------------------------------------------------
	PC_MUX_inst : PC_Mux
		generic map(BusWidth => BusWidth, DoubleRegWidth => 2*RegWidth)
		port map(
			PC_current => PC_out,
			PCsel      => PCsel,
			jmp_offset => imm8_sig,
			next_pc    => PC_next
		);

	-----------------------------------------------------------------
	-- PC: register holding the current instruction address
	-----------------------------------------------------------------
	PC_inst : PC
		generic map(BusWidth => BusWidth)
		port map(
			clk     => clk,
			rst     => rst,
			PCin    => PCin,
			PC_next => PC_next,
			PCout   => PC_out
		);


	ITCM_inst : ProgMem
		generic map(Dwidth => BusWidth, Awidth => AddrWidth, dept => 2**AddrWidth)
		port map(
			clk      => clk,
			memEn    => ITCM_tb_wr,
			WmemData => ITCM_tb_in,
			WmemAddr => ITCM_tb_addr_in,
			RmemAddr => PC_out(AddrWidth-1 downto 0),
			RmemData => instr_data
		);

	-----------------------------------------------------------------
	-- IR: latches instruction from ProgMem (not from BUS)
	-- IRin='1' on rising edge → IR_data <= instr_data
	-----------------------------------------------------------------
	IR_inst : IR
		generic map(BusWidth => BusWidth, RegWidth => RegWidth)
		port map(
			clk         => clk,
			rst         => rst,
			data_in     => instr_data,
			IR_In       => IRin,
			whichReg_wr => RFaddr_wr_sel,
			whichReg_re => RFaddr_rd_sel,
			opc         => opc_sig,
			reg_out_re  => RFaddr_rd,
			reg_out_wr  => RFaddr_wr,
			imm8        => imm8_sig,
			imm4        => imm4_sig
		);

	-----------------------------------------------------------------
	-- OPC Decoder: decodes opcode field → one-hot instruction flags
	-----------------------------------------------------------------
	OPC_DEC_inst : opc_decoder
		generic map(RegWidth => RegWidth)
		port map(
			opc   => opc_sig,
			add   => add,
			sub   => sub,
			andop => andop,
			orop  => orop,
			xorop => xorop,
			jmp   => jmp,
			jc    => jc,
			jnc   => jnc,
			mov   => mov,
			ld    => ld,
			st    => st,
			done  => done
		);


	RF_inst : RF
		generic map(Dwidth => BusWidth, Awidth => RegWidth)
		port map(
			clk       => clk,
			rst       => rst,
			WregEn    => RFin,
			WregData  => BUS_sig,
			WregAddr  => RFaddr_wr,
			RregAddr  => RFaddr_rd,
			RregData  => RF_data_out,
			PC_update => PCin,
			PC_val    => PC_out
		);

	-----------------------------------------------------------------
	-- REG-A: latches the first ALU operand from BUS
	-----------------------------------------------------------------
	process(clk, rst)
	begin
		if rst = '1' then
			A_reg <= (others => '0');
		elsif rising_edge(clk) then
			if Ain = '1' then
				A_reg <= BUS_sig;
			end if;
		end if;
	end process;

	-----------------------------------------------------------------
	-- ALU: computes A op BUS, outputs result and flags
	-- A = REG-A, B = current BUS value
	-----------------------------------------------------------------
	ALU_inst : ALU
		generic map(BusWidth => BusWidth, RegWidth => RegWidth)
		port map(
			A     => A_reg,
			B     => BUS_sig,
			ALUFN => ALUFN,
			C     => ALU_out,
			Zflag => Zflag_alu,
			Nflag => Nflag_alu,
			Cflag => Cflag_alu
		);

	process(clk, rst)
	begin
		if rst = '1' then
			Zflag_reg <= '0';
			Nflag_reg <= '0';
			Cflag_reg <= '0';
		elsif rising_edge(clk) then
			if Cin = '1' then
				Zflag_reg <= Zflag_alu;
				Nflag_reg <= Nflag_alu;
				Cflag_reg <= Cflag_alu;
			end if;
		end if;
	end process;

	Zflag <= Zflag_reg;
	Nflag <= Nflag_reg;
	Cflag <= Cflag_reg;

	-----------------------------------------------------------------
	-- REG-C (M-S type): latches ALU result, drives BUS when Cout='1'
	-----------------------------------------------------------------
	process(clk, rst)
	begin
		if rst = '1' then
			C_reg <= (others => '0');
		elsif rising_edge(clk) then
			if Cin = '1' then
				C_reg <= ALU_out;
			end if;
		end if;
	end process;

	-----------------------------------------------------------------
	-- Sign extension of IR immediate fields
	-----------------------------------------------------------------
	imm8_ext <= (BusWidth-1 downto 2*RegWidth => imm8_sig(2*RegWidth-1)) & imm8_sig;
	imm4_ext <= (BusWidth-1 downto RegWidth   => imm4_sig(RegWidth-1))   & imm4_sig;


	process(clk, rst)
	begin
		if rst = '1' then
			DTCM_addr_reg <= (others => '0');
		elsif rising_edge(clk) then
			if DTCM_addr_in = '1' then
				DTCM_addr_reg <= BUS_sig(AddrWidth-1 downto 0);
			end if;
		end if;
	end process;

	-----------------------------------------------------------------
	-- DTCM mux
	-----------------------------------------------------------------
	DTCM_waddr <= DTCM_tb_addr_in               when TBactive = '1' else DTCM_addr_reg;
	DTCM_raddr <= DTCM_tb_addr_out              when TBactive = '1' else BUS_sig(AddrWidth-1 downto 0);
	DTCM_wdata <= DTCM_tb_in       when TBactive = '1' else BUS_sig;
	DTCM_wen   <= DTCM_tb_wr       when TBactive = '1' else DTCM_wr;

	-----------------------------------------------------------------
	-- Data Memory (DTCM)
	-----------------------------------------------------------------
	DTCM_inst : dataMem
		generic map(Dwidth => BusWidth, Awidth => AddrWidth, dept => 2**AddrWidth)
		port map(
			clk      => clk,
			memEn    => DTCM_wen,
			WmemData => DTCM_wdata,
			WmemAddr => DTCM_waddr,
			RmemAddr => DTCM_raddr,
			RmemData => DTCM_data_out
		);

	DTCM_tb_out <= DTCM_data_out;

	-----------------------------------------------------------------
	-- Main BUS driver: only one source active at a time
	-- CU guarantees mutual exclusion of enable signals
	-----------------------------------------------------------------
	BUS_sig <= RF_data_out   when RFout    = '1' else
	           C_reg         when Cout     = '1' else
	           imm4_ext      when Imm2_in  = '1' else
	           imm8_ext      when Imm1_in  = '1' else
	           DTCM_data_out when DTCM_out = '1' else
	           (others => '0');

end structural;
