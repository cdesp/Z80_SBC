library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Z80_PS2_Bridge is
    port (
        -- Clock/Reset
        CLK            : in    std_logic;
        nRESET         : in    std_logic;

        PS2_DS_N       : in  std_logic; -- Active Low 
        PS2_BT_RDY     : out  std_logic; -- Active Low  
        -- Z80 Bus Interface
        Z80_IO_ADDR    : in    std_logic_vector(7 downto 0);
        Z80_RD_N       : in    std_logic;
        Z80_WR_N       : in    std_logic;
        Z80_DATA_IN    : IN    std_logic_vector(7 downto 0);
        Z80_DATA_OUT   : out   std_logic_vector(7 downto 0);

        -- Physical PS/2 Pins
        PS2_CLK        : inout std_logic;
        PS2_DATA       : inout std_logic
    );
end entity;

architecture RTL of Z80_PS2_Bridge is
    signal nWR_sync1, nWR_sync2 : std_logic := '1';    
    signal Z80_DATA_sync1, Z80_DATA_sync2 : std_logic_vector(7 downto 0) := (others => '0');
    signal KB_DATA_OUT : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Internal signals for the controller
    signal rx_ready    : std_logic;
    signal rx_data     : std_logic_vector(7 downto 0);

    signal ps2_tx_start   : std_logic := '0';
    signal ps2_tx_data    : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_busy        : std_logic;
    signal wr_n_delayed   : std_logic := '1';
    
    -- State machine: 0=Idle, 1=Sending 0xED, 2=Wait for Finish, 3=Sending Data
    signal tx_state       : integer range 0 to 8 := 0;
    
    -- Status and Buffer
    signal byte_reg    : std_logic_vector(7 downto 0);
    signal byte_ready  : std_logic := '0';
    signal rd_prev : std_logic :='1';

    -- =========================================================
    -- NEW SIGNALS: For Z80 Read Edge Detection & FIFO
    -- =========================================================
    signal z80_read_req  : std_logic;
    signal z80_rd_sync_1 : std_logic := '0';
    signal z80_rd_sync_2 : std_logic := '0';
    signal z80_rd_done   : std_logic;

    type fifo_type is array (0 to 15) of std_logic_vector(7 downto 0);
    signal fifo        : fifo_type := (others => (others => '0'));
    signal fifo_wr_ptr : integer range 0 to 15 := 0;
    signal fifo_rd_ptr : integer range 0 to 15 := 0;
    signal fifo_count  : integer range 0 to 16 := 0;

begin

    -- Instantiate your original controller
    PS2_INST : entity work.PS2_Keyboard_Controller
        generic map (CLK_FREQ_MHZ => 50)
        port map (
            CLK => CLK, nRESET => nRESET,
            PS2_CLK => PS2_CLK, PS2_DATA => PS2_DATA,
            RX_DATA_O => rx_data, RX_READY_O => rx_ready,
            TX_START_I => ps2_tx_start, 
            TX_DATA_I => ps2_tx_data,
            TX_BUSY_O  => tx_busy,
            TX_ACK_ERROR_O => open
        );

    process(CLK) -- 50MHz Clock
    begin
        if rising_edge(CLK) then
            -- Two-stage synchronization
            nWR_sync1      <= Z80_WR_N;    
            nWR_sync2      <= nWR_sync1;        
            Z80_DATA_sync1 <= Z80_DATA_IN; 
            Z80_DATA_sync2 <= Z80_DATA_sync1;
        end if;
    end process;

    process(CLK, nRESET)
    begin
        if nRESET = '0' then
            ps2_tx_start <= '0';
            tx_state     <= 0;
        elsif rising_edge(CLK) then
            ps2_tx_start <= '0';

            case tx_state is
                when 0 => -- Idle: Wait for Z80 to send a byte
                    if PS2_DS_N = '0' and nWR_sync2 = '0' then                        
                        tx_state     <= 1;
                    end if;

                when 1 => ps2_tx_data  <= Z80_DATA_IN;
                          ps2_tx_start <= '1';
                          tx_state     <= 2;

                when 2 => -- Wait for controller to finish TX
                    if tx_busy = '1' then tx_state <= 3; end if;

                when 3 => -- Controller busy transmitting...
                    if tx_busy = '0' then tx_state <= 5; end if;

                when 4 => -- WAIT FOR ACK FROM KEYBOARD
                    if rx_ready = '1' then
                        if rx_data = x"FA" then
                            tx_state <= 5; -- ACK received, safe to exit
                        else
                            tx_state <= 7; -- Error or unknown byte, reset
                        end if;
                    end if;

                when 5 => 
                        tx_state <= 6;

                when 6 => -- Wait for Z80 to release the port
                    if nWR_sync2 = '1' then
                        tx_state <= 0;
                    end if;

                when 7 =>  --error
                        tx_state <= 0;

            end case;
        end if;
    end process;

    -- =========================================================
    -- NEW LOGIC: Z80 Read Edge Detection (Trailing Edge)
    -- =========================================================
    z80_read_req <= '1' when (PS2_DS_N = '0' and Z80_RD_N = '0' and Z80_IO_ADDR(0) = '0') else '0';

    process(CLK, nRESET)
    begin
        if nRESET = '0' then
            z80_rd_sync_1 <= '0';
            z80_rd_sync_2 <= '0';
        elsif rising_edge(CLK) then
            z80_rd_sync_1 <= z80_read_req;
            z80_rd_sync_2 <= z80_rd_sync_1;
        end if;
    end process;

    -- Pulses high for exactly 1 clock cycle when the Z80 FINISHES reading
    z80_rd_done <= '1' when (z80_rd_sync_2 = '1' and z80_rd_sync_1 = '0') else '0';

    -- =========================================================
    -- NEW LOGIC: 16-Byte FIFO for capturing PS/2 Data
    -- =========================================================
    process(CLK, nRESET)
        variable write_en : boolean;
        variable read_en  : boolean;
    begin
        if nRESET = '0' then
            fifo_wr_ptr <= 0;
            fifo_rd_ptr <= 0;
            fifo_count  <= 0;
            byte_ready  <= '0';
            byte_reg    <= (others => '0');
        elsif rising_edge(CLK) then
            write_en := false;
            read_en  := false;

            -- A. Acknowledge that the Z80 took the byte
            if z80_rd_done = '1' then
                byte_ready <= '0';
            end if;

            -- B. Incoming PS/2 Data -> Push to FIFO
            if rx_ready = '1' and fifo_count < 16 then
                fifo(fifo_wr_ptr) <= rx_data;
                write_en := true;
                if fifo_wr_ptr = 15 then
                    fifo_wr_ptr <= 0;
                else
                    fifo_wr_ptr <= fifo_wr_ptr + 1;
                end if;
            end if;

            -- C. Load next byte from FIFO to output register
            if (byte_ready = '0' or z80_rd_done = '1') and fifo_count > 0 then
                byte_reg <= fifo(fifo_rd_ptr);
                byte_ready <= '1'; 
                read_en := true;
                if fifo_rd_ptr = 15 then
                    fifo_rd_ptr <= 0;
                else
                    fifo_rd_ptr <= fifo_rd_ptr + 1;
                end if;
            end if;

            -- D. Safely Update FIFO Count
            if write_en and not read_en then
                fifo_count <= fifo_count + 1;
            elsif read_en and not write_en then
                fifo_count <= fifo_count - 1;
            end if;

        end if;
    end process;

    -- Bus Multiplexer (Output to Z80)
    process(Z80_IO_ADDR, PS2_DS_N, Z80_RD_N, byte_reg, byte_ready, tx_busy)
    begin
        Z80_DATA_OUT <= (others => 'Z'); -- Default high-impedance
        PS2_BT_RDY <= byte_ready;
        if (PS2_DS_N = '0' and Z80_RD_N = '0') then
            if (Z80_IO_ADDR(0) = '0') then
                Z80_DATA_OUT <= byte_reg;
            elsif (Z80_IO_ADDR(0) = '1') then
                Z80_DATA_OUT <= tx_busy & "000000" & byte_ready;
            end if;
        end if;
    end process;
   
end architecture;