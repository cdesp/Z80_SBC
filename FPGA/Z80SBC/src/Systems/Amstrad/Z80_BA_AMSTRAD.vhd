LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;
USE work.defs_pkg.ALL; -- Import MMU I/O address constants

ENTITY Z80_BA_Amstrad IS
    PORT (
        CLK_FPGA            : in  std_logic;
        -- Z80 Side
        CLK                 : IN STD_LOGIC;                     -- Z80 Operating Clock (e.g., 8MHz)
        nRESET              : IN STD_LOGIC;
       -- All Z80 inputs bundled together
        Z80_In              : IN  t_z80_to_system;
        -- All system outputs bundled together
        Z80_Out             : OUT t_system_to_z80;
        -- Other signals
        OTSigs_in           : IN t_ot_sigs_to_system;
        OTSigs_out          : OUT t_ot_sigs_from_system;
        -- Video registers
        VDRegs_out          : OUT t_video_regs;

        --Amstrad signals
        amst_Sigs           : OUT t_amstrad_sigs
    );
END Z80_BA_Amstrad;

ARCHITECTURE behavioral OF Z80_BA_Amstrad IS
    

    -- ========================================================================
    -- GATE ARRAY & UPPER ROM SELECTION (0x7F00 / 0xDF00)
    -- ========================================================================
    -- Gate Array: Αποκωδικοποιείται όταν A15 = '0' και A14 = '1'
    -- Upper ROM Select: Αποκωδικοποιείται όταν A13 = '0'
    constant GA_MASK_A15          : integer := 15;
    constant GA_MASK_A14          : integer := 14;
    constant ROM_MASK_A13         : integer := 13;
    
    constant PORT_GATE_ARRAY_BASE : std_logic_vector(15 downto 0) := X"7F00";
    constant PORT_UPPER_ROM_BASE  : std_logic_vector(15 downto 0) := X"DF00";

    -- ========================================================================
    -- CRTC 6845 VIDEO CONTROLLER (0x4000 - 0x4FFF)
    -- ========================================================================
    -- Αποκωδικοποιείται όταν A14 = '0'
    -- Αν A9 = '0' -> CRTC Register Select (0x4000)
    -- Αν A8 = '1' -> CRTC Data Write/Read (0x4100)
    constant CRTC_MASK_A14        : integer := 14;
    constant CRTC_MASK_A9         : integer := 9;
    constant CRTC_MASK_A8         : integer := 8;

    constant PORT_CRTC_REG_SEL    : std_logic_vector(15 downto 0) := X"4000";
    constant PORT_CRTC_DATA       : std_logic_vector(15 downto 0) := X"4100";

    -- ========================================================================
    -- PPI 8255 & AY-3-8912 SOUND CHIP (0xF400 - 0xF700)
    -- ========================================================================
    -- Αποκωδικοποιείται όταν A11 = '0'
    -- Αν A10 / A9 ορίζουν ποιο register του PPI επιλέγεται
    constant PPI_MASK_A11         : integer := 11;
    constant PPI_MASK_A10         : integer := 10;
    constant PPI_MASK_A9          : integer := 9;
    constant PPI_MASK_A8          : integer := 8;

    constant PORT_PPI_A_DATA      : std_logic_vector(15 downto 0) := X"F400"; -- AY Data / Keyboard
    constant PORT_PPI_B_DATA      : std_logic_vector(15 downto 0) := X"F500"; -- VSYNC / Jumper Links (Κρίσιμο για Boot!)
    constant PORT_PPI_C_DATA      : std_logic_vector(15 downto 0) := X"F600"; -- Keyboard Row / Cassette / AY Control
    constant PORT_PPI_CTRL        : std_logic_vector(15 downto 0) := X"F700"; -- PPI Control Word Register

    -- ========================================================================
    -- EXPANSION PORTS (Προαιρετικά για αργότερα - π.χ. DDI-1 Disk Controller)
    -- ========================================================================
    -- AMSDOS / Floppy Disk: Αποκωδικοποιείται όταν A7 = '0'
    constant FDC_MASK_A7          : integer := 7;
    constant PORT_FDC_STATUS      : std_logic_vector(15 downto 0) := X"FB7E"; -- Read FDC Status
    constant PORT_FDC_DATA        : std_logic_vector(15 downto 0) := X"FB7F"; -- Read/Write FDC Data
    constant PORT_FDC_MOTOR       : std_logic_vector(15 downto 0) := X"FA7E"; -- Drive Motor Control

    -- Internal signal for I/O Address (A0-A15)
    SIGNAL Z80_IO_ADDR      : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL Z80_IO_LOWADDR      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    -- Signal to hold current wait state logic (default is no wait, '1')
    SIGNAL internal_wait_n  : STD_LOGIC; 
    
    -- 2-bit vector to hold the calculated BA inputs for the 74LS139 (B=DEV2, A=DEV1)
    SIGNAL LS139_BA_OUT : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ISLS139 : STD_LOGIC :='1';
    signal io_strobe : std_logic;

    --amstrad signals
    signal amstrad_upper_rom : std_logic_vector(7 downto 0) := X"00";
    signal ga_rom_config     : std_logic_vector(7 downto 0) := X"00";
    signal crtc_index        : std_logic_vector(4 downto 0) := (others => '0');
    

    signal dOUT_PPI          : std_logic_vector(7 downto 0);
    signal dOUT_CRTC         : std_logic_vector(7 downto 0);
    signal dOUT_FDC          : std_logic_vector(7 downto 0);

   

    signal lower_rom_en_reg     : std_logic;
    signal upper_rom_en_reg     : std_logic;
    signal ram_bank0_reg   : std_logic_vector(2 downto 0);
    signal ram_bank1_reg   : std_logic_vector(2 downto 0);
    signal ram_bank2_reg   : std_logic_vector(2 downto 0);
    signal ram_bank3_reg   : std_logic_vector(2 downto 0);


    signal capture1 :std_logic :='0';

    signal system_en: std_logic:='0'; -- default disabled;

    -- ========================================================================
    -- 8255 PPI REGISTERS
    -- ========================================================================
    signal ppi_port_a : std_logic_vector(7 downto 0) := (others => '1');
    signal ppi_port_b : std_logic_vector(7 downto 0) := (others => '1');
    signal ppi_port_c : std_logic_vector(7 downto 0) := (others => '1');

    -- Default after reset (Mode 0, all ports input)
    signal ppi_ctrl : std_logic_vector(7 downto 0) := X"9B";




    -- CRTC REGISTERS
    -- CRTC Registers R0-R15


    signal crtc_regs : crtc_reg_array := (
        X"3F", X"28", X"2E", X"8E",
        X"26", X"00", X"19", X"1E",
        X"00", X"07", X"00", X"00",
        X"30", X"00", X"00", X"00",
        X"00", X"00"
    );



signal dbg_crtc_r12 : std_logic_vector(7 downto 0);
signal dbg_crtc_r13 : std_logic_vector(7 downto 0);
signal dbg_crtc_r14 : std_logic_vector(7 downto 0);
signal dbg_crtc_r15 : std_logic_vector(7 downto 0);


--ppi signals to return to cpc
    signal vsync_signal     : std_logic := '0';
    signal int_reg          : std_logic:='1';  --active low

-- Signal declarations for MC6845
signal crtc_hsync     : std_logic;
signal crtc_vsync     : std_logic;
signal hsync_delayed  : std_logic := '0';
signal hsync_falling  : std_logic;
signal vsync_delayed  : std_logic := '0';
signal vsync_rising   : std_logic;
signal cclk_tick      : std_logic;

--Interrupt
signal r_int          :std_logic := '0'; --active high

 

    signal clk_div              : unsigned(1 downto 0) := (others => '0');
    signal ga_int_counter       : unsigned(6 downto 0);
    signal vsync_hsync_count    : unsigned(2 downto 0);   

-- Edge detection signals for MC6845 outputs
    signal hsync_falling_edge   : std_logic;
    signal vsync_rising_edge    : std_logic;

    signal int_ack : std_logic := '0';

-- keyboard signals
    type t_cpc_matrix is array (0 to 9) of std_logic_vector(7 downto 0);
    signal kb_matrix : t_cpc_matrix := (others => (others => '1'));
    signal ps2_rd_req : std_logic := '0';
    signal ps2_data_byte : std_logic_vector(7 downto 0);
    signal CPC_KEYB_OUT  : std_logic_vector(7 downto 0);
    signal cpc_row_sel   : std_logic_vector(3 downto 0);

    signal AMS_Reg1: std_logic_vector(7 downto 0) := (others => '0');
    signal AMS_Reg2: std_logic_vector(7 downto 0) := (others => '0');
    signal AMS_pen_palette :  t_pen_array;


BEGIN


    Z80_Out.Z80_BUSREQ_N <= '1';
    amst_Sigs.lower_rom_en    <= lower_rom_en_reg;
    amst_Sigs.upper_rom_en    <= upper_rom_en_reg;
    amst_Sigs.ram_page_bank0  <= ram_bank0_reg;
    amst_Sigs.ram_page_bank1  <= ram_bank1_reg;
    amst_Sigs.ram_page_bank2  <= ram_bank2_reg;
    amst_Sigs.ram_page_bank3  <= ram_bank3_reg;

    process(all)
        variable v_out : t_ot_sigs_from_system;
    begin
        v_out := C_OT_SIGS_DEFAULT;
        v_out.SYS_SEL := OTSigs_in.SYS_SEL;
        --amstrad out signals
        v_out.PS2_KEYB_READ := ps2_rd_req;
        OTSigs_out <= v_out;
    end process;


--==============keyboard ========================

-- Amstrad CPC Keyboard Scanner
    -- to get another key from ps/2 keyboard
     
    --------------------------------------------------------------------------------
    -- Combinational: Output the selected row for the AY-3-8912 Port A
    -- 'cpc_row_sel' (4-bit signal, 0-9) should be driven by your 8255/74LS145 logic
    --------------------------------------------------------------------------------
    process(cpc_row_sel, kb_matrix)
    begin
        if to_integer(unsigned(cpc_row_sel)) < 10 then
            CPC_KEYB_OUT <= kb_matrix(to_integer(unsigned(cpc_row_sel)));
        else
            CPC_KEYB_OUT <= (others => '1');
        end if;
    end process;
     
    --------------------------------------------------------------------------------
    -- PS/2 decode FSM (mapped to Amstrad CPC 10x8 Matrix)
    --------------------------------------------------------------------------------
    process(CLK_FPGA, nRESET)
        type t_ps2_state is (IDLE, DECODE_BYTE);
        variable dec_state     : t_ps2_state := IDLE;
        variable release_flag  : std_logic := '0';
        variable extended_flag : std_logic := '0';
        variable val           : std_logic; -- '0' = pressed, '1' = released
    begin
        if nRESET = '0' then
            kb_matrix     <= (others => (others => '1'));
            dec_state     := IDLE;
            release_flag  := '0';
            extended_flag := '0';
            ps2_rd_req    <= '0';
     
        elsif rising_edge(CLK_FPGA) then
            ps2_rd_req <= '0'; -- pulse for 1 cycle when we pop a byte
     
            case dec_state is
                when IDLE =>
                    if OTSigs_in.PS2_BT_Avail = '1' then
                        ps2_data_byte <= OTSigs_in.PS2_DATA;
                        ps2_rd_req    <= '1'; -- pop this byte from the PS/2 FIFO
                        dec_state     := DECODE_BYTE;
                    end if;
     
                when DECODE_BYTE =>
                    val := release_flag;
     
                    if ps2_data_byte = X"E0" then
                        extended_flag := '1';
     
                    elsif ps2_data_byte = X"F0" then
                        release_flag := '1';
     
                    else
                        if extended_flag = '1' then
                            -- Extended (E0-prefixed) keys
                            case ps2_data_byte is
                                when X"75" => kb_matrix(0)(0) <= val; -- Up Arrow
                                when X"74" => kb_matrix(0)(1) <= val; -- Right Arrow
                                when X"72" => kb_matrix(0)(2) <= val; -- Down Arrow
                                when X"6B" => kb_matrix(1)(0) <= val; -- Left Arrow
                                when X"5A" => kb_matrix(0)(6) <= val; -- Numpad Enter
                                when X"14" => kb_matrix(2)(7) <= val; -- Right Ctrl
                                when X"71" => kb_matrix(9)(7) <= val; -- Delete -> Del
                                when others => null;
                            end case;
                            extended_flag := '0';
                        else
                            -- Standard (Set 2) keys
                            case ps2_data_byte is
                                -- Row 0 (Partial - Symbols & Numpad)
                                when X"01" => kb_matrix(0)(3) <= val; -- F9
                                when X"0B" => kb_matrix(0)(4) <= val; -- F6
                                when X"04" => kb_matrix(0)(5) <= val; -- F3
                                when X"71" => kb_matrix(0)(7) <= val; -- Numpad .
     
                                -- Row 1 (F-Keys & Copy)
                                when X"11" => kb_matrix(1)(1) <= val; -- L-Alt -> Copy
                                when X"83" => kb_matrix(1)(2) <= val; -- F7
                                when X"0A" => kb_matrix(1)(3) <= val; -- F8
                                when X"03" => kb_matrix(1)(4) <= val; -- F5
                                when X"05" => kb_matrix(1)(5) <= val; -- F1
                                when X"06" => kb_matrix(1)(6) <= val; -- F2
                                when X"09" => kb_matrix(1)(7) <= val; -- F10 -> f0
     
                                -- Row 2
                                when X"0E" => kb_matrix(2)(0) <= val; -- ` -> Clr
                                when X"54" => kb_matrix(2)(1) <= val; -- [
                                when X"5A" => kb_matrix(2)(2) <= val; -- Enter
                                when X"5B" => kb_matrix(2)(3) <= val; -- ]
                                when X"0C" => kb_matrix(2)(4) <= val; -- F4
                                when X"12" | X"59" => kb_matrix(2)(5) <= val; -- L/R Shift
                                when X"5D" => kb_matrix(2)(6) <= val; -- \
                                when X"14" => kb_matrix(2)(7) <= val; -- L-Ctrl
     
                                -- Row 3
                                when X"55" => kb_matrix(3)(0) <= val; -- = -> ^
                                when X"4E" => kb_matrix(3)(1) <= val; -- -
                                when X"79" => kb_matrix(3)(2) <= val; -- Numpad + -> @
                                when X"4D" => kb_matrix(3)(3) <= val; -- P
                                when X"4C" => kb_matrix(3)(4) <= val; -- ;
                                when X"52" => kb_matrix(3)(5) <= val; -- ' -> :
                                when X"4A" => kb_matrix(3)(6) <= val; -- /
                                when X"49" => kb_matrix(3)(7) <= val; -- .
     
                                -- Row 4
                                when X"45" => kb_matrix(4)(0) <= val; -- 0
                                when X"46" => kb_matrix(4)(1) <= val; -- 9
                                when X"44" => kb_matrix(4)(2) <= val; -- O
                                when X"43" => kb_matrix(4)(3) <= val; -- I
                                when X"4B" => kb_matrix(4)(4) <= val; -- L
                                when X"42" => kb_matrix(4)(5) <= val; -- K
                                when X"3A" => kb_matrix(4)(6) <= val; -- M
                                when X"41" => kb_matrix(4)(7) <= val; -- ,
     
                                -- Row 5
                                when X"3E" => kb_matrix(5)(0) <= val; -- 8
                                when X"3D" => kb_matrix(5)(1) <= val; -- 7
                                when X"3C" => kb_matrix(5)(2) <= val; -- U
                                when X"35" => kb_matrix(5)(3) <= val; -- Y
                                when X"33" => kb_matrix(5)(4) <= val; -- H
                                when X"3B" => kb_matrix(5)(5) <= val; -- J
                                when X"31" => kb_matrix(5)(6) <= val; -- N
                                when X"29" => kb_matrix(5)(7) <= val; -- Space
     
                                -- Row 6
                                when X"36" => kb_matrix(6)(0) <= val; -- 6
                                when X"2E" => kb_matrix(6)(1) <= val; -- 5
                                when X"2D" => kb_matrix(6)(2) <= val; -- R
                                when X"2C" => kb_matrix(6)(3) <= val; -- T
                                when X"34" => kb_matrix(6)(4) <= val; -- G
                                when X"2B" => kb_matrix(6)(5) <= val; -- F
                                when X"32" => kb_matrix(6)(6) <= val; -- B
                                when X"2A" => kb_matrix(6)(7) <= val; -- V
     
                                -- Row 7
                                when X"25" => kb_matrix(7)(0) <= val; -- 4
                                when X"26" => kb_matrix(7)(1) <= val; -- 3
                                when X"24" => kb_matrix(7)(2) <= val; -- E
                                when X"1D" => kb_matrix(7)(3) <= val; -- W
                                when X"1B" => kb_matrix(7)(4) <= val; -- S
                                when X"23" => kb_matrix(7)(5) <= val; -- D
                                when X"21" => kb_matrix(7)(6) <= val; -- C
                                when X"22" => kb_matrix(7)(7) <= val; -- X
     
                                -- Row 8
                                when X"16" => kb_matrix(8)(0) <= val; -- 1
                                when X"1E" => kb_matrix(8)(1) <= val; -- 2
                                when X"76" => kb_matrix(8)(2) <= val; -- Esc
                                when X"15" => kb_matrix(8)(3) <= val; -- Q
                                when X"0D" => kb_matrix(8)(4) <= val; -- Tab
                                when X"1C" => kb_matrix(8)(5) <= val; -- A
                                when X"58" => kb_matrix(8)(6) <= val; -- Caps Lock
                                when X"1A" => kb_matrix(8)(7) <= val; -- Z
     
                                -- Row 9 (Partial - Del / Joystick maps usually go here)
                                when X"66" => kb_matrix(9)(7) <= val; -- Backspace -> Del
     
                                when others => null;
                            end case;
                        end if;
     
                        release_flag := '0'; -- consumed
                    end if;
     
                    dec_state := IDLE;
     
                when others =>
                    dec_state := IDLE;
            end case;
        end if;
    end process;



--===============================================
    
-- 1 MHz Character Clock Tick Generator from 4 MHz CLK
    process(CLK, nRESET)
        
    begin
        if nRESET = '0' then
            clk_div   <= (others => '0');
            cclk_tick <= '0';
        elsif rising_edge(CLK) then
            if clk_div = 3 then  -- 4 MHz / 4 = 1 MHz
                clk_div   <= (others => '0');
                cclk_tick <= '1';
            else
                clk_div   <= clk_div + 1;
                cclk_tick <= '0';
            end if;
        end if;
    end process;


-- 6845
u_mc6845 : entity work.mc6845
    port map (
        CLOCK       => CLK,
        CLKEN       => cclk_tick,         -- Your 1 MHz character clock enable tick
        CLKEN_CPU   => '1',               -- Tie active if registers update synchronously on CLKEN
        nRESET      => nRESET,
        
        -- Bus interface (Map your Z80 register write interface to the MC6845 inputs)
        ENABLE      => not Z80_In.Z80_IORQ_N, -- Active high
        R_nW        => Z80_In.Z80_WR_N,  -- Low write, High read
        RS          => Z80_In.Z80_ADDR(8),-- Typically Register Select is tied to A8 or your CRTC address decode
        DI          => Z80_In.Z80_Data,
        DO          => open,              -- Unused if only writing configuration registers
        
        -- Display interface
        VSYNC       => crtc_vsync,
        HSYNC       => crtc_hsync,
        DE          => open,              -- Not needed since screen updates independently
        CURSOR      => open,              -- Not needed
        LPSTB       => '0',               -- Light pen strobe unused
        VGA         => '0',               -- Standard Amstrad non-interlaced mode
        
        -- Memory interface (Left open since your FPGA handles display generation independently)
        MA          => open,
        RA          => open,
        test        => open
    );

vsync_signal <= crtc_vsync;

---------------------------------------------------------------------------
-- EDGE DETECTION & INTERRUPT GENERATION
---------------------------------------------------------------------------

---------------------------------------------------------------------------
    -- 3. EDGE DETECTION (CLK_FPGA Domain)
    ---------------------------------------------------------------------------
    process(CLK_FPGA, nRESET)
    begin
        if nRESET = '0' then
            hsync_delayed <= '0';
            vsync_delayed <= '0';
        elsif rising_edge(CLK_FPGA) then
            hsync_delayed <= crtc_hsync;
            vsync_delayed <= crtc_vsync;
        end if;
    end process;

    hsync_falling_edge <= '1' when (hsync_delayed = '1' and crtc_hsync = '0') else '0';
    vsync_rising_edge  <= '1' when (vsync_delayed = '0' and crtc_vsync = '1') else '0';

    int_ack <= '1' when Z80_In.Z80_IORQ_N = '0' and Z80_In.Z80_M1_N = '0' else '0';

    process(CLK_FPGA, nRESET)
    begin
        if nRESET = '0' then
            ga_int_counter    <= (others => '0');
            vsync_hsync_count <= (others => '0');
            r_int             <= '0';
        elsif rising_edge(CLK_FPGA) then
            
            -- Clear Interrupt on Z80 ACK cycle
            if int_ack='1' then
                r_int <= '0';
                ga_int_counter(5) <= '0';
            end if;

            -- Synchronize line count on VSYNC Rising Edge
            if vsync_rising_edge = '1' then
                vsync_hsync_count <= (others => '0');
            end if;

            -- Process Gate Array Logic on HSYNC Falling Edge
            if hsync_falling_edge = '1' then
                ga_int_counter <= ga_int_counter + 1;

                -- If VSYNC is active, count incoming HSYNC pulses
                if crtc_vsync = '1' then
                    if vsync_hsync_count < 2 then
                        vsync_hsync_count <= vsync_hsync_count + 1;
                    end if;
                    
                    -- On the 2nd HSYNC pulse during active VSYNC, evaluate and reset
                    if vsync_hsync_count = 1 then
                        -- Check if counter is < 32 (bit 5 is '0')
                        if ga_int_counter(5) = '0' then
                            r_int <= '1'; -- Fire Z80 Interrupt
                        else
                            r_int <= '0';
                        end if;
                        ga_int_counter <= (others => '0');
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

-- Active-low interrupt output mapping
int_reg <= not r_int;

--=====================================================================


    system_en <= '1' when OTSigs_in.SYS_SEL="0100"  else '0'; --4=amstrad

dbg_crtc_r12 <= crtc_regs(12);
dbg_crtc_r13 <= crtc_regs(13);
dbg_crtc_r14 <= crtc_regs(14);
dbg_crtc_r15 <= crtc_regs(15);



    Z80_IO_ADDR <= Z80_In.Z80_ADDR;
    -- Map lower 8 bits of Z80 address bus for I/O decoding
    Z80_IO_LOWADDR <= Z80_IO_ADDR(7 downto 0);



 -- ========================================================================
    -- GATE ARRAY & MEMORY CONTROL REGISTERS
    -- ========================================================================
    process(CLK_FPGA, nReset,system_en)
        variable selected_pen : integer range 0 to 31 := 0;
    begin
        if nReset = '0' or system_en='0' then -- Reset active low
            amstrad_upper_rom <= X"00";
            ga_rom_config     <= X"00";
            
            -- Boot Defaults (Standard 1:1 CPC 464 Layout)
            lower_rom_en_reg <= '1';   -- Lower OS ROM ON
            upper_rom_en_reg <= '1';   -- Upper BASIC ROM ON
            
            ram_bank0_reg    <= "000"; -- Physical Block 0 (0x0000 - 0x3FFF)
            ram_bank1_reg    <= "001"; -- Physical Block 1 (0x4000 - 0x7FFF)
            ram_bank2_reg    <= "010"; -- Physical Block 2 (0x8000 - 0xBFFF)
            ram_bank3_reg    <= "011"; -- Physical Block 3 / VRAM (0xC000 - 0xFFFF)

            ppi_port_a <= X"00";
            ppi_port_b <= X"00";
            ppi_port_c <= X"00";
            ppi_ctrl   <= X"9B";

             
        elsif rising_edge(CLK_FPGA) then
            capture1 <='0';
            -- Check for Z80 I/O Write Cycle
            if Z80_In.Z80_IORQ_N = '0' and Z80_In.Z80_WR_N = '0' then
                
                -- 1. GATE ARRAY DECODING (A15 = '0' and A14 = '1') --7fxx
                if Z80_In.Z80_ADDR(GA_MASK_A15) = '0' and Z80_In.Z80_ADDR(GA_MASK_A14) = '1' then
                    ga_rom_config <= Z80_In.Z80_Data;
                    
                    -- Inspect Data Command Type (Bits D7 and D6)
                    case Z80_In.Z80_Data(7 downto 6) is

                        -- 00xxxxxx: Select Pen Register (0..15) or Border (16)
                        when "00" =>
                            if Z80_In.Z80_Data(4) = '1' then
                                selected_pen := 16; -- Border
                            else
                                selected_pen := to_integer(unsigned(Z80_In.Z80_Data(3 downto 0)));
                            end if;

                        -- 01xxxxxx: Set Pen/Border Color (Palette)
                        when "01" =>
                            if selected_pen = 16 then
                                AMS_Reg2 <= Z80_In.Z80_Data; -- Border color
                            else
                                AMS_pen_palette(selected_pen) <= Z80_In.Z80_Data(4 downto 0);
                            end if;

                        -- 10xxxxxx: ROM Selection, Screen Mode & Interrupt Reset
                        when "10" =>
                            -- Bit 0 & 1: Screen Mode (0, 1, 2)
                            AMS_Reg1 <= Z80_In.Z80_Data; 
                            
                            -- Bit 2: '0' = Lower OS ROM ON, '1' = OFF
                            lower_rom_en_reg <= not Z80_In.Z80_Data(2);  -- REVERSED
                            
                            -- Bit 3: '0' = Upper BASIC ROM ON, '1' = OFF
                            upper_rom_en_reg <= not Z80_In.Z80_Data(3); -- REVERSED

                        -- 11xxxxxx: RAM Bank Configuration Command (6128 PAL Logic)
                        when "11" =>
                            capture1 <='1';
                            case Z80_In.Z80_Data(2 downto 0) is
                                -- C0: Standard 64K Base RAM
                                when "000" => 
                                    ram_bank0_reg <= "000"; ram_bank1_reg <= "001"; 
                                    ram_bank2_reg <= "010"; ram_bank3_reg <= "011";
                                
                                -- C1: Bank 7 mapped to C000-FFFF
                                when "001" => 
                                    ram_bank0_reg <= "000"; ram_bank1_reg <= "001"; 
                                    ram_bank2_reg <= "010"; ram_bank3_reg <= "111";
                                
                                -- C2: Full Extended RAM array (4, 5, 6, 7) mapped across all slots
                                when "010" => 
                                    ram_bank0_reg <= "100"; ram_bank1_reg <= "101"; 
                                    ram_bank2_reg <= "110"; ram_bank3_reg <= "111";
                                
                                -- C3: Bank 7 mapped to C000-FFFF (Alt)
                                when "011" => 
                                    ram_bank0_reg <= "000"; ram_bank1_reg <= "001"; 
                                    ram_bank2_reg <= "010"; ram_bank3_reg <= "111";
                                
                                -- C4: Bank 4 mapped to 4000-7FFF
                                when "100" => 
                                    ram_bank0_reg <= "000"; ram_bank1_reg <= "100"; 
                                    ram_bank2_reg <= "010"; ram_bank3_reg <= "011";
                                
                                -- C5: Bank 5 mapped to 4000-7FFF
                                when "101" => 
                                    ram_bank0_reg <= "000"; ram_bank1_reg <= "101"; 
                                    ram_bank2_reg <= "010"; ram_bank3_reg <= "011";
                                
                                -- C6: Bank 6 mapped to 4000-7FFF
                                when "110" => 
                                    ram_bank0_reg <= "000"; ram_bank1_reg <= "110"; 
                                    ram_bank2_reg <= "010"; ram_bank3_reg <= "011";
                                
                                -- C7: Bank 7 mapped to 4000-7FFF
                                when "111" => 
                                    ram_bank0_reg <= "000"; ram_bank1_reg <= "111"; 
                                    ram_bank2_reg <= "010"; ram_bank3_reg <= "011";
                                
                                when others => null;
                            end case;

                        when others =>
                            null;
                    end case;
               -- end if;

                -- 2. UPPER ROM SELECT DECODING (A13 = '0')
                elsif Z80_In.Z80_ADDR(15) = '0' and Z80_In.Z80_ADDR(ROM_MASK_A13) = '0' then
                    amstrad_upper_rom <= Z80_In.Z80_Data;
              --  end if;

                -- 3. CRTC REGISTER INDEX SELECT (A14 = '0' and A9 = '0')
                elsif Z80_In.Z80_ADDR(CRTC_MASK_A14) = '0'  and Z80_In.Z80_ADDR(CRTC_MASK_A9) = '0' then
                   -- Index Select: A8 = '0' (Standard address &0xBE00 / &xBC00)
                    if Z80_In.Z80_ADDR(8) = '0' then
                        crtc_index <= Z80_In.Z80_Data(4 downto 0);
                    -- Data Write: A8 = '1' (Standard address &0xBF00 / &xBD00)
                    else
                        case to_integer(unsigned(crtc_index)) is
                            when 4 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= "0" & Z80_In.Z80_Data(6 downto 0);
                            when 5 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= "000" & Z80_In.Z80_Data(4 downto 0);
                            when 6 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= "0" & Z80_In.Z80_Data(6 downto 0);
                            when 7 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= "0" & Z80_In.Z80_Data(6 downto 0);
                            when 9 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= "000" & Z80_In.Z80_Data(4 downto 0);
                            when 10 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= "0" & Z80_In.Z80_Data(6 downto 0);
                            when 11 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= "000" & Z80_In.Z80_Data(4 downto 0);
                            when 12 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= "00" & Z80_In.Z80_Data(5 downto 0);
                            when 13 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= Z80_In.Z80_Data;
                            when 14 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= "00" & Z80_In.Z80_Data(5 downto 0);
                            when 15 =>
                                crtc_regs(to_integer(unsigned(crtc_index))) <= Z80_In.Z80_Data;
                            when others => 
                                crtc_regs(to_integer(unsigned(crtc_index))) <= Z80_In.Z80_Data;
                        end case;
                    end if;
--                end if;

                -- =====================================================================
                -- 8255 PPI WRITE
                -- =====================================================================
                elsif Z80_In.Z80_ADDR(PPI_MASK_A11) = '0' then

                    -- Port select using A9:A8
                    case Z80_In.Z80_ADDR(PPI_MASK_A9 downto PPI_MASK_A8) is

                        -- F4xx : Port A
                        when "00" =>
                            ppi_port_a <= Z80_In.Z80_Data;

                        -- F5xx : Port B
                        when "01" =>
                            ppi_port_b <= Z80_In.Z80_Data;

                        -- F6xx : Port C
                        when "10" =>
                            ppi_port_c <= Z80_In.Z80_Data;
                            cpc_row_sel <= Z80_In.Z80_Data(3 downto 0);

                        -- F7xx : Control Register
                        when "11" =>

                            -- Mode Set command
                            if Z80_In.Z80_Data(7)='1' then
                                ppi_ctrl <= Z80_In.Z80_Data;

                            -- Bit Set/Reset command
                            else
                                case Z80_In.Z80_Data(3 downto 1) is
                                    when "000" =>
                                        ppi_port_c(0) <= Z80_In.Z80_Data(0);
                                    when "001" =>
                                        ppi_port_c(1) <= Z80_In.Z80_Data(0);
                                    when "010" =>
                                        ppi_port_c(2) <= Z80_In.Z80_Data(0);
                                    when "011" =>
                                        ppi_port_c(3) <= Z80_In.Z80_Data(0);
                                    when "100" =>
                                        ppi_port_c(4) <= Z80_In.Z80_Data(0);
                                    when "101" =>
                                        ppi_port_c(5) <= Z80_In.Z80_Data(0);
                                    when "110" =>
                                        ppi_port_c(6) <= Z80_In.Z80_Data(0);
                                    when "111" =>
                                        ppi_port_c(7) <= Z80_In.Z80_Data(0);
                                    when others =>
                                        null;
                                end case;
                            end if;

                        when others =>
                            null;
                    end case;

                end if;

            end if;
        end if;
    end process;

    process(all)
        variable v_VDRegs : t_video_regs;
    begin
        v_VDRegs := DUMMY_VDREGS;
        v_VDRegs.CRTC_R12 := crtc_regs(12);
        v_VDRegs.CRTC_R13 := crtc_regs(13);
        v_VDRegs.Reg1 := AMS_Reg1;
        v_VDRegs.Reg2 := AMS_Reg2;
        v_VDRegs.pen_palette := AMS_pen_palette;
        VDRegs_out <= v_VDRegs;
    end process;



    -- ========================================================================
    -- READ OUTPUT ENABLES & DATA MULTIPLEXER
    -- ========================================================================
    
    -- Signal is active low ('0' enables FPGA data bus output towards the Z80)
    Z80_out.isDOut <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_RD_N = '0' AND (
        (Z80_IO_ADDR(PPI_MASK_A11) = '0') OR
        (Z80_IO_ADDR(CRTC_MASK_A14) = '0' AND Z80_IO_ADDR(CRTC_MASK_A8) = '1') OR
        (Z80_IO_ADDR(FDC_MASK_A7) = '0')
    )) ELSE '1';

    Z80_out.DataOut <= 
        dOUT_PPI  WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_RD_N = '0' AND Z80_IO_ADDR(PPI_MASK_A11) = '0') ELSE
        dOUT_CRTC WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_RD_N = '0' AND Z80_IO_ADDR(CRTC_MASK_A14) = '0' AND Z80_IO_ADDR(CRTC_MASK_A8) = '1') ELSE
        dOUT_FDC  WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_RD_N = '0' AND Z80_IO_ADDR(FDC_MASK_A7) = '0') ELSE
        X"FF";

        -- Minimal Boot Data Read Process
    process(Z80_IO_ADDR, Z80_In, crtc_VSYNC, ppi_port_a, ppi_port_b, ppi_port_c, ppi_ctrl, CPC_KEYB_OUT, vsync_signal)
    begin
        dOUT_PPI  <= X"FF";        
        dOUT_FDC  <= X"FF";
        
        if (Z80_In.Z80_IORQ_N = '0' and Z80_In.Z80_RD_N = '0') then
             if (Z80_IO_ADDR(PPI_MASK_A11) = '0') then
                case Z80_IO_ADDR(PPI_MASK_A9 downto PPI_MASK_A8) is

                    -- Port A =f400
                    when "00" =>
                     --   if (ppi_port_c(7 downto 6) = "01") then
                            dOUT_PPI <= CPC_KEYB_OUT ;--"11111111"; -- Fake "No keys pressed"
                     --   else
                     --       dOUT_PPI <= ppi_port_a; 
                     --   end if;

                    -- Port B F500
                    when "01" => 
                         -- Δίνει &1E (όταν VSYNC=0) και &1F (όταν VSYNC=1)
                         dOUT_PPI <= "0001111" & vsync_signal;                          

                    -- Port C F600
                    when "10" =>
                        dOUT_PPI <= ppi_port_c; 

                    -- Control register F700
                    when "11" =>
                        dOUT_PPI <= ppi_ctrl;

                    when others =>
                        dOUT_PPI <= X"FF";
                end case;
            end if;
        end if;
    end process;


     
    process(crtc_index, crtc_regs, Z80_In)
    begin
        dOUT_CRTC <= X"00";
        if Z80_In.Z80_ADDR(8) = '0' then
           dOUT_CRTC <=  x"FF"; --crtc type 0
        else 
            case to_integer(unsigned(crtc_index)) is
                when 10 =>
                    dOUT_CRTC <= crtc_regs(10);

                when 11 =>
                    dOUT_CRTC <= crtc_regs(11);

                when 12 =>
                    dOUT_CRTC <= crtc_regs(12);  --crtc type 0

                when 13 =>
                    dOUT_CRTC <= crtc_regs(13);  --crtc type 0

                when 14 =>
                    dOUT_CRTC <= crtc_regs(14);

                when 15 =>
                    dOUT_CRTC <= crtc_regs(15);

                when 16 =>
                    dOUT_CRTC <= crtc_regs(16);

                when 17 =>
                    dOUT_CRTC <= crtc_regs(17);

                when others =>
                    dOUT_CRTC <= X"00";
            end case;
        end if;
    end process;

----------------------


    
                       
    -- ***************************************************************
    -- ** 1. 74LS138 INPUTS (DEV0-DEV2) - Configurable for Emulation **
    -- ***************************************************************
    
    -- This PROCESS implements the flexible I/O port mapping.
    -- When a specific Z80 I/O address is accessed, we calculate the required CBA input 
    -- to activate the desired Y output on the 74LS138.
    
    PROCESS (Z80_In.Z80_IORQ_N, Z80_IO_LOWADDR)
    BEGIN
        
        -- Default to unused Y0 (CBA = 000) when not performing an I/O request.
        -- This drives Y0 to active low, which is assumed not to be connected to a peripheral.
        LS139_BA_OUT <= B"00"; --pin 7 unconnected
        ISLS139 <='1';
        IF (Z80_In.Z80_IORQ_N = '0') THEN -- Only calculate if I/O Request is active
            CASE Z80_IO_LOWADDR IS
                -- Custom Decoding Examples (as per user request)
                WHEN C_LS139_Y1 => 
                    -- OUT (45h, Data) activates Y1 (BA = 01) 
                    LS139_BA_OUT <= B"01";   --pin 6 LAUD_MUX_N select ausio device d7=1 selects AY
                    ISLS139 <='0';
                WHEN C_LS139_Y2 => 
                    -- OUT (40h, Data) activates Y2 (CBA = 010)
                    LS139_BA_OUT <= B"10";   --pin 5 LAUD_CS_N this for sn76489 
                    ISLS139 <='0';
                WHEN C_LS139_Y2_1 => 
                    -- OUT (41h, Data) activates Y2 (CBA = 010)
                    LS139_BA_OUT <= B"10";   --pin 5 LAUD_CS_N this for ay38912 BCDIR=A0=1 BC1=A1=0
                    ISLS139 <='0';
                WHEN C_LS139_Y2_2 => 
                    -- OUT (42h, Data) activates Y2 (CBA = 010)
                    LS139_BA_OUT <= B"10";   --pin 5 LAUD_CS_N this for ay38912 BCDIR=A0=0 BC1=A1=1
                    ISLS139 <='0';
                WHEN C_LS139_Y2_3 => 
                    -- OUT (43h, Data) activates Y2 (CBA = 010)
                    LS139_BA_OUT <= B"10";   --pin 5 LAUD_CS_N this for ay38912 BCDIR=A0=1 BC1=A1=1
                    ISLS139 <='0';

                WHEN C_LS139_Y3_0 => 
                    -- OUT (30h, CMD) activates Y3 (CBA = 011)
                    LS139_BA_OUT <= B"11";   --pin 3 CH376_CS_N
                    ISLS139 <='0';
                WHEN C_LS139_Y3_1 => --NEEDS 2 ADDRESSES
                    -- OUT (31h, Data) activates Y3 (CBA = 011)
                    LS139_BA_OUT <= B"11";   --pin 3 CH376_CS_N
                    ISLS139 <='0';
                WHEN OTHERS => 
                    -- For all other addresses, we default to using the lowest 2 address bits pin 15 unconnected                    
                    LS139_BA_OUT <= B"00";
            END CASE;
        END IF;

    END PROCESS;
    
  --  io_strobe <= '1' when (Z80_In.Z80_IORQ_N = '0' and (Z80_In.Z80_WR_N = '0' or Z80_In.Z80_RD_N = '0')) 
   --              else '0';

io_strobe <= '0';
    Z80_Out.DEV2 <= LS139_BA_OUT(1) WHEN (io_strobe = '1' AND ISLS139 = '0') ELSE '0';  --B
    Z80_Out.DEV1 <= LS139_BA_OUT(0) WHEN (io_strobe = '1' AND ISLS139 = '0') ELSE '0';  --A
    
    -- ***************************************************************
    -- ** 2. MMU I/O PORT DECODING (Z80 OUT commands) **
    -- ***************************************************************


    -- Port 0: Write Page Mapping Registers (C_MMU_MAP_REG_ADDR = x"00")
    Z80_Out.MMU_nMAP_REG_N <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_LOWADDR = C_MMU_MAP_REG_ADDR) and OTSigs_in.ToolActive='1'
                      ELSE '1';
               
    -- Port 0: Read Page Mapping Registers (C_MMU_MAP_REG_ADDR = x"00")
    Z80_Out.MMU_nMAP_RD_N <= '0' WHEN (Z80_In.Z80_IORQ_N = '0'  AND Z80_In.Z80_RD_N = '0' AND Z80_IO_LOWADDR = C_MMU_MAP_REG_ADDR) and OTSigs_in.ToolActive='1'
                      ELSE '1';

       
    -- Port 1: Set Read-Only Protection (C_MMU_SET_RO_ADDR = x"01")
    Z80_Out.MMU_nSET_RO_N  <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_LOWADDR = C_MMU_SET_RO_ADDR) and OTSigs_in.ToolActive='1'
                     ELSE '1';
                      
    -- Port 2: Set Read/Write Protection (C_MMU_SET_RW_ADDR = x"02")
    Z80_Out.MMU_nSET_RW_N  <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_LOWADDR = C_MMU_SET_RO_ADDR) and OTSigs_in.ToolActive='1'
                      ELSE '1';
                      
    -- Z80 Clock Selection Register Write Strobe Generation
    -- This signal is active low when the Z80 reads/writes  to the I/O port (nIORQ=0)
    -- whose address matches the CLK_SEL_PORT_ADDR (x"80").
    Z80_Out.CLK_SEL_RG_N    <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_LOWADDR = CLK_SEL_PORT_ADDR) and OTSigs_in.ToolActive='1'
                   else '1';

    Z80_Out.UART_CS_N       <= '0' when (Z80_In.Z80_IORQ_N = '0' and  Z80_IO_LOWADDR(7 downto 3) = UART_PORT_BASE(7 downto 3)) and OTSigs_in.ToolActive='1'
                     else '1';

    Z80_Out.PS2_DS_N        <= '0' when (Z80_In.Z80_IORQ_N = '0' and (Z80_IO_LOWADDR = C_PS2_PORT_ADDR OR Z80_IO_LOWADDR = std_logic_vector(unsigned(C_PS2_PORT_ADDR) + 1) )) and OTSigs_in.ToolActive='1'
                  else '1';

    Z80_Out.VD_DS_N         <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_LOWADDR = C_VD_PORT_ADDR) and OTSigs_in.ToolActive='1'
                  else '1';

    Z80_Out.I2C_CS_N        <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_LOWADDR(7 downto 3) =  C_I2C_PORT_ADDR_BASE(7 downto 3)) and OTSigs_in.ToolActive='1'
                  else '1';

    Z80_Out.SYS_CS_N        <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_LOWADDR = C_SYS_PORT_ADDR) and OTSigs_in.ToolActive='1'
                  else '1';


    -- ***************************************************************
    -- ** 3. WAIT STATE GENERATION **
    -- ***************************************************************
    
    -- Placeholder: For the moment, assert Z80_WAIT_N high (no wait states)
    internal_wait_n <= '1';
    
    Z80_Out.Z80_WAIT_N <= internal_wait_n;


    -- ***************************************************************
    -- ** 4. INTERRUPT MANAGEMENT **
    -- ***************************************************************
    
    --INTERRUPTS CLOCK OR KEYBOARD
    Z80_Out.Z80_INT_N <= Z80_In.INT_REQ_N AND int_reg;
    
END behavioral;