library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VD_types_pkg.all;
USE work.defs_pkg.ALL; -- Import constants

entity NewbrainVideo is
port (
    V_IN      : in  video_bus_in;  -- Assuming this brings in 800x600 timing signals
    V_OUT     : out video_bus_out;

    Z80_CLK   : in  std_logic;
    Z80_WR_N  : in  std_logic;
    REG_SEL_N : in  std_logic;

    Z80_ADDR  : in  std_logic_vector(3 downto 0);
    Z80_DATA  : in  std_logic_vector(7 downto 0);

    VRAM_DATA : in  std_logic_vector(7 downto 0);
    VRAM_ADDR : out std_logic_vector(15 downto 0);

    -- Video registers
    VDRegs    : in t_video_regs
);
end entity;

architecture RTL of NewbrainVideo is

signal px_out : std_logic_vector(3 downto 0);
signal vram_addr_pxl   : integer range 0 to 65535 := 0;


------
--NB STUFF
			  --VIDEO SIGNALS
Signal sUCR     : STD_LOGIC; --10 PIXEL PER CHAR
Signal s80L     : STD_LOGIC; -- 80 CHARS PER LINE (MEANS 1 PIXEL HORIZ)
Signal s3240    : STD_LOGIC; -- narrow graphics screen
Signal sFS      : STD_LOGIC; --
Signal sRV      : STD_LOGIC; -- REVERSE FIELD
Signal TVP      : STD_LOGIC; -- eNABLE	
Signal sVIDEO9  : STD_LOGIC;  -- 1 WHEN low VIDEO ADDR start from 1


Signal VidCTRsig : std_logic_vector(7 downto 0);
Signal addrrow : std_logic_vector(7 downto 0);
Signal addrcol : std_logic_vector(6 downto 0);

signal vidaddr: std_logic_vector(15 downto 0);
signal video_addr:integer range 0 to 65535;

begin
--------------------------------------------------------------------
-- PIXEL RENDER PIPE (CENTERED 640x400 INSIDE 800x600)
--------------------------------------------------------------------
process(V_IN.clk_pixel)
    variable x_rel, y_rel : integer;
    variable fetch_x, fetch_y : integer;
    variable addr : integer;
    variable var_textchar : integer;
    variable next_pxltext : std_logic_vector(7 downto 0);
    variable next_pxlfore : std_logic_vector(3 downto 0);
    variable next_pxlback : std_logic_vector(3 downto 0);
    variable dblpxl : std_logic;
begin
    if rising_edge(V_IN.clk_pixel) then

    -- Check if video beam is within the active centered window
        if (V_IN.h_cnt >= 80 and V_IN.h_cnt < 720 and V_IN.v_cnt >= 100 and V_IN.v_cnt < 500) then
        
            -- Normalize structural layout tracking coordinate relative to window top-left corner
            x_rel := V_IN.h_cnt - 80;
            y_rel := V_IN.v_cnt - 100;


            ------------------------------------------------------------
            -- Pixel Doubling Logic
            ------------------------------------------------------------
            if dblpxl = '0' then
                fetch_x := x_rel / 2;
                fetch_y := y_rel / 2;
            else
                fetch_x := x_rel;
                fetch_y := y_rel;
            end if;

            ------------------------------------------------------------
            -- Video Mode Selection Switch
            ------------------------------------------------------------
        end if;
    end if;

end process;

--------------------------------------------------------------------
-- RGB OUTPUT PALETTE CONVERSION
--------------------------------------------------------------------
process(px_out)
begin
    case to_integer(unsigned(px_out)) is
        when 0  => -- BLACK
            V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"00";
        when 1  => -- BLUE
            V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"AA";
        when 2  => -- GREEN
            V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"AA"; V_OUT.b_8 <= x"00";
        when 3  => -- CYAN
            V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"AA"; V_OUT.b_8 <= x"AA";
        when 4  => -- RED
            V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"00";
        when 5  => -- MAGENTA
            V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"AA";
        when 6  => -- BROWN
            V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"55"; V_OUT.b_8 <= x"00";
        when 7  => -- LIGHT GRAY
            V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"AA"; V_OUT.b_8 <= x"AA";
        when 8  => -- DARK GRAY
            V_OUT.r_8 <= x"55"; V_OUT.g_8 <= x"55"; V_OUT.b_8 <= x"55";
        when 9  => -- LIGHT BLUE
            V_OUT.r_8 <= x"55"; V_OUT.g_8 <= x"55"; V_OUT.b_8 <= x"FF";
        when 10 => -- LIGHT GREEN
            V_OUT.r_8 <= x"55"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"55";
        when 11 => -- LIGHT CYAN
            V_OUT.r_8 <= x"55"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"FF";
        when 12 => -- LIGHT RED
            V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"55"; V_OUT.b_8 <= x"55";
        when 13 => -- LIGHT MAGENTA
            V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"55"; V_OUT.b_8 <= x"FF";
        when 14 => -- YELLOW
            V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"55";
        when 15 => -- WHITE
            V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"FF";
        when others =>
            V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"00";
    end case;
end process;

--------------------------------------------------------------------
-- VIDEO CONTROL PASS-THROUGH
--------------------------------------------------------------------
-- Map the system-generated input display signals straight to video out outputs
VRAM_ADDR    <= std_logic_vector(to_unsigned(vram_addr_pxl, 16));
V_OUT.h_sync <= '1';
V_OUT.v_sync <= '1';
V_OUT.de     <= '1';

    TVP <= VDRegs.Reg1(2);        -- ENABLEREG(2);    --1 enables display
    VidCTRsig <= VDRegs.Reg2;
    sVideo9 <= VDRegs.Reg3(0); -- bit 0 is addrow bit8
    addrrow <= VDRegs.Reg4;
 
	sRV   <= VidCTRsig(0); -- 1 reverse screen colors (0)
	sFS  <= VidCTRsig(1); -- 1 generates 256 chars from 8bit, 0 128 chars and 128 reverse chars (1)
	s3240 <= VidCTRsig(2); -- 1 256 or 512 horz pixels , 0 320 or 640 (0)
	sUCR  <= VidCTRsig(3); -- 1 256 chars 8x8 , 0 256 chars 8x10 (0)
	s80L  <= VidCTRsig(6); -- 1 80 chars , 0 40 chars (0)


    addrcol<="0000010" when s80L='0'  --skip 2 bytes for initilization
	  else	 "0000100"; --skip 4 bytes for initilization
    VIDADDR <= sVideo9&addrrow&addrcol;


end architecture;