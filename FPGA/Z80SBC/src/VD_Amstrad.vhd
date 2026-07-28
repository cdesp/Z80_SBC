library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VD_types_pkg.all;
use work.defs_pkg.all;

entity AmstradVideo is
    port (
        V_IN      : in  video_bus_in;   -- Host 800x600 pixel clock timing
        V_OUT     : out video_bus_out;

        FPGA_CLK  : in  std_logic;

        Z80_CLK   : in  std_logic;
        Z80_WR_N  : in  std_logic;
        REG_SEL_N : in  std_logic;

        Z80_ADDR  : in  std_logic_vector(3 downto 0);
        Z80_DATA  : in  std_logic_vector(7 downto 0);

        VRAM_DATA : in  std_logic_vector(7 downto 0);
        VRAM_ADDR : out std_logic_vector(15 downto 0);

        -- Video control registers
        VDRegs    : in  t_video_regs
    );
end entity AmstradVideo;

architecture RTL of AmstradVideo is

    constant ZOOM     : integer := 2;    -- 2x horizontal/vertical scale
    constant BORDER_H : integer := 80;   -- Horizontal border offset
    constant BORDER_V : integer := 100;  -- Vertical border offset
    constant ACTIVE_W : integer := 640;  -- 320 CPC pixels * 2
    constant ACTIVE_H : integer := 400;  -- 200 CPC lines * 2

    signal in_active   : std_logic;
    signal x_rel       : integer range 0 to 2047;
    signal y_rel       : integer range 0 to 2047;
    signal fetch_x     : integer range 0 to 1023;
    signal fetch_y     : integer range 0 to 511;

    signal vram_addr_pxl : unsigned(15 downto 0) := (others => '0');
    signal vram_data_reg : std_logic_vector(7 downto 0);

    -- Pipelined Data Buffers
    signal bitmap_next   : std_logic_vector(7 downto 0) := (others => '0');
    signal bitmap_shift  : std_logic_vector(7 downto 0) := (others => '0');

    signal pen_index     : integer range 0 to 15 := 0;
    signal video_mode    : std_logic_vector(1 downto 0);
    signal border_color  : std_logic_vector(4 downto 0);

    -- Gate Array Hardware Palette Lookup
    type t_cpc_color is record
        r, g, b : std_logic_vector(7 downto 0);
    end record;
    type t_cpc_palette is array (0 to 31) of t_cpc_color;

    constant CPC_HARDWARE_COLORS : t_cpc_palette := (
        0  => (x"80", x"80", x"80"), 1  => (x"80", x"80", x"80"),
        2  => (x"00", x"FF", x"80"), 3  => (x"FF", x"FF", x"80"),
        4  => (x"00", x"00", x"80"), 5  => (x"FF", x"00", x"80"),
        6  => (x"00", x"80", x"80"), 7  => (x"FF", x"80", x"80"),
        8  => (x"FF", x"00", x"80"), 9  => (x"FF", x"FF", x"80"),
        10 => (x"FF", x"FF", x"00"), 11 => (x"FF", x"FF", x"FF"),
        12 => (x"FF", x"00", x"00"), 13 => (x"FF", x"00", x"FF"),
        14 => (x"FF", x"80", x"00"), 15 => (x"FF", x"80", x"FF"),
        16 => (x"00", x"00", x"80"), 17 => (x"00", x"FF", x"80"),
        18 => (x"00", x"FF", x"00"), 19 => (x"00", x"FF", x"FF"),
        20 => (x"00", x"00", x"00"), 21 => (x"00", x"00", x"FF"),
        22 => (x"00", x"80", x"00"), 23 => (x"00", x"80", x"FF"),
        24 => (x"80", x"00", x"80"), 25 => (x"80", x"FF", x"80"),
        26 => (x"80", x"FF", x"00"), 27 => (x"80", x"FF", x"FF"),
        28 => (x"80", x"00", x"00"), 29 => (x"80", x"00", x"FF"),
        30 => (x"80", x"80", x"00"), 31 => (x"80", x"80", x"FF")
    );

begin
    video_mode   <= VDRegs.Reg1(1 downto 0);
    border_color <= VDRegs.Reg2(4 downto 0); 

    in_active <= '1' when (V_IN.h_cnt >= BORDER_H and V_IN.h_cnt < BORDER_H + ACTIVE_W and
                            V_IN.v_cnt >= BORDER_V and V_IN.v_cnt < BORDER_V + ACTIVE_H)
                 else '0';

    x_rel <= (V_IN.h_cnt - BORDER_H) when (V_IN.h_cnt >= BORDER_H) else 0;
    y_rel <= (V_IN.v_cnt - BORDER_V) when (V_IN.v_cnt >= BORDER_V) else 0;

    fetch_x <= x_rel / ZOOM;
    fetch_y <= y_rel / ZOOM;

    vram_data_reg <= VRAM_DATA;

    ----------------------------------------------------------------------
    -- PIPELINED VRAM FETCH & RENDER ENGINE
    ----------------------------------------------------------------------
    process(V_IN.clk_pixel)
        variable char_row    : integer;
        variable line_in_row : integer;
        variable bm_addr     : unsigned(15 downto 0);
        variable bit_idx     : integer range 0 to 7;
        variable hw_color    : integer range 0 to 31;
        variable sub_px      : integer range 0 to 7;
        variable col_cnt     : integer range 0 to 63;
        variable phase       : integer range 0 to 15;
    begin
        if rising_edge(V_IN.clk_pixel) then

            char_row    := fetch_y / 8;
            line_in_row := fetch_y mod 8;

            ------------------------------------------------------------
            -- 1. EXACT PREFETCH PIPELINE (Starts at BORDER_H - 16)
            ------------------------------------------------------------
            -- Column 0 prefetch starts at (BORDER_H - 16).
            -- Each column takes 16 clock ticks (8 CPC pixels @ 2x ZOOM).
            if (V_IN.h_cnt >= BORDER_H - 16) and (V_IN.h_cnt < BORDER_H + ACTIVE_W) and
               (V_IN.v_cnt >= BORDER_V) and (V_IN.v_cnt < BORDER_V + ACTIVE_H) then

                col_cnt := (V_IN.h_cnt - (BORDER_H - 16)) / 16;
                phase   := (V_IN.h_cnt - (BORDER_H - 16)) mod 16;

                if col_cnt <= 39 then
                    case phase is
                        when 0 =>
                            -- Step A: Set Address for current block/column
                            -- Kept base address at "000" as requested
                            bm_addr := "000" & 
                                       to_unsigned(line_in_row, 3) & 
                                       to_unsigned(char_row, 5) & 
                                       to_unsigned(col_cnt, 5);
                            vram_addr_pxl <= bm_addr;

                        when 4 =>
                            -- Step B: Latch VRAM data from bus
                            bitmap_next <= vram_data_reg;

                        when 15 =>
                            -- Step C: Pass to active shifter right at byte boundary
                            bitmap_shift <= bitmap_next;

                        when others => null;
                    end case;
                end if;
            end if;

            ------------------------------------------------------------
            -- 2. PIXEL DECODER & PALETTE LOOKUP
            ------------------------------------------------------------
            if in_active = '1' then
                sub_px := fetch_x mod 8;

                case video_mode is
                    -- MODE 0 (160x200, 16 Colors)
                    when "00" =>
                        if sub_px < 4 then
                            pen_index <= to_integer(unsigned'(
                                bitmap_shift(0) & bitmap_shift(2) & bitmap_shift(4) & bitmap_shift(6)
                            ));
                        else
                            pen_index <= to_integer(unsigned'(
                                bitmap_shift(1) & bitmap_shift(3) & bitmap_shift(5) & bitmap_shift(7)
                            ));
                        end if;

                    -- MODE 1 (320x200, 4 Colors)
                    when "01" =>
                        bit_idx := 3 - (sub_px / 2);
                        case bit_idx is
                            when 3 => pen_index <= to_integer(unsigned'(bitmap_shift(3) & bitmap_shift(7)));
                            when 2 => pen_index <= to_integer(unsigned'(bitmap_shift(2) & bitmap_shift(6)));
                            when 1 => pen_index <= to_integer(unsigned'(bitmap_shift(1) & bitmap_shift(5)));
                            when 0 => pen_index <= to_integer(unsigned'(bitmap_shift(0) & bitmap_shift(4)));
                        end case;

                    -- MODE 2 (640x200, 2 Colors)
                    when "10" =>
                        bit_idx := 7 - sub_px;
                        if bitmap_shift(bit_idx) = '1' then
                            pen_index <= 1;
                        else
                            pen_index <= 0;
                        end if;

                    when others =>
                        pen_index <= 0;
                end case;

                hw_color := to_integer(unsigned(VDRegs.pen_palette(pen_index)));

            else
                hw_color := to_integer(unsigned(border_color));
            end if;

            ------------------------------------------------------------
            -- 3. RGB OUTPUT STAGE
            ------------------------------------------------------------
            V_OUT.r_8 <= CPC_HARDWARE_COLORS(hw_color).r;
            V_OUT.g_8 <= CPC_HARDWARE_COLORS(hw_color).g;
            V_OUT.b_8 <= CPC_HARDWARE_COLORS(hw_color).b;

        end if;
    end process;

    V_OUT.de     <= V_IN.de;
    V_OUT.h_sync <= V_IN.h_sync;
    V_OUT.v_sync <= V_IN.v_sync;

    VRAM_ADDR <= std_logic_vector(vram_addr_pxl);

end architecture RTL;