--------------------------------------------------------------------------------
-- vd_spectrum.vhd
--
-- ZX Spectrum video display controller.
--
-- Renders the classic 256x192 Spectrum bitmap display (32x24 attribute
-- cells, standard ink/paper/bright/flash attributes) scaled 3x to 768x576
-- and centred inside an 800x600 host video frame, leaving a symmetric
-- border of 16px (horizontal) / 12px (vertical) on every side:
--
--        800 px wide, 600 px tall host frame
--        +--------------------------------------+
--        |<16>                              <16>|
--        |    +----------------------------+     |
--        |    |                            |     |
--        | 12 |   768 x 576 active window  | 12  |
--        |    |   (256x192 Spectrum * 3)   |     |
--        |    |                            |     |
--        |    +----------------------------+     |
--        |<16>                              <16>|
--        +--------------------------------------+
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VD_types_pkg.all;
use work.defs_pkg.all;

entity spectrumvideo is
    port (
        V_IN      : in  video_bus_in;   -- 800x600 host pixel-clock timing
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
end entity spectrumvideo;

architecture RTL of spectrumvideo is

  -- Host frame geometry (must match the timing generator driving V_IN)
    constant SCREEN_W       : integer := 800;
    constant SCREEN_H       : integer := 600;

    -- Native Spectrum resolution
    constant SPEC_W         : integer := 256;
    constant SPEC_H         : integer := 192;

    -- Scale factor and resulting active (non-border) window
    constant ZOOM           : integer := 3;
    constant ACTIVE_W       : integer := SPEC_W * ZOOM;  -- 768
    constant ACTIVE_H       : integer := SPEC_H * ZOOM;  -- 576

    -- Border thickness from centring math (symmetric both sides)
    constant BORDER_H       : integer := (SCREEN_W - ACTIVE_W) / 2; -- 16
    constant BORDER_V       : integer := (SCREEN_H - ACTIVE_H) / 2; -- 12

    -- Spectrum 16K video-RAM memory map (byte offsets)
    -- FOR PAGE $C0 IS 0. FOR $C1 IS 8192
    constant BITMAP_BASE    : integer := 8192;      -- 0x0000..0x17FF (6144 bytes)
    constant ATTR_OFFSET    : integer := 6144;   -- 0x1800..0x1AFF (768 bytes)
    constant SHADOW_OFFSET  : integer := 16384;   -- shadow/second screen offset 16384 for +2,+3

    -- Flash-attribute toggle period, in host frames (~ once every 16 frames,
    -- matching the classic Spectrum flash rate)
    constant FLASH_DIVIDE   : integer := 16;

    ----------------------------------------------------------------------
    -- CPU-writable border colour latch (mimics the real ULA's port 0xFE
    -- border-colour bits, latched directly by the Z80 write below)
    ----------------------------------------------------------------------
    signal cpu_border : std_logic_vector(2 downto 0) := (others => '0');

    ----------------------------------------------------------------------
    -- VRAM address bus sources
    ----------------------------------------------------------------------
    signal vram_addr_pxl : unsigned(15 downto 0) := (others => '0'); -- pixel-engine access
    signal vram_data_reg : std_logic_vector(7 downto 0);

    ----------------------------------------------------------------------
    -- Bitmap/attribute fetch pipeline
    ----------------------------------------------------------------------
    signal bitmap_byte : std_logic_vector(7 downto 0) := (others => '0');
    signal attr_byte   : std_logic_vector(7 downto 0) := (others => '0');

    signal px_shift  : std_logic_vector(7 downto 0) := (others => '0'); -- latched bitmap byte for current 8px group
    signal px_ink    : std_logic_vector(2 downto 0) := (others => '0');
    signal px_paper  : std_logic_vector(2 downto 0) := (others => '0');
    signal px_bright : std_logic := '0';
    signal px_flash  : std_logic := '0';

    signal px_out : std_logic_vector(3 downto 0) := (others => '0'); -- bit3=bright, 2:0=colour idx

    ----------------------------------------------------------------------
    -- FLASH attribute toggle (~ every FLASH_DIVIDE host frames)
    ----------------------------------------------------------------------
    signal flash_div_cnt : integer range 0 to FLASH_DIVIDE-1 := 0;
    signal flash_state   : std_logic := '0';

    ----------------------------------------------------------------------
    -- Window / geometry
    ----------------------------------------------------------------------
    signal in_active        : std_logic;
    signal x_rel, y_rel     : integer range 0 to 2047;
    signal fetch_x, fetch_y : integer range 0 to 1023;

    signal vid_buf_sel      : std_logic := '0';

    signal bitmap_next : std_logic_vector(7 downto 0) := (others => '0'); -- staged bitmap byte for the NEXT block
    signal attr_next   : std_logic_vector(7 downto 0) := (others => '0'); -- staged attribute byte for the NEXT block

begin
    --Bits 0–2	Border Color	Sets border color (0: Black, 1: Blue, 2: Red, 3: Magenta, 4: Green, 5: Cyan, 6: Yellow, 7: White).
    --Bit 3	MIC Output	Tape drive WRITE line (audio signal sent to tape during SAVE).
    --Bit 4	Beeper	Drives the internal piezo speaker (1 = high, 0 = low; toggled rapidly to generate sound).
    --Bits 5–7	Unused	Normally set to 0.
    cpu_border <= VDRegs.Reg1(2 downto 0);


    ----------------------------------------------------------------------
    -- FLASH toggle: increments once per host frame (detected at raster
    -- position 0,0) and flips flash_state every FLASH_DIVIDE frames.
    ----------------------------------------------------------------------
    process(V_IN.clk_pixel)
    begin
        if rising_edge(V_IN.clk_pixel) then
            if V_IN.h_cnt = 0 and V_IN.v_cnt = 0 then
                if flash_div_cnt = FLASH_DIVIDE-1 then
                    flash_div_cnt <= 0;
                    flash_state   <= not flash_state;
                else
                    flash_div_cnt <= flash_div_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- Geometry: are we inside the centred 768x576 active window?
    ----------------------------------------------------------------------
    in_active <= '1' when (V_IN.h_cnt >= BORDER_H and V_IN.h_cnt < BORDER_H + ACTIVE_W and
                            V_IN.v_cnt >= BORDER_V and V_IN.v_cnt < BORDER_V + ACTIVE_H)
                 else '0';

    -- Only force to 0 if we haven't reached the start of the screen area yet
    x_rel <= (V_IN.h_cnt - BORDER_H) when (V_IN.h_cnt >= BORDER_H) else 0;
    y_rel <= (V_IN.v_cnt - BORDER_V) when (V_IN.v_cnt >= BORDER_V) else 0;

    -- 3x scale: divide relative window coordinate by ZOOM to get the
    -- native Spectrum pixel coordinate. (A counter-based /3 that increments
    -- fetch_x every third pixel clock is cheaper in real hardware than a
    -- division; shown here as a division for clarity.)
    fetch_x <= x_rel / ZOOM;
    fetch_y <= y_rel / ZOOM;

    process(V_IN.clk_pixel)
        variable bm_addr, at_addr : integer;
        variable pre_col          : integer;
        variable y_u              : unsigned(7 downto 0);
        variable bit_pos          : integer range 0 to 7;
    begin
        if rising_edge(V_IN.clk_pixel) then

            ------------------------------------------------------------
            -- FETCH SCHEDULING
            -- Left border (h_cnt 0..BORDER_H-1): prime column 0 of THIS
            -- scanline (row is valid across the whole line, borders
            -- included) so block 0 is ready the instant active video
            -- starts. Inside the active window: prefetch block N+1 while
            -- block N is on screen, committing right at the block
            -- boundary. Either way there's a full block's worth of host
            -- cycles (16 in the border, 24 = 8*ZOOM elsewhere) of slack,
            -- so it isn't sensitive to your exact VRAM read latency.
            ------------------------------------------------------------
            if V_IN.h_cnt < BORDER_H then
                case V_IN.h_cnt is
                    when 2 =>
                        y_u := to_unsigned(fetch_y, 8);
                        bm_addr := BITMAP_BASE + (to_integer(y_u and "11000000") * 32) +
                                   (to_integer(y_u and "00000111") * 256) +
                                   (to_integer(y_u and "00111000") * 4) + 0;
                        vram_addr_pxl <= to_unsigned(bm_addr, 16);

                    when 6 =>
                        bitmap_next <= vram_data_reg;
                        at_addr := BITMAP_BASE + ATTR_OFFSET + (fetch_y/8)*32 + 0;
                        vram_addr_pxl <= to_unsigned(at_addr, 16);

                    when 10 =>
                        attr_next <= vram_data_reg;

                    when BORDER_H - 1 =>
                        px_shift  <= bitmap_next;
                        px_ink    <= attr_next(2 downto 0);
                        px_paper  <= attr_next(5 downto 3);
                        px_bright <= attr_next(6);
                        px_flash  <= attr_next(7);

                    when others => null;
                end case;

            elsif in_active = '1' then
                pre_col := (fetch_x/8) + 1;

                if pre_col <= 31 then
                    case ((V_IN.h_cnt - BORDER_H) mod (8*ZOOM)) is
                        when 0 =>
                            y_u := to_unsigned(fetch_y, 8);
                            bm_addr := BITMAP_BASE + (to_integer(y_u and "11000000") * 32) +
                                       (to_integer(y_u and "00000111") * 256) +
                                       (to_integer(y_u and "00111000") * 4) + pre_col;
                            vram_addr_pxl <= to_unsigned(bm_addr, 16);

                        when 4 =>
                            bitmap_next <= vram_data_reg;
                            at_addr := BITMAP_BASE + ATTR_OFFSET + (fetch_y/8)*32 + pre_col;
                            vram_addr_pxl <= to_unsigned(at_addr, 16);

                        when 8 =>
                            attr_next <= vram_data_reg;

                        when 8*ZOOM - 1 => -- last cycle of this block: commit
                            px_shift  <= bitmap_next;
                            px_ink    <= attr_next(2 downto 0);
                            px_paper  <= attr_next(5 downto 3);
                            px_bright <= attr_next(6);
                            px_flash  <= attr_next(7);

                        when others => null;
                    end case;
                end if;
            end if;

            ------------------------------------------------------------
            -- COLOUR OUTPUT for the pixel currently being scanned out.
            -- No delay needed here: px_shift/px_ink/etc. are already fully
            -- committed for the WHOLE current block before it starts.
            ------------------------------------------------------------
            if in_active = '1' then
                bit_pos := fetch_x mod 8;
                if (px_flash = '1' and flash_state = '1') then
                    if px_shift(7 - bit_pos) = '1' then
                        px_out <= px_bright & px_paper;
                    else
                        px_out <= px_bright & px_ink;
                    end if;
                else
                    if px_shift(7 - bit_pos) = '1' then
                        px_out <= px_bright & px_ink;
                    else
                        px_out <= px_bright & px_paper;
                    end if;
                end if;
            else
                px_out <= '0' & cpu_border;
            end if;

        end if;
    end process;

    ----------------------------------------------------------------------
    -- RGB OUTPUT PALETTE CONVERSION
    -- bit3 of px_out = bright, bits 2:0 = base ZX colour (0=black stays
    -- black regardless of bright, matching real Spectrum ULA behaviour).
    ----------------------------------------------------------------------
    process(px_out)
    begin
        case to_integer(unsigned(px_out(2 downto 0))) is
            when 0 =>
                V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"00";
            when 1 => -- BLUE
                if px_out(3) = '1' then
                    V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"FF";
                else
                    V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"AA";
                end if;
            when 2 => -- GREEN
                if px_out(3) = '1' then
                    V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"00";
                else
                    V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"AA"; V_OUT.b_8 <= x"00";
                end if;
            when 3 => -- CYAN
                if px_out(3) = '1' then
                    V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"FF";
                else
                    V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"AA"; V_OUT.b_8 <= x"AA";
                end if;
            when 4 => -- RED
                if px_out(3) = '1' then
                    V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"00";
                else
                    V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"00";
                end if;
            when 5 => -- MAGENTA
                if px_out(3) = '1' then
                    V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"FF";
                else
                    V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"AA";
                end if;
            when 6 => -- YELLOW
                if px_out(3) = '1' then
                    V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"00";
                else
                    V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"AA"; V_OUT.b_8 <= x"00";
                end if;
            when 7 => -- WHITE
                if px_out(3) = '1' then
                    V_OUT.r_8 <= x"FF"; V_OUT.g_8 <= x"FF"; V_OUT.b_8 <= x"FF";
                else
                    V_OUT.r_8 <= x"AA"; V_OUT.g_8 <= x"AA"; V_OUT.b_8 <= x"AA";
                end if;
            when others =>
                V_OUT.r_8 <= x"00"; V_OUT.g_8 <= x"00"; V_OUT.b_8 <= x"00";
        end case;
    end process;

    V_OUT.de <= V_IN.de ;
    V_OUT.h_sync <= V_IN.h_sync ;
    V_OUT.v_sync <= V_IN.h_sync ;

    VRAM_ADDR <= std_logic_vector(vram_addr_pxl);

    vram_data_reg <= VRAM_DATA;

end architecture RTL;