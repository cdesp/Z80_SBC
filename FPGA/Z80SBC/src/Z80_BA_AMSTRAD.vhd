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
        VDRegs_out          : OUT t_video_regs
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

    signal vsync_signal      : std_logic := '0';

    signal lower_rom_en_reg     : std_logic;
    signal upper_rom_en_reg     : std_logic;
    signal ram_bank0_reg   : std_logic_vector(2 downto 0);
    signal ram_bank1_reg   : std_logic_vector(2 downto 0);
    signal ram_bank2_reg   : std_logic_vector(2 downto 0);
    signal ram_bank3_reg   : std_logic_vector(2 downto 0);

    signal capture1 :std_logic :='0';

    signal system_en: std_logic:='0'; -- default disabled;

BEGIN
    system_en <= '1' when OTSigs_in.SYS_SEL=4  else '0';


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
            upper_rom_en_reg <= '0';   -- Upper BASIC ROM OFF
            
            ram_bank0_reg    <= "000"; -- Physical Block 0 (0x0000 - 0x3FFF)
            ram_bank1_reg    <= "001"; -- Physical Block 1 (0x4000 - 0x7FFF)
            ram_bank2_reg    <= "010"; -- Physical Block 2 (0x8000 - 0xBFFF)
            ram_bank3_reg    <= "011"; -- Physical Block 3 / VRAM (0xC000 - 0xFFFF)
            
        elsif rising_edge(CLK_FPGA) then
            capture1 <='0';
            -- Check for Z80 I/O Write Cycle
            if Z80_In.Z80_IORQ_N = '0' and Z80_In.Z80_WR_N = '0' then
                
                -- 1. GATE ARRAY DECODING (A15 = '0' and A14 = '1')
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
                                VDRegs_out.Reg2 <= Z80_In.Z80_Data; -- Border color
                            else
                                VDRegs_out.pen_palette(selected_pen) <= Z80_In.Z80_Data(4 downto 0);
                            end if;

                        -- 10xxxxxx: ROM Selection, Screen Mode & Interrupt Reset
                        when "10" =>
                            -- Bit 0 & 1: Screen Mode (0, 1, 2)
                            VDRegs_out.Reg1 <= Z80_In.Z80_Data; 
                            
                            -- Bit 2: '0' = Lower OS ROM ON, '1' = OFF
                            lower_rom_en_reg <= not Z80_In.Z80_Data(2);
                            
                            -- Bit 3: '0' = Upper BASIC ROM ON, '1' = OFF
                            upper_rom_en_reg <= not Z80_In.Z80_Data(3);

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
                end if;

                -- 2. UPPER ROM SELECT DECODING (A13 = '0')
                if Z80_In.Z80_ADDR(ROM_MASK_A13) = '0' then
                    amstrad_upper_rom <= Z80_In.Z80_Data;
                end if;

                -- 3. CRTC REGISTER INDEX SELECT (A14 = '0' and A9 = '0')
                if Z80_In.Z80_ADDR(CRTC_MASK_A14) = '0' and Z80_In.Z80_ADDR(CRTC_MASK_A9) = '0' then
                    crtc_index <= Z80_In.Z80_Data(4 downto 0);
                end if;

            end if;
        end if;
    end process;

    -- Assign internal registers to output ports
    OTSigs_out.lower_rom_en   <= lower_rom_en_reg;
    OTSigs_out.upper_rom_en   <= upper_rom_en_reg;
    OTSigs_out.ram_page_bank0 <= ram_bank0_reg;
    OTSigs_out.ram_page_bank1 <= ram_bank1_reg;
    OTSigs_out.ram_page_bank2 <= ram_bank2_reg;
    OTSigs_out.ram_page_bank3 <= ram_bank3_reg;

    vsync_signal <= OTSigs_in.vsync;

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
    process(Z80_IO_ADDR, Z80_In, vsync_signal)
    begin
        dOUT_PPI  <= X"FF";
        dOUT_CRTC <= X"FF";
        dOUT_FDC  <= X"FF";

        if (Z80_In.Z80_IORQ_N = '0' and Z80_In.Z80_RD_N = '0') then
            -- PPI Read Decoding (A11 = '0')
            if (Z80_IO_ADDR(PPI_MASK_A11) = '0') then
                -- PPI Port B (A10='0', A9='1' -> Address 0xF5xx)
                if (Z80_IO_ADDR(PPI_MASK_A10) = '0' and Z80_IO_ADDR(PPI_MASK_A9) = '1') then
                    -- Bit 0: VSYNC, Bits 1-3: European CPC links ("111"), Bit 4: 50Hz ("1")
                    dOUT_PPI <= "111" & "1" & "111" & vsync_signal;
                end if;
            end if;
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
    
    io_strobe <= '1' when (Z80_In.Z80_IORQ_N = '0' and (Z80_In.Z80_WR_N = '0' or Z80_In.Z80_RD_N = '0')) 
                 else '0';

    Z80_Out.DEV2 <= LS139_BA_OUT(1) WHEN (io_strobe = '1' AND ISLS139 = '0') ELSE '0';  --B
    Z80_Out.DEV1 <= LS139_BA_OUT(0) WHEN (io_strobe = '1' AND ISLS139 = '0') ELSE '0';  --A
    
    -- ***************************************************************
    -- ** 2. MMU I/O PORT DECODING (Z80 OUT commands) **
    -- ***************************************************************
    Z80_Out.MMU_nMAP_REG_N <= '1';       
    Z80_Out.MMU_nSET_RO_N  <= '1';
    Z80_Out.MMU_nSET_RW_N  <= '1';
    Z80_Out.CLK_SEL_RG_N    <= '1';
    Z80_Out.UART_CS_N       <= '1';
    Z80_Out.PS2_DS_N        <= '1';
    Z80_Out.VD_DS_N         <= '1';
    Z80_Out.I2C_CS_N        <= '1';
    Z80_Out.SYS_CS_N        <= '1';

    -- Port 0: Write Page Mapping Registers (C_MMU_MAP_REG_ADDR = x"00")
   -- Z80_Out.MMU_nMAP_REG_N <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_ADDR = C_MMU_MAP_REG_ADDR)
   --                   ELSE '1';
                      
    -- Port 1: Set Read-Only Protection (C_MMU_SET_RO_ADDR = x"01")
  --  Z80_Out.MMU_nSET_RO_N  <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_ADDR = C_MMU_SET_RO_ADDR)
    --                  ELSE '1';
                      
    -- Port 2: Set Read/Write Protection (C_MMU_SET_RW_ADDR = x"02")
  --  Z80_Out.MMU_nSET_RW_N  <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_ADDR = C_MMU_SET_RO_ADDR)
      --                ELSE '1';
                      
    -- Z80 Clock Selection Register Write Strobe Generation
    -- This signal is active low when the Z80 reads/writes  to the I/O port (nIORQ=0)
    -- whose address matches the CLK_SEL_PORT_ADDR (x"80").
  --  Z80_Out.CLK_SEL_RG_N    <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_ADDR(7 downto 0) = CLK_SEL_PORT_ADDR)
   --                else '1';

 --   Z80_Out.UART_CS_N       <= '0' when (Z80_In.Z80_IORQ_N = '0' and  Z80_IO_ADDR(7 downto 3) = UART_PORT_BASE(7 downto 3)) 
--else '1';

  --  Z80_Out.PS2_DS_N        <= '0' when (Z80_In.Z80_IORQ_N = '0' and (Z80_IO_ADDR = C_PS2_PORT_ADDR OR Z80_IO_ADDR = std_logic_vector(unsigned(C_PS2_PORT_ADDR) + 1) ))
   --               else '1';

   -- Z80_Out.VD_DS_N         <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_ADDR = C_VD_PORT_ADDR)
    --              else '1';

   -- Z80_Out.I2C_CS_N        <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_ADDR(7 downto 3) =  C_I2C_PORT_ADDR_BASE(7 downto 3))
     --             else '1';

   -- Z80_Out.SYS_CS_N        <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_ADDR = C_SYS_PORT_ADDR)
      --            else '1';


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
    Z80_Out.Z80_INT_N <= Z80_In.INT_REQ_N;
    
END behavioral;