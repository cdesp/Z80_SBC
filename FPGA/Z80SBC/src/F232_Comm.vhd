library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.defs_pkg.ALL; -- Assuming UART_PORT_BASE is defined here

entity FT232_Comm is
    port (
        -- System Clocks and Reset
        CLK             : in  std_logic;                                -- Main Clock (CLK_IN 50MHz)
        RESET_N         : in  std_logic;                                -- Synchronous Active Low Reset (reset_n_sync2)
        IO_SELECT_N     : in  std_logic;                                -- chip select

        -- Z80 Bus Interface (I/O Access)
        IO_ADDR         : in  std_logic_vector(15 downto 0);            -- Z80 Address Bus (A0-A15)
        IO_DATA_IN      : in  std_logic_vector(7 downto 0);             -- Data from Z80 to UART
        IO_DATA_OUT     : out std_logic_vector(7 downto 0);             -- Data from UART to Z80
        IORQ_N          : in  std_logic;                                -- Active Low I/O Request
        RD_N            : in  std_logic;                                -- Active Low Read Strobe
        WR_N            : in  std_logic;                                -- Active Low Write Strobe

        -- External Interface (FT232 Chip)
        RXD             : in  std_logic;                                -- Receive Data from FT232 (PC TX)
        TXD             : out std_logic;                                -- Transmit Data to FT232 (PC RX)
        CTS_N           : out std_logic                                 -- Clear To Send (Active Low) output to FT232 (Pin 23 / RTS#)
    );
end entity FT232_Comm;

architecture Behavioral of FT232_Comm is

    -- ---------------------------------------------------------------
    --  PRESCALER (50MHz -> ~1.85MHz)
    -- ---------------------------------------------------------------
    -- Standard 16550 Clock: 1.8432 MHz (1,843,200 Hz)
    -- Target Division Ratio (for 50 MHz CLK_PERIPH): 50,000,000 / 1,843,200 = 27.126
    -- We use integer division: Divide by 27.
    -- New effective clock: 50,000,000 / 27 = 1,851,851 Hz (0.47% error)
    constant PRESCALE_DIV : integer := 27; 
    signal prescale_count : integer range 0 to PRESCALE_DIV-1 := 0;
    signal clk_1_8432mhz_approx : std_logic := '0'; -- The new clock for the BRG

    -- Internal Register Definitions (16C550 offsets)
    signal RBR_THR_DLL      : std_logic_vector(7 downto 0) := (others => '0'); -- Offset 0
    signal IER_DLM          : std_logic_vector(7 downto 0) := (others => '0'); -- Offset 1
    signal FCR              : std_logic_vector(7 downto 0) := (others => '0'); -- Offset 2 (FIFO Control Register)
    signal LCR              : std_logic_vector(7 downto 0) := (others => '0'); -- Offset 3 (Line Control Register)
    signal MCR              : std_logic_vector(7 downto 0) := (others => '0'); -- Offset 4 (Modem Control Register)
    
    -- LCR Field Extraction
    alias DLAB              : std_logic is LCR(7);  -- Divisor Latch Access Bit
    alias WORD_LENGTH       : std_logic_vector(1 downto 0) is LCR(1 downto 0); -- Word Length (5-8 bits)
    alias STOP_BIT_LEN      : std_logic is LCR(2);  -- Stop Bit Length (1=2 stop bits, 0=1 stop bit)
    alias PARITY_EN         : std_logic is LCR(3);  -- Parity Enable
    alias EVEN_PARITY       : std_logic is LCR(4);  -- Even Parity Select

    -- Baud Rate Divisor Latch (16-bit)
    signal BAUD_DIVISOR_REG : unsigned(15 downto 0) := X"0000"; 
    
    -- Internal Signals
    signal CS_THIS_PORT     : std_logic; 

    -- Baud Rate Generator Signals
    signal brg_count        : unsigned(15 downto 0) := (others => '0');
    signal brg_tick_16x     : std_logic := '0'; -- 16x Baud Rate Clock

    -- ***************************************************************
    -- Receiver (RX) Signals and State Machine
    -- ***************************************************************
    signal RXD_sync         : std_logic_vector(2 downto 0) := (others => '1'); -- Shift register for synchronizing RXD
    
    type RX_STATE_T is (RX_IDLE, RX_START_WAIT, RX_DATA, RX_PARITY, RX_STOP);
    signal rx_state         : RX_STATE_T := RX_IDLE;
    
    signal os_count         : unsigned(3 downto 0) := (others => '0'); -- Oversampling counter (0 to 15)
    signal bit_tick         : std_logic := '0';    -- Single Baud Rate Clock (center of bit)
    
    signal rx_shift_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_bit_count     : integer range 0 to 8 := 0;
    
    -- RX Buffer and Status Flags
    signal rx_buffer        : std_logic_vector(7 downto 0) := (others => '0'); -- RBR
    signal rx_data_ready    : std_logic := '0';    -- LSR bit 0 (CONSOLIDATED DRIVE)
    signal rx_overrun_error : std_logic := '0';    -- LSR bit 1
    signal rx_parity_error  : std_logic := '0';    -- LSR bit 2
    signal rx_framing_error : std_logic := '0';    -- LSR bit 3
    signal rx_break_detect  : std_logic := '0';    -- LSR bit 4 (Not fully implemented, tied to RXD low for frame length)
    
    -- Control signal for clearing the RX flags when RBR is read by Z80
    signal rbr_read_clear   : std_logic := '0';
    
    -- Flow Control Signal
    signal rx_buffer_full   : std_logic; 

    -- ***************************************************************
    -- Transmitter (TX) Signals and State Machine
    -- ***************************************************************
    signal tx_buffer        : std_logic_vector(7 downto 0) := (others => '0'); -- THR
    signal tx_shift_reg     : std_logic_vector(10 downto 0) := (others => '1'); 
    signal tx_busy          : std_logic := '0';    -- TSRE (LSR bit 6)
    signal tx_data_available: std_logic := '0';    -- THRE (LSR bit 5)
    signal tx_bit_count     : integer range 0 to 9 := 0;
    
    type TX_STATE_T is (TX_IDLE, TX_START, TX_DATA, TX_PARITY, TX_STOP);
    signal tx_state         : TX_STATE_T := TX_IDLE;
    
    constant START_BIT      : std_logic := '0';

    signal total_bits        : integer range 8 to 11;
    signal data_length       : integer range 5 to 8;     
    signal read_data : std_logic_vector(7 downto 0);  
begin
    
    -- ***************************************************************
    -- 0. I/O ADDRESS DECODING (Chip Select)
    -- ***************************************************************
    CS_THIS_PORT <= NOT IO_SELECT_N;

  -- ***************************************************************
    -- 1. PRESCALER IMPLEMENTATION
    -- ***************************************************************
    -- Generates the 1.85 MHz clock required for 16550 compatibility
    process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET_N = '0' then
                prescale_count <= 0;
                clk_1_8432mhz_approx <= '0';
            else
                if prescale_count = PRESCALE_DIV - 1 then
                    prescale_count <= 0;
                    clk_1_8432mhz_approx <= '1'; -- Generate one tick on the new slower clock
                else
                    prescale_count <= prescale_count + 1;
                    clk_1_8432mhz_approx <= '0';
                end if;
            end if;
        end if;
    end process;


    -- ***************************************************************
    -- 2. BAUD RATE GENERATOR (16x Clock)
    -- ***************************************************************
    -- Now clocked by clk_1_8432mhz_approx, making it 16550 compatible.
    process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET_N = '0' then
                brg_count <= (others => '0');
                brg_tick_16x <= '0';
            elsif clk_1_8432mhz_approx = '1' then -- Clock the counter on the slower tick
                if BAUD_DIVISOR_REG /= X"0000" then 
                    if brg_count = BAUD_DIVISOR_REG then
                        brg_count <= (others => '0');
                        brg_tick_16x <= '1'; 
                    else
                        brg_count <= brg_count + 1;
                        brg_tick_16x <= '0';
                    end if;
                else
                    brg_count <= (others => '0');
                    brg_tick_16x <= '0';
                end if;
            else
                -- Maintain the tick state if the slower clock hasn't ticked yet
                brg_tick_16x <= '0'; 
            end if;
        end if;
    end process;

    -- ***************************************************************
    -- 3. RECEIVER (RX) LOGIC (16x Oversampling)
    -- ***************************************************************

    -- Synchronize RXD input to CLK domain
    process(CLK)
    begin
        if rising_edge(CLK) then
            RXD_sync <= RXD_sync(1 downto 0) & RXD;
        end if;
    end process;
    
    -- --- Combinatorial Logic for Frame Size Calculation ---
    
    -- A. Calculate Data Length (based on LCR[1:0] / WORD_LENGTH)
    data_length_calc: process(WORD_LENGTH)
    begin
        -- LCR[1:0]: 00=5 bits, 01=6 bits, 10=7 bits, 11=8 bits
        case WORD_LENGTH is
            when "00"   => data_length <= 5;
            when "01"   => data_length <= 6;
            when "10"   => data_length <= 7;
            when others => data_length <= 8; -- Default to 8 bits
        end case;
    end process data_length_calc;
    
    -- B. Calculate Total Frame Bits
    total_bits_calc: process(data_length, PARITY_EN, STOP_BIT_LEN)
        -- Use variables to calculate conditional integer components to avoid EX4948 error
        variable v_parity_bits : integer range 0 to 1;
        variable v_stop_bits   : integer range 1 to 2;
    begin
        -- Parity Bit: 1 if enabled (PARITY_EN='1'), 0 otherwise
        if PARITY_EN = '1' then
            v_parity_bits := 1;
        else
            v_parity_bits := 0;
        end if;
        
        -- Stop Bits: 2 if STOP_BIT_LEN='1', 1 otherwise (LCR[2]=0 is 1 stop bit)
        if STOP_BIT_LEN = '1' then
            v_stop_bits := 2;
        else
            v_stop_bits := 1;
        end if;
        
        -- Total Bits = Data Length + Start Bit (1) + Parity Bits (0/1) + Stop Bits (1/2)
        total_bits <= data_length + 1 + v_parity_bits + v_stop_bits;
    end process total_bits_calc;

    -- RX State Machine (Driven by 16x Clock, actions triggered by os_count=8)
    process(CLK)
        -- Variables for error calculation within the frame
        variable calculated_parity : std_logic;
    begin
        if rising_edge(CLK) then
            -- 1. Reset Logic
            if RESET_N = '0' then
                rx_state <= RX_IDLE;
                rx_bit_count <= 0;
                rx_data_ready <= '0';
                rx_overrun_error <= '0';
                rx_parity_error <= '0';
                rx_framing_error <= '0';
                rx_break_detect <= '0';
                rx_shift_reg <= (others => '0');
                os_count <= (others => '0'); 
                bit_tick <= '0';
            else
                
                -- --- OVERSAMPLING COUNTER LOGIC (Integrated) ---
                bit_tick <= '0'; -- Clear bit_tick every clock
                
                if brg_tick_16x = '1' then
                    os_count <= os_count + 1;
                    
                    -- Check for the center of the bit (Sample 8 of 16)
                    if os_count = 8 then
                        bit_tick <= '1';
                    end if;
                end if;
                -- ---------------------------------------------------
                
                -- --- Data Ready Clear Logic (Consolidated Fix) ---
                -- Clear DR and all error flags if Z80 read the RBR register
                if rbr_read_clear = '1' then
                    rx_data_ready <= '0'; 
                    rx_overrun_error <= '0'; 
                    rx_parity_error <= '0';
                    rx_framing_error <= '0';
                    rx_break_detect <= '0';
                end if;
                
                -- State machine logic
                case rx_state is
                    when RX_IDLE =>
                        -- Check for falling edge (Start Bit) using synchronized input
                        if RXD_sync(2 downto 1) = "10" then
                            -- Start Bit Detected: Move to wait state
                            os_count <= (others => '0'); 
                            rx_state <= RX_START_WAIT;
                        end if;
                    
                    when RX_START_WAIT =>
                        -- Wait until center of the start bit (os_count=8)
                        if os_count = 8 then
                            -- Verify if the line is still low (valid start bit)
                            if RXD_sync(2) = '0' then
                                rx_bit_count <= 0;
                                rx_state <= RX_DATA;
                            else
                                -- False start or noise, return to IDLE
                                rx_state <= RX_IDLE;
                            end if;
                        end if;
                        
                    when RX_DATA =>
                        if bit_tick = '1' then
                            -- Sample Data Bit (os_count=8)
                            rx_shift_reg <= RXD_sync(2) & rx_shift_reg(7 downto 1);
                            rx_bit_count <= rx_bit_count + 1;
                            
                            if rx_bit_count = (data_length - 1) then -- Last data bit
                                if PARITY_EN = '1' then
                                    rx_state <= RX_PARITY;
                                else
                                    rx_state <= RX_STOP;
                                end if;
                            end if;
                        end if;
                        
                    when RX_PARITY =>
                        if bit_tick = '1' then
                            -- Sample Parity Bit
                            rx_bit_count <= rx_bit_count + 1;
                            
                            -- Calculate parity check: XOR all received bits
                            calculated_parity := rx_shift_reg(0) XOR rx_shift_reg(1) XOR rx_shift_reg(2) XOR rx_shift_reg(3) XOR 
                                                rx_shift_reg(4) XOR rx_shift_reg(5) XOR rx_shift_reg(6) XOR rx_shift_reg(7);
                            
                            -- Check Parity Error (LSR[2])
                            -- Odd Parity: Parity bit should match calculated_parity
                            -- Even Parity: Parity bit should match NOT calculated_parity
                            if (EVEN_PARITY = '0' and calculated_parity /= RXD_sync(2)) or -- Odd Parity: If calculated is '1' (odd 1s), parity bit must be '1'. If calculated is '0' (even 1s), parity bit must be '0'.
                               (EVEN_PARITY = '1' and calculated_parity = RXD_sync(2)) then -- Even Parity: If calculated is '1', parity bit must be '0'. If calculated is '0', parity bit must be '1'.
                                rx_parity_error <= '1';
                            else
                                rx_parity_error <= '0'; -- No Parity Error
                            end if;
                            
                            rx_state <= RX_STOP;
                        end if;
                        
                    when RX_STOP =>
                        if bit_tick = '1' then
                            -- Sample Stop Bit (or first of two stop bits)
                            rx_bit_count <= rx_bit_count + 1;

                            -- Check Framing Error (LSR[3]): Stop bit must be '1' (high)
                            if RXD_sync(2) = '0' then
                                rx_framing_error <= '1';
                            else
                                -- Only clear framing error if a new, valid stop bit is detected.
                                -- Error propagation is typically handled by the clearing logic upon RBR read.
                                null; 
                            end if;
                            
                            -- Check Break Condition (LSR[4]): If the line has been low for the entire frame length
                            -- Note: This is a simplified check. A true break means RXD held low > frame time.
                            if rx_bit_count = total_bits and RXD_sync(2) = '0' then
                                rx_break_detect <= '1';
                            end if;

                            -- Check for two stop bits (LCR[2] = '1')
                            if STOP_BIT_LEN = '1' and rx_bit_count < (total_bits - 1) then 
                                -- If two stop bits are configured, and we are on the first stop bit.
                                null; 
                            else
                                -- Frame received, finalize data
                                if rx_data_ready = '1' then
                                    -- Overrun Error (LSR[1]): New data arrived before old was read
                                    rx_overrun_error <= '1';
                                else
                                    -- Transfer data to RBR
                                    rx_buffer <= rx_shift_reg; 
                                    rx_data_ready <= '1'; -- Set DR (LSR[0])
                                end if;
                                rx_state <= RX_IDLE;
                            end if;
                        end if;
                        
                end case;
            end if;
        end if;
    end process;
    
    -- ***************************************************************
    -- 4. TRANSMITTER (TX) LOGIC
    -- ***************************************************************

    TXD <= '1' when tx_state = TX_IDLE else tx_shift_reg(tx_bit_count);
    
    -- Main TX Process
    process(CLK)
        variable parity_enable_v : std_logic;
        variable shift_load : std_logic_vector(10 downto 0); -- Max size for 8N2 frame
        variable p_bit : std_logic;
    begin
        if rising_edge(CLK) then
            if RESET_N = '0' then
                tx_state <= TX_IDLE;
                tx_shift_reg <= (others => '1');
                tx_bit_count <= 0;
                tx_busy <= '0';
            elsif brg_tick_16x = '1' and os_count = 8 then -- Triggered by center of bit (bit_tick)
                
                -- Configuration based on LCR (for full implementation)
                parity_enable_v := PARITY_EN;
                
                -- Calculate parity bit for the TX frame (8 data bits assumed for simplicity)
                p_bit := tx_buffer(0) XOR tx_buffer(1) XOR tx_buffer(2) XOR tx_buffer(3) XOR 
                         tx_buffer(4) XOR tx_buffer(5) XOR tx_buffer(6) XOR tx_buffer(7);
                if EVEN_PARITY = '1' then p_bit := NOT p_bit; end if; 
                
                case tx_state is
                    when TX_IDLE =>
                        tx_busy <= '0';
                        if tx_data_available = '1' then
                            -- Construct the frame: [Stop Bits(1 or 2)][Parity Bit(0 or 1)][Data Bits][Start Bit(0)]
                            -- Frame bits: 0 (Start) to Data_Length-1, then Parity/Stop
                            
                            -- Load the shift register (LSB first: Start Bit is at index 0)
                            if PARITY_EN = '1' then
                                -- Parity is used. Shift register index: 0(Start), 1-8(Data), 9(Parity), 10(Stop1/Stop2)
                                shift_load := '1' & p_bit & tx_buffer & START_BIT; -- Using 11 bits for 8N2 frame [Stop2][Parity][Data][Start]
                                if STOP_BIT_LEN = '1' then -- If 2 stop bits
                                     shift_load(10) := '1';
                                else -- If 1 stop bit
                                     shift_load(10) := '0'; -- Pad the 11th bit if only one stop bit is used
                                end if;
                            else
                                -- No Parity. Shift register index: 0(Start), 1-8(Data), 9(Stop1), 10(Stop2, if enabled)
                                if STOP_BIT_LEN = '1' then -- 8N2
                                    shift_load := '1' & '1' & tx_buffer & START_BIT; -- [Stop2][Pad][Data][Start] - Pad bit is ignored by count
                                    shift_load(9) := '1'; -- Stop 1
                                else -- 8N1
                                    shift_load := '1' & '1' & tx_buffer & START_BIT; -- [Pad][Pad][Data][Start]
                                    shift_load(9) := '1'; -- Stop 1
                                    shift_load(10) := '0'; -- Pad for 11 bit max
                                end if;
                            end if;

                            tx_shift_reg <= shift_load;
                            tx_data_available <= '0'; 
                            tx_bit_count <= 0;
                            tx_state <= TX_START;
                            tx_busy <= '1';
                        end if;
                    
                    when TX_START =>
                        tx_bit_count <= tx_bit_count + 1;
                        tx_state <= TX_DATA;

                    when TX_DATA =>
                        tx_bit_count <= tx_bit_count + 1;
                        if tx_bit_count = (data_length - 1) then -- Last data bit
                            if parity_enable_v = '1' then
                                tx_state <= TX_PARITY;
                            else
                                tx_state <= TX_STOP;
                            end if;
                        end if;
                    
                    when TX_PARITY =>
                        tx_bit_count <= tx_bit_count + 1;
                        tx_state <= TX_STOP;
                        
                    when TX_STOP =>
                        tx_bit_count <= tx_bit_count + 1;
                        -- Check if all stop bits have been transmitted
                        if tx_bit_count = (total_bits - 1) then
                            tx_state <= TX_IDLE;
                        end if;
                    
                end case;
            end if;
        end if;
    end process;

    -- ***************************************************************
    -- 5. Z80 INTERFACE: Register Read/Write
    -- ***************************************************************

    -- RBR read clear signal generation (Combinational or Clocked for synchronicity)
    -- This signal is set high for one clock cycle when the Z80 reads the RBR
    -- (RBR = Offset 0, DLAB=0, RD_N=0, IORQ_N=0, CS_THIS_PORT=1)
    
    rbr_read_clear <= '1' when CS_THIS_PORT = '1' and IO_ADDR(2 downto 0) = "000" and RD_N = '0' and IORQ_N = '0' and DLAB = '0' else '0';
    -- This signal is only used by the RX state machine and only driven by this combinational logic.

    -- ** WRITE LOGIC (Z80 -> UART) **
    process(CLK)
        variable write_data : std_logic_vector(7 downto 0);
    begin
        if rising_edge(CLK) then
            if RESET_N = '0' then
                LCR <= (others => '0');
                FCR <= (others => '0'); 
                MCR <= (others => '0'); 
                tx_buffer <= (others => '0');
                tx_data_available <= '0';
                BAUD_DIVISOR_REG <= X"0001"; 
            elsif CS_THIS_PORT = '1' and WR_N = '0' and IORQ_N = '0' then
                write_data := IO_DATA_IN;
                
                case IO_ADDR(2 downto 0) is
                    when "000" => -- Offset 0
                        if DLAB = '1' then 
                            BAUD_DIVISOR_REG(7 downto 0) <= unsigned(write_data);
                        else -- Transmit Holding Register (THR)
                            if tx_data_available = '0' then
                                tx_buffer <= write_data;
                                tx_data_available <= '1'; 
                            end if;
                        end if;
                        
                    when "001" => -- Offset 1
                        if DLAB = '1' then 
                            BAUD_DIVISOR_REG(15 downto 8) <= unsigned(write_data);
                        else -- Interrupt Enable Register (IER)
                            IER_DLM <= write_data; 
                        end if;
                        
                    when "010" => -- Offset 2: FIFO Control Register (FCR)
                        FCR <= write_data; 
                        
                    when "011" => -- Offset 3: Line Control Register (LCR)
                        LCR <= write_data;
                        
                    when "100" => -- Offset 4: Modem Control Register (MCR)
                        MCR <= write_data; 
                        
                    when others => 
                        null;
                end case;
            end if;
        end if;
    end process;
    
    -- The Z80 Read Logic is now purely combinational, selecting the output data.

    with IO_ADDR(2 downto 0) select read_data <=
    -- RBR/DLL (Address 000)
    (
        std_logic_vector(BAUD_DIVISOR_REG(7 downto 0)) when DLAB = '1' else
        rx_buffer
    ) when "000",

    -- IER/DLM (Address 001)
    (
        std_logic_vector(BAUD_DIVISOR_REG(15 downto 8)) when DLAB = '1' else
        IER_DLM
    ) when "001",

    -- LCR (Address 011)
    LCR when "011",

    -- LSR (Address 101)
    -- Offset 5: Line Status Register (LSR)
    "0" & (NOT tx_busy) & (NOT tx_data_available) & rx_break_detect & rx_framing_error & rx_parity_error & rx_overrun_error & rx_data_ready when "101",
    
    -- Addresses 010, 100, 110, 111 (Default/Unused)
    (others => '0') when others; 


    -- The main bus output is driven by 'read_data' only when the Z80 read condition is met.
    IO_DATA_OUT <= 
      read_data when CS_THIS_PORT = '1' and RD_N = '0' and IORQ_N = '0' else
      (others => 'Z');
      
    -- Placeholder for control signals (CTS_N is active low)
    CTS_N <= '0'; 


end architecture Behavioral;