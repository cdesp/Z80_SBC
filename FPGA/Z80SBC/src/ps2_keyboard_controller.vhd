-- ps2_keyboard_controller.vhd
-- Handles bidirectional PS/2 protocol for keyboard data and LED control.
-- Implements "Open-Drain" logic for 3.3V to 5V safe communication.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PS2_Keyboard_Controller is
    generic (
        CLK_FREQ_MHZ : integer := 50 -- Adjust based on your system clock
    );
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
end entity PS2_Keyboard_Controller;

architecture BEHAVIORAL of PS2_Keyboard_Controller is

    -- Timing constants for PS/2 protocol
    constant TIMEOUT_100US : integer := CLK_FREQ_MHZ * 100;
    
    -- Filter signals to avoid noise on PS2_CLK
    signal clk_filter      : std_logic_vector(7 downto 0) := (others => '1');
    signal ps2_clk_clean   : std_logic := '1';
    signal ps2_clk_edge    : std_logic := '0';

    -- FSM States
    type state_type is (IDLE, RX_BITS, TX_INHIBIT, TX_REQ_TO_SEND, TX_BITS, TX_ACK_WAIT);
    signal state : state_type := IDLE;

    -- Shift registers and counters
    signal bit_cnt         : integer range 0 to 11 := 0;
    signal shift_reg       : std_logic_vector(10 downto 0) := (others => '0');
    signal timer           : integer := 0;
    
    -- Tristate Control logic
    -- '0' = Force Low, '1' = High Impedance (let pull-up work)
    signal clk_out_en      : std_logic := '1'; 
    signal data_out_en     : std_logic := '1';

begin

    -- Open-Drain Implementation: 
    -- We only drive '0'. To drive '1', we go to High-Z and let pull-up do the work.
    PS2_CLK  <= '0' when clk_out_en = '0' else 'Z';
    PS2_DATA <= '0' when data_out_en = '0' else 'Z';

    -- Simple Glitch Filter for PS2_CLK
    process(CLK)
    begin
        if rising_edge(CLK) then
            clk_filter <= clk_filter(6 downto 0) & PS2_CLK;
            if clk_filter = "11111111" then
                ps2_clk_clean <= '1';
            elsif clk_filter = "00000000" then
                ps2_clk_clean <= '0';
            end if;
            
            -- Detect Falling Edge
            if clk_filter(7) = '1' and ps2_clk_clean = '0' then
                ps2_clk_edge <= '1';
            else
                ps2_clk_edge <= '0';
            end if;
        end if;
    end process;

    -- Main State Machine
    process(CLK, nRESET)
        variable parity : std_logic;
    begin
        if nRESET = '0' then
            state <= IDLE;
            RX_READY_O <= '0';
            TX_BUSY_O <= '0';
            clk_out_en <= '1';
            data_out_en <= '1';
            bit_cnt <= 0;
        elsif rising_edge(CLK) then
            RX_READY_O <= '0'; -- Default pulse

            case state is
                
                when IDLE =>
                    TX_BUSY_O <= '0';
                    clk_out_en <= '1';
                    data_out_en <= '1';
                    bit_cnt <= 0;
                    
                    if TX_START_I = '1' then
                        state <= TX_INHIBIT;
                        timer <= 0;
                        TX_BUSY_O <= '1';
                    elsif ps2_clk_edge = '1' and PS2_DATA = '0' then -- Start bit detected
                        state <= RX_BITS;
                        bit_cnt <= 0;
                    end if;

                when RX_BITS =>
                    if ps2_clk_edge = '1' then
                        if bit_cnt < 9 then -- 8 data + 1 parity
                            shift_reg(bit_cnt) <= PS2_DATA;
                            bit_cnt <= bit_cnt + 1;
                        else -- Stop bit
                            RX_DATA_O <= shift_reg(7 downto 0);
                            RX_READY_O <= '1';
                            state <= IDLE;
                        end if;
                    end if;

                -- Command Transmission Logic (Inhibit Bus)
                when TX_INHIBIT =>
                    clk_out_en <= '0'; -- Pull clock low for 100us
                    if timer < TIMEOUT_100US then
                        timer <= timer + 1;
                    else
                        state <= TX_REQ_TO_SEND;
                        data_out_en <= '0'; -- Pull Data Low (Request to Send)
                    end if;

                when TX_REQ_TO_SEND =>
                    clk_out_en <= '1'; -- Release clock
                    if ps2_clk_edge = '1' then -- Wait for keyboard to start clocking
                        bit_cnt <= 0;
                        state <= TX_BITS;
                        -- Prep shift register: Data(8) + Parity(1) + Stop(1)
                        -- Logic: calc odd parity
                        parity := not (TX_DATA_I(0) xor TX_DATA_I(1) xor TX_DATA_I(2) xor TX_DATA_I(3) xor 
                                       TX_DATA_I(4) xor TX_DATA_I(5) xor TX_DATA_I(6) xor TX_DATA_I(7));
                        shift_reg(7 downto 0) <= TX_DATA_I; -- Fixed: changed from (0 downto 7)
                        shift_reg(8) <= parity;
                        shift_reg(9) <= '1'; -- Stop bit
                    end if;

                when TX_BITS =>
                    if ps2_clk_edge = '1' then
                        if bit_cnt < 10 then
                            if shift_reg(bit_cnt) = '0' then
                                data_out_en <= '0';
                            else
                                data_out_en <= '1';
                            end if;
                            bit_cnt <= bit_cnt + 1;
                        else
                            data_out_en <= '1'; -- Release data
                            state <= TX_ACK_WAIT;
                        end if;
                    end if;

                when TX_ACK_WAIT =>
                    if ps2_clk_edge = '1' then
                        TX_ACK_ERROR_O <= PS2_DATA; -- Keyboard should pull low for ACK
                        state <= IDLE;
                    end if;

                when others => state <= IDLE;
            end case;
        end if;
    end process;

end architecture BEHAVIORAL;