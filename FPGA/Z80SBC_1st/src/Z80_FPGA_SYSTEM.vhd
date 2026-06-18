library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE work.defs_pkg.ALL; -- Import  I/O address constants
USE work.VD_types_pkg.ALL; 


-- Define the main component that interfaces with the physical pins on the PCB.
-- All signals are defined in the 3.3V logic domain (indicated by the 'L_' prefix)
-- where they connect to the FPGA's I/O pins.

entity Z80_FPGA_SYSTEM is 
    port (
        -- Global Clock/Reset (Mandatory inputs for the Clock_Manager and general FPGA operation)
        CLK_IN              : in  std_logic;                                   -- Main FPGA Clock (e.g., 50MHz ) E2

        -- J10 CONNECTOR 40 PIN (Z80 Bus, MMU Outputs, UART)
        TXD                 : out  std_logic;                                  -- P40 Data from FPGA to FT232(24) J11
        RXD                 : in std_logic;                                    -- P38 Data from FT232(25) to FPGA F7
        LRAMEN3_N           : out std_logic;                                   -- P36 1MB SRAM IC J8 (MMU nCE0)
        EA19                : out std_logic;                                   -- P34 EXTENDED ADDR BUS L9 (MMU Output)
        EA18                : out std_logic;                                   -- P32 EXTENDED ADDR BUS L10 (MMU Output)
        EA17                : out std_logic;                                   -- P30 EXTENDED ADDR BUS L7 (MMU Output)
        EA16                : out std_logic;                                   -- P28 EXTENDED ADDR BUS K7 (MMU Output)
        EA15                : out std_logic;                                   -- P26 EXTENDED ADDR BUS H1 (MMU Output)
        LRAMEN2_N           : out std_logic;                                   -- P24 512KB FLASH RAM IC G4 (MMU nCE1)
        EA14                : out std_logic;                                   -- P22 EXTENDED ADDR BUS J1 (MMU Output)
        EA13                : out std_logic;                                   -- P20 EXTENDED ADDR BUS E3 (MMU Output)
        LA0                 : inout std_logic;                                 -- P18 Z80 ADDR BUS E1
        LA1                 : inout std_logic;                                 -- P16 Z80 ADDR BUS F2
        LA2                 : inout std_logic;                                 -- P12 Z80 ADDR BUS B2
        LA3                 : inout std_logic;                                 -- P10 Z80 ADDR BUS L4
        LA4                 : inout std_logic;                                 -- P8 Z80 ADDR BUS G2
        LA5                 : inout std_logic;                                 -- P6 Z80 ADDR BUS J4
        LA6                 : inout std_logic;                                 -- P4 Z80 ADDR BUS L2
        LA7                 : inout std_logic;                                 -- P2 Z80 ADDR BUS K1

        CTS_N               : out std_logic;                                   -- P39 CTS from FPGA to FT232(RTS 22) J10
        DEV2                : out std_logic;                                   -- P37 DEVICE SEL 2 (74LS138 C) F6
        DEV1                : out std_logic;                                   -- P35 DEVICE SEL 1 (74LS138 B) K8
        LD0                 : inout std_logic;                                 -- P33 Z80 DATA BUS K9
        LD1                 : inout std_logic;                                 -- P31 Z80 DATA BUS K10
        LD2                 : inout std_logic;                                 -- P29 Z80 DATA BUS L8
        LD3                 : inout std_logic;                                 -- P27 Z80 DATA BUS J7
        LD4                 : inout std_logic;                                 -- P25 Z80 DATA BUS H2
        LD5                 : inout std_logic;                                 -- P23 Z80 DATA BUS H4
        LD6                 : inout std_logic;                                 -- P21 Z80 DATA BUS J2
        LD7                 : inout std_logic;                                 -- P19 Z80 DATA BUS D1
        LA15                : inout std_logic;                                 -- P17 Z80 ADDR BUS A1
        LA14                : inout std_logic;                                 -- P15 Z80 ADDR BUS F1
        LA13                : inout std_logic;                                 -- P13 Z80 ADDR BUS C2
        LA12                : inout std_logic;                                 -- P9 Z80 ADDR BUS L3
        LA11                : inout std_logic;                                 -- P7 Z80 ADDR BUS G1
        LA10                : inout std_logic;                                 -- P5 Z80 ADDR BUS K4
        LA9                 : inout std_logic;                                 -- P3 Z80 ADDR BUS L1
        LA8                 : inout std_logic;                                 -- P1 Z80 ADDR BUS K2

        -- J11 CONNECTOR 12 PIN (PS/2 & Z80 Control)
        LKB_DATA            : inout std_logic;                                 -- P5 PS/2 Data Line H5
        LKB_CLOCK           : inout std_logic;                                 -- P7 PS/2 Clock Line H8
        LRESET_N            : in  std_logic;                                   -- P9 Global Reset G7 (Input from Z80 Logic/Button)
        LBUSACK_N           : in  std_logic;                                   -- P11 Z80 BUS ACK F5 (Input from Z80)

        LCLOCK              : out std_logic;                                   -- P6 Z80 Clock Pin J5 (Output to Z80)
        LINT_N              : out std_logic;                                   -- P8 Interrupt Request H7 (Output to Z80)
        LBUSREQ_N           : out std_logic;                                   -- P10 Bus Request G8 (Output to Z80)
        LWR_N               : out std_logic;                                 -- P12 Low-Voltage Write Strobe G5 (Output from MMU/FPGA) input for flashprog

        -- J12 CONNECTOR 12 PIN (Z80 Control Inputs & Audio)
        LWR_CPU_N           : in  std_logic;                                   -- P5 Z80 /WR_N signal from Z80 L5
        L_RD_N              : inout  std_logic;                                -- P7 Low-Voltage Read Strobe K11 (Input from Z80) 
        L_IORQ_N            : in  std_logic;                                   -- P9 Low-Voltage I/O Request E11 (Input from Z80)
        L_MREQ_N            : in  std_logic;                                   -- P11 Low-Voltage Memory Request A11 (Input from Z80)

        L_M1_N              : in std_logic;                                    -- P6 Z80 M1 K5 (Input from Z80)
        L_NMI_N             : inout std_logic;                                 -- P8 Z80 NMI InOut signal def IN L11
        SCL                 : out std_logic;                                   -- P10 SCL E10
        SDA                 : inout std_logic;                                 -- P12 SDA A10
        
        -- J13 CONNECTOR 12 PIN (HDMI/DVI CONNECTIONS) Only the positive the negative are handled as PAIR
        D2N                 : out std_logic;                                   -- P5 TMDS Data Negative 2   C11
        D1N                 : out std_logic;                                   -- P7 TMDS Data Negative 1   B11
        D0N                 : out std_logic;                                   -- P9 TMDS Data Negative 0   D11
        CKN                 : out std_logic;                                   -- P11 TMDS Clock Negative   G11

        D2P                 : out std_logic;                                   -- P6 TMDS Data Positive 2   C10
        D1P                 : out std_logic;                                   -- P8 TMDS Data Positive 1   B10
        D0P                 : out std_logic;                                   -- P10 TMDS Data Positive 0  D10
        CKP                 : out std_logic                                    -- P12 TMDS Clock Positive   G10

    );
end Z80_FPGA_SYSTEM;

  


architecture structural of Z80_FPGA_SYSTEM is

 

    -- =========================================================================
    -- INTERNAL SIGNALS & STRUCTURAL COMPONENTS (Add your component declarations here)
    -- =========================================================================
    
-- Test module bridge signals
signal test_addr_bus   : std_logic_vector(18 downto 0);
signal test_data_bus   : std_logic_vector(7 downto 0);
signal test_we_n       : std_logic;
signal test_oe_n       : std_logic;
signal test_ce_n       : std_logic;
signal stest_ce_n     : std_logic;

signal s_start_test    : std_logic := '0';
signal s_test_running  : std_logic;
signal s_test_passed   : std_logic;
signal s_test_failed   : std_logic;

    -- Example internal signal to manage the system power-up/safe state
    signal system_initialized : std_logic := '0'; -- Set to '1' only when your FPGA PLL is locked and ready
    signal esp_control : std_logic := '0'; 
    signal tst_data_out   : std_logic_vector(7 downto 0) := (others => '0');
    signal tst_data_in    : std_logic_vector(7 downto 0) := (others => '0');
    signal tst_addr       : std_logic_vector(15 downto 0) := (others => '0');
    signal tst_bus_oe     : std_logic := '0';
    signal tst_we_n       : std_logic := '1';
    signal tst_rd_n       : std_logic := '1';
    signal tst_ce_n       : std_logic := '1';
    signal tst_mmu        : std_logic_vector(3 downto 0) := (others => '0');


  -- ***************************************************************
    -- ** SIGNALS FOR ASYNCHRONOUS RESET SYNCHRONIZATION **
    -- ***************************************************************
    signal reset_n_sync1    : std_logic := '1'; -- Stage 1 (Active Low)
    signal reset_n_sync2    : std_logic := '1'; -- Synchronized Reset (Active Low)
    signal reset_a_sync     : std_logic;        -- Synchronized Reset (Active High) for DPVRAM
    -- ***************************************************************

 -- Derived Clock Signals
    signal CLK_Z80_INT          : std_logic := '0'; -- Z80 Operating Clock (Output from Clock Manager)
    signal CLK_PIXEL_INT        : std_logic := '0'; -- 40 Mhz Video Clock (Output from Clock Manager)
    signal CLK_SN76489_INT      : std_logic := '0'; -- 4MHz Audio Clock
    signal CLK_AY38912_INT      : std_logic := '0'; -- 2MHz Audio Clock
    signal CLK_TMDS_INT         : std_logic := '0'; -- 200MHz TMDS Clock
    signal clock_en_n           : std_logic := '0'; -- Main Clock disable when 0

    signal clk_1_8432mhz   : std_logic; -- for UART

 -- Clock Manager Control Register
    signal Z80_CLK_SEL_REG      : std_logic_vector(7 downto 0) := (others => '0'); -- Default to 2MHz (selection '000')
    signal nCLK_SEL_WR          : std_logic; -- Write strobe for the clock selection register




    -- ***************************************************************
    -- Signals for the UART (16C550 compatible) component
    -- These bridge the Z80 bus logic to the actual UART core instance.
    -- ***************************************************************
--signal s_z80_addr      : std_logic_vector(7 downto 0);
signal s_z80_data_in   : std_logic_vector(7 downto 0);
signal s_z80_data_out  : std_logic_vector(7 downto 0);
signal s_z80_iorq_n    : std_logic;
signal s_z80_rd_n      : std_logic;
signal s_z80_wr_n      : std_logic;
signal s_z80_int_n     : std_logic;
signal UART_nCS        : std_logic;
signal s_uart_data_out : std_logic_vector(7 downto 0);
signal sCTS_N          : std_logic;
signal s_TestSig       : std_logic;




-- Debounce tracking (Assuming a slow 100Hz to 1kHz sample clock, or a large counter)
signal nmi_sync_reg : std_logic_vector(2 downto 0) := (others => '1');
signal nmi_debounced : std_logic := '1';
signal nmi_debounced_prev : std_logic := '1';
-- Signal to safely read what the NMI line is doing
signal nmi_input_clean : std_logic;
-- Internal control signal. Set this to '1' when the FPGA needs to pull the NMI pin low.
signal fpga_drive_nmi_low : std_logic := '0';

-- Debounce timer counter (Adjust maximum value based on your master clock speed)
-- To get ~10ms of filter time with a 50MHz clock, count to 500,000.
signal debounce_counter : integer range 0 to 500000 := 0;

-- The final usable, clean trigger signal
signal nmi_triggered : std_logic := '0';

signal flash_prog : std_logic := '1';
signal inRD_n : std_logic := '1';
signal inWR_n : std_logic := '1';
signal sWRn : std_logic := '1';
signal sram_wr_reg : std_logic := '1';
 

    -- --- Internal Bus Vectors (For easy use within the FPGA logic) ---
    -- PHYS_ADDR_BUS_INT is the full 21-bit physical address for memory access (A0-A20)
    signal PHYS_ADDR_BUS_INT    : std_logic_vector(19 downto 0);
    signal Z80_LA_BUS_INT       : std_logic_vector(15 downto 0);
    signal Z80_DATA_IN_INT      : std_logic_vector(7 downto 0);
    signal Z80_DATA_OUT_INT     : std_logic_vector(7 downto 0);
    signal inpRD                : std_logic;
    signal inpWR_CPU            : std_logic;
    signal sIsDataOut           : std_logic;--if we ouput data


-- Internal synchronous control signals
    signal vram_wr_reg1    : std_logic := '1';
    signal vram_wr_reg2    : std_logic := '1';
    signal write_pulse     : std_logic := '0';
    
    signal vram_ce_reg1    : std_logic := '1';
    signal vram_ce_reg2    : std_logic := '1';

-- Signals to capture the ESP32 bus inputs safely
    signal esp_wr_reg1    : std_logic := '0';
    signal esp_wr_reg2    : std_logic := '0';
    signal write_execute  : std_logic := '0';
    
    signal addr_latched   : std_logic_vector(15 downto 0) := (others => '0');
    signal data_latched   : std_logic_vector(7 downto 0)  := (others => '0');
-- Signal declarations to add to your architecture preamble:
signal wr_n_reg1      : std_logic := '1';
signal wr_n_reg2      : std_logic := '1';
signal write_strobe   : std_logic := '0';


    signal CLK_PIXEL_SYS      : std_logic;      -- High-speed Video Clock
    -- Video Ram Signals
    signal VRAM_DATA_TO_CPU   : std_logic_vector(7 downto 0); -- Data read from VRAM Port A
    signal VRAM_DATA_TO_VCTRL : std_logic_vector(7 downto 0); -- Data read from VRAM Port B (Pixel data)
    signal VCTRL_ADDR_BUS     : std_logic_vector(15 downto 0); -- Address from the Video Controller

    -- INTERNAL RAM SIGNALS
    signal VRAM_CE_CPU      : std_logic; 
    signal VRAM_WR          : std_logic; 
    signal VRAM_nCE         : std_logic :='1';


-- signals fro video generation
    -- 2. Internal Video Bus Signals
    signal video_timing     : video_bus_in;
    
    -- Video Output from V80 System
    signal v80_bus_out      : video_bus_out;
    -- Video Output from a second system (e.g., Terminal/Text Mode)
    signal text_bus_out     : video_bus_out;
    -- The multiplexed bus sent to the HDMI controller
    signal selected_video   : video_bus_out;

    -- 3. Control Signals
    signal video_selection  : std_logic := '0'; -- 0 = V80, 1 = TextMode
    signal reg_video_sel_n  : std_logic;
    signal VD_DSn           : std_logic; --for video registers


 component Clock_Manager
        port (
            CLK_IN              : in  std_logic;
            RST_N               : in  std_logic;
            Z80_CLK_SEL         : in  std_logic_vector(7 downto 0);
            CLK_Z80             : out std_logic;
            CLK_PIXEL           : out std_logic;
            CLK_SN76489         : out std_logic;
            CLK_AY38912         : out std_logic
        );
  end component;

    component Clock_TMDS
       port (
            clkin :in std_logic;
            clkout0 : out std_logic;
            mdclk : in std_logic; 
       );
    end component;

  --------------------------------------------------------------------------------
    -- Component Declaration: 16550D UART
    --------------------------------------------------------------------------------
   -- 1. Fractional Clock Divider Component
component clk_div_18432 is
    port (
        clk_in   : in  std_logic;
        rst      : in  std_logic;
        clk_out  : out std_logic
    );
end component;


component z80_to_gowin_16550_wrapper is
    port (
        CLK_FPGA        : in  std_logic; -- 50MHz Master Clock
        CLK_Z80         : in  std_logic; -- 4MHz Z80 System Clock
        rst_high        : in  std_logic; -- Active High system reset
        
        -- Z80 Hardware Bus Interface
        DEV_CS_N        : in  std_logic; -- Active Low from Z80 decoding
        WRcpu_N         : in  std_logic; -- Active Low Z80 Write Strobe
        RDcpu_N         : in  std_logic; -- Active Low Z80 Read Strobe
        ADDR_BUS        : in  std_logic_vector(2 downto 0);  -- A2, A1, A0
        DATA_BUS_IN     : in  std_logic_vector(7 downto 0);  -- Z80 Data Bus Out (from CPU)
        DATA_BUS_OUT    : out std_logic_vector(7 downto 0);  -- Z80 Data Bus In (to CPU)

        testSig         : out  std_logic;
        
        -- Physical Serial Interface (FT232 connection)
        sRXD             : in  std_logic; -- Serial Data In
        sTXD             : out std_logic; -- Serial Data Out
        sCTSn            : out std_logic  -- Output to tell FT232 to stop/go
    );
end component;


  component DPVRAM is
    port (
            douta: out std_logic_vector(7 downto 0); -- Port A: Z80 Read Data
            doutb: out std_logic_vector(7 downto 0); -- Port B: Video Read Data
            clka: in std_logic;                      -- Port A: Z80 Clock
            ocea: in std_logic;                      -- Port A: Output Clock Enable
            cea: in std_logic;                       -- Port A: Chip Enable
            reseta: in std_logic;                    -- Port A: Reset
            wrea: in std_logic;                      -- Port A: Write Enable
            clkb: in std_logic;                      -- Port B: TMDS Clock
            oceb: in std_logic;                      -- Port B: Output Clock Enable
            ceb: in std_logic;                       -- Port B: Chip Enable
            resetb: in std_logic;                    -- Port B: Reset
            wreb: in std_logic;                      -- Port B: Write Enable (for video side)
            ada: in std_logic_vector(15 downto 0);   -- Port A: Z80 Address (A0-A15)
            dina: in std_logic_vector(7 downto 0);   -- Port A: Z80 Data In
            adb: in std_logic_vector(15 downto 0);   -- Port B: Video Address (A0-A15)
            dinb: in std_logic_vector(7 downto 0)    -- Port B: Video Data In
    );
    end component;

component z80_bridge_decoder is
    Port (
        clk          : in  STD_LOGIC;
        z80_addr     : in  STD_LOGIC_VECTOR (15 downto 0);
        z80_data     : inout STD_LOGIC_VECTOR (7 downto 0);
        z80_mreq_n   : in  STD_LOGIC;
        z80_rd_n     : in  STD_LOGIC;
        z80_wr_n     : in  STD_LOGIC;
        LRAMEN3_N    : out STD_LOGIC
    );
end component;

    --****************************************************************
    -- Video system
    component hdmi_video_subsystem is
        port (
            CLK_PIXEL       : in  std_logic;
            CLK_TMDS        : in  std_logic;
            nRESET          : in  std_logic;
            VIDEO_BUS_IN    : in  video_bus_out;
            VIDEO_BUS_TIMING: out video_bus_in;
            CKP, CKN        : out std_logic;
            D0P, D0N        : out std_logic;
            D1P, D1N        : out std_logic;
            D2P, D2N        : out std_logic
        );
    end component;

    component video_system_v80 is
        port (
            V_IN            : in  video_bus_in;
            V_OUT           : out video_bus_out;
            Z80_CLK         : in  std_logic;
            Z80_WR_N        : in  std_logic;
            Z80_ADDR        : in  std_logic_vector(3 downto 0);
            Z80_DATA        : in  std_logic_vector(7 downto 0);
            REG_SEL_N       : in  std_logic;
            VRAM_DATA       : in  std_logic_vector(7 downto 0);
            VRAM_ADDR       : out std_logic_vector(15 downto 0)
        );
    end component;


signal stestsram: std_logic := '0';

begin

-- Dynamic bidirectional routing for the data lines during test mode
--LD0 <= test_data_bus(0) when (stestsram = '0' and test_we_n = '0') else VRAM_DATA_TO_CPU(0) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '0' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD1 <= test_data_bus(1) when (stestsram = '0' and test_we_n = '0') else VRAM_DATA_TO_CPU(1) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD2 <= test_data_bus(2) when (stestsram = '0' and test_we_n = '0') else VRAM_DATA_TO_CPU(2) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD3 <= test_data_bus(3) when (stestsram = '0' and test_we_n = '0') else VRAM_DATA_TO_CPU(3) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD4 <= test_data_bus(4) when (stestsram = '0' and test_we_n = '0') else VRAM_DATA_TO_CPU(4) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD5 <= test_data_bus(5) when (stestsram = '0' and test_we_n = '0') else VRAM_DATA_TO_CPU(5) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD6 <= test_data_bus(6) when (stestsram = '0' and test_we_n = '0') else VRAM_DATA_TO_CPU(6) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD7 <= test_data_bus(7) when (stestsram = '0' and test_we_n = '0') else VRAM_DATA_TO_CPU(7) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';

--LD0 <= test_data_bus(0) when (stestsram = '0' and test_oe_n = '0') else 'Z';
--LD1 <= test_data_bus(1) when (stestsram = '0' and test_oe_n = '0') else 'Z';
--LD2 <= test_data_bus(2) when (stestsram = '0' and test_oe_n = '0') else 'Z';
--LD3 <= test_data_bus(3) when (stestsram = '0' and test_oe_n = '0') else 'Z';
--LD4 <= test_data_bus(4) when (stestsram = '0' and test_oe_n = '0') else 'Z';
--LD5 <= test_data_bus(5) when (stestsram = '0' and test_oe_n = '0') else 'Z';
--LD6 <= test_data_bus(6) when (stestsram = '0' and test_oe_n = '0') else 'Z';
--LD7 <= test_data_bus(7) when (stestsram = '0' and test_oe_n = '0') else 'Z';


-- Feed incoming pin data back into the test module input channel when reading
test_data_bus <= (LD7 & LD6 & LD5 & LD4 & LD3 & LD2 & LD1 & LD0) when (test_we_n = '0') else (others => 'Z');
    
test_addr_bus <= ( EA18 & EA17 & EA16 & LA15 & LA14 & LA13 & LA12 & LA11 & LA10 & LA9 & LA8 & LA7 & LA6 & LA5 & LA4 & LA3 & LA2 & LA1 & LA0);
 
 
 
test_oe_n <= inpRD ;
test_we_n <= inpWR_CPU when (to_integer(unsigned(test_addr_bus)) < 204 or to_integer(unsigned(test_addr_bus)) > 1500) else '1';
--LWR_N<= LWR_CPU_N;

     

LA0<='Z';
LA1<='Z';
LA2<='Z';
LA3<='Z';
LA4<='Z';
LA5<='Z';
LA6<='Z';
LA7<='Z'; 
LA8<='Z';
LA9<='Z';
LA10<='Z';
LA11<='Z';
LA12<='Z';
LA13<='Z';
LA14<='Z';
LA15<='Z';


--LA0  <= test_addr_bus(0)  when (stestsram = '0') else 'Z'; -- Or your normal assignment here
--LA1  <= test_addr_bus(1)  when (stestsram = '0') else 'Z';
--LA2  <= test_addr_bus(2)  when (stestsram = '0') else 'Z';
--LA3  <= test_addr_bus(3)  when (stestsram = '0') else 'Z';
--LA4  <= test_addr_bus(4)  when (stestsram = '0') else 'Z';
--LA5  <= test_addr_bus(5)  when (stestsram = '0') else 'Z';
--LA6  <= test_addr_bus(6)  when (stestsram = '0') else 'Z';
--LA7  <= test_addr_bus(7)  when (stestsram = '0') else 'Z';
--LA8  <= test_addr_bus(8)  when (stestsram = '0') else 'Z';
--LA9  <= test_addr_bus(9)  when (stestsram = '0') else 'Z';
--LA10 <= test_addr_bus(10) when (stestsram = '0') else 'Z';
--LA11 <= test_addr_bus(11) when (stestsram = '0') else 'Z';
--LA12 <= test_addr_bus(12) when (stestsram = '0') else 'Z';

-- Since the test only tracks addresses up to 520, pull upper lines safely low
--LA13 <= '0' when (stestsram = '0') else 'Z';
--LA14 <= '0' when (stestsram = '0') else 'Z';
--LA15 <= '0' when (stestsram = '0') else 'Z';
 

tst_mmu <= std_logic_vector(unsigned(test_addr_bus(15 downto 12)) - 2);


EA13 <= 'Z' when flash_prog='0' else test_addr_bus(13) when (stestsram = '0') and stest_ce_n='1' else tst_mmu(1) when stest_ce_n='0' else 'Z';
EA14 <= 'Z' when flash_prog='0' else test_addr_bus(14) when (stestsram = '0') and stest_ce_n='1' else tst_mmu(2) when stest_ce_n='0' else 'Z';
EA15 <= 'Z' when flash_prog='0' else test_addr_bus(15) when (stestsram = '0') and stest_ce_n='1' else tst_mmu(3) when stest_ce_n='0' else 'Z';

--EA13 <= test_addr_bus(13) when (stestsram = '0') and stest_ce_n='1' else '0' when stest_ce_n='0' else 'Z';
--EA14 <= test_addr_bus(14) when (stestsram = '0') else 'Z';
--EA15 <= test_addr_bus(15) when (stestsram = '0') else 'Z';
EA16 <= 'Z' when flash_prog='0' else '0' when (stestsram = '0') else 'Z';
EA17 <= 'Z' when flash_prog='0' else '0' when (stestsram = '0') else 'Z';
EA18 <= 'Z' when flash_prog='0' else '0' when (stestsram = '0') else 'Z';
EA19 <= 'Z' when flash_prog='0' else '0' when (stestsram = '0') else 'Z';

    -- 3. Control Signal Conditional Overrides
  --  EA13 <= 'Z'; 
  --  EA14 <= 'Z'; 
  --  EA15 <= 'Z'; 
  --  EA16 <= 'Z';
  --  EA17 <= 'Z'; 
  --  EA18 <= 'Z'; 
  -- EA19 <= 'Z';  

 
 
inWR_n <= LWR_CPU_N when (stestsram = '0') else to_X01(LWR_N);
inRD_n <= to_X01(L_RD_N);

 -- LRAMEN3_N <= test_ce_n when (stestsram = '0') else '0' when flash_prog='0' else '1';
 -- LWR_N <= test_we_n when (stestsram = '0') else 'Z';
 -- L_RD_N <= test_oe_n when (stestsram = '0') else 'Z';
 
LRAMEN2_N <= '0' when flash_prog='0' else stest_ce_n;  --outer chip enable
sWRn <= LWR_CPU_N when stest_ce_n='0' AND L_MREQ_N='0'  else 'Z' when flash_prog='0' else '1'; -- z when flashing
--LWR_N <= LWR_CPU_N when stest_ce_n='0' AND L_MREQ_N='0'  else '1'; -- z when flashing
L_RD_N <='Z' when LBUSACK_N='0' else 'Z';
   
test_ce_n <=  stest_ce_n;    

LWR_N <= 'Z' when flash_prog='0' else sWRn;
--LWR_N <= 'Z' when flash_prog='0' else sram_wr_reg;

    --debug     
    SCL <= stest_ce_n;
    --SDA <= '0' when L_IORQ_N='0' and L_RD_N='0' else '1';
   SDA <= sWRn;--sWRn when stest_ce_n='0' else '1'; --s_TestSig;

                
-- This creates a "safe" write pulse that ends 
-- *before* the Z80 can possibly change the bus.
process(CLK_IN)
begin
    if rising_edge(CLK_IN) then
        -- We detect the start of the WR cycle
        if (LWR_CPU_N = '0' and stest_ce_n = '0') then
            sram_wr_reg <= '0'; 
        -- We force it high on the NEXT clock edge 
        -- This effectively "chops" the tail off the WR signal
        else
            sram_wr_reg <= '1';
        end if; 
    end if;
end process;



--FREEZE the cpu       
process(CLK_IN,reset_n_sync2)   
begin   
   if rising_edge(CLK_IN) then
        -- Logic: Freeze when (CE is low) AND (RD is low OR WR is low)
        -- We want to run the clock only if NOT (Freeze Condition)   
        if (stest_ce_n = '0' and flash_prog='1' and (inRD_n = '0')) then --or inWR_n = '0')) then
            LCLOCK <= CLK_Z80_INT;--'1'; -- FREEZE: CPU stops mid-access
        else
            LCLOCK <= CLK_Z80_INT; -- RUN: Normal operation
        end if;
    end if; 
end process;
  

 -- CTS_N <= s_test_running;
  --LKB_DATA <= s_test_passed;--inRD_n;
  --LKB_CLOCK <= s_test_failed;--inWR_n;

-- Hook your physical SRAM Chip Enable pin up similarly if available

  -- =========================================================================
-- 1. TRI-STATE BI-DIRECTIONAL DATA BUS (LD7 downto LD0)
-- =========================================================================
-- Outputs RAM data to the ESP32 only during a valid read cycle.
-- Otherwise, stays high-impedance ('Z') so the ESP32 can drive the bus.
--LD7 <= VRAM_DATA_TO_CPU(7) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD6 <= VRAM_DATA_TO_CPU(6) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD5 <= VRAM_DATA_TO_CPU(5) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD4 <= VRAM_DATA_TO_CPU(4) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD3 <= VRAM_DATA_TO_CPU(3) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD2 <= VRAM_DATA_TO_CPU(2) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD1 <= VRAM_DATA_TO_CPU(1) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '1' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';
--LD0 <= VRAM_DATA_TO_CPU(0) when (VRAM_CE_CPU = '0' and inRD_n = '0') else '0' when (VRAM_CE_CPU = '0' and inWR_n = '1') else 'Z';

-- Combine the split data lines into your internal input bus for writing
Z80_DATA_IN_INT <= LD7 & LD6 & LD5 & LD4 & LD3 & LD2 & LD1 & LD0;
Z80_LA_BUS_INT <= (LA15 & LA14 & LA13 & LA12 & LA11 & LA10 & LA9 & LA8 & LA7 & LA6 & LA5 & LA4 & LA3 & LA2 & LA1 & LA0);

-- C. Z80 Data Multiplexer (Determining which device drives the bus for a Z80 read)
    -- This internal signal selects the data to drive onto the tristate bus based on which chip enable is active.
Z80_DATA_OUT_INT <= 
        VRAM_DATA_TO_CPU      when VRAM_nCE = '0' else   -- VRAM selected
        test_data_bus         when stestsram = '0' and L_RD_N = '0' and L_MREQ_N='0' and stest_ce_n='1' else --read from internal ram
        s_uart_data_out        when UART_nCS = '0' and L_RD_N = '0' else -- UART read selected  
  --      i2c_data_out_s        when i2c_data_oe_s ='0' and i2c_master_active_s = '1' else --data output enable fpga-->PC9665
  --      ps2_rx_data           when PS2_DSn ='0' and L_RD_N = '0' else --ps/2 keyboard read
        (others => 'Z');                           -- Default if no device is selected for read

sIsDataOut <= '1' when flash_prog='0' else '0' when (VRAM_nCE = '0' or (stest_ce_n='1' and L_MREQ_N='0') or UART_nCS='0') else '1';

inpRD <= L_RD_N;   
inpWR_CPU <= LWR_CPU_N;  

    -- C. Data Bus (LD0-LD7) Tristate output
    -- Data is driven when Z80_DATA_OE is asserted (TBD logic)
    LD7 <= Z80_DATA_OUT_INT(7) when L_RD_N = '0' and sIsDataOut='0' else 'Z';
    LD6 <= Z80_DATA_OUT_INT(6) when L_RD_N = '0' and sIsDataOut='0' else 'Z';
    LD5 <= Z80_DATA_OUT_INT(5) when L_RD_N = '0' and sIsDataOut='0' else 'Z';
    LD4 <= Z80_DATA_OUT_INT(4) when L_RD_N = '0' and sIsDataOut='0' else 'Z';
    LD3 <= Z80_DATA_OUT_INT(3) when L_RD_N = '0' and sIsDataOut='0' else 'Z';
    LD2 <= Z80_DATA_OUT_INT(2) when L_RD_N = '0' and sIsDataOut='0' else 'Z';
    LD1 <= Z80_DATA_OUT_INT(1) when L_RD_N = '0' and sIsDataOut='0' else 'Z';
    LD0 <= Z80_DATA_OUT_INT(0) when L_RD_N = '0' and sIsDataOut='0' else 'Z';


-- =========================================================================
-- 2. ADDRESS BUS MAPPING (Individual Pins to 21-bit Vector)
-- =========================================================================
-- Lower 8 bits (Assuming LA0 to LA7 are mapped elsewhere or handled via lower address lines)
PHYS_ADDR_BUS_INT(7 downto 0) <= LA7 & LA6 & LA5 & LA4 & LA3 & LA2 & LA1 & LA0; 

-- Middle bits from your inout LA pins
PHYS_ADDR_BUS_INT(8)  <= LA8;
PHYS_ADDR_BUS_INT(9)  <= LA9;
PHYS_ADDR_BUS_INT(10) <= LA10;
PHYS_ADDR_BUS_INT(11) <= LA11;
PHYS_ADDR_BUS_INT(12) <= LA12;
-- Extended upper bits mapped directly from your EA input pins
PHYS_ADDR_BUS_INT(13) <= '0';--EA13;
PHYS_ADDR_BUS_INT(14) <= '0';-- EA14;
PHYS_ADDR_BUS_INT(15) <= '0';-- EA15;
PHYS_ADDR_BUS_INT(16) <= '0';-- EA16;
PHYS_ADDR_BUS_INT(17) <= '0';-- EA17;
PHYS_ADDR_BUS_INT(18) <= '0';-- EA18;
PHYS_ADDR_BUS_INT(19) <= '0';-- EA19;


   UART_nCS <= '0' when L_IORQ_N = '0' and  Z80_LA_BUS_INT(7 downto 3) = "00100" else '1';

     
--    LWR_N  <= tst_we_n when (esp_control = '1') else 'Z'; 
--    L_RD_N <= tst_rd_n when (esp_control = '1') else 'Z'; 
    --LRAMEN2_N <= tst_ce_n when (flash_prog = '0') else 'Z'; --FLASH RAM
--    LRAMEN2_N <= '1';
  -- LRAMEN3_N <= '0' when (flash_prog = '0') else '1';  --SRAM
    LRAMEN3_N <= '1';
   --VRAM_CE_CPU <= '0' when (flash_prog = '0') else '1';    --Internal DPRAM
    VRAM_CE_CPU <= '1';
    
    --CTS_N <= LRAMEN3_N;--reset_a_sync;

    VRAM_WR <=not inWR_n;
    
    

  
   -- inWR_n <= to_X01(LWR_N) when (flash_prog = '0') else '1';
   -- inRD_n <= to_X01(L_RD_N) when (flash_prog = '0') else '1';
 --   LWR_N  <=  'Z'; 
  --  L_RD_N <=  'Z';
 --   inWR_n <= LWR_N when flash_prog='0' else '1';
  
 --   inRD_n <= L_RD_N when flash_prog='0' else '1';


   
    

    esp_control <= '0'; --disbaled
    



    -- ***************************************************************
    -- ** RESET SYNCHRONIZATION PROCESS (Active-Low LRESET_N to CLK) **
    -- ***************************************************************
    -- This synchronizer converts the asynchronous LRESET_N to a reliable,
    -- synchronous signal (reset_n_sync2) in the CLK domain.
    PROCESS (CLK_Z80_INT)
    BEGIN
        IF rising_edge(CLK_Z80_INT) THEN
            -- Reset propagation path (active low)
            reset_n_sync1 <= LRESET_N;
            reset_n_sync2 <= reset_n_sync1;
        END IF;
    END PROCESS;

    -- Invert the final synchronized active-low signal to get active-high reset for DPVRAM
    reset_a_sync <= NOT reset_n_sync2;

    
    clock_en_n <= '1'; -- temp
    

-- ***************************************************************
-- ** NMI BUTTON DEBOUNCER AND EDGE-TRIGGER DETECTOR **
-- ***************************************************************
process(CLK_IN,reset_n_sync2)
begin
    if rising_edge(CLK_IN) then
        -- 1. Pass through a shift register to eliminate metastability 
        nmi_sync_reg <= nmi_sync_reg(1 downto 0) & nmi_input_clean;        

        -- Default state: strobe is low unless an edge is explicitly detected
        nmi_triggered <= '0';

        -- 2. Debouncer Filter
        -- Wait for the input to remain absolutely stable for our timer duration
        if nmi_sync_reg(2) /= nmi_debounced then
            if debounce_counter = 500000 then -- (~10ms filter window at 50MHz)
                nmi_debounced <= nmi_sync_reg(2);
                debounce_counter <= 0;
            else
                debounce_counter <= debounce_counter + 1;
            end if;
        else
            debounce_counter <= 0; -- Reset counter if signal glitches back
        end if;

        -- 3. Edge Detection
        -- Track the history of the cleaned signal
        nmi_debounced_prev <= nmi_debounced;

        -- If it was high on the last clock cycle, but is low right now: Trigger!
        if (nmi_debounced_prev = '1' and nmi_debounced = '0') then
            nmi_triggered <= '1'; -- Fires high for exactly one clock cycle          
        end if;

    end if;
end process;


-- ***************************************************************
    -- ** CLOCK MANAGER INSTANTIATION **
    -- ***************************************************************
    
    clock_inst: Clock_Manager
        port map (
            CLK_IN              => CLK_IN,
            RST_N               => clock_en_n,
            Z80_CLK_SEL         => Z80_CLK_SEL_REG,         -- Input from Z80 control register
            CLK_Z80             => CLK_Z80_INT,             -- Output to Z80 (LCLOCK pin)
            CLK_PIXEL           => CLK_PIXEL_INT,            -- Output for DVI/HDMI serializer
            CLK_SN76489         => CLK_SN76489_INT,         -- Output for SN76489 (LAUD_CLK pin)  *** Not  used fixed clock
            CLK_AY38912         => CLK_AY38912_INT          -- Output for AY38912 (Internal signal) *** Not  used fixed clock
        );
        
    -- Connect Clock Manager outputs to physical pins   
    Z80_CLK_SEL_REG <= "00000001";

 TMDS_PLL_Core : Clock_TMDS
        port map (
            clkin           => CLK_IN,          -- Connects 50MHz external clock
            clkout0         => CLK_TMDS_INT,    -- Internal 200 MHz signal
            mdclk           => CLK_IN           -- Tie unused DRP clock to main clock for stability
        );

    -- =========================================================================
    -- SAFE STATE / INITIALIZATION ASSIGNMENTS
    -- =========================================================================
    -- Note: When 'system_initialized' is '0', the pins are forced to your safe state.
    -- Once your internal FPGA state machine takes over, swap these out for your real internal signals.

    -- 1. Memory Control (Disabled / High-Z or Pull-ups active externally)
    --LRAMEN3_N <= '1'; -- 1MB SRAM Disabled (Active Low)
    --LRAMEN2_N <= '1'; -- 512KB Flash Disabled (Active Low)

   -- LRAMEN2_N <= '0' when nmi_triggered='1' else '1' when reset_n_sync2='0' else LRAMEN2_N;
   -- LRAMEN2_N <= '1' when nmi_triggered='1' else '0';

-- ***************************************************************
-- ** STRUCTURALLY CLEAN CLOCK-ENABLE LATCH                     **
-- ***************************************************************
process(CLK_IN) -- Keep the rock-solid global system clock here
begin 
    if rising_edge(CLK_IN) then
        if reset_n_sync2 = '0' then
            flash_prog <= '1'; -- Default boot state            
        -- Use the trigger as a condition inside the clock domain
        elsif nmi_triggered = '1' then 
            flash_prog <= not flash_prog;--'0'; -- Latches high cleanly on the next clock tick!
        end if;
    end if;
end process;

    -- 2. Z80 Bus Masters & State Control
    LBUSREQ_N <= '0' when flash_prog='0' else '1'; -- Low to force Z80 into Tristate (Bus Acknowledgment requested)
    --LCLOCK    <= '0'; -- Keep Z80 clock low / parked
    LINT_N    <= 'H'; -- Pull-up state (Active Low Interrupt inactive)
-- ***************************************************************
-- ** OPEN-DRAIN INOUT BUFFER DESIGN                            **
-- ***************************************************************
-- 1. Always read the real-time state of the pin safely into our internal logic
nmi_input_clean <= L_NMI_N;
-- 2. Drive the pin: If our control signal is '1', pull it hard to '0'. 
-- Otherwise, release the line to 'Z' (High-Z) so the button or pull-up works!
L_NMI_N <= '0' when fpga_drive_nmi_low = '1' else 'Z';
   

  

    -- 6. HDMI / TMDS Outputs (Disabled Low)
--    D2N <= '0'; D2P <= '0';
--    D1N <= '0'; D1P <= '0';
--    D0N <= '0'; D0P <= '0';
--    CKN <= '0'; CKP <= '0';
   -- D2P <= '0';
   -- D1P <= '0';
   -- D0P <= '0';
   -- CKP <= '0';



    -- 7. Peripherals & Miscellaneous
    DEV1  <= '0';
    DEV2  <= '0';
   -- CTS_N <= '1'; -- Not Ready To Receive
--    SCL   <= '1';
   -- SDA   <= 'H'; -- I2C lines should rest high

    -- =========================================================================
    -- YOUR STRUCTURAL INSTANTIATIONS GO HERE
    -- =========================================================================
    -- component_inst : some_component port map (...);
-- =========================================================================

  
    -- 1. Synchronize and Edge-Detect the ESP32 Write Signal
    -- =========================================================================
    -- We sample the ESP32's write pin using a fast internal FPGA clock 
    -- (e.g., CLK_SYS, ideally 50MHz or higher) to find the exact moment the write ends.
    process(CLK_IN)
    begin
        if rising_edge(CLK_IN) then
            if reset_a_sync = '1' then
                wr_n_reg1    <= '1';
                wr_n_reg2    <= '1';
                write_strobe <= '0';
            else
                -- Double-register the asynchronous write line to prevent metastability
                wr_n_reg1 <= inWR_n;
                wr_n_reg2 <= wr_n_reg1;
                
                -- DETECT RISING EDGE OF inWR_n (The exact moment the ESP32 finishes the write)
                -- At this specific moment, the ESP32 address and data lines are completely stable.
                if (wr_n_reg1 = '1' and wr_n_reg2 = '0' and VRAM_CE_CPU = '0') then
                    write_strobe <= '1';
                    -- Safely capture the stable address bits for Port A (16-bit)
                    addr_latched <= PHYS_ADDR_BUS_INT(15 downto 0);
                else
                    write_strobe <= '0';
                end if;
            end if;
        end if;
end    process;

    -- =========================================================================
    -- 2. Connect directly to your Dual-Port RAM Block
    -- =========================================================================
 DPVRAM_Inst : entity work.DPVRAM
        port map (
            -- === Port A: Safe ESP32 Interface ===
            clka        => CLK_IN,
            reseta      => reset_a_sync,     
            
            -- Enable RAM block when ESP32 chip select is active (LOW)
            cea         => not VRAM_CE_CPU,  
            
            -- Fire the write enable ONLY for 1 system clock cycle at the end of the write strobe
            wrea        => not inWR_n,     
            
            -- Feed the safely latched, static address
            ada         => PHYS_ADDR_BUS_INT(15 downto 0),     
            
            dina        => Z80_DATA_IN_INT,      
            douta       => VRAM_DATA_TO_CPU,  -- Routes directly back to the LD tri-state buffer   
            ocea        => not inRD_n,                   

            -- === Port B: Video Controller Interface (Read-Only) ===
            clkb        => CLK_PIXEL_SYS,
            resetb      => reset_a_sync,     
            ceb         => '1',                   
            wreb        => '0',                   
            adb         => VCTRL_ADDR_BUS,        
            dinb        => (others => '0'),       
            doutb       => VRAM_DATA_TO_VCTRL,    
            oceb        => '1'                    
        );


-- =========================================================================
-- FLASH PROGRAMMER MODE DETECTOR & TEST TRIGGER
-- =========================================================================
process(CLK_IN)
begin
    if rising_edge(CLK_IN) then
        if reset_n_sync2 = '0' then
            s_start_test <= '0';
        else
            -- Automatically fire the self-test the EXACT moment 
            -- flash_prog transitions from '0' to '1'
            if flash_prog = '0' and s_test_running = '0' and s_test_passed = '0' and s_test_failed = '0' then
                s_start_test <= '1';  -- Fire the test loop
            else
                s_start_test <= '0';  -- Clear the trigger immediately (single pulse)
            end if;
        end if;
    end if;
end process;




u_z80_decoder : z80_bridge_decoder
    port map (
        clk          => CLK_IN,       -- Connect to your FPGA system clock
        z80_addr     => test_addr_bus(15 downto 0),-- Connect to the 16-bit Z80 address lines
        z80_data     => test_data_bus,   -- Connect to the 8-bit bidirectional Z80 data lines
        z80_mreq_n   => L_MREQ_N,   -- Connect to the Z80 /MREQ pin
        z80_rd_n     => test_oe_n,     -- Connect to the Z80 /RD pin
        z80_wr_n     => test_we_n,     -- Connect to the Z80 /WR pin
        
        LRAMEN3_N    => stest_ce_n     -- Connect to the physical external SRAM CE leg
    );


 --------------------------------------------------------------------------------
    -- UART 16550D Instantiation
    --------------------------------------------------------------------------------
 --------------------------------------------------------------------------------

      


u_uart_translator : z80_to_gowin_16550_wrapper
    port map (
        -- Global Clocks & Resets
        CLK_FPGA         => CLK_IN,              -- Your 50MHz oscillator input
        CLK_Z80          => CLK_Z80_INT,          -- Your 4MHz Z80 system clock
        rst_high         => reset_a_sync,        -- Your active-high reset signal

        -- Z80 Hardware Bus Interface
        DEV_CS_N         => UART_nCS,            -- Active-LOW chip select from your decoder
        WRcpu_N          => inpWR_CPU,              -- Active-LOW CPU write strobe
        RDcpu_N          => inpRD,              -- Active-LOW CPU read strobe
        ADDR_BUS         => Z80_LA_BUS_INT(2 downto 0), -- Direct connection to bottom 3 address bits
        DATA_BUS_IN      => Z80_DATA_IN_INT,     -- Data lines coming out of the Z80 CPU
        DATA_BUS_OUT     => s_uart_data_out,     -- <--- Connect this to your internal read-mux databus!

        testSig          => s_TestSig,

        -- Physical Serial Interface (External Pins)
        sRXD             => RXD,                 -- To physical RX pin driving the FT232
        sTXD             => TXD,                 -- To physical TX pin driving the FT232
        sCTSn            => sCTS_N                 -- To physical hardware flow control pin
    ); 
       
    CTS_N <= '0';-- s_uart_rtsn ;  
      
    

--****************************************************************
    -- Video system

    -- ***************************************************************
    -- ** HDMI PHYSICAL LAYER (The Consumer) **
    -- ***************************************************************
    U_HDMI_PHY : hdmi_video_subsystem
        port map (
            CLK_PIXEL        => CLK_PIXEL_INT,
            CLK_TMDS         => CLK_TMDS_INT,
            nRESET           => reset_n_sync2,
            VIDEO_BUS_IN     => selected_video,  -- The multiplexed signal
            VIDEO_BUS_TIMING => video_timing,    -- Common timing fed back to all producers
            CKP => CKP, CKN => CKN,
            D0P => D0P, D0N => D0N,
            D1P => D1P, D1N => D1N,
            D2P => D2P, D2N => D2N
        );

    -- ***************************************************************
    -- ** INSTANTIATION: VIDEO PRODUCERS **
    -- ***************************************************************
    
    -- Producer A: The V80 Graphics Engine
    U_PRODUCER_V80 : video_system_v80
        port map (
            V_IN       => video_timing,
            V_OUT      => v80_bus_out,
            Z80_CLK    => CLK_Z80_INT,
            Z80_WR_N   => LWR_N,
            Z80_ADDR   => Z80_LA_BUS_INT(3 downto 0),
            Z80_DATA   => Z80_DATA_IN_INT,
            REG_SEL_N  => '0', -- Assume selected for this example
            VRAM_DATA  => x"AA", -- Placeholder for VRAM connection
            VRAM_ADDR  => open
        );

    -- Producer B: A generic second system (Placeholder for interchangeability)
    -- This could be a text-mode controller, a debug overlay, or a splash screen.
    text_bus_out.r_8    <= x"FF" when ((video_timing.h_cnt / 16) mod 2 = 0) else x"00";
    text_bus_out.g_8    <= x"FF";
    text_bus_out.b_8    <= x"00";
    text_bus_out.h_sync <= '1';
    text_bus_out.v_sync <= '1';
    text_bus_out.de     <= '1';

    -- Video handler

    -- Video register from z80 is active
    reg_video_sel_n <= '0' when (VD_DSn = '0' and LWR_N = '0') else  '1';

    process(CLK_Z80_INT)
    begin
        if rising_edge(CLK_Z80_INT) then
            if reg_video_sel_n = '0' then
                video_selection <= Z80_DATA_IN_INT(0); -- Bit 0 chooses the system could expand to more
            end if;
        end if;
    end process;

    --this selects the video system
    selected_video <= v80_bus_out when video_selection = '0' else text_bus_out;

end structural;