library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VD_types_pkg.all;

entity AtlasVideo is
port (
    V_IN      : in  video_bus_in;  -- Assuming this brings in 800x600 timing signals
    V_OUT     : out video_bus_out;

    Z80_CLK   : in  std_logic;
    Z80_WR_N  : in  std_logic;
    REG_SEL_N : in  std_logic;

    Z80_ADDR  : in  std_logic_vector(3 downto 0);
    Z80_DATA  : in  std_logic_vector(7 downto 0);

    VRAM_DATA : in  std_logic_vector(7 downto 0);
    VRAM_ADDR : out std_logic_vector(15 downto 0)
);
end entity;

architecture RTL of AtlasVideo is

--------------------------------------------------------------------
-- VRAM SYSTEM
--------------------------------------------------------------------
signal vram_addr_reg   : integer range 0 to 65535 := 0;
signal vram_addr_pxl   : integer range 0 to 65535 := 0;
signal vram_data_reg   : std_logic_vector(7 downto 0) := (others => '0');

--------------------------------------------------------------------
-- VIDEO REGISTERS
--------------------------------------------------------------------
signal vidset     : std_logic_vector(1 downto 0) := "01";
signal vidbuf     : std_logic := '0';
signal pxlfore_r  : std_logic_vector(3 downto 0) := "1111"; 
signal pxlback_r  : std_logic_vector(3 downto 0) := "0000"; -- Used as Border Color!

--------------------------------------------------------------------
-- CONTROL
--------------------------------------------------------------------
signal frame_start : std_logic := '0';

type state_t is (
    RUN,
    READ_R0_ADDR,
    READ_R0_WAIT,
    READ_R0_DATA,
    READ_R1_WAIT,
    READ_R1_DATA    
);

signal state : state_t := RUN;

constant REG_VIDSET : integer := 32760;
constant REG_COLOR  : integer := 32761;

--------------------------------------------------------------------
-- PIXEL PIPE
--------------------------------------------------------------------
signal px_out : std_logic_vector(3 downto 0);
signal regread : std_logic :='1'; 

-- Text Engine Internal Registers
SIGNAL txfontline : INTEGER RANGE 0 TO 10-1 := 0; 
SIGNAL textchar   : INTEGER RANGE 0 TO 256-1 := 0; 
SIGNAL pxltext    : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000"; 
signal pxlfore    : std_logic_vector(3 downto 0) := "1111";
signal pxlback    : std_logic_vector(3 downto 0) := "0000";

-- DEBUG
SIGNAL CAPTURE : STD_LOGIC := '0';

begin

--------------------------------------------------------------------
-- FRAME START DETECT
--------------------------------------------------------------------
frame_start <= '1' when (V_IN.h_cnt = 0 and V_IN.v_cnt = 0) else '0';

--------------------------------------------------------------------
-- VRAM STATE MACHINE
--------------------------------------------------------------------
process(V_IN.clk_pixel)
begin
if rising_edge(V_IN.clk_pixel) then
    vram_data_reg <= VRAM_DATA;

    case state is
    when RUN =>
        if frame_start = '1' then
            regread <= '1';
            vram_addr_reg <= REG_VIDSET;
            state <= READ_R0_ADDR;
        end if;

    when READ_R0_ADDR =>
        state <= READ_R0_wait;
     
    when READ_R0_WAIT =>
          vram_addr_reg <= REG_COLOR;
          state <= READ_R0_DATA;         

    when READ_R0_DATA =>
        vidset <= vram_data_reg(1 downto 0);
        vidbuf <= vram_data_reg(7);
        state <= READ_R1_WAIT;

    when READ_R1_WAIT =>
        state <= READ_R1_DATA;

    when READ_R1_DATA =>
        pxlfore_r <= vram_data_reg(3 downto 0);
        pxlback_r <= vram_data_reg(7 downto 4); -- Stored color index maps to outer border
        regread <= '0';
        state <= RUN;
    end case;
end if;
end process;

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
begin
if rising_edge(V_IN.clk_pixel) then

    -- Check if video beam is within the active centered window
    if (V_IN.h_cnt >= 80 and V_IN.h_cnt < 720 and V_IN.v_cnt >= 100 and V_IN.v_cnt < 500) then
        
        -- Normalize structural layout tracking coordinate relative to window top-left corner
        x_rel := V_IN.h_cnt - 80;
        y_rel := V_IN.v_cnt - 100;

        CAPTURE <= '1' WHEN x_rel = 0 and y_rel = 0 else '0';

        ------------------------------------------------------------
        -- Pixel Doubling Logic
        ------------------------------------------------------------
        if vidset(1) = '0' then
            fetch_x := x_rel / 2;
            fetch_y := y_rel / 2;
        else
            fetch_x := x_rel;
            fetch_y := y_rel;
        end if;

        ------------------------------------------------------------
        -- Video Mode Selection Switch
        ------------------------------------------------------------
        case vidset is

            --------------------------------------------------------
            -- "00" : 320x200 GRAPHICS MODE
            --------------------------------------------------------
            when "00" =>
                addr := (fetch_y * 160) + (fetch_x / 2);
                if vidbuf = '1' then
                    addr := addr + 32768;
                end if;
                vram_addr_pxl <= addr;

                if (fetch_x mod 2) = 0 then
                    px_out <= vram_data_reg(7 downto 4);
                else
                    px_out <= vram_data_reg(3 downto 0);
                end if;

            --------------------------------------------------------
            -- "01" : 320x200 TEXT MODE WITH PIPELINE PREFETCH
            --------------------------------------------------------
            when "01" =>
                case (x_rel mod 16) is
                    when 2 =>
                        addr := (fetch_y / 10) * 40 + (((fetch_x / 8) + 1) mod 40);
                        if vidbuf = '1' then
                            addr := addr + 32768;
                        end if;
                        vram_addr_pxl <= addr;

                    when 6 =>
                        var_textchar := to_integer(unsigned(vram_data_reg));
                        textchar     <= var_textchar; 
                        txfontline   <= fetch_y mod 10;
                        vram_addr_pxl <= 4096 + var_textchar + ((fetch_y mod 10) * 256);

                    when 10 =>
                        next_pxltext := vram_data_reg;
                        addr := 1024 + (fetch_y / 10) * 40 + (((fetch_x / 8) + 1) mod 40);
                        vram_addr_pxl <= addr;

                    when 14 =>
                        next_pxlfore := vram_data_reg(3 downto 0);
                        next_pxlback := vram_data_reg(7 downto 4);

                    when 15 =>
                        pxltext <= next_pxltext;
                        pxlfore <= next_pxlfore;
                        pxlback <= next_pxlback;

                    when others =>
                        null;
                end case;

                if pxltext(7 - (fetch_x mod 8)) = '1' then
                    px_out <= pxlfore;
                else
                    px_out <= pxlback;
                end if;

            --------------------------------------------------------
            -- "10" : 640x400 MONOCHROME GRAPHICS
            --------------------------------------------------------
            when "10" =>
                addr := (fetch_y * 80) + (fetch_x / 8);
                if vidbuf = '1' then
                    addr := addr + 32768;
                end if;
                vram_addr_pxl <= addr;

                if vram_data_reg(7 - (fetch_x mod 8)) = '1' then
                    px_out <= pxlfore_r;
                else
                    px_out <= pxlback_r;
                end if;

            when others =>
                px_out <= pxlfore_r;
        end case;

    else
        -- BEAM IS OUTSIDE THE ACTIVE 640x400 ZONE: Output Selected Border Color!
        px_out <= pxlback_r; 
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
VRAM_ADDR    <= std_logic_vector(to_unsigned(vram_addr_reg, 16)) when regread='1' else std_logic_vector(to_unsigned(vram_addr_pxl, 16));
V_OUT.h_sync <= '1';
V_OUT.v_sync <= '1';
V_OUT.de     <= '1';

end architecture;