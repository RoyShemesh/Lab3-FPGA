library ieee;
use ieee.std_logic_1164.all;
-----------------------------------------------------------------
-- Control Unit testbench
-- Drives status inputs manually and verifies FSM control outputs
-----------------------------------------------------------------
entity tb_Control is
end tb_Control;

architecture sim of tb_Control is

	constant RegWidth   : integer := 4;
	constant CLK_PERIOD : time    := 10 ns;

	signal clk   : std_logic := '0';
	signal rst   : std_logic := '1';
	signal ena   : std_logic := '1';

	-- Status inputs (from Datapath in real system)
	signal add   : std_logic := '0';
	signal sub   : std_logic := '0';
	signal andop : std_logic := '0';
	signal orop  : std_logic := '0';
	signal xorop : std_logic := '0';
	signal jmp   : std_logic := '0';
	signal jc    : std_logic := '0';
	signal jnc   : std_logic := '0';
	signal mov   : std_logic := '0';
	signal ld    : std_logic := '0';
	signal st    : std_logic := '0';
	signal done  : std_logic := '0';
	signal Zflag : std_logic := '0';
	signal Nflag : std_logic := '0';
	signal Cflag : std_logic := '0';

	-- Control outputs (to Datapath in real system)
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
	signal DTCM_out      : std_logic;
	signal DTCM_addr_in  : std_logic;
	signal DTCM_wr       : std_logic;
	signal done_out      : std_logic;

begin

	clk <= not clk after CLK_PERIOD / 2;

	DUT : entity work.Control
		generic map(RegWidth => RegWidth)
		port map(
			clk           => clk,
			rst           => rst,
			ena           => ena,
			add           => add,
			sub           => sub,
			andop         => andop,
			orop          => orop,
			xorop         => xorop,
			jmp           => jmp,
			jc            => jc,
			jnc           => jnc,
			mov           => mov,
			ld            => ld,
			st            => st,
			done          => done,
			Zflag         => Zflag,
			Nflag         => Nflag,
			Cflag         => Cflag,
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
			DTCM_out      => DTCM_out,
			DTCM_addr_in  => DTCM_addr_in,
			DTCM_wr       => DTCM_wr,
			done_out      => done_out
		);

	process
	begin
		-- Reset FSM
		rst <= '1';
		wait for 3 * CLK_PERIOD;
		rst <= '0';
		wait until rising_edge(clk);

		-- ---- Test 1: ADD (R-type) → FETCH → R1 → R2 → R3 → FETCH ----
		report "Test 1: ADD instruction (4 cycles)";
		add <= '1';
		wait for 4 * CLK_PERIOD;  -- FETCH + R1 + R2 + R3
		add <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 2: SUB (R-type) ----
		report "Test 2: SUB instruction";
		sub <= '1';
		wait for 4 * CLK_PERIOD;
		sub <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 3: AND (R-type) ----
		report "Test 3: AND instruction";
		andop <= '1';
		wait for 4 * CLK_PERIOD;
		andop <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 4: OR (R-type) ----
		report "Test 4: OR instruction";
		orop <= '1';
		wait for 4 * CLK_PERIOD;
		orop <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 5: XOR (R-type) ----
		report "Test 5: XOR instruction";
		xorop <= '1';
		wait for 4 * CLK_PERIOD;
		xorop <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 6: MOV (I-type) → FETCH → MOV → FETCH ----
		report "Test 6: MOV instruction (2 cycles)";
		mov <= '1';
		wait for 2 * CLK_PERIOD;
		mov <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 7: LD (I-type) → FETCH → LD1 → LD2 → LD3 → LD4 → FETCH ----
		report "Test 7: LD instruction (5 cycles)";
		ld <= '1';
		wait for 5 * CLK_PERIOD;
		ld <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 8: ST (I-type) → FETCH → ST1 → ST2 → ST3 → ST4 → FETCH ----
		report "Test 8: ST instruction (5 cycles)";
		st <= '1';
		wait for 5 * CLK_PERIOD;
		st <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 9: JMP (J-type) → FETCH → JMP → FETCH ----
		report "Test 9: JMP instruction (2 cycles)";
		jmp <= '1';
		wait for 2 * CLK_PERIOD;
		jmp <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 10: JC taken (Cflag=1) ----
		report "Test 10: JC taken (Cflag=1)";
		jc    <= '1';
		Cflag <= '1';
		wait for 2 * CLK_PERIOD;
		jc    <= '0';
		Cflag <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 11: JC not taken (Cflag=0) ----
		report "Test 11: JC not taken (Cflag=0)";
		jc    <= '1';
		Cflag <= '0';
		wait for 2 * CLK_PERIOD;
		jc    <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 12: JNC taken (Cflag=0) ----
		report "Test 12: JNC taken (Cflag=0)";
		jnc   <= '1';
		Cflag <= '0';
		wait for 2 * CLK_PERIOD;
		jnc   <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 13: JNC not taken (Cflag=1) ----
		report "Test 13: JNC not taken (Cflag=1)";
		jnc   <= '1';
		Cflag <= '1';
		wait for 2 * CLK_PERIOD;
		jnc   <= '0';
		Cflag <= '0';
		wait for CLK_PERIOD;

		-- ---- Test 14: DONE → FSM stays in S_DONE ----
		report "Test 14: DONE instruction (stays in S_DONE)";
		done <= '1';
		wait for 4 * CLK_PERIOD;

		report "All Control FSM tests complete." severity note;
		wait;
	end process;

end sim;