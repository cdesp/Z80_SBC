library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity z80_to_gowin_16550_wrapper is
    port (
        -- Global Clocks & Resets
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
end z80_to_gowin_16550_wrapper;

architecture Behavioral of z80_to_gowin_16550_wrapper is

    -- 1. Component Declaration for the Gowin IP Core
    component UART_MASTER_Top
        port (
            I_CLK    : in  std_logic;
            I_RESETN : in  std_logic;
            I_TX_EN  : in  std_logic;
            I_WADDR  : in  std_logic_vector(2 downto 0);
            I_WDATA  : in  std_logic_vector(7 downto 0);
            I_RX_EN  : in  std_logic;
            I_RADDR  : in  std_logic_vector(2 downto 0);
            O_RDATA  : out std_logic_vector(7 downto 0);
            SIN      : in  std_logic;
            RxRDYn   : out std_logic;
            SOUT     : out std_logic;
            TxRDYn   : out std_logic;
            DDIS     : out std_logic;
            INTR     : out std_logic;
            DCDn     : in  std_logic;
            CTSn     : in  std_logic;
            DSRn     : in  std_logic;
            RIn      : in  std_logic;
            DTRn     : out std_logic;
            RTSn     : out std_logic
        );
    end component;

    -- Emulated 16550 registers
    signal reg_dll       : std_logic_vector(7 downto 0) := x"1B"; -- Default 115200 divisor at 50MHz
    signal reg_dlm       : std_logic_vector(7 downto 0) := x"00";
    signal dlab_reg      : std_logic := '0';

    -- Pulse Generator Logic (Z80 Domain)
    signal s_uart_cs     : std_logic;
    signal z80_cs_delay  : std_logic := '0';
    signal z80_cs_pulse  : std_logic := '0';

    -- Signals feeding into Gowin IP
    signal ip_resetn     : std_logic;
    signal ip_tx_en      : std_logic;
    signal ip_rx_en      : std_logic;
    signal ip_wdata      : std_logic_vector(7 downto 0);
    signal ip_rdata      : std_logic_vector(7 downto 0);
    
    -- Status flags coming from Gowin IP
    signal ip_rxrdyn     : std_logic; -- Low when data available
    signal ip_txrdyn     : std_logic; -- Low when transmitter ready/holding register empty
    signal ip_rtsn       : std_logic;

    signal z80_wr_clean       : std_logic;
    signal wr_sync_reg1       : std_logic;
    signal wr_sync_reg2       : std_logic;
    signal wr_sync_reg3       : std_logic;

    signal tx_hw_lock : std_logic := '0'; -- Hardware lockout flag

    signal z80_rd_clean     : std_logic := '0';
    signal rd_sync_reg1     : std_logic := '0';
    signal rd_sync_reg2     : std_logic := '0';
    signal rd_sync_reg3     : std_logic := '0';

begin

    -- Active-low reset logic for Gowin IP
    ip_resetn <= not rst_high;
    
    -- Forward hardware flow control status out to the physical FT232 chip
    sCTSn <= ip_rtsn;

    ----------------------------------------------------------------------------
    -- 1. Z80 SINGLE-CYCLE EDGE DETECTOR WRAPPER
    ----------------------------------------------------------------------------
    s_uart_cs <= not DEV_CS_N; -- Convert Z80 Chip Select to Active High

    process(CLK_Z80)
    begin
        if rising_edge(CLK_Z80) then
            if rst_high = '1' then
                z80_cs_delay <= '0';
            else
                z80_cs_delay <= s_uart_cs;
            end if;
        end if;
    end process;

    -- Fires high for exactly ONE cycle at the leading edge of a Z80 I/O access
    z80_cs_pulse <= s_uart_cs and (not z80_cs_delay);

    ----------------------------------------------------------------------------
    -- 2. WRITE INTERCEPT & SPEED REGISTERS (Synchronized to Z80 Interface)
    ----------------------------------------------------------------------------

----------------------------------------------------------------------------
    -- 2. DUAL HARDWARE SYNCHRONIZER (TX & RX Clean-Up)
    ----------------------------------------------------------------------------
    
    -- Detect when the Z80 is actively writing to register 0
    z80_wr_clean <= '1' when (DEV_CS_N = '0' and WRcpu_N = '0' and ADDR_BUS = "000") else '0';
    
    -- Detect when the Z80 is actively reading from register 0
    z80_rd_clean <= '1' when (DEV_CS_N = '0' and RDcpu_N = '0' and ADDR_BUS = "000") else '0';

    -- Separate DLAB register tracking (Z80 Domain)
    process(CLK_Z80)
    begin
        if rising_edge(CLK_Z80) then
            if rst_high = '1' then
                dlab_reg <= '0';
                reg_dll  <= x"1B";
                reg_dlm  <= x"00";
            elsif (not DEV_CS_N) = '1' and WRcpu_N = '0' then
                if ADDR_BUS = "011" then
                    dlab_reg <= DATA_BUS_IN(7);
                elsif ADDR_BUS = "000" and dlab_reg = '1' then
                    reg_dll  <= DATA_BUS_IN;
                elsif ADDR_BUS = "001" and dlab_reg = '1' then
                    reg_dlm  <= DATA_BUS_IN;
                end if;
            end if;
        end if;
    end process;

    -- Pristine Dual-Edge 50MHz Domain Processor
    process(CLK_FPGA)
    begin
        if rising_edge(CLK_FPGA) then
            if rst_high = '1' then
                wr_sync_reg1   <= '0'; wr_sync_reg2 <= '0'; wr_sync_reg3 <= '0';
                rd_sync_reg1   <= '0'; rd_sync_reg2 <= '0'; rd_sync_reg3 <= '0';
                ip_tx_en       <= '0';
                ip_rx_en       <= '0';
                ip_wdata       <= (others => '0');
                tx_hw_lock     <= '0';
            else
                -- Shift both signals down their respective sync chains
                wr_sync_reg1   <= z80_wr_clean;
                wr_sync_reg2   <= wr_sync_reg1;
                wr_sync_reg3   <= wr_sync_reg2;
                
                rd_sync_reg1   <= z80_rd_clean;
                rd_sync_reg2   <= rd_sync_reg1;
                rd_sync_reg3   <= rd_sync_reg2;
                
                -- Default strobes to 0 every clock cycle
                ip_tx_en <= '0';
                ip_rx_en <= '0';
                
                -- Release the transmitter lockout flag safely
                if ip_txrdyn = '0' then
                    tx_hw_lock <= '0';
                end if;
                
                -- TRANSMIT EDGE DETECT (Z80 Write)
                if (wr_sync_reg2 = '1' and wr_sync_reg3 = '0') then
                    ip_wdata   <= DATA_BUS_IN; 
                    ip_tx_en   <= '1';             
                    tx_hw_lock <= '1'; 
                end if;
                
                -- RECEIVE EDGE DETECT (Z80 Read)
                -- Fires high for exactly ONE 50MHz cycle to pop a single byte from the FIFO
                if (rd_sync_reg2 = '1' and rd_sync_reg3 = '0') and dlab_reg = '0' then
                    ip_rx_en   <= '1';
                end if;
            end if;
        end if;
    end process;

  

    ----------------------------------------------------------------------------
    -- 3. READ INTERCEPT & STATUS TRANSLATION (Combinatorial Bus Routing)
    ----------------------------------------------------------------------------
   -- ip_rx_en <= '1' when (z80_cs_pulse = '1' and L_RD_N = '0' and Z80_LA_BUS_INT = "000" and dlab_reg = '0') else '0';

    process(ADDR_BUS, dlab_reg, reg_dll, reg_dlm, ip_rdata, ip_txrdyn, ip_rxrdyn, tx_hw_lock)
        variable fake_lsr : std_logic_vector(7 downto 0);
    begin
       -- Synthesize a vintage 16550 Line Status Register (LSR) byte
        fake_lsr := (others => '0');
         
        -- FIXED: Bit 5 stays 0 if either the Gowin core is busy OR our hardware lock is active
        fake_lsr(5) := (not ip_txrdyn) and (not tx_hw_lock); 
        fake_lsr(6) := not ip_txrdyn; 
        fake_lsr(0) := not ip_rxrdyn;

        case ADDR_BUS is
            when "000" =>
                if dlab_reg = '1' then
                    DATA_BUS_OUT <= reg_dll; -- Return low divisor byte
                else
                    DATA_BUS_OUT <= ip_rdata; -- Return live received character from IP
                end if;
                
            when "001" =>
                if dlab_reg = '1' then
                    DATA_BUS_OUT <= reg_dlm; -- Return high divisor byte
                else
                    DATA_BUS_OUT <= x"00";
                end if;
                
            when "101" => -- Offset 5: Line Status Register!
                DATA_BUS_OUT <= fake_lsr; -- Hand Z80 our emulated polling flags
                
            when others =>
                DATA_BUS_OUT <= x"00"; -- Stable bus clamping
        end case;
    end process;

    ----------------------------------------------------------------------------
    -- 4. GOWIN UART MASTER IP INSTANTIATION
    ----------------------------------------------------------------------------
    -- NOTE: Gowin IP works entirely inside a linear synchronous block clock.
    -- We map I_CLK straight to your CLK_Z80_INT to guarantee timing match.
    u_gowin_core : UART_MASTER_Top
        port map (
            I_CLK    => CLK_FPGA,      -- Clean synchronous bus tracking clock
            I_RESETN => ip_resetn,
            I_TX_EN  => ip_tx_en,         -- Single-cycle pulsed write strobe
            I_WADDR  => ADDR_BUS,
            I_WDATA  => ip_wdata,
            I_RX_EN  => ip_rx_en,         -- Single-cycle pulsed read strobe
            I_RADDR  => ADDR_BUS,
            O_RDATA  => ip_rdata,
            SIN      => sRXD,              -- Connect straight to incoming physical serial stream
            SOUT     => sTXD,              -- Connect straight to outgoing physical serial stream
            RxRDYn   => ip_rxrdyn,
            TxRDYn   => ip_txrdyn,
            DDIS     => open,
            INTR     => open,
            DCDn     => '1',              -- Inactive
            CTSn     => '0',              -- Hardwire to 0 so internal engine always transmits
            DSRn     => '1',              -- Inactive
            RIn      => '1',              -- Inactive
            DTRn     => open,
            RTSn     => ip_rtsn           -- Tracked to feed back to physical flow control pin
        );
 
--  z80_wr_clean <= '1' when (UART_nCS = '0' and LWR_CPU_N = '0' and Z80_LA_BUS_INT = "000") else '0';
        testSig <= WRcpu_N;

end Behavioral;