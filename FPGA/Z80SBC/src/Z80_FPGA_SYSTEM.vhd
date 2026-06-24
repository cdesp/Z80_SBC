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
        DEV2                : out std_logic;                                   -- P37 DEVICE SEL 2 (74LS139 B) F6
        DEV1                : out std_logic;                                   -- P35 DEVICE SEL 1 (74LS139 A) K8
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

 
 -- --- Internal Bus Vectors (For easy use within the FPGA logic) ---
    -- PHYS_ADDR_BUS_INT is the full 21-bit physical address for memory access (A0-A20)
    signal PHYS_ADDR_BUS_INT    : std_logic_vector(20 downto 0);
    signal Z80_LA_BUS_INT       : std_logic_vector(15 downto 0);
    signal Z80_DATA_IN_INT      : std_logic_vector(7 downto 0);
    signal Z80_DATA_OUT_INT     : std_logic_vector(7 downto 0);
    signal nIORQ_r              : std_logic;
    signal nMREQ_r              : std_logic;
    signal nWR_CPU_r            : std_logic;
    signal nRD_CPU_r            : std_logic;

    -- Derived Clock Signals
    signal CLK_Z80_INT          : std_logic := '0'; -- Z80 Operating Clock (Output from Clock Manager)
    signal CLK_PIXEL_INT        : std_logic := '0'; -- 40 Mhz Video Clock (Output from Clock Manager)
    signal CLK_SN76489_INT      : std_logic := '0'; -- 4MHz Audio Clock
    signal CLK_AY38912_INT      : std_logic := '0'; -- 2MHz Audio Clock
    signal CLK_TMDS_INT         : std_logic := '0'; -- 200MHz TMDS Clock
    signal clock_en_n           : std_logic := '0'; -- Main Clock disable when 0
    
    -- MMU Signals
    signal MMU_EA_INT           : std_logic_vector(20 downto 13); -- Extended Address A13-A20
    signal MMU_nCE0             : std_logic; -- 1MB SRAM CE (LRAMEN3_N)
    signal MMU_nCE1             : std_logic; -- 512KB Flash CE (LRAMEN2_N)
    signal MMU_nCE2             : std_logic; -- 64KB Video RAM CE (Internal only)
    signal MMU_WR               : std_logic; --WR signal with write protect
    
    -- MMU Control Signals generated by the Bus Arbiter
    signal nINTMMU              : std_logic := '1'; -- Port 0: Map Registers (Active Low)
    signal nINTMMU_ro           : std_logic := '1'; -- Port 1: Set RO (Active Low)
    signal nINTMMU_rw           : std_logic := '1'; -- Port 2: Set RW (Active Low)
    
    -- General Control Signals
    signal nINT_REQ_PERIPH      : std_logic := '1'; -- Master Interrupt Request from all peripherals (Active Low)
    
    -- Video Ram Signals
    signal VRAM_DATA_TO_CPU     : std_logic_vector(7 downto 0); -- Data read from VRAM Port A
    signal VRAM_DATA_TO_VCTRL   : std_logic_vector(7 downto 0); -- Data read from VRAM Port B (Pixel data)
    signal CLK_PIXEL_SYS        : std_logic;      -- High-speed Video Clock
    signal VCTRL_ADDR_BUS       : std_logic_vector(15 downto 0); -- Address from the Video Controller

    -- Clock Manager Control Register
    signal Z80_CLK_SEL_REG      : std_logic_vector(7 downto 0) := (others => '0'); -- Default to 2MHz (selection '000')
    signal nCLK_SEL             : std_logic := '1'; -- Read/Write strobe for the clock selection register
    signal clk_reg_out          : std_logic_vector(7 downto 0) := (others => '0'); -- read the real mhz as number


    SIGNAL Z80_IO_ADDR          : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal sEnableDataOut       : std_logic :='1'; --Enables data output from the fpga to databus
    signal l_wait_n             : std_logic :='1'; --for wait states freezes cpu when 0
    

    -- ***************************************************************
    -- ** SIGNALS FOR ASYNCHRONOUS RESET SYNCHRONIZATION **
    -- ***************************************************************
    signal reset_n_sync1    : std_logic := '1'; -- Stage 1 (Active Low)
    signal reset_n_sync2    : std_logic := '1'; -- Synchronized Reset (Active Low)
    signal reset_a_sync     : std_logic;        -- Synchronized Reset (Active High) for DPVRAM
    signal nreset           : std_logic := '1'; -- Synchronized Reset (Active Low) copy of reset_n_sync2
    -- ***************************************************************

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
    --we are in flash ram mode when 0 currently triggered by NMI
    signal flash_prog : std_logic := '1';




    --BUS ARBITER 
    signal BADEV1           : std_logic;
    signal BADEV2           : std_logic;

    -- INTERNAL RAM SIGNALS
    signal VRAM_CE_CPU_N    : std_logic; 
    signal VRAM_CE_CPU      : std_logic; 
    signal VRAM_WR          : std_logic; 



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

  
    -- Signals for global bus arbitration (connect these to your physical pins)
    signal L_BUSRQ_N_S         : std_logic; -- Connect this to your physical /BUSRQ pin

    -- Signal declarations for PS/2 Keyboard
    signal ps2_rx_data    : std_logic_vector(7 downto 0);
    signal ps2_rx_ready   : std_logic;
    signal ps2_tx_data    : std_logic_vector(7 downto 0);
    signal ps2_tx_start   : std_logic := '0';
    signal ps2_tx_busy    : std_logic;
    signal ps2_ack_err    : std_logic;
    signal PS2_DSn        : std_logic;  --ps/2 keyboard port signal 
    signal wr_n_delayed   : std_logic := '1';

    -- signals fro video generation
    -- 2. Internal Video Bus Signals
    signal video_timing     : video_bus_in;
    
    -- Video Output from Video Systems
    signal v80_bus_out      : video_bus_out;  --demo
    signal atlas_bus_out    : video_bus_out;  --atlas video controller
    signal nb_bus_out       : video_bus_out;  --Newbrain video controller
    signal zx_bus_out       : video_bus_out;  --ZX Spectrum video controller
    signal am_bus_out       : video_bus_out;  --Amstrad video controller
    

    -- The multiplexed bus sent to the HDMI controller
    signal selected_video   : video_bus_out;

    -- 3. Control Signals
    signal video_selection : unsigned(3 downto 0) := (others => '0');
    signal reg_video_sel_n  : std_logic;
    signal VD_DSn           : std_logic; --for video registers


--debug signals
    signal capturedata : std_logic := '0';
    signal write_event : std_logic := '0';
    signal write_count : integer range 0 to 15 := 0;
    signal wr_strobe_d1, wr_strobe_d2 : std_logic := '1';
    signal z80_strobe_raw : std_logic;
    signal sync_reg1, sync_reg2, sync_reg3 : std_logic := '1';
signal pulse_timer : integer range 0 to 7 := 0;
signal event_processed : std_logic := '0';
    


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



    component Z80_Bus_Arbiter
        port (
            -- Z80 Side
            CLK               : in  std_logic;
            nRESET            : in  std_logic;
            Z80_IORQ_N        : in  std_logic;
            Z80_WR_N          : in  std_logic; -- Z80 Write Strobe
            Z80_RD_N          : in  std_logic; -- Z80 Read Strobe
            Z80_ADDR          : in  std_logic_vector(15 downto 0);
            -- MMU Control Outputs (Generated from I/O Decode)
            MMU_nMAP_REG_N    : out std_logic; -- nINTMMU
            MMU_nSET_RO_N     : out std_logic; -- nSET_RO
            MMU_nSET_RW_N     : out std_logic; -- nSET_RW
            -- Peripheral Decoding Outputs (74LS138 Inputs)
            DEV1              : out std_logic;
            DEV2              : out std_logic;
            CLK_SEL_RG_N      : out std_logic;
            UART_CS_N         : out std_logic;
            PS2_DS_N          : out std_logic;                    -- for PS/2 keyboard  
            VD_DS_N           : out std_logic;                    -- for Video
            -- Wait State Generation
            Z80_WAIT_N        : out std_logic;
            -- Interrupt Management
            INT_REQ_N         : in  std_logic; -- Master Peripheral Interrupt Request
            Z80_INT_N         : out std_logic
        );
    end component;

    component MMU is
        port (
            CLK             :  IN  STD_LOGIC;
            A13     : in  std_logic;
            A14     : in  std_logic;
            A15     : in  std_logic;
            nMREQ   : in  std_logic;
            nINTMMU : in  std_logic;    -- From I/O Decoder (MMU Mapping Port)
            nSET_RO : in  std_logic;    -- From I/O Decoder (Read-Only Port)
            nSET_RW : in  std_logic;    -- From I/O Decoder (Read/Write Port)
            nWR_CPU : in  std_logic;    -- Z80 Write Strobe
            nRESET  : in  std_logic;
            DATA    : in  std_logic_vector(7 downto 0);
            EA      : out std_logic_vector(20 downto 13);
            nWR_OUT : out std_logic;    -- Protected Write Strobe to Memory
            nCE0    : out std_logic;
            nCE1    : out std_logic;
            nCE2    : out std_logic;
            nCE3    : out std_logic;
            nCE4    : out std_logic
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

   --------------------------------------------------------------------------------
    -- Component Declaration: 16550D UART
    --------------------------------------------------------------------------------
    component gh_uart_16550 is
    	port(
    		clk      : in std_logic;
    		BR_clk   : in std_logic;
    		rst      : in std_logic;
    		CS       : in std_logic;
    		WR       : in std_logic;
    		ADD      : in std_logic_vector(2 downto 0);
    		D        : in std_logic_vector(7 downto 0);
    		
    		sRX	     : in std_logic;
    		CTSn     : in std_logic := '1';
    		DSRn     : in std_logic := '1';
    		RIn      : in std_logic := '1';
    		DCDn     : in std_logic := '1';
    		
    		sTX      : out std_logic;
    		DTRn     : out std_logic;
    		RTSn     : out std_logic;
    		OUT1n    : out std_logic;
    		OUT2n    : out std_logic;
    		TXRDYn   : out std_logic;
    		RXRDYn   : out std_logic;
    		
    		IRQ      : out std_logic;
    		B_CLK    : out std_logic;
    		RD       : out std_logic_vector(7 downto 0)
    		);
    end component;


    component PS2_Keyboard_Controller
        port (
            CLK             : in    std_logic;
            nRESET          : in    std_logic;

            -- Physical Interface (to SN74LVC1G07 or direct pins with pull-ups)
            PS2_CLK         : inout std_logic;
            PS2_DATA        : inout std_logic;

            -- Z80/System Interface (Raw Scan Codes)
            RX_DATA_O       : out   std_logic_vector(7 downto 0);
            RX_READY_O      : out   std_logic; -- Pulse high when raw byte received
        
            -- Command Interface (For LEDs / Initialization)
            TX_DATA_I       : in    std_logic_vector(7 downto 0);
            TX_START_I      : in    std_logic; -- Pulse high to send byte
            TX_BUSY_O       : out   std_logic;
            TX_ACK_ERROR_O  : out   std_logic  -- High if keyboard fails to ACK
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

    component AtlasVideo is
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


begin

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
    nreset <= reset_n_sync2;


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
    -- ** PIN TO INTERNAL VECTOR MAPPING (CONVENIENCE) **
    -- ***************************************************************

    PROCESS(CLK_Z80_INT)
    BEGIN
        IF rising_edge(CLK_Z80_INT) THEN
            -- Capture the buses synchronously
            Z80_LA_BUS_INT <= LA15 & LA14 & LA13 & LA12 & LA11 & LA10 & LA9 & LA8 &
                            LA7 & LA6 & LA5 & LA4 & LA3 & LA2 & LA1 & LA0;
        
            Z80_DATA_IN_INT <= LD7 & LD6 & LD5 & LD4 & LD3 & LD2 & LD1 & LD0;

        nIORQ_r <= L_IORQ_N; 
        nMREQ_r <= L_MREQ_N;
        nWR_CPU_r <= LWR_CPU_N;
        nRD_CPU_r <= L_RD_N;
        END IF;
     
    END PROCESS;
    
    -- C. Full Physical Address (A0-A20) construction
    -- A0-A12 from Z80; A13-A20 from MMU
    PHYS_ADDR_BUS_INT <= MMU_EA_INT & Z80_LA_BUS_INT(12 downto 0);

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
            CLK_SN76489         => CLK_SN76489_INT,         -- Output for SN76489 (LAUD_CLK pin)
            CLK_AY38912         => CLK_AY38912_INT          -- Output for AY38912 (Internal signal)
        );
      clock_en_n <= '1'; --TEMP??
  
    -- Connect Clock Manager outputs to physical pins
--    LCLOCK   <= CLK_Z80_INT;
  --  LAUD_CLK <= CLK_SN76489_INT; --not used
    -- CLK_TMDS_INT and CLK_AY38912_INT are used internally

    TMDS_PLL_Core : Clock_TMDS
        port map (
            clkin           => CLK_IN,          -- Connects 50MHz external clock
            clkout0         => CLK_TMDS_INT,    -- Internal 200 MHz signal
            mdclk           => CLK_IN           -- Tie unused DRP clock to main clock for stability
        );


    -- ***************************************************************
    -- ** Z80 CLOCK SELECTION REGISTER (Port 04H) **
    -- ***************************************************************
    
 -- The Z80 clock selection register write strobe is *dedicately* decoded here.
    -- nCLK_SEL is active low ('0') only when:
    -- 1. IORQ is active low (L_IORQ_N = '0')
    -- 2. WR is active low (LWR_CPU_N = '0')
    -- 3. Address lines A0-A7 match CLK_SEL_PORT_ADDR (x"04")
     
    -- Clock Select Register Latch
    -- Latching data synchronously with the main system clock (50MHz)
    process (CLK_IN, LRESET_N, Z80_CLK_SEL_REG)
    begin
        if LRESET_N = '0' then
            -- Reset to default speed (2MHz, selection "000")
            --Z80_CLK_SEL_REG <= (others => '0'); 
            Z80_CLK_SEL_REG <= "00000001"; --4 mhz            
        elsif rising_edge(CLK_IN) then
            -- Latch the data if it is an I/O Write cycle to port 04H
            if nCLK_SEL = '0' and nWR_CPU_r='0' then
                 Z80_CLK_SEL_REG <= Z80_DATA_IN_INT;                 
            end if;
        end if;

       WITH Z80_CLK_SEL_REG(2 DOWNTO 0) SELECT
         clk_reg_out <= 
            x"02" WHEN SEL_2MHZ_C,   -- 2 MHz
            x"04" WHEN SEL_4MHZ_C,   -- 4 MHz
            x"08" WHEN SEL_8MHZ_C,   -- 8 MHz
            x"0C" WHEN SEL_12MHZ_C,  -- 12 MHz
            x"10" WHEN SEL_16MHZ_C,  -- 16 MHz
            x"14" WHEN SEL_20MHZ_C,  -- 20 MHz
            x"0A" WHEN SEL_10MHZ_C,  -- 10 MHz
            x"02" WHEN OTHERS;       -- Default

    end process;

    -- ***************************************************************
    -- ** Z80 BUS ARBITER INSTANTIATION **
    -- ***************************************************************

    arbiter_inst: Z80_Bus_Arbiter
        port map (
            CLK               => CLK_Z80_INT,             -- Z80 Operating Clock
            nRESET            => reset_n_sync2,                -- System Reset (from external logic/button)
            Z80_IORQ_N        => nIORQ_r,                -- Z80 IORQ signal (Input)
            Z80_WR_N          => nWR_CPU_r,               -- Z80 Write Strobe (Input)
            Z80_RD_N          => nRD_CPU_r,                  -- Z80 Write Strobe (Input)
            Z80_ADDR          => Z80_LA_BUS_INT,          -- Z80 Address Bus (Input)
            -- MMU Control Outputs
            MMU_nMAP_REG_N    => nINTMMU,                 -- Output Port 0 (Map Registers)
            MMU_nSET_RO_N     => nINTMMU_ro,              -- Output Port 1 (Set RO)
            MMU_nSET_RW_N     => nINTMMU_rw,              -- Output Port 2 (Set RW)
            -- Peripheral Decoding (74LS138 Inputs)
            DEV1              => BADEV1,                    -- Output pin DEV1
            DEV2              => BADEV2,                    -- Output pin DEV2
            CLK_SEL_RG_N      => nCLK_SEL,             -- CPU Selection Clock Register
            UART_CS_N         => UART_nCS,                -- RS232 cs  
            PS2_DS_N          => PS2_DSn,                 -- ps/2 keyb
            VD_DS_N           => VD_DSn,                  -- video 
            -- Wait State Generation
            Z80_WAIT_N        => L_WAIT_N,                -- Output pin L_WAIT_N
            -- Interrupt Management
            INT_REQ_N         => nINT_REQ_PERIPH,         -- Master Peripheral Interrupt Request (TBD)
            Z80_INT_N         => LINT_N                   -- Output pin LINT_N
        );

    -- ***************************************************************
    -- ** 4. MMU INSTANTIATION **
    -- ***************************************************************

    mmu_inst: MMU
        port map (
            CLK     => CLK_Z80_INT,
            A13     => Z80_LA_BUS_INT(13),             -- LA13 from Z80 bus
            A14     => Z80_LA_BUS_INT(14),             -- LA14 from Z80 bus
            A15     => Z80_LA_BUS_INT(15),             -- LA15 from Z80 bus
            nMREQ   => nMREQ_r,                       -- Z80 Memory Request (Input)
            nINTMMU => nINTMMU,                        -- MMU Mapping Port (from Arbiter)
            nSET_RO => nINTMMU_ro,                     -- Set RO Port (from Arbiter)
            nSET_RW => nINTMMU_rw,                     -- Set RW Port (from Arbiter)
            nWR_CPU => nWR_CPU_r,                      -- Z80 Write Strobe (RAW Input)
            nRESET  => reset_n_sync2,                       -- Global System Reset
            DATA    => Z80_DATA_IN_INT,                -- Data to write to MMU registers (Page Number)
            
            -- Outputs
            EA      => MMU_EA_INT,                     -- Extended Address A13-A20
            nWR_OUT => MMU_WR,                          -- Protected Write Strobe to memory chips (Output pin LWR_N) else NWR_CPU
            nCE0    => MMU_nCE0,                       -- CE for 1MB SRAM
            nCE1    => MMU_nCE1,                       -- CE for 512KB Flash
            nCE2    => MMU_nCE2,                       -- CE for 64KB Video RAM (used internally)
            nCE3    => open,                           -- Unconnected
            nCE4    => open                            -- Unconnected
        );

    -- Calculate VRAM Chip Enable (cea) based on MMU output (Active High required by Port A)
    VRAM_CE_CPU_N <= MMU_nCE2;
    VRAM_CE_CPU <= NOT VRAM_CE_CPU_N;
    VRAM_WR     <=  not MMU_WR;      --MMU_WR signal Wr signal with write protection

    DPVRAM_Inst : entity work.DPVRAM
    port map (
        -- === Port A: CPU Interface (R/W) === 
        clka        => NOT CLK_Z80_INT,
        reseta      => reset_a_sync,     -- Inverted Active Low Reset
        cea         => '1',              -- Inverted Active Low Chip Enable '1' IS ALWAYS ENABLE TO UPDATE ADDRESSES
        wrea        => VRAM_WR and VRAM_CE_CPU,          -- Inverted Active Low Write Enable
        ada         => MMU_EA_INT(15 downto 13) & Z80_LA_BUS_INT(12 downto 0),
        dina        => Z80_DATA_IN_INT,      -- Z80 Data to VRAM
        douta       => VRAM_DATA_TO_CPU,      -- VRAM Data to Z80 MUX
        
        -- DPVRAM IP Core specific signals for Port A
        ocea        => '1',                   -- Output Clock Enable (Always enabled for bus interface)

        -- === Port B: Video Controller Interface (Read-Only) ===
        clkb        => CLK_PIXEL_INT,
        resetb      => reset_a_sync,     -- Invert Active Low Reset
        ceb         => '1',                   -- Always enabled for continuous video read
        wreb        => '0',                   -- Video Port is Read-Only (Always Disabled)
        adb         => VCTRL_ADDR_BUS,        -- Address from Video Controller
        dinb        => (others => '0'),       -- Not used (Read-Only port)
        doutb       => VRAM_DATA_TO_VCTRL,    -- VRAM Data to Video Output Logic

        -- DPVRAM IP Core specific signals for Port B
        oceb        => '1'                    -- Output Clock Enable (Always enabled for video)
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
        WRcpu_N          => nWR_CPU_r,              -- Active-LOW CPU write strobe
        RDcpu_N          => nRD_CPU_r,              -- Active-LOW CPU read strobe
        ADDR_BUS         => Z80_LA_BUS_INT(2 downto 0), -- Direct connection to bottom 3 address bits
        DATA_BUS_IN      => Z80_DATA_IN_INT,     -- Data lines coming out of the Z80 CPU
        DATA_BUS_OUT     => s_uart_data_out,     -- <--- Connect this to your internal read-mux databus!

        testSig          => s_TestSig,

        -- Physical Serial Interface (External Pins)
        sRXD             => RXD,                 -- To physical RX pin driving the FT232
        sTXD             => TXD,                 -- To physical TX pin driving the FT232
        sCTSn            => sCTS_N                 -- To physical hardware flow control pin
    ); 
       
    CTS_N <= 'Z';--sCTS_N;--'0';


    PS2KeybCtrl :PS2_Keyboard_Controller
    port map (
        CLK             => CLK_in,          --50Mhz clock
        nRESET          => reset_n_sync2,
        -- Physical Interface (to SN74LVC1G07 or direct pins with pull-ups)
        PS2_CLK         => LKB_CLOCK,
        PS2_DATA        => LKB_DATA,

        -- Z80/System Interface (Raw Scan Codes)
        RX_DATA_O       =>  ps2_rx_data,    --Scan Code
        RX_READY_O      =>  ps2_rx_ready,   -- Pulse high when raw byte received
        
        -- Command Interface (For LEDs / Initialization)
        TX_DATA_I       =>  ps2_tx_data,
        TX_START_I      =>  ps2_tx_start,   -- Pulse high to send byte
        TX_BUSY_O       =>  ps2_tx_busy,
        TX_ACK_ERROR_O  =>  ps2_ack_err     -- High if keyboard fails to ACK
    );
    

    -- Synchronous process to handle the Z80 Write to Port PS2/Keyb
    -- write 0xED then 
    --The status byte bit mapping is:
    --Bit 0: Scroll Lock
    --Bit 1: Number Lock
    --Bit 2: Caps Lock
    --Bits 3-7: Must be 0
    process(CLK_Z80_INT, reset_n_sync2)
    begin
        if reset_n_sync2 = '0' then
            ps2_tx_start   <= '0';
            ps2_tx_data    <= (others => '0');
            wr_n_delayed   <= '1';
        elsif rising_edge(CLK_Z80_INT) then
            -- Default state
            ps2_tx_start <= '0';
            
            -- Edge detection for L_WR_N (falling edge)
            wr_n_delayed <= nWR_CPU_r;
            
            -- If IORQ is active, port matches, and we see a falling edge of WR_N
            if nIORQ_r = '0' and PS2_DSn = '0' then
                if nWR_CPU_r = '0' and wr_n_delayed = '1' then
                    ps2_tx_data  <= Z80_DATA_IN_INT; -- Capture the LED bits from Z80 bus
                    ps2_tx_start <= '1';     -- Trigger the PS2 Controller for 1 clock cycle
                end if;
            end if;
        end if;
    end process;


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
            Z80_WR_N   => nWR_CPU_r,
            Z80_ADDR   => Z80_LA_BUS_INT(3 downto 0),
            Z80_DATA   => Z80_DATA_IN_INT,
            REG_SEL_N  => '1', -- FOR OUT TO VIDEO CIRCUIT TO SET REGISTERS
            VRAM_DATA  => x"AA", -- Placeholder for VRAM connection
            VRAM_ADDR  => open
        );

    U_PRODUCER_ATLAS : AtlasVideo
        port map(
            V_IN       => video_timing,
            V_OUT      => atlas_bus_out,
            Z80_CLK    => CLK_Z80_INT,
            Z80_WR_N   => nWR_CPU_r,
            Z80_ADDR   => Z80_LA_BUS_INT(3 downto 0),
            Z80_DATA   => Z80_DATA_IN_INT,
            REG_SEL_N  => '1', 
            VRAM_DATA  => VRAM_DATA_TO_VCTRL,
            VRAM_ADDR  => VCTRL_ADDR_BUS
        );

    -- Video handler

    -- Video register from z80 is active
    reg_video_sel_n <= '0' when (VD_DSn = '0' and LWR_N = '0') else  '1';

    process(CLK_Z80_INT, nRESET)
    begin
        if nRESET = '0' then
            video_selection <= (others => '0');
        elsif rising_edge(CLK_Z80_INT) then
            if reg_video_sel_n = '0' then
                -- Store lower 4 bits to address 16 potential systems
                video_selection <= unsigned(Z80_DATA_IN_INT(3 downto 0)); 
            end if;
        end if;
    end process;

    --this selects the video system
    with video_selection select
        selected_video <= --v80_bus_out when "0000",
                        atlas_bus_out when "0000",
                          nb_bus_out when "0001",
                          zx_bus_out when "0010",
                          am_bus_out when "0011",

                          v80_bus_out when others;

    --FREEZE the cpu  -- implement wait states     
    process(CLK_IN,reset_n_sync2)   
    begin   
       if rising_edge(CLK_IN) then            
            -- We want to run the clock only if NOT (Freeze Condition)   
            if (l_wait_n = '0') then
                LCLOCK <= CLK_Z80_INT;--'1'; -- FREEZE: CPU stops mid-access
            else
                LCLOCK <= CLK_Z80_INT; -- RUN: Normal operation
            end if;
        end if; 
    end process;


    -- ***************************************************************
    -- ** CHIP ENABLE AND EXTENDED ADDRESS PIN MAPPING **
    -- ***************************************************************
    DEV1 <= BADEV1; -- Z80's decoded output
    DEV2 <= BADEV2; -- Z80's decoded output

    --capturedata <= '1' when BADEV1='1' and BADEV2='1' else '0';



-- 1. Combine the Z80 control signals first
z80_strobe_raw <= '0' when (BADEV1='1' and BADEV2='1' and nIORQ_r='0' ) else '1'; 

process(CLK_IN)
begin
    if rising_edge(CLK_IN) then
        sync_reg1 <= z80_strobe_raw;
        sync_reg2 <= sync_reg1;
        sync_reg3 <= sync_reg2;
        
        -- Detect edge
        if (sync_reg3 = '1' and sync_reg2 = '0') then
            pulse_timer <= 7; -- Start a timer
        elsif pulse_timer > 0 then
            pulse_timer <= pulse_timer - 1;
        end if;
        
        -- Signal is active as long as the timer is running
        if pulse_timer > 0 then
            write_event <= '1';
        else
            write_event <= '0';
        end if;
    end if;
end process;

 


process(CLK_IN, reset_n_sync2)
begin
    if reset_n_sync2 = '0' then
        write_count <= 0;
        capturedata <= '0';
        event_processed <= '0';
    elsif rising_edge(CLK_IN) then
        if write_event = '1' then
            -- Only count if we haven't processed this specific pulse yet
            if event_processed = '0' then
                if write_count < 0 then -- Change 2 to 6 to skip 6 writes
                    write_count <= write_count + 1;
                    event_processed <= '1'; -- Lock out further counts for this pulse
                else
                    capturedata <= '1';
                end if;
            end if;
        else
            -- Pulse is gone, reset the lockout so we are ready for the next one
            event_processed <= '0';
        end if;
    end if;
end process;
    --i2c_rd_n_s goes low to signal we can read the data
    --i2c_data_out_s to the data bus
      
                  


 -- C. Z80 Data Multiplexer (Determining which device drives the bus for a Z80 read)
    -- This internal signal selects the data to drive onto the tristate bus based on which chip enable is active.

    PROCESS(CLK_Z80_INT) -- Or your bus clock
    BEGIN
        IF rising_edge(CLK_Z80_INT) THEN
           Z80_DATA_OUT_INT <=         
                s_uart_data_out       when UART_nCS = '0' and nRD_CPU_r = '0' else -- UART read selected          
                ps2_rx_data           when PS2_DSn ='0' and nRD_CPU_r = '0' else --ps/2 keyboard read
                VRAM_DATA_TO_CPU      when VRAM_CE_CPU_N = '0' and nRD_CPU_r = '0' else   -- VRAM selected
                clk_reg_out           when nCLK_SEL='0' and nRD_CPU_r = '0' else
                (others => 'Z');                           -- Default if no device is selected for read
        END IF;
    END PROCESS;

   
    
    sEnableDataOut <= '1' when flash_prog='0' 
           else '0' when ( UART_nCS = '0' or PS2_DSn ='0' or VRAM_CE_CPU_N = '0' or nCLK_SEL='0') and nRD_CPU_r = '0'--add i2c when it works
           else '1';
    LWR_N <= 'Z' when flash_prog='0' else MMU_WR; --FlRam and Sram control
    L_RD_N <= 'Z'; --read only make the signal in
    
    -- A. Chip Enables to Physical Pins
    LRAMEN3_N <= '1' when flash_prog='0' else MMU_nCE0; -- 1MB SRAM
    LRAMEN2_N <= '0' when flash_prog='0' else MMU_nCE1; -- 512Kb Flash RAM    

    -- B. MMU Extended Address (A13-A19) to Physical Address Pins
    -- MMU_EA_INT is (20 DOWNTO 13). We map A13-A19 to the external pins.
    EA19 <= 'Z' when flash_prog='0' else MMU_EA_INT(19);
    EA18 <= 'Z' when flash_prog='0' else MMU_EA_INT(18);
    EA17 <= 'Z' when flash_prog='0' else MMU_EA_INT(17);
    EA16 <= 'Z' when flash_prog='0' else MMU_EA_INT(16);
    EA15 <= 'Z' when flash_prog='0' else MMU_EA_INT(15);
    EA14 <= 'Z' when flash_prog='0' else MMU_EA_INT(14);
    EA13 <= 'Z' when flash_prog='0' else MMU_EA_INT(13);

    -- C. Data Bus (LD0-LD7) Tristate output
    -- Data is driven when Z80_DATA_OE is asserted (TBD logic)
    LD7 <= Z80_DATA_OUT_INT(7) when nRD_CPU_r = '0' and sEnableDataOut='0' else 'Z';
    LD6 <= Z80_DATA_OUT_INT(6) when nRD_CPU_r = '0' and sEnableDataOut='0' else 'Z';
    LD5 <= Z80_DATA_OUT_INT(5) when nRD_CPU_r = '0' and sEnableDataOut='0' else 'Z';
    LD4 <= Z80_DATA_OUT_INT(4) when nRD_CPU_r = '0' and sEnableDataOut='0' else 'Z';
    LD3 <= Z80_DATA_OUT_INT(3) when nRD_CPU_r = '0' and sEnableDataOut='0' else 'Z';
    LD2 <= Z80_DATA_OUT_INT(2) when nRD_CPU_r = '0' and sEnableDataOut='0' else 'Z';
    LD1 <= Z80_DATA_OUT_INT(1) when nRD_CPU_r = '0' and sEnableDataOut='0' else 'Z';
    LD0 <= Z80_DATA_OUT_INT(0) when nRD_CPU_r = '0' and sEnableDataOut='0' else 'Z';
    
    -- D. Address Bus (LA0-LA15) Tristate output
    -- Address bus is currently passive in the FPGA, assuming the Z80 is always the master.
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

    -- F. Placeholder: Audio Mux Select
--    LAUDMUX_SEL <= '0'; -- Default to one channel for now


    --VIDEO OUTPUT
    -- -------------------------------------------------------------------------
    -- Connect the VRAM output data to your video controller's input data bus.
    -- VCTRL_DATA_IN <= VRAM_DATA_TO_VCTRL;


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
                flash_prog <= '0'; -- Latches high cleanly on the next clock tick!
            end if; 
        end if;
    end process;

    LBUSREQ_N <= '0' when flash_prog='0' else '1'; -- Low to force Z80 into Tristate (Bus Acknowledgment requested)
    nmi_input_clean <= L_NMI_N;
    L_NMI_N <= '0' when fpga_drive_nmi_low = '1' else 'Z';

    SCL <= sCTS_N;--;s_uart_data_out(0) when UART_nCS='0' and nRD_CPU_r='0' else '1'; -- i2c not implemented yet
    SDA <= s_TestSig; --'0' when BADEV1='1' and BADEV2='1' else '1';

end structural;