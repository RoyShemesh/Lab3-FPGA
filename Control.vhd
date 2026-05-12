library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;
-----------------------------------------------------------------
entity Control is
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
end Control;
-----------------------------------------------------------------
architecture arch of Control is

	-- FSM states.
	-- S_FETCH drives PCin/IRin so IR latches at end of FETCH; PC increments.
	-- S_DECODE is a one-cycle window so the just-latched IR is visible
	-- to the decoder BEFORE the next-state logic dispatches to an action
	-- state. Without S_DECODE, the FSM would dispatch using stale IR
	-- contents and lose the first instruction after reset.
	type state_type is (
		S_FETCH,
		S_DECODE,
		S_R1, S_R2, S_R3,            -- R-Type: add/sub/and/or/xor
		S_MOV,                       -- I-Type: mov
		S_LD1, S_LD2, S_LD3, S_LD4,  -- I-Type: ld
		S_ST1, S_ST2, S_ST3, S_ST4,  -- I-Type: st
		S_JMP,                       -- J-Type: jmp
		S_JC,                        -- J-Type: jc
		S_JNC,                       -- J-Type: jnc
		S_DONE                       -- Special: done
	);

	signal current_state, next_state : state_type;
	signal opcode : std_logic_vector(RegWidth-1 downto 0);

begin

	-----------------------------------------------------------------
	-- Concurrent opcode assignment for ALU function code (R-type)
	-- (kept outside any process to avoid a latched signal)
	-----------------------------------------------------------------
	opcode <= "0000" when add='1'   else
	          "0001" when sub='1'   else
	          "0010" when andop='1' else
	          "0011" when orop='1'  else
	          "0100" when xorop='1' else
	          (others => '0');

	-----------------------------------------------------------------
	-- Process 1: State Register (clocked)
	-- ena='0' freezes the FSM
	-----------------------------------------------------------------
	process(clk, rst)
	begin
		if rst = '1' then
			current_state <= S_FETCH;
		elsif rising_edge(clk) then
			if ena = '1' then
				current_state <= next_state;
			end if;
		end if;
	end process;

	-----------------------------------------------------------------
	-- Process 2: Next State Logic (combinational)
	-----------------------------------------------------------------
	process(current_state, add, sub, andop, orop, xorop,
	        mov, ld, st, jmp, jc, jnc, done)
	begin
		case current_state is
			when S_FETCH =>
				next_state <= S_DECODE;

			when S_DECODE =>
				if add='1' or sub='1' or andop='1' or orop='1' or xorop='1' then
					next_state <= S_R1;
				elsif ld='1'   then next_state <= S_LD1;
				elsif mov='1'  then next_state <= S_MOV;
				elsif jmp='1'  then next_state <= S_JMP;
				elsif st='1'   then next_state <= S_ST1;
				elsif jc='1'   then next_state <= S_JC;
				elsif jnc='1'  then next_state <= S_JNC;
				elsif done='1' then next_state <= S_DONE;
				else                next_state <= S_FETCH;
				end if;

			when S_R1  => next_state <= S_R2;
			when S_R2  => next_state <= S_R3;
			when S_R3  => next_state <= S_FETCH;

			when S_MOV => next_state <= S_FETCH;

			when S_LD1 => next_state <= S_LD2;
			when S_LD2 => next_state <= S_LD3;
			when S_LD3 => next_state <= S_LD4;
			when S_LD4 => next_state <= S_FETCH;

			when S_ST1 => next_state <= S_ST2;
			when S_ST2 => next_state <= S_ST3;
			when S_ST3 => next_state <= S_ST4;
			when S_ST4 => next_state <= S_FETCH;

			when S_JMP => next_state <= S_FETCH;
			when S_JC  => next_state <= S_FETCH;
			when S_JNC => next_state <= S_FETCH;

			when S_DONE => next_state <= S_DONE;

			when others => next_state <= S_FETCH;
		end case;
	end process;

	-----------------------------------------------------------------
	-- Process 3: Output Logic (combinational)
	-- Outputs are aligned with current_state so the FSM table reads
	-- straightforwardly: "in state X, signal Y is Z".
	-----------------------------------------------------------------
	process(current_state, opcode, Cflag)
	begin
		-- defaults: deassert every output
		IRin          <= '0';
		RFout         <= '0';
		RFin          <= '0';
		Ain           <= '0';
		Cin           <= '0';
		Cout          <= '0';
		ALUFN         <= (others => '0');
		RFaddr_wr_sel <= "00";
		RFaddr_rd_sel <= "00";
		Imm1_in       <= '0';
		Imm2_in       <= '0';
		PCin          <= '0';
		PCsel         <= "00";
		DTCM_out      <= '0';
		DTCM_addr_in  <= '0';
		DTCM_wr       <= '0';
		done_out      <= '0';

		case current_state is
			when S_FETCH =>
				PCin  <= '1';
				IRin  <= '1';
				PCsel <= "00";

			when S_DECODE =>
				null;  -- one-cycle decode window; outputs stay deasserted

			when S_R1 =>
				RFout         <= '1';
				Ain           <= '1';
				RFaddr_rd_sel <= "01";

			when S_R2 =>
				RFout         <= '1';
				Cin           <= '1';
				RFaddr_rd_sel <= "00";
				ALUFN         <= opcode;

			when S_R3 =>
				RFin          <= '1';
				Cout          <= '1';
				RFaddr_wr_sel <= "10";

			when S_MOV =>
				Imm1_in       <= '1';
				RFin          <= '1';
				RFaddr_wr_sel <= "10";

			when S_LD1 =>
				Ain           <= '1';
				RFout         <= '1';
				RFaddr_rd_sel <= "01";

			when S_LD2 =>
				Imm2_in <= '1';
				Cin     <= '1';
				ALUFN   <= "0000";

			when S_LD3 =>
				Cout <= '1';

			when S_LD4 =>
				RFin          <= '1';
				DTCM_out      <= '1';
				RFaddr_wr_sel <= "10";

			when S_ST1 =>
				RFout         <= '1';
				Ain           <= '1';
				RFaddr_rd_sel <= "01";

			when S_ST2 =>
				Imm2_in <= '1';
				Cin     <= '1';
				ALUFN   <= "0000";

			when S_ST3 =>
				DTCM_addr_in <= '1';
				Cout         <= '1';

			when S_ST4 =>
				RFout         <= '1';
				RFaddr_rd_sel <= "10";
				DTCM_wr       <= '1';

			when S_JMP =>
				PCin  <= '1';
				PCsel <= "01";

			when S_JC =>
				if Cflag = '1' then
					PCin  <= '1';
					PCsel <= "01";
				end if;

			when S_JNC =>
				if Cflag = '0' then
					PCin  <= '1';
					PCsel <= "01";
				end if;

			when S_DONE =>
				done_out <= '1';

			when others => null;
		end case;
	end process;

	-----------------------------------------------------------------
	-- Console Debug Process
	-----------------------------------------------------------------
	process(current_state)
	begin
		report "FSM Transition: " & state_type'image(current_state)
		severity note;
	end process;

end arch;