library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VD_types_pkg.all;
use work.defs_pkg.all;

entity NewbrainVideo is
    port (
        V_IN      : in  video_bus_in;  
        V_OUT     : out video_bus_out;

        FPGA_CLK  : in  std_logic;

        Z80_CLK   : in  std_logic;
        Z80_WR_N  : in  std_logic;
        REG_SEL_N : in  std_logic;

        Z80_ADDR  : in  std_logic_vector(3 downto 0);
        Z80_DATA  : in  std_logic_vector(7 downto 0);

        VRAM_DATA : in  std_logic_vector(7 downto 0);
        VRAM_ADDR : out std_logic_vector(15 downto 0);

        VDRegs    : in t_video_regs
    );
end entity NewbrainVideo;

architecture RTL of NewbrainVideo is

    constant COLOR_FORE_R : std_logic_vector(7 downto 0) := x"FF"; 
    constant COLOR_FORE_G : std_logic_vector(7 downto 0) := x"FF";
    constant COLOR_FORE_B : std_logic_vector(7 downto 0) := x"FF";

    constant COLOR_BACK_R : std_logic_vector(7 downto 0) := x"00"; 
    constant COLOR_BACK_G : std_logic_vector(7 downto 0) := x"00";
    constant COLOR_BACK_B : std_logic_vector(7 downto 0) := x"1A";

    constant ACTIVE_HEIGHT : integer := 500;
    constant START_Y       : integer := (600 - ACTIVE_HEIGHT) / 2;

    signal sRV    : std_logic;
    signal sFS    : std_logic;
    signal s3240  : std_logic;
    signal sUCR   : std_logic;
    signal s80L   : std_logic;
    signal TVP    : std_logic;
    
   
    signal memaddr_reg : unsigned(15 downto 0) := (others => '0');
    
    signal shift_reg         : std_logic_vector(7 downto 0) := x"00";
    signal char_rev_flag     : std_logic := '0';
    signal line_blank_active : std_logic := '0';
    
    signal holding_shift : std_logic_vector(7 downto 0) := x"00";
    signal holding_rev   : std_logic := '0';
    signal holding_blank : std_logic := '0';

-- =================================================================
    -- VBLANK SCANNER SIGNALS
    -- =================================================================
    type t_scan_state is (S_IDLE, S_INIT, S_RD0, S_W0_1, S_W0_2, S_CHK0, 
                          S_RD1, S_W1_1, S_W1_2, S_CHK1, S_RD2, S_W2_1, S_W2_2, 
                          S_CHK2, S_RD3, S_W3_1, S_W3_2, S_CHK3, S_NEXT, S_DONE);
    
    signal scan_state      : t_scan_state := S_IDLE;
    signal scan_addr       : unsigned(15 downto 0) := (others => '0');
    signal scan_base       : unsigned(15 downto 0) := (others => '0');
    signal scan_row        : integer := 0;
    signal b2_val          : std_logic_vector(7 downto 0) := (others => '0');
    signal first_zero_addr : unsigned(15 downto 0) := (others => '0');
    
    signal text_end_row    : integer := 255; 
    signal graph_en        : std_logic := '0';
    signal graph_base      : unsigned(15 downto 0) := (others => '0');

    signal base_page       : unsigned(15 downto 0);
    signal latched_video_addr : unsigned(15 downto 0);

    -- 1. These are updated by System Clock (Z80 bus speed)
    signal shadow_addrrow : std_logic_vector(7 downto 0);
    signal shadow_sVideo9 : std_logic;

    -- 2. These are the "safe" signals for your Pixel Clock pipeline
    signal sync_addrrow   : std_logic_vector(7 downto 0);
    signal sync_sVideo9   : std_logic;

    signal addrrow_meta : std_logic_vector(7 downto 0);
    signal sVideo9_meta : std_logic;



    signal addrcol : std_logic_vector(6 downto 0);
   

    -- debug
    signal vdcapture :std_logic :='0';

begin

    TVP      <= VDRegs.Reg1(2);  --ENABLE REG
    sRV      <= VDRegs.Reg2(0);  --VIDEO CONTROL REG
    sFS      <= VDRegs.Reg2(1);
    s3240    <= VDRegs.Reg2(2);
    sUCR     <= VDRegs.Reg2(3);
    s80L     <= VDRegs.Reg2(6);
    
 --   sVideo9  <= VDRegs.Reg3(0);
--    addrrow  <= VDRegs.Reg4;
    addrcol  <= "0000010" when s80L = '0' else "0000100";


    process (FPGA_CLK)
    begin
        if rising_edge(FPGA_CLK) then
            -- Only update at the very start of the frame (VBLANK)
            if (V_IN.v_cnt = 0 and V_IN.h_cnt = 0) then
                shadow_addrrow <= VDRegs.Reg4; 
                shadow_sVideo9 <= VDRegs.Reg3(0);
            end if;
        end if;
    end process;

    -- Synchronizer process (Run this in the Pixel Clock domain)
    process(V_IN.clk_pixel)
    begin
        if rising_edge(V_IN.clk_pixel) then
            -- Simple two-stage synchronizer
            addrrow_meta <= shadow_addrrow;
            sync_addrrow <= addrrow_meta;
            
            sVideo9_meta <= shadow_sVideo9;
            sync_sVideo9 <= sVideo9_meta;
        end if;
    end process;


    process (V_IN.clk_pixel)
    begin
        if rising_edge(V_IN.clk_pixel) then
            -- Only grab the Z80 ports when the beam is at the very top of the screen
            if V_IN.v_cnt = 0 and V_IN.h_cnt = 0 then
                -- sVideo9 from Port 8 automatically provides the +64 byte offset when set
                latched_video_addr <= unsigned(std_logic_vector'("0" & sync_addrrow & sync_sVideo9 & "000000"));
            end if;
        end if;
    end process;

    process(V_IN.clk_pixel)
        variable active_width     : integer;
        variable start_x          : integer;
        variable is_graph_line    : std_logic;
        
        variable graph_width      : integer;
        variable graph_start      : integer;
        
        variable x_rel, y_rel     : integer;
        variable native_y         : integer;
        variable char_row         : integer;
        variable font_row         : integer;
        variable font_height      : integer;
        
        variable max_col          : integer;
        variable fetch_x          : integer;
        variable fetch_col        : integer;
        variable fetch_phase      : integer;
        variable latch_phase      : integer;
        
        variable base_addr        : unsigned(15 downto 0);
        variable row_addr         : unsigned(15 downto 0);
        variable font_base        : unsigned(15 downto 0);
        variable char_code        : unsigned(7 downto 0);
        
        variable graph_y          : integer;
        variable bytes_per_line   : integer;
        variable graph_addr       : unsigned(15 downto 0);
        
        variable pixel_bit        : std_logic;
        variable final_pixel      : std_logic;
        variable is_char_reversed : std_logic;

        variable video_addr_reg : unsigned(15 downto 0);
        variable nStart         : unsigned(15 downto 0);
        variable actual_row     : integer;
        variable EL             : integer;

        variable base_temp : unsigned(15 downto 0);
        
    begin
        if rising_edge(V_IN.clk_pixel) then
            
            y_rel := V_IN.v_cnt - START_Y;
            native_y := y_rel / 2;

            if sUCR = '1' then
                font_height := 8;  char_row := native_y / 8;  font_row := native_y mod 8;
                font_base := x"8000";
            else
                font_height := 10; char_row := native_y / 10; font_row := native_y mod 10;
                font_base := x"9000";
            end if;

            -- 1. DECOUPLE TEXT AND GRAPHICS GEOMETRY
            if s3240 = '1' then
                graph_width := 512; graph_start := 144; -- (800 - 512) / 2
            else
                graph_width := 640; graph_start := 80;  -- (800 - 640) / 2
            end if;

            if (native_y >= 0) and (native_y < ACTIVE_HEIGHT) and (char_row >= text_end_row) then
                if graph_en = '1' then
                    is_graph_line := '1';
                    active_width  := graph_width;
                    start_x       := graph_start;
                else
                    is_graph_line := '0';
                    active_width  := 0;
                    start_x       := 800; -- Hide blank graphics line
                end if;
            else
                -- Text is ALWAYS 640 width
                is_graph_line := '0';
                active_width  := 640;
                start_x       := 80;
            end if;

            x_rel := V_IN.h_cnt - start_x;
            
            -- =================================================================
            -- 2. VBLANK PRE-SCANNER 
            -- =================================================================
            if (y_rel < 0) or (y_rel >= ACTIVE_HEIGHT) then
                case scan_state is
                    when S_IDLE =>
                        if y_rel = -20 and V_IN.h_cnt = 0 then scan_state <= S_INIT; end if;
                        
                    when S_INIT =>
                        
                        base_temp := unsigned(std_logic_vector'("0" & sync_addrrow & sync_sVideo9 & "000000"));

                        -- Apply the mode offset (+4 or +2)
                        if s80L = '1' then
                            scan_base <= base_temp + 4;
                            scan_addr <= base_temp + 4;
                        else
                            scan_base <= base_temp + 2;
                            scan_addr <= base_temp + 2;
                        end if;
                        scan_row  <= 0;
                        scan_state <= S_RD0;
                        
                    when S_RD0 => memaddr_reg <= scan_addr; scan_state <= S_W0_1;
                    when S_W0_1 => scan_state <= S_W0_2;
                    when S_W0_2 => scan_state <= S_CHK0;
                    when S_CHK0 =>
                        if VRAM_DATA = x"00" then
                            first_zero_addr <= scan_addr; -- Save exact anchor point
                            scan_addr <= scan_addr + 1;
                            scan_state <= S_RD1;
                        else
                            scan_state <= S_NEXT;
                        end if;
                        
                    when S_RD1 => memaddr_reg <= scan_addr; scan_state <= S_W1_1;
                    when S_W1_1 => scan_state <= S_W1_2;
                    when S_W1_2 => scan_state <= S_CHK1;
                    when S_CHK1 =>
                        if VRAM_DATA = x"00" then
                            scan_addr <= scan_addr + 1; scan_state <= S_RD2;
                        else
                            scan_state <= S_NEXT;
                        end if;
                        
                    when S_RD2 => memaddr_reg <= scan_addr; scan_state <= S_W2_1;
                    when S_W2_1 => scan_state <= S_W2_2;
                    when S_W2_2 => scan_state <= S_CHK2;
                    when S_CHK2 =>
                        b2_val <= VRAM_DATA;
                        scan_addr <= scan_addr + 1; scan_state <= S_RD3;
                        
                    when S_RD3 => memaddr_reg <= scan_addr; scan_state <= S_W3_1;
                    when S_W3_1 => scan_state <= S_W3_2;
                    when S_W3_2 => scan_state <= S_CHK3;
                    when S_CHK3 =>
                        if (b2_val = x"00" and VRAM_DATA = x"00") then
                            graph_en <= '1';
                        else
                            graph_en <= '0';
                        end if;
                        
                    
                    -- Standard, compatible conditional logic
                    if s3240 = '1' then
                        if s80L = '0' then
                            graph_base <= first_zero_addr + 4;
                        else
                            graph_base <= first_zero_addr + 8;
                        end if;
                    else
                        graph_base <= first_zero_addr;
                    end if;
                       
                        text_end_row <= scan_row;
                        scan_state <= S_DONE;
                        
                    when S_NEXT =>
                        if s80L = '1' then
                            scan_base <= scan_base + 128; scan_addr <= scan_base + 128;
                        else
                            scan_base <= scan_base + 64; scan_addr <= scan_base + 64;
                        end if;
                        scan_row <= scan_row + 1;
                        
                        if scan_row >= 40 then
                            text_end_row <= 255; scan_state <= S_DONE;
                        else
                            scan_state <= S_RD0;
                        end if;
                        
                    when S_DONE => null;
                end case;

            -- =================================================================
            -- 3. ACTIVE DISPLAY PIPELINE
            -- =================================================================
            else
                scan_state <= S_IDLE;
---                
                -- 1. Calculate nStart and Line Width (EL) using the LATCHED address
                if s80L = '1' then
                    nStart := latched_video_addr + 4;
                    EL     := 128;
                else
                    nStart := latched_video_addr + 2;
                    EL     := 64;
                end if;

                -- 3. Final Row Address Calculation (No actual_row double-count needed)
                row_addr := nStart + to_unsigned(char_row * EL, 16);

                --base_addr := unsigned(sVideo9 & addrrow & addrcol);
--- 
--                if s80L = '1' then
--                    row_addr := base_addr + to_unsigned(char_row * 128, 16);
--                else
--                    row_addr := base_addr + to_unsigned(char_row * 64, 16);
--                end if;


                if V_IN.h_cnt = 0 then
                    line_blank_active <= '0';
                    holding_blank     <= '0';
                end if;

                if s80L = '1' then
                    fetch_x := V_IN.h_cnt - start_x + 8;
                    fetch_col := fetch_x / 8;  fetch_phase := fetch_x mod 8;
                    latch_phase := 7;          max_col := active_width / 8;
                else
                    fetch_x := V_IN.h_cnt - start_x + 16;
                    fetch_col := fetch_x / 16; fetch_phase := fetch_x mod 16;
                    latch_phase := 15;         max_col := active_width / 16;
                end if;

                if (fetch_x >= 0) and (fetch_col < max_col) and (y_rel >= 0) and (y_rel < ACTIVE_HEIGHT) then
                    
                    if is_graph_line = '1' then
                        -- ==================== GRAPHICS FETCH ====================
                        graph_y := native_y - (text_end_row * font_height);
                        
                        if s3240 = '0' then
                            if s80L = '1' then bytes_per_line := 80; else bytes_per_line := 40; end if;
                        else
                            if s80L = '1' then bytes_per_line := 64; else bytes_per_line := 32; end if;
                        end if;
                        
                        graph_addr := graph_base + to_unsigned(graph_y * bytes_per_line, 16) + to_unsigned(fetch_col, 16);
                        
                        case fetch_phase is
                            when 0 => memaddr_reg <= graph_addr;
                            when 3 => 
                                holding_shift <= VRAM_DATA; 
                                holding_blank <= '0';
                                holding_rev   <= '0';
                            when others => null;
                        end case;
                    else
                        -- ==================== TEXT FETCH ====================
                        case fetch_phase is
                            when 0 =>
                                memaddr_reg <= row_addr + to_unsigned(fetch_col, 16);
                            when 3 =>
                                char_code := unsigned(VRAM_DATA);
                                if char_code = 0 then holding_blank <= '1'; else holding_blank <= '0'; end if;
                                
                                is_char_reversed := '0';
                                if sFS = '0' and char_code >= 128 then
                                    is_char_reversed := '1'; char_code := char_code - 128;
                                end if;
                                holding_rev <= is_char_reversed;
                                
                                memaddr_reg <= font_base + to_unsigned(font_row * 256, 16) + char_code;
                            when 6 =>
                                holding_shift <= VRAM_DATA;
                            when others => null;
                        end case;
                    end if;

                    if fetch_phase = latch_phase then
                        shift_reg     <= holding_shift;
                        char_rev_flag <= holding_rev;
                        if holding_blank = '1' then line_blank_active <= '1'; end if;
                    end if;
                end if;

 -- =================================================================
                -- 4. PIXEL DRAWING (Zero Delay)
                -- =================================================================
                if (y_rel >= 0) and (y_rel < ACTIVE_HEIGHT) and (TVP = '1') then
                    
                    -- The logical screen is always 640 pixels wide (from h_cnt 80 to 719)
                    if (V_IN.h_cnt >= 80) and (V_IN.h_cnt < 720) then
                        
                        -- Are we inside the active content width (640 for Text/Wide, 512 for Narrow)?
                        if (x_rel >= 0) and (x_rel < active_width) then
                            
                            if line_blank_active = '1' then
                                pixel_bit := '0'; 
                            else
                                if is_graph_line = '1' then
                                    -- Graphics Mode (LSB to MSB)
                                    if s80L = '1' then
                                        pixel_bit := shift_reg(x_rel mod 8);
                                    else
                                        pixel_bit := shift_reg((x_rel / 2) mod 8);
                                    end if;
                                else
                                    -- Text Mode (MSB to LSB)
                                    if s80L = '1' then
                                        pixel_bit := shift_reg(7 - (x_rel mod 8));
                                    else
                                        pixel_bit := shift_reg(7 - ((x_rel / 2) mod 8));
                                    end if;
                                end if;
                            end if;

                            final_pixel := pixel_bit xor sRV xor char_rev_flag;

                            if final_pixel = '1' then
                                V_OUT.r_8 <= COLOR_FORE_R; V_OUT.g_8 <= COLOR_FORE_G; V_OUT.b_8 <= COLOR_FORE_B;
                            else
                                V_OUT.r_8 <= COLOR_BACK_R; V_OUT.g_8 <= COLOR_BACK_G; V_OUT.b_8 <= COLOR_BACK_B;
                            end if;
                            
                        else
                            -- We are in the Padding Area (Left/Right margins in narrow mode)
                            -- Note: sRV is applied here so global Reverse Video still works on the padding!
                            if sRV = '1' then
                                V_OUT.r_8 <= COLOR_FORE_R; V_OUT.g_8 <= COLOR_FORE_G; V_OUT.b_8 <= COLOR_FORE_B;
                            else
                                V_OUT.r_8 <= COLOR_BACK_R; V_OUT.g_8 <= COLOR_BACK_G; V_OUT.b_8 <= COLOR_BACK_B;
                            end if;
                        end if;
                        
                    else
                        -- Outside the 640-wide logical display (true hardware border)
                        V_OUT.r_8 <= (others => '1'); V_OUT.g_8 <= (others => '0'); V_OUT.b_8 <= (others => '0');
                    end if;
                    
                else
                    -- Outside the vertical active display (true hardware border)
                    V_OUT.r_8 <= (others => '1'); V_OUT.g_8 <= (others => '0'); V_OUT.b_8 <= (others => '0');
                end if;


            end if;
        end if;
    end process;

    V_OUT.de <= V_IN.de ;
    V_OUT.h_sync <= V_IN.h_sync ;
    V_OUT.v_sync <= V_IN.h_sync ;

    VRAM_ADDR <= std_logic_vector(memaddr_reg);

end architecture RTL;