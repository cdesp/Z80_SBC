library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VD_types_pkg.all;
USE work.defs_pkg.ALL; -- Import constants

entity AtlasVideo is
port (
    V_IN      : in  video_bus_in;  -- Assuming this brings in 800x600 timing signals
    V_OUT     : out video_bus_out;

    FPGA_CLK  : in  std_logic;

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
    READ_R1_WAIT2,
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

--------------------------------------------------------------------
-- SPRITE ENGINE (ported from vga_controller.vhd)
--------------------------------------------------------------------
-- Header table fields are read one byte at a time from VRAM (shared bus,
-- same 2-cycle SET->WAIT->USE latency convention as the VRAM STATE MACHINE
-- above), then sprite pixel data is copied into a dedicated local SPRAM.
type spr_load_state_t is (
    SRS_IDLE,
    SRS_INIT,
    SRS_HDR_WAIT,
    SRS_HDR_USE,
    SRS_DATA_ST,
    SRS_DATA_WAIT,
    SRS_DATA_USE
);

type spr_field_t is (F_ADDR_LO, F_ADDR_HI, F_X_LO, F_X_HI, F_Y_LO, F_Y_HI, F_WID, F_HEI);

type spr_struct_t is record
    addr   : integer range 0 to 65535; -- sprite pixel-data address in VRAM
    xpos   : integer range 0 to 640;
    ypos   : integer range 0 to 400;
    spwd   : integer range 0 to 31;
    spht   : integer range 0 to 31;
    intram : integer range 0 to 8191;  -- base address inside local SPRAM
end record;

constant MAXSPR : integer := 2; -- sprites 0 .. MAXSPR are loaded (3 total, matching vga_controller)
constant SPR_HEADER_BASE : integer := 32010; -- sprite header table address in VRAM (matches vga_controller)

type spr_arr_t is array (0 to MAXSPR) of spr_struct_t;
signal sprites  : spr_arr_t;
signal sprno    : integer range 0 to MAXSPR := 0;
signal sprstate : spr_load_state_t := SRS_IDLE;
signal spr_field : spr_field_t := F_ADDR_LO;

signal spr_pxl_left_nxt  : std_logic_vector(3 downto 0) := "0000";
signal spr_pxl_right_nxt : std_logic_vector(3 downto 0) := "0000";
signal sprread : std_logic := '0'; -- '1' while the sprite loader owns the shared VRAM bus
signal vram_addr_spr : integer range 0 to 65535 := 0;

-- Local sprite pixel-data memory (Gowin single-port SRAM, same interface as vga_controller.vhd)
signal spr_dout  : std_logic_vector(7 downto 0);
signal spr_oce   : std_logic := '1';
signal spr_ce    : std_logic := '1';
signal spr_reset : std_logic := '1';
signal spr_wre   : std_logic := '1';
signal spr_ad    : std_logic_vector(12 downto 0);
signal spr_din   : std_logic_vector(7 downto 0);

component Gowin_SPRAM
    port (
        dout: out std_logic_vector(7 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        wre: in std_logic;
        ad: in std_logic_vector(12 downto 0);
        din: in std_logic_vector(7 downto 0)
    );
end component;

-- DEBUG
SIGNAL CAPTURE : STD_LOGIC := '0';

begin

--------------------------------------------------------------------
-- FRAME START DETECT
--------------------------------------------------------------------
frame_start <= '1' when (V_IN.h_cnt = 0 and V_IN.v_cnt = 0) else '0';

--------------------------------------------------------------------
-- SPRITE PIXEL MEMORY
--------------------------------------------------------------------
SPRMEM: Gowin_SPRAM
    port map (
        dout   => spr_dout,
        clk    => V_IN.clk_pixel,
        oce    => spr_oce,
        ce     => spr_ce,
        reset  => spr_reset,
        wre    => spr_wre,
        ad     => spr_ad,
        din    => spr_din
    );

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
          
          state <= READ_R0_DATA;         

    when READ_R0_DATA =>
        vram_addr_reg <= REG_COLOR;
        vidset <= vram_data_reg(1 downto 0);
        vidbuf <= vram_data_reg(7);
        state <= READ_R1_WAIT;

    when READ_R1_WAIT =>
        state <= READ_R1_WAIT2;

    when READ_R1_WAIT2 =>
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
-- SPRITE LOADER + PIXEL RENDER PIPE (CENTERED 640x400 INSIDE 800x600)
--------------------------------------------------------------------
process(V_IN.clk_pixel)
    variable x_rel, y_rel : integer;
    variable fetch_x, fetch_y : integer;
    variable addr : integer;
    variable var_textchar : integer;
    variable next_pxltext : std_logic_vector(7 downto 0);
    variable next_pxlfore : std_logic_vector(3 downto 0);
    variable next_pxlback : std_logic_vector(3 downto 0);

    -- sprite loader working variables (persist across clocks, mirrors vga_controller.vhd)
    variable spr_dattemp  : integer range 0 to 255;
    variable spr_addr_lo  : integer range 0 to 255;
    variable spr_x_lo     : integer range 0 to 255;
    variable spr_y_lo     : integer range 0 to 255;
    variable sprbytes     : integer range 0 to 1023;
    variable intram_v     : integer range 0 to 8191 := 0;

    -- sprite compositing working variables
    variable spridx      : integer range 0 to MAXSPR;
    variable sprx        : integer range 0 to 63;
    variable spry        : integer range 0 to 63;
    variable sprxpre     : integer range 0 to 127;
    variable sprsteven   : boolean;
    variable spr_pxl_left  : std_logic_vector(3 downto 0) := "0000";
    variable spr_pxl_right : std_logic_vector(3 downto 0) := "0000";
begin
if rising_edge(V_IN.clk_pixel) then

    ----------------------------------------------------------------
    -- SPRITE LOADER STATE MACHINE
    -- Reloads sprite headers + pixel data from VRAM into the local
    -- SPRAM once per frame, during vertical blanking (v_cnt >= 500,
    -- i.e. right after the active window closes). This never overlaps
    -- the active window (h_cnt 80..719, v_cnt 100..499), so it shares
    -- the VRAM bus with the pixel fetch logic below without contention,
    -- as long as the timing generator gives enough blanking rows to
    -- finish loading before v_cnt reaches 100 again.
    ----------------------------------------------------------------
    spr_wre   <= '0';
    spr_ce    <= '0';
    spr_oce   <= '0';
    spr_reset <= '0';

    if (V_IN.h_cnt = 0 and V_IN.v_cnt = 500) then
        sprstate <= SRS_INIT;
    end if;

    case sprstate is
        when SRS_IDLE =>
            sprread <= '0';

        when SRS_INIT =>
            sprread       <= '1';
            sprno         <= 0;
            spr_field     <= F_ADDR_LO;
            intram_v      := 0;
            vram_addr_spr <= SPR_HEADER_BASE;
            sprstate      <= SRS_HDR_WAIT;

        when SRS_HDR_WAIT =>
            sprstate <= SRS_HDR_USE;

        when SRS_HDR_USE =>
            spr_dattemp := to_integer(unsigned(vram_data_reg));
            case spr_field is
                when F_ADDR_LO =>
                    spr_addr_lo   := spr_dattemp;
                    vram_addr_spr <= vram_addr_spr + 1;
                    spr_field     <= F_ADDR_HI;
                    sprstate      <= SRS_HDR_WAIT;

                when F_ADDR_HI =>
                    sprites(sprno).addr <= spr_dattemp * 256 + spr_addr_lo;
                    vram_addr_spr       <= vram_addr_spr + 1;
                    spr_field           <= F_X_LO;
                    sprstate            <= SRS_HDR_WAIT;

                when F_X_LO =>
                    spr_x_lo      := spr_dattemp;
                    vram_addr_spr <= vram_addr_spr + 1;
                    spr_field     <= F_X_HI;
                    sprstate      <= SRS_HDR_WAIT;

                when F_X_HI =>
                    sprites(sprno).xpos <= spr_dattemp * 256 + spr_x_lo;
                    vram_addr_spr       <= vram_addr_spr + 1;
                    spr_field           <= F_Y_LO;
                    sprstate            <= SRS_HDR_WAIT;

                when F_Y_LO =>
                    spr_y_lo      := spr_dattemp;
                    vram_addr_spr <= vram_addr_spr + 1;
                    spr_field     <= F_Y_HI;
                    sprstate      <= SRS_HDR_WAIT;

                when F_Y_HI =>
                    sprites(sprno).ypos <= spr_dattemp * 256 + spr_y_lo;
                    vram_addr_spr       <= vram_addr_spr + 1;
                    spr_field           <= F_WID;
                    sprstate            <= SRS_HDR_WAIT;

                when F_WID =>
                    sprites(sprno).spwd <= spr_dattemp;
                    vram_addr_spr       <= vram_addr_spr + 1;
                    spr_field           <= F_HEI;
                    sprstate            <= SRS_HDR_WAIT;

                when F_HEI =>
                    sprites(sprno).spht <= spr_dattemp;
                    vram_addr_spr       <= vram_addr_spr + 1;
                    spr_field           <= F_ADDR_LO;
                    if sprno >= MAXSPR then
                        sprstate <= SRS_DATA_ST;
                        sprno    <= 0;
                    else
                        sprno    <= sprno + 1;
                        sprstate <= SRS_HDR_WAIT;
                    end if;
            end case;

        when SRS_DATA_ST =>
            if sprno >= MAXSPR then
                sprstate <= SRS_IDLE;
            elsif sprites(sprno).addr /= 0 then
                vram_addr_spr <= sprites(sprno).addr;
                sprbytes      := sprites(sprno).spwd * sprites(sprno).spht;
                if sprbytes = 0 then -- sanity check
                    sprbytes := 1;
                end if;
                sprites(sprno).intram <= intram_v;
                sprstate              <= SRS_DATA_WAIT;
            else
                sprno <= sprno + 1;
            end if;

        when SRS_DATA_WAIT =>
            sprstate <= SRS_DATA_USE;

        when SRS_DATA_USE =>
            spr_wre       <= '1'; -- write enabled
            spr_ce        <= '1';
            spr_din       <= vram_data_reg;
            spr_ad        <= std_logic_vector(to_unsigned(intram_v, spr_ad'length));
            intram_v      := intram_v + 1;
            vram_addr_spr <= vram_addr_spr + 1;
            if sprbytes <= 1 then -- no more bytes to read
                sprstate <= SRS_DATA_ST;
                sprno    <= sprno + 1;
            else
                sprbytes := sprbytes - 1;
                sprstate <= SRS_DATA_WAIT;
            end if;
    end case;

    ----------------------------------------------------------------
    -- PIXEL FETCH / RENDER
    ----------------------------------------------------------------
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

            --------------------------------------------------------
            -- "11" : 640x400 TEXT MODE (single fore/back color pair,
            -- no per-character color attribute -- matches vga_controller.vhd)
            --------------------------------------------------------
            when "11" =>
                case (fetch_x mod 8) is
                    when 0 =>
                        -- prefetch NEXT character's code (character codes live on buffer 0 only)
                        addr := (fetch_y / 10) * 80 + (((fetch_x / 8) + 1) mod 80);
                        vram_addr_pxl <= addr;
 
                    when 3 =>
                        var_textchar := to_integer(unsigned(vram_data_reg));
                       -- textchar     <= var_textchar;
                       -- txfontline   <= fetch_y mod 10;
                        vram_addr_pxl <= 4096 + var_textchar + ((fetch_y mod 10) * 256); -- font pattern, buffer 0 only
 
                    when 6 =>
                        next_pxltext := vram_data_reg;
 
                    when 7 =>
                        pxltext <= next_pxltext;
 
                    when others =>
                        null;
                end case;
 
                if pxltext(7 - (fetch_x mod 8)) = '1' then
                    px_out <= pxlfore_r;
                else
                    px_out <= pxlback_r;
                end if;


            when others =>
                px_out <= pxlfore_r;
        end case;

        ------------------------------------------------------------
        -- SPRITE DISPLAY (320-wide modes only, i.e. vidset(1) = '0')
        -- Sprites are 4bpp, packed 2 pixels/byte, read from the local
        -- SPRAM (not the shared VRAM bus), so this runs concurrently
        -- with the fetch logic above with no bus contention. Note:
        -- like the original vga_controller.vhd, only sprite index 0
        -- is composited here even though up to MAXSPR+1 are loaded --
        -- extend the loop range below to display more at once.
        ------------------------------------------------------------
        if vidset(1) = '0' then
            spr_wre <= '0'; -- read only
            spr_ce  <= '1'; -- active
            spr_oce <= '0'; -- output register inactive

            for sprno_i in 0 to 0 loop
                spridx := sprno_i;
                if sprites(spridx).addr /= 0 then
                    if fetch_y >= sprites(spridx).ypos and fetch_y < sprites(spridx).ypos + sprites(spridx).spht then
                        spry := fetch_y - sprites(spridx).ypos;

                        if fetch_x = (sprites(spridx).xpos - 2) then
                            spr_ad     <= std_logic_vector(to_unsigned(sprites(spridx).intram + (spry * sprites(spridx).spwd / 2), spr_ad'length));
                            sprxpre    := 0;
                            sprx       := 0;
                            sprsteven  := (fetch_x + 2) mod 2 = 0;
                        end if;

                        if fetch_x = (sprites(spridx).xpos - 1) then
                            spr_pxl_left  := spr_dout(7 downto 4);
                            spr_pxl_right := spr_dout(3 downto 0);
                        end if;

                        if fetch_x >= sprites(spridx).xpos and fetch_x < sprites(spridx).xpos + sprites(spridx).spwd then
                            sprx := (fetch_x - sprites(spridx).xpos) / 2;
                            if sprx /= sprxpre then
                                sprxpre       := sprx;
                                spr_pxl_left  := spr_pxl_left_nxt;
                                spr_pxl_right := spr_pxl_right_nxt;
                            else
                                spr_ad <= std_logic_vector(to_unsigned(sprites(spridx).intram + 1 + sprx + (spry * sprites(spridx).spwd / 2), spr_ad'length));
                                spr_pxl_left_nxt  <= spr_dout(7 downto 4);
                                spr_pxl_right_nxt <= spr_dout(3 downto 0);
                            end if;

                            if (fetch_x mod 2 = 1 and sprsteven) or (fetch_x mod 2 = 0 and not sprsteven) then
                                if spr_pxl_right /= "0000" then
                                    px_out <= spr_pxl_right;
                                end if;
                            else
                                if spr_pxl_left /= "0000" then
                                    px_out <= spr_pxl_left;
                                end if;
                            end if;
                        end if; -- columns
                    end if; -- rows
                end if; -- sprite present
            end loop;
        end if;

    else
        -- BEAM IS OUTSIDE THE ACTIVE 640x400 ZONE: Output Selected Border Color!
        px_out <= std_logic_vector(to_unsigned(VGA_RED, 4));  --RED COLOR FOR BORDER
    end if;

end if;
end process;

-- Process mapping pixel values to 8-bit RGB
process(px_out)
begin
    case to_integer(unsigned(px_out)) is
        when VGA_BLACK => 
            V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"00";
        when VGA_BLUE => 
            V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"AA";
        when VGA_GREEN => 
            V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"AA"; V_OUT.b_8 <= x"00";
        when VGA_CYAN => 
            V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"AA"; V_OUT.b_8 <= x"AA";
        when VGA_RED => 
            V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"00";
        when VGA_MAGENTA => 
            V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"AA";
        when VGA_BROWN => 
            V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"55"; V_OUT.b_8 <= x"00";
        when VGA_LIGHTGRAY => 
            V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"AA"; V_OUT.b_8 <= x"AA";
        when VGA_DARKGRAY => 
            V_OUT.r_8 <= x"55"; V_OUT.g_8 <= x"55"; V_OUT.b_8 <= x"55";
        when VGA_LIGHTBLUE => 
            V_OUT.r_8 <= x"55"; V_OUT.g_8 <= x"55"; V_OUT.b_8 <= x"FF";
        when VGA_LIGHTGREEN => 
            V_OUT.r_8 <= x"55"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"55";
        when VGA_LIGHTCYAN => 
            V_OUT.r_8 <= x"55"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"FF";
        when VGA_LIGHTRED => 
            V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"55"; V_OUT.b_8 <= x"55";
        when VGA_LIGHTMAGENTA => 
            V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"55"; V_OUT.b_8 <= x"FF";
        when VGA_YELLOW => 
            V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"55";
        when VGA_WHITE => 
            V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"FF";
        when others =>
            V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"00";
    end case;
end process;


--------------------------------------------------------------------
-- VIDEO CONTROL PASS-THROUGH
--------------------------------------------------------------------
-- Map the system-generated input display signals straight to video out outputs
-- VRAM bus arbitration: config-register reads (regread) have top priority,
-- then the sprite loader (sprread), then the per-pixel fetch logic.
VRAM_ADDR    <= std_logic_vector(to_unsigned(vram_addr_reg, 16)) when regread = '1' else
                std_logic_vector(to_unsigned(vram_addr_spr, 16)) when sprread = '1' else
                std_logic_vector(to_unsigned(vram_addr_pxl, 16));
V_OUT.h_sync <= '1';
V_OUT.v_sync <= '1';
V_OUT.de     <= '1';


end architecture;