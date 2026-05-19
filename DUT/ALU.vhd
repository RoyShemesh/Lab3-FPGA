library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.aux_package.all;

-----------------------------------------------------------------
entity ALU is
    generic(
        BusWidth : integer := 16;
        RegWidth : integer := 4
    );
    port(
        A     : in  std_logic_vector(BusWidth-1 downto 0); --R[B]
        B     : in  std_logic_vector(BusWidth-1 downto 0); --R[C]
        ALUFN : in  std_logic_vector(RegWidth-1 downto 0);
        C     : out std_logic_vector(BusWidth-1 downto 0); --R[A]
        Zflag : out std_logic;
        Nflag : out std_logic;
        Cflag : out std_logic
    );
end ALU;

architecture dataflow of ALU is

    -- Results of each ALU operation
    signal add_res : std_logic_vector(BusWidth-1 downto 0);
    signal sub_res : std_logic_vector(BusWidth-1 downto 0);
    signal and_res : std_logic_vector(BusWidth-1 downto 0);
    signal or_res  : std_logic_vector(BusWidth-1 downto 0);
    signal xor_res : std_logic_vector(BusWidth-1 downto 0);
    signal shl_res : std_logic_vector(BusWidth-1 downto 0);

    -- Final selected result
    signal result  : std_logic_vector(BusWidth-1 downto 0);

    -- Carry chains for ripple-carry add/sub
    signal carry_add : std_logic_vector(BusWidth downto 0);
    signal carry_sub : std_logic_vector(BusWidth downto 0);
    signal carry_shl : std_logic;

    -- Inverted B for subtraction: A - B = A + not(B) + 1
    signal B_not : std_logic_vector(BusWidth-1 downto 0);

    -- Final selected carry flag
    signal carry : std_logic;

begin

    -----------------------------------------------------------------
    -- ADD operation: A + B
    -----------------------------------------------------------------

    -- Initial carry-in for addition is 0
    carry_add(0) <= '0';

    -- Ripple Carry
    gen_add : for i in 0 to BusWidth-1 generate
        FA_add : FA port map(
                xi   => A(i),
                yi   => B(i),
                cin  => carry_add(i),
                s    => add_res(i),
                cout => carry_add(i+1)
            );
    end generate;

    -----------------------------------------------------------------
    -- SUB operation: A - B = A + not(B) + 1
    -----------------------------------------------------------------

    -- Invert B for two's complement subtraction
    B_not <= not B;

    -- Initial carry-in for subtraction is 1
    carry_sub(0) <= '1';

    -- Ripple Carry Subtractor built from Full Adders
    gen_sub : for i in 0 to BusWidth-1 generate
        FA_sub : FA port map(
                xi   => A(i),
                yi   => B_not(i),
                cin  => carry_sub(i),
                s    => sub_res(i),
                cout => carry_sub(i+1)
            );
    end generate;

    -----------------------------------------------------------------
    -- Logic operations
    -----------------------------------------------------------------

    and_res <= A and B;
    or_res  <= A or B;
    xor_res <= A xor B;


    -----------------------------------------------------------------
    -- shl operations
    -----------------------------------------------------------------

    ShiftUnit: SHIFTER
                GENERIC MAP(n => BusWidth, k => RegWidth)
					PORT MAP (
						X_i => B(RegWidth-1 DOWNTO 0),
						Y_i	=> A,
						ALUFN_i => "000", --If we want to implemnt another behavior of shifter such as (shr) we should change this line and shifter
						ALUout_o => shl_res,
						Cflag_o => carry_shl
						);

    -----------------------------------------------------------------
    -- Result MUX
    -----------------------------------------------------------------

    result <= add_res         when ALUFN = "0000" else
              sub_res         when ALUFN = "0001" else
              and_res         when ALUFN = "0010" else
              or_res          when ALUFN = "0011" else
              xor_res         when ALUFN = "0100" else
              shl_res         when ALUFN = "0101" else
            --   xor_res         when ALUFN = "0100" else
              (others => '0');

    carry  <= carry_add(BusWidth) when ALUFN = "0000" else
              carry_sub(BusWidth) when ALUFN = "0001" else
              carry_shl when ALUFN = "0101" else
            --   carry_sub(BusWidth) when ALUFN = "0001" else
              '0';

    -----------------------------------------------------------------
    -- Output assignments
    -----------------------------------------------------------------

    C <= result;

    -- Zero flag is set when the result is zero
    Zflag <= '1' when result = (result'range => '0') else '0';

    -- Negative flag is the MSB of the result
    Nflag <= result(BusWidth-1);

    -- Carry flag from add/sub operation
    Cflag <= carry;

    -----------------------------------------------------------------
    -- Debug: print inputs and outputs on any change (simulation only)
    -----------------------------------------------------------------
    -- debug_print : process(A, B, ALUFN, result, carry)
    --     variable l : line;
    -- begin
    --     write(l, string'("[ALU] A=0x"));  hwrite(l, A);
    --     write(l, string'(" B=0x"));       hwrite(l, B);
    --     write(l, string'(" ALUFN="));     hwrite(l, ALUFN);
    --     write(l, string'(" => C=0x"));    hwrite(l, result);
    --     write(l, string'(" Z="));
    --     if result = (result'range => '0') then write(l, string'("1")); else write(l, string'("0")); end if;
    --     write(l, string'(" N="));         write(l, result(BusWidth-1));
    --     write(l, string'(" C="));         write(l, carry);
    --     writeline(output, l);
    -- end process debug_print;

end dataflow;