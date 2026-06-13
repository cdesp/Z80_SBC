library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity z80_gh16550_wrapper is
    port (
        -- FPGA Clocks & Reset
        sys_clk         : in  std_logic; 
        br_clk_i        : in  std_logic; 
        rst_i           : in  std_logic; 

        -- Z80 CPU Bus Pins
        z80_addr        : in  std_logic_vector(7 downto 0);
        z80_data_in     : in  std_logic_vector(7 downto 0);
        z80_data_out    : out std_logic_vector(7 downto 0); -- Driven to Z when not reading
        z80_uartCSn     : in  std_logic;
        z80_iorq_n      : in  std_logic;
        z80_rd_n        : in  std_logic;
        z80_wr_n        : in  std_logic;
        z80_int_n       : out std_logic;

        testSig         : out std_logic;

        -- External Serial Interface
        uart_sRX        : in  std_logic;
        uart_sTX        : out std_logic;
        uart_ctsn       : in  std_logic := '1';
        uart_rtsn       : out std_logic
    );
end z80_gh16550_wrapper;

architecture rtl of z80_gh16550_wrapper is

    -- Signals to synchronize asynchronous Z80 inputs to sys_clk
    signal iorq_sync    : std_logic_vector(1 downto 0) := "11";
    signal rd_sync      : std_logic_vector(1 downto 0) := "11";
    signal wr_sync      : std_logic_vector(1 downto 0) := "11";

    -- Internal Control Flags
    signal cs_decoded   : std_logic;
    signal core_wr      : std_logic;
    signal core_irq     : std_logic;
    signal core_data_out : std_logic_vector(7 downto 0); -- Holds output from core 'RD' port

    -- Component declaration matching your exact entity
    component gh_uart_16550 is
        port(
            clk     : in std_logic;
            BR_clk  : in std_logic;
            rst     : in std_logic;
            CS      : in std_logic;
            WR      : in std_logic;
            ADD     : in std_logic_vector(2 downto 0);
            D       : in std_logic_vector(7 downto 0);
            sRX	    : in std_logic;
            CTSn    : in std_logic := '1';
            DSRn    : in std_logic := '1';
            RIn     : in std_logic := '1';
            DCDn    : in std_logic := '1';
            sTX     : out std_logic;
            DTRn    : out std_logic;
            RTSn    : out std_logic;
            OUT1n   : out std_logic;
            OUT2n   : out std_logic;
            TXRDYn  : out std_logic;
            RXRDYn  : out std_logic;
            IRQ     : out std_logic;
            B_CLK   : out std_logic;
            RD      : out std_logic_vector(7 downto 0)
        );
    end component;

begin

    -- 1. Double-flop synchronizers for Z80 control lines
    process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if rst_i = '1' then
                iorq_sync <= "11";
                rd_sync   <= "11";
                wr_sync   <= "11";
            else
                iorq_sync <= iorq_sync(0) & z80_iorq_n;
                rd_sync   <= rd_sync(0)   & z80_rd_n;
                wr_sync   <= wr_sync(0)   & z80_wr_n;
            end if;
        end if;
    end process;

    -- 2. Generate synchronous chip-select and write strobes
    cs_decoded <= '1' when (z80_uartCSn='0' and iorq_sync(1) = '0') else '0';
    core_wr    <= '1' when (cs_decoded = '1' and wr_sync(1) = '0') else '0';

    -- 3. Tri-state output to Z80 bus. 
    -- Only drive the bus when this specific UART is chip-selected AND the Z80 is requesting a read cycle.
    z80_data_out <= core_data_out when (cs_decoded = '1' and rd_sync(1) = '0') else (others => 'Z'); 

    -- 4. Open-drain Z80 interrupt line behavior
    z80_int_n  <= '0' when core_irq = '1' else 'Z';

    --testSig <= cs_decoded;

    -- 5. Core Instantiation
    u_core : gh_uart_16550
        port map (
            clk     => sys_clk,
            BR_clk  => br_clk_i,
            rst     => rst_i,
            CS      => cs_decoded,
            WR      => core_wr,
            ADD     => z80_addr(2 downto 0),
            D       => z80_data_in,
            
            sRX     => uart_sRX,
            CTSn    => uart_ctsn,
            DSRn    => '1', 
            RIn     => '1', 
            DCDn    => '1', 
            
            sTX     => uart_sTX,
            DTRn    => open,
            RTSn    => uart_rtsn,
            OUT1n   => open,
            OUT2n   => open,
            TXRDYn  => open,
            RXRDYn  => open,
            
            IRQ     => core_irq,
            B_CLK   => testSig,
            RD      => core_data_out -- Correctly connected to internal tracking signal
        );

end rtl;
