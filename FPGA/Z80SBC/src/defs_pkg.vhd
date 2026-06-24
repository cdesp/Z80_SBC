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
    CONSTANT C_VD_PORT_ADDR    : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"90"; --Video Regs

    --LS139 Selection PORT Constants
    CONSTANT C_LS139_Y1     : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"40"; -- LAUD_MUX_N
    CONSTANT C_LS139_Y2     : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"41"; -- LAUD_CS_N (out) ,D7 --> select AY or SN
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

END defs_pkg;

-- Package Body 
PACKAGE BODY defs_pkg IS
    -- Empty body as only constants are declared
END defs_pkg;