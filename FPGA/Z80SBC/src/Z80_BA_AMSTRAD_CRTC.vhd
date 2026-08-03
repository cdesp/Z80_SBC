library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE work.defs_pkg.ALL; -- Import MMU I/O address constants

entity Z80_BA_AMSTRAD_CRTC is
    port (
        CLK_FPGA            : in  std_logic;                    -- Main high-speed FPGA clock
        CLK                 : in  std_logic;                    -- Z80 Operating Clock (e.g., 4MHz / 8MHz)
        nRESET              : in  std_logic;                    -- Asynchronous active-low reset
        
        -- Z80 Inputs
        Z80_In              : in  t_z80_to_system;
        
        -- Registers provided by your external Z80 decoding logic
        CRTC_Regs           : in  crtc_reg_array;
        
        -- Outputs
        VSYNC               : out std_logic;
        INT                 : out std_logic                     -- Active LOW Interrupt to Z80
    );
end entity Z80_BA_AMSTRAD_CRTC;

architecture Behavioral of Z80_BA_AMSTRAD_CRTC is

    -- 1 MHz Character Clock Generator (CCLK)
    signal cclk_tick            : std_logic := '0';
    signal clk_div              : unsigned(5 downto 0) := (others => '0');

    -- CRTC Internal Counters
    signal h_count              : unsigned(7 downto 0) := (others => '0');
    signal hsync_width_count    : unsigned(3 downto 0) := (others => '0');
    signal hsync_active         : std_logic := '0';
    
    signal v_row_count          : unsigned(6 downto 0) := (others => '0');
    signal v_line_count         : unsigned(4 downto 0) := (others => '0');
    signal vsync_width_count    : unsigned(3 downto 0) := (others => '0');
    signal vsync_active         : std_logic := '0';
    
    -- Internal Signal Mirrors
    signal r_hsync              : std_logic := '0';
    signal r_vsync              : std_logic := '0';
    
    -- Edges for Gate Array Interrupt Counter
    signal hsync_delayed        : std_logic := '0';
    signal hsync_falling_edge   : std_logic;
    signal vsync_delayed        : std_logic := '0';
    signal vsync_rising_edge    : std_logic;

    -- Gate Array Interrupt Emulation Registers
    signal ga_int_counter       : unsigned(5 downto 0) := (others => '0');
    signal vsync_hsync_count    : unsigned(1 downto 0) := (others => '0');
    signal r_int                : std_logic := '0';
    signal z80_int_ack          : std_logic := '0';

begin

    -- Output Assigns
    VSYNC <= r_vsync;
    INT   <= not r_int;

    ---------------------------------------------------------------------------
    -- 1. CHARACTER CLOCK (CCLK) TICK GENERATOR (1 MHz)
    -- Modify this divider to match your exact CLK_FPGA frequency. 
    -- Example assumes CLK_FPGA is 16 MHz (16 ticks per 1 MHz CCLK).
    ---------------------------------------------------------------------------
    process(CLK_FPGA, nRESET)
    begin
        if nRESET = '0' then
            clk_div   <= (others => '0');
            cclk_tick <= '0';
        elsif rising_edge(CLK_FPGA) then
            if clk_div = 49 then  -- 16 MHz / 16 = 1 MHz
                clk_div   <= (others => '0');
                cclk_tick <= '1';
            else
                clk_div   <= clk_div + 1;
                cclk_tick <= '0';
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- 2. TYPE 0 CRTC CORE TIMING STATE MACHINE
    ---------------------------------------------------------------------------
    process(CLK_FPGA, nRESET)
        variable target_h_width : unsigned(3 downto 0);
        variable target_v_width : unsigned(3 downto 0);
    begin
        if nRESET = '0' then
            h_count            <= (others => '0');
            hsync_width_count  <= (others => '0');
            hsync_active       <= '0';
            r_hsync            <= '0';
            
            v_row_count        <= (others => '0');
            v_line_count       <= (others => '0');
            vsync_width_count  <= (others => '0');
            vsync_active       <= '0';
            r_vsync            <= '0';
        elsif rising_edge(CLK_FPGA) then
            if cclk_tick = '1' then
                
                ---------------------------------------------------------------
                -- Horizontal Counter
                ---------------------------------------------------------------
                if h_count >= unsigned(CRTC_Regs(0)) then
                    h_count <= (others => '0');
                    
                    -----------------------------------------------------------
                    -- Vertical Counter (Triggers on Horizontal Line End)
                    -----------------------------------------------------------
                    if v_line_count >= unsigned(CRTC_Regs(9)) then
                        v_line_count <= (others => '0');
                        if v_row_count >= unsigned(CRTC_Regs(4)) then
                            v_row_count <= (others => '0');
                        else
                            v_row_count <= v_row_count + 1;
                        end if;
                    else
                        v_line_count <= v_line_count + 1;
                    end if;
                    
                else
                    h_count <= h_count + 1;
                end if;

                ---------------------------------------------------------------
                -- HSYNC Generator
                ---------------------------------------------------------------
                if h_count = unsigned(CRTC_Regs(2)) then
                    hsync_active      <= '1';
                    r_hsync           <= '1';
                    hsync_width_count <= (others => '0');
                end if;

                if hsync_active = '1' then
                    -- Type 0 Quirk: Width of 0 in R3(3:0) defaults to 16 characters
                    if CRTC_Regs(3)(3 downto 0) = "0000" then
                        target_h_width := "1111"; -- 16 chars (0 to 15)
                    else
                        target_h_width := unsigned(CRTC_Regs(3)(3 downto 0)) - 1;
                    end if;

                    if hsync_width_count = target_h_width then
                        r_hsync      <= '0';
                        hsync_active <= '0';
                    else
                        hsync_width_count <= hsync_width_count + 1;
                    end if;
                end if;

                ---------------------------------------------------------------
                -- VSYNC Generator
                ---------------------------------------------------------------
                if h_count = 0 and
                    v_line_count = 0 and
                        v_row_count = unsigned(CRTC_Regs(7)) then
                    vsync_active      <= '1';
                    r_vsync           <= '1';
                    vsync_width_count <= (others => '0');
                end if;

                if vsync_active = '1' then
                    -- Type 0 Quirk: Width of 0 in R3(7:4) defaults to 16 lines
                    if CRTC_Regs(3)(7 downto 4) = "0000" then
                        target_v_width := "1111"; -- 16 scanlines
                    else
                        target_v_width := unsigned(CRTC_Regs(3)(7 downto 4)) - 1;
                    end if;

                    -- VSYNC tracks horizontal lines completed during its active state
                    if h_count = unsigned(CRTC_Regs(0)) then
                        if vsync_width_count = target_v_width then
                            r_vsync      <= '0';
                            vsync_active <= '0';
                        else
                            vsync_width_count <= vsync_width_count + 1;
                        end if;
                    end if;
                end if;

            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- 3. EDGE DETECTION (CLK_FPGA Domain)
    ---------------------------------------------------------------------------
    process(CLK_FPGA, nRESET)
    begin
        if nRESET = '0' then
            hsync_delayed <= '0';
            vsync_delayed <= '0';
        elsif rising_edge(CLK_FPGA) then
            hsync_delayed <= r_hsync;
            vsync_delayed <= r_vsync;
        end if;
    end process;

    hsync_falling_edge <= '1' when (hsync_delayed = '1' and r_hsync = '0') else '0';
    vsync_rising_edge  <= '1' when (vsync_delayed = '0' and r_vsync = '1') else '0';

    ---------------------------------------------------------------------------
    -- 4. Z80 INTERRUPT ACKNOWLEDGE DETECTION
    ---------------------------------------------------------------------------
    z80_int_ack <= '1' when (Z80_In.Z80_IORQ_N = '0' and Z80_In.Z80_M1_N = '0') else '0';

    ---------------------------------------------------------------------------
    -- 5. AMSTRAD GATE ARRAY INTERRUPT COUNTER EMULATION
    ---------------------------------------------------------------------------
    process(CLK_FPGA, nRESET)
    begin
        if nRESET = '0' then
            ga_int_counter    <= (others => '0');
            vsync_hsync_count <= (others => '0');
            r_int             <= '0';
        elsif rising_edge(CLK_FPGA) then
            
            -- Clear Interrupt on Z80 ACK cycle
            if z80_int_ack = '1' then
                r_int <= '0';
                ga_int_counter(5) <= '0';
            end if;

            -- Synchronize with VSYNC Rising Edge
            if vsync_rising_edge = '1' then
                vsync_hsync_count <= (others => '0');
            end if;

            -- Process Gate Array Logic on HSYNC Falling Edge
            if hsync_falling_edge = '1' then
                ga_int_counter <= ga_int_counter + 1;

                -- If VSYNC is active, count incoming HSYNC pulses
                if r_vsync = '1' then
                    if vsync_hsync_count < 3 then
                        vsync_hsync_count <= vsync_hsync_count + 1;
                    end if;
                    
                    -- On the 3rd HSYNC pulse during active VSYNC, clear counter
                    if vsync_hsync_count = 2 then
                        ga_int_counter <= (others => '0');
                        r_int <= '0';
                    end if;
                end if;

                -- Standard Amstrad Interrupt condition (52 lines elapsed)
                if ga_int_counter = 51 then 
                    r_int          <= '1'; -- Fire Z80 Interrupt
                    ga_int_counter <= (others => '0');
                end if;
            end if;

            -- Handle clearing via manual Gate Array configuration write
            if Z80_In.Z80_IORQ_N = '0' and Z80_In.Z80_WR_N = '0' and Z80_In.Z80_ADDR(15) = '0' then
                if Z80_In.Z80_Data(4 downto 3) = "10" then -- Interrupt Clear Command
                    ga_int_counter <= (others => '0');
                    r_int          <= '0';
                end if;
            end if;

        end if;
    end process;

end architecture Behavioral;
