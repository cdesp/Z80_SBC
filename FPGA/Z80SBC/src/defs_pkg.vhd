LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL; 

-- General Package Declaration for Project Constants
PACKAGE defs_pkg IS

    -- =======================================================
    -- MMU I/O Port Definitions (Z80 Address Bus A[7:0])
    -- =======================================================

    -- Port 0: Write Page Mapping Registers (sets up the bank registers)
    CONSTANT C_MMU_MAP_REG_ADDR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";     
    -- Port 1: Set Read-Only Protection for the page specified by the DATA bus
    CONSTANT C_MMU_SET_RO_ADDR  : STD_LOGIC_VECTOR(7 DOWNTO 0) := std_logic_vector(unsigned(C_MMU_MAP_REG_ADDR) + 1);     
    -- Port 2: Set Read/Write Protection for the page specified by the DATA bus
    CONSTANT C_MMU_SET_RW_ADDR  : STD_LOGIC_VECTOR(7 DOWNTO 0) := std_logic_vector(unsigned(C_MMU_MAP_REG_ADDR) + 2); 

    -- [ΣΤΑΘΕΡΕΣ ΓΙΑ ΑΛΛΑ ΠΕΡΙΦΕΡΕΙΑΚΑ 
    CONSTANT CLK_SEL_PORT_ADDR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"80"; --Clock Selection
    CONSTANT UART_PORT_BASE    : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"20"; --RS232 via FT232 usb 
    CONSTANT C_PS2_PORT_ADDR   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"48"; --PS/2 Keyb
    CONSTANT C_VD_PORT_ADDR    : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"90"; --Video Regs video system select 
    CONSTANT C_I2C_PORT_ADDR_BASE   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"70"; --I2C
    CONSTANT C_SYS_PORT_ADDR   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"E1"; --SYSTEM SELECT 0,1,2,3...


    --LS139 Selection PORT Constants
    CONSTANT C_LS139_Y1     : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"45"; -- LAUD_MUX_N  (out) ,D7 --> select AY or SN
    CONSTANT C_LS139_Y2     : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"40"; -- LAUD_CS_N FOR SN
    CONSTANT C_LS139_Y2_1   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"41"; -- LAUD_CS_N FOR AY
    CONSTANT C_LS139_Y2_2   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"42"; -- LAUD_CS_N FOR AY
    CONSTANT C_LS139_Y2_3   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"43"; -- LAUD_CS_N FOR AY
    CONSTANT C_LS139_Y3_0   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"30"; -- CH376_CS_N PORT DATA
    CONSTANT C_LS139_Y3_1   : STD_LOGIC_VECTOR(7 DOWNTO 0) := std_logic_vector(unsigned(C_LS139_Y3_0) + 1); -- CH376_CS_N PORT COMMAND

    -- Z80 Clock Speed Selection Codes (3-bit selection)
    -- These correspond to the data bits 2:0 written by the Z80 to CLK_SEL_PORT_ADDR
    constant SEL_2MHZ_C        : std_logic_vector(2 downto 0) := "000";
    constant SEL_4MHZ_C        : std_logic_vector(2 downto 0) := "001";
    constant SEL_8MHZ_C        : std_logic_vector(2 downto 0) := "010";
    constant SEL_12MHZ_C       : std_logic_vector(2 downto 0) := "011";
    constant SEL_16MHZ_C       : std_logic_vector(2 downto 0) := "100";
    constant SEL_20MHZ_C       : std_logic_vector(2 downto 0) := "101";
    constant SEL_10MHZ_C       : std_logic_vector(2 downto 0) := "110"; 

    -- Define constants for clock and target baud rate divisor
    constant CLK_FREQ : integer := 50_000_000; -- 50 MHz clock
    constant TARGET_BR_CLK_HZ : integer := 1_843_200; -- Target 1.8432 MHz (16 * 115200 bps)
    -- Divisor calculation: 50,000,000 / 1,843,200 = 27.1267 -> Use 27
    constant BR_CLK_DIV : integer := 14; -- Integer divisor for 50MHz clock 
    -- Actual Baud Rate: (50,000,000 / 27) / 16 ~= 115,740.74 bps (0.47% error, which is acceptable)

-- Signals coming FROM the Z80 / Arbiter TO the system cores
    TYPE t_z80_to_system IS RECORD      
        -- Z80 Side    
        Z80_Data    : STD_LOGIC_VECTOR(7 DOWNTO 0);
        Z80_IORQ_N  : STD_LOGIC;
        Z80_M1_N    : STD_LOGIC;
        Z80_WR_N    : STD_LOGIC;
        Z80_RD_N    : STD_LOGIC;
        Z80_ADDR    : STD_LOGIC_VECTOR(15 DOWNTO 0);
        INT_REQ_N   : STD_LOGIC;                     -- Master Peripheral Interrupt Request (Active Low)
    END RECORD;

    -- Signals coming OUT of each system core BACK to the Z80 / Arbiter
    TYPE t_system_to_z80 IS RECORD
        -- MMU Control Outputs (Generated from I/O Decode)
        MMU_nMAP_REG_N      : STD_LOGIC;                    -- MMU Map Reg Port (OUT (00h), PageNo)
        MMU_nMAP_RD_N       : STD_LOGIC;                    -- MMU PORT READ PAGE IN BANK 
        MMU_nSET_RO_N       : STD_LOGIC;                    -- MMU Set Read-Only Port (OUT (01h), PageNo)
        MMU_nSET_RW_N       : STD_LOGIC;                    -- MMU Set Read/Write Port (OUT (02h), PageNo)
        
        -- Peripheral Decoding Outputs (Configurable for Emulation)
        DEV1                : STD_LOGIC;                    -- 74LS139 Input A (L/S Bit)
        DEV2                : STD_LOGIC;                    -- 74LS139 Input B (M/S Bit)
        -- LS138_nCS_N and LAY_SEL are removed, as the 74LS138 is assumed to be permanently enabled,
        -- and AY control logic is derived from 74LS138 outputs and Z80 address lines.
        CLK_SEL_RG_N        : std_logic;                    -- for clock selection
        UART_CS_N           : std_logic;                    -- for UART RS232 Selection
        PS2_DS_N            : std_logic;                    -- for PS/2 Keyboard Device communication
        VD_DS_N             : std_logic;                    -- for Video Device Communication
        I2C_CS_N            : std_logic;                    -- for i2c Communication
        SYS_CS_N            : std_logic;                    -- for system selection 
        -- Wait State Generation
        Z80_WAIT_N          : STD_LOGIC;                    -- Z80 Wait Request (Active Low)
        -- Interrupt Management
        Z80_INT_N           : STD_LOGIC;                     -- Z80 Interrupt Pin (Active Low)
        -- Data to z80
        DataOut             : STD_LOGIC_VECTOR(7 DOWNTO 0);
        isDOut              : std_logic;    
    END RECORD;


   TYPE t_ot_sigs_to_system IS RECORD  
         --Main system 
        CPU_SPEED   : std_logic_vector(7 downto 0); --as a number
        SYS_SEL     : unsigned(3 downto 0); --current system selection
        ToolActive  : std_logic;
       
        PS2_KEYB_Int: STD_LOGIC;
        PS2_DATA    :  std_logic_vector(7 downto 0);

        FrameStart  : STD_LOGIC;
    END RECORD;

   TYPE t_ot_sigs_from_system IS RECORD  
        PS2_KEYB_READ : STD_LOGIC; --this flags that we have read the key to the ps.2 module
        
        lower_rom_en : std_logic;
        upper_rom_en : std_logic;
        ram_page_bank0 : std_logic_vector(2 downto 0);
        ram_page_bank1 : std_logic_vector(2 downto 0);
        ram_page_bank2 : std_logic_vector(2 downto 0);
        ram_page_bank3 : std_logic_vector(2 downto 0);


   END RECORD;

   type t_pen_array is array (0 to 15) of std_logic_vector(4 downto 0); --for amstrad

   TYPE t_video_regs IS RECORD      
        --video system 
        Reg1 : std_logic_vector(7 downto 0); --generic video register
        Reg2 : std_logic_vector(7 downto 0); --generic video register
        Reg3 : std_logic_vector(7 downto 0); --generic video register
        Reg4 : std_logic_vector(7 downto 0); --generic video register
        Reg5 : std_logic_vector(7 downto 0); --generic video register

        pen_palette  : t_pen_array;
        CRTC_R12: std_logic_vector(7 downto 0);
        CRTC_R13: std_logic_vector(7 downto 0);
    END RECORD;

    constant DUMMY_VDREGS : t_video_regs := (
        Reg1 => (others => '0'),
        Reg2 => (others => '0'),
        Reg3 => (others => '0'),
        Reg4 => (others => '0'),
        Reg5 => (others => '0'),
        pen_palette => (others => (others => '0')), -- Fills all 16 array slots with "00000"
        CRTC_R12 => (others => '0'),
        CRTC_R13 => (others => '0')
    );

    type crtc_reg_array is array (0 to 17) of std_logic_vector(7 downto 0);

END defs_pkg;

-- Package Body 
PACKAGE BODY defs_pkg IS
    -- Empty body as only constants are declared
END defs_pkg;