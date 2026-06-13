library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VD_types_pkg.all;

entity video_system_v80 is
    port (
        -- Timing and Sync inputs from the Master Generator
        V_IN            : in  video_bus_in;
        V_OUT           : out video_bus_out;

        -- Z80 Config Interface
        Z80_CLK         : in  std_logic;
        Z80_WR_N        : in  std_logic;
        Z80_ADDR        : in  std_logic_vector(3 downto 0);
        Z80_DATA        : in  std_logic_vector(7 downto 0);
        REG_SEL_N       : in  std_logic;

        -- VRAM Interface
        VRAM_DATA       : in  std_logic_vector(7 downto 0);
        VRAM_ADDR       : out std_logic_vector(15 downto 0)
    );
end entity video_system_v80;

architecture RTL of video_system_v80 is
    -- Parameter Registers
    type reg_array is array (0 to 15) of std_logic_vector(7 downto 0);
    signal video_regs : reg_array := (others => (others => '0'));
    
    -- Pixel processing signals
    signal r, g, b : std_logic_vector(7 downto 0);

begin

    -- 1. Z80 Registers (Configurable Offsets/Border)
    process(Z80_CLK, V_IN.nreset)
    begin
        if V_IN.nreset = '0' then
            video_regs <= (others => (others => '0'));
        elsif rising_edge(Z80_CLK) then
            if REG_SEL_N = '0' and Z80_WR_N = '0' then
                video_regs(to_integer(unsigned(Z80_ADDR))) <= Z80_DATA;
            end if;
        end if;
    end process;

    -- 2. Pixel Generation Logic
    process(V_IN, video_regs, VRAM_DATA)
        variable x_rel, y_rel : integer;
        variable offset_x, offset_y : integer;
    begin
        offset_x := to_integer(unsigned(video_regs(3)));
        offset_y := to_integer(unsigned(video_regs(4)));
        
        x_rel := V_IN.h_cnt - offset_x;
        y_rel := V_IN.v_cnt - offset_y;

        -- Centered 256x192 box (Double pixels = 512x384)
        if x_rel >= 0 and x_rel < 512 and y_rel >= 0 and y_rel < 384 then
            VRAM_ADDR <= std_logic_vector(to_unsigned((y_rel/2) * 32 + (x_rel/16), 16));
            if VRAM_DATA((x_rel/2) mod 8) = '1' then
                r <= x"FF"; g <= x"FF"; b <= x"FF";
            else
                r <= x"00"; g <= x"00"; b <= x"00";
            end if;
        else
            -- Border color
            r <= video_regs(5);
            g <= video_regs(5);
            b <= video_regs(5);
        end if;
    end process;

    -- 3. Output Assignment (Syncs are passed through or modified if needed)
    V_OUT.r_8 <= r;
    V_OUT.g_8 <= g;
    V_OUT.b_8 <= b;
    -- Note: Sync generation usually happens in the HDMI controller, 
    -- but here we pass them through to allow systems to define their own timing if necessary.
    V_OUT.h_sync <= '1'; -- Defaulting high, usually driven by master timing
    V_OUT.v_sync <= '1';
    V_OUT.de     <= '1'; -- Active

end architecture RTL;