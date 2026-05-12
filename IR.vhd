library ieee;
use ieee.std_logic_1164.all;
-----------------------------------------------------------------
entity IR is
	generic( BusWidth: integer:=16;
			 RegWidth: integer:=4 );
	port(
		clk:         in  std_logic;
		rst:         in  std_logic;
		data_in:     in  std_logic_vector(BusWidth-1 downto 0);    -- from BUS
		IR_In:       in  std_logic;                                 -- load enable from CU
		whichReg_wr: in  std_logic_vector(1 downto 0);
		whichReg_re: in  std_logic_vector(1 downto 0);
		opc:         out std_logic_vector(RegWidth-1 downto 0);     -- IR[15:12]
		reg_out_re:  out std_logic_vector(RegWidth-1 downto 0);     -- read address
		reg_out_wr:  out std_logic_vector(RegWidth-1 downto 0);     -- write address
		imm8:        out std_logic_vector(2*RegWidth-1 downto 0);   -- IR[7:0]  for J-type offset / I-type mov
		imm4:        out std_logic_vector(RegWidth-1 downto 0)      -- IR[3:0]  for I-type ld/st
	);
end IR;
-----------------------------------------------------------------
architecture arch of IR is
	signal IR_data: std_logic_vector(BusWidth-1 downto 0);
	signal ra:      std_logic_vector(RegWidth-1 downto 0);
	signal rb:      std_logic_vector(RegWidth-1 downto 0);
	signal rc:      std_logic_vector(RegWidth-1 downto 0);
begin

	-- Clocked register: latch BUS data when IR_In is asserted
	process(clk, rst)
	begin
		if rst = '1' then
			IR_data <= (others => '0');
		elsif rising_edge(clk) then
			if IR_In = '1' then
				IR_data <= data_in;
			end if;
		end if;
	end process;

	-- Field extraction (combinational)
	rc  <= IR_data(RegWidth-1 downto 0);           -- IR[3:0]
	rb  <= IR_data(2*RegWidth-1 downto RegWidth);  -- IR[7:4]
	ra  <= IR_data(3*RegWidth-1 downto 2*RegWidth);-- IR[11:8]
	opc <= IR_data(BusWidth-1 downto 3*RegWidth);  -- IR[15:12]

	-- Register address muxes
	with whichReg_re select
		reg_out_re <= rc when "00",
		              rb when "01",
		              ra when others;

	with whichReg_wr select
		reg_out_wr <= rc when "00",
		              rb when "01",
		              ra when others;

	-- Immediate fields
	imm8 <= IR_data(2*RegWidth-1 downto 0);  -- IR[7:0]
	imm4 <= IR_data(RegWidth-1 downto 0);    -- IR[3:0]

end arch;
