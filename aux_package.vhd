library ieee;
USE ieee.std_logic_1164.all;
----------------------------------------------
package aux_package is

---------------IR------------------
	component IR is
		generic( BusWidth: integer:=16;
				 RegWidth: integer:=4 );
		port(
			clk:         in  std_logic;
			rst:         in  std_logic;
			data_in:     in  std_logic_vector(BusWidth-1 downto 0);
			IR_In:       in  std_logic;
			whichReg_wr: in  std_logic_vector(1 downto 0);
			whichReg_re: in  std_logic_vector(1 downto 0);
			opc:         out std_logic_vector(RegWidth-1 downto 0);
			reg_out_re:  out std_logic_vector(RegWidth-1 downto 0);
			reg_out_wr:  out std_logic_vector(RegWidth-1 downto 0);
			imm8:        out std_logic_vector(2*RegWidth-1 downto 0);
			imm4:        out std_logic_vector(RegWidth-1 downto 0)
		);
	end component;

---------------opc_decoder-----------
	component opc_decoder is
		generic( RegWidth: integer:=4 );
		port(   opc:                                                            in  std_logic_vector(RegWidth-1 downto 0);
				st, ld, mov, done, add, sub, jmp, jc, jnc, andop, orop, xorop: out std_logic
		);
	end component;

---------------FA-------------------
	component FA is
		port( xi, yi, cin: in  std_logic;
			  s, cout:     out std_logic );
	end component;

---------------ALU-------------------
	component ALU is
		generic( BusWidth: integer:=16;
				 RegWidth: integer:=4 );
		port(
			A     : in  std_logic_vector(BusWidth-1 downto 0);
			B     : in  std_logic_vector(BusWidth-1 downto 0);
			ALUFN : in  std_logic_vector(RegWidth-1 downto 0);
			C     : out std_logic_vector(BusWidth-1 downto 0);
			Zflag : out std_logic;
			Nflag : out std_logic;
			Cflag : out std_logic
		);
	end component;

---------------PC-------------------
	component PC is
		generic( BusWidth: integer:=16 );
		port(
			clk     : in  std_logic;
			rst     : in  std_logic;
			PCin    : in  std_logic;
			PC_next : in  std_logic_vector(BusWidth-1 downto 0);
			PCout   : out std_logic_vector(BusWidth-1 downto 0)
		);
	end component;

---------------PC_Mux-------------------
	component PC_Mux is
		generic( BusWidth:      integer:=16;
				 DoubleRegWidth: integer:=8 );
		port(
			PC_current : in  std_logic_vector(BusWidth-1 downto 0);
			PCsel      : in  std_logic_vector(1 downto 0);
			jmp_offset : in  std_logic_vector(DoubleRegWidth-1 downto 0);
			next_pc    : out std_logic_vector(BusWidth-1 downto 0)
		);
	end component;

---------------RF-------------------
	component RF is
		generic( Dwidth: integer:=16;
				 Awidth: integer:=4 );
		port(
			clk, rst, WregEn: in  std_logic;
			WregData:         in  std_logic_vector(Dwidth-1 downto 0);
			WregAddr, RregAddr: in  std_logic_vector(Awidth-1 downto 0);
			RregData:         out std_logic_vector(Dwidth-1 downto 0);
			PC_update:        in  std_logic;
			PC_val:           in  std_logic_vector(Dwidth-1 downto 0)
		);
	end component;

---------------ProgMem-------------------
	component ProgMem is
		generic( Dwidth: integer:=16;
				 Awidth: integer:=6;
				 dept:   integer:=64 );
		port(
			clk, memEn: in  std_logic;
			WmemData:   in  std_logic_vector(Dwidth-1 downto 0);
			WmemAddr, RmemAddr: in  std_logic_vector(Awidth-1 downto 0);
			RmemData:   out std_logic_vector(Dwidth-1 downto 0)
		);
	end component;

---------------dataMem-------------------
	component dataMem is
		generic( Dwidth: integer:=16;
				 Awidth: integer:=6;
				 dept:   integer:=64 );
		port(
			clk, memEn: in  std_logic;
			WmemData:   in  std_logic_vector(Dwidth-1 downto 0);
			WmemAddr, RmemAddr: in  std_logic_vector(Awidth-1 downto 0);
			RmemData:   out std_logic_vector(Dwidth-1 downto 0)
		);
	end component;
	
---------------Control-------------------
	component Control is
		generic( RegWidth : integer := 4 );
		port(
			clk : in std_logic;
			rst : in std_logic;
			ena : in std_logic;

			-- Status inputs from Datapath (15 signals)
			add   : in std_logic;
			sub   : in std_logic;
			andop : in std_logic;
			orop  : in std_logic;
			xorop : in std_logic;
			jmp   : in std_logic;
			jc    : in std_logic;
			jnc   : in std_logic;
			mov   : in std_logic;
			ld    : in std_logic;
			st    : in std_logic;
			done  : in std_logic;
			Zflag : in std_logic;
			Nflag : in std_logic;
			Cflag : in std_logic;

			-- Control outputs to Datapath
			IRin          : out std_logic;
			RFout         : out std_logic;
			RFin          : out std_logic;
			Ain           : out std_logic;
			Cin           : out std_logic;
			Cout          : out std_logic;
			ALUFN         : out std_logic_vector(RegWidth-1 downto 0);
			RFaddr_wr_sel : out std_logic_vector(1 downto 0);
			RFaddr_rd_sel : out std_logic_vector(1 downto 0);
			Imm1_in       : out std_logic;
			Imm2_in       : out std_logic;
			PCin          : out std_logic;
			PCsel         : out std_logic_vector(1 downto 0);
			DTCM_out      : out std_logic;
			DTCM_addr_in  : out std_logic;
			DTCM_wr       : out std_logic;

			-- Done flag to testbench
			done_out : out std_logic
		);
	end component;
	---------------DataPath-------------------
	component DataPath is
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
			jmp   : out std_logic;
			jc    : out std_logic;
			jnc   : out std_logic;
			mov   : out std_logic;
			ld    : out std_logic;
			st    : out std_logic;
			done  : out std_logic;
			Zflag : out std_logic;
			Nflag : out std_logic;
			Cflag : out std_logic
		);
	end component;
end aux_package;
