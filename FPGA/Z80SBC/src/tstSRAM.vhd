library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sram_test_controller is
    Port (
        clk          : in  STD_LOGIC;                      -- Main FPGA Clock
        reset_n      : in  STD_LOGIC;                      -- Active Low Reset
        start_test   : in  STD_LOGIC;                      -- Trigger test routine
        
        -- Physical SRAM Interface Pins
        sram_addr    : out STD_LOGIC_VECTOR(18 downto 0); -- Physical Address Bus
        sram_data    : inout STD_LOGIC_VECTOR(7 downto 0); -- Physical Data Bus
        sram_we_n    : out STD_LOGIC;                      -- Write Enable
        sram_oe_n    : out STD_LOGIC;                      -- Output Enable
        sram_ce_n    : out STD_LOGIC;                      -- Chip Enable
        
        -- Status LEDs / Output Flags
        test_running : out STD_LOGIC;
        test_passed  : out STD_LOGIC;                      -- High if 512+ block is independent
        test_failed  : out STD_LOGIC                       -- High if 512+ block mirrors 0+
    );
end sram_test_controller;

architecture Behavioral of sram_test_controller is

    -- Test Parameters
    type data_array is array (0 to 4) of unsigned(7 downto 0);
    constant test_values : data_array := (
        x"05", -- Val at Addr 0
        x"FA", -- Val at Addr 1 (250)
        x"05", -- Val at Addr 2
        x"FA", -- Val at Addr 3 (250)
        x"05"  -- Val at Addr 4
    );

    -- State Machine
    type state_type is (IDLE, 
                        WRITE_SET_ADDR, WRITE_PULSE_LOW, WRITE_HOLD, WRITE_NEXT,
                        READ_LOW_SET, READ_LOW_PULSE, READ_LOW_SAVE, READ_LOW_NEXT,
                        READ_HIGH_SET, READ_HIGH_PULSE, READ_HIGH_SAVE, READ_HIGH_NEXT,
                        EVALUATE);
    signal state : state_type := IDLE;

    -- Internal Registers
    signal index        : integer range 0 to 5 := 0;
    signal data_out_reg : unsigned(7 downto 0) := x"00";
    signal sram_is_out  : std_logic := '0';
    
    -- Arrays to hold the actual read results for verification
    type read_array is array (0 to 4) of std_logic_vector(7 downto 0);
    signal low_block_data  : read_array := (others => (others => '0'));
    signal high_block_data : read_array := (others => (others => '0'));

begin

    -- Bi-directional Data Bus Control
    sram_data <= std_logic_vector(data_out_reg) when (sram_is_out = '1') else (others => 'Z');
    sram_ce_n <= '0'; -- Keep chip enabled throughout the test sequence

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state           <= IDLE;
            sram_we_n       <= '1';
            sram_oe_n       <= '1';
            sram_is_out     <= '0';
            sram_addr       <= (others => '0');
            index           <= 0;
            test_running    <= '0';
            test_passed     <= '0';
            test_failed     <= '0';
            low_block_data  <= (others => (others => '0'));
            high_block_data <= (others => (others => '0'));
            
        elsif rising_edge(clk) then
            case state is
                
                when IDLE =>
                    sram_we_n    <= '1';
                    sram_oe_n    <= '1';
                    sram_is_out  <= '0';
                    index        <= 0;
                    if start_test = '1' then
                        test_running <= '1';
                        test_passed  <= '0';
                        test_failed  <= '0';
                        state        <= WRITE_SET_ADDR;
                    end if;

                ---------------------------------------------------------------
                -- WRITE PHASE: Write values to addresses 0, 1, 2, 3, 4
                ---------------------------------------------------------------
                when WRITE_SET_ADDR =>
                    sram_addr    <= std_logic_vector(to_unsigned(index, 19));
                    data_out_reg <= test_values(index);
                    sram_is_out  <= '1'; -- Drive the data bus
                    state        <= WRITE_PULSE_LOW;
                    
                when WRITE_PULSE_LOW =>
                    sram_we_n    <= '0'; -- Assert WE_n LOW
                    state        <= WRITE_HOLD;
                    
                when WRITE_HOLD =>
                    sram_we_n    <= '1'; -- Pull WE_n HIGH (Data captures here)
                    state        <= WRITE_NEXT;
                    
                when WRITE_NEXT =>
                    sram_is_out  <= '0'; -- Release data bus
                    if index = 4 then
                        index <= 0;
                        state <= READ_LOW_SET; -- Move to verification phases
                    else
                        index <= index + 1;
                        state <= WRITE_SET_ADDR;
                    end if;

                ---------------------------------------------------------------
                -- READ PHASE 1: Read back from addresses 0, 1, 2, 3, 4
                ---------------------------------------------------------------
                when READ_LOW_SET =>
                    sram_addr <= std_logic_vector(to_unsigned(index, 19));
                    state     <= READ_LOW_PULSE;
                    
                when READ_LOW_PULSE =>
                    sram_oe_n <= '0'; -- Assert OE_n LOW
                    state     <= READ_LOW_SAVE;
                    
                when READ_LOW_SAVE =>
                    low_block_data(index) <= sram_data; -- Capture output bus
                    sram_oe_n             <= '1';
                    state                 <= READ_LOW_NEXT;
                    
                when READ_LOW_NEXT =>
                    if index = 4 then
                        index <= 0;
                        state <= READ_HIGH_SET; -- Move to checking the 512 offset
                    else
                        index <= index + 1;
                        state <= READ_LOW_SET;
                    end if;

                ---------------------------------------------------------------
                -- READ PHASE 2: Read from offset 512 (512, 513, 514, 515, 516)
                ---------------------------------------------------------------
                when READ_HIGH_SET =>
                    -- Address = 512 + index
                    sram_addr <= std_logic_vector(to_unsigned(512 + index, 19));
                    state     <= READ_HIGH_PULSE;
                    
                when READ_HIGH_PULSE =>
                    sram_oe_n <= '0';
                    state     <= READ_HIGH_SAVE;
                    
                when READ_HIGH_SAVE =>
                    high_block_data(index) <= sram_data; -- Capture offset data
                    sram_oe_n              <= '1';
                    state                  <= READ_HIGH_NEXT;
                    
                when READ_HIGH_NEXT =>
                    if index = 4 then
                        state <= EVALUATE;
                    else
                        index <= index + 1;
                        state <= READ_HIGH_SET;
                    end if;

                ---------------------------------------------------------------
                -- EVALUATION PHASE: Compare the two captured blocks
                ---------------------------------------------------------------
                when EVALUATE =>
                    test_running <= '0';
                    
                    -- Check if the bytes at 512+ match the bytes written to 0+
                    if (low_block_data(0) = high_block_data(0)) and
                       (low_block_data(1) = high_block_data(1)) and
                       (low_block_data(2) = high_block_data(2)) and
                       (low_block_data(3) = high_block_data(3)) and
                       (low_block_data(4) = high_block_data(4)) then
                        
                        -- If they are identical, the glitch is present (Mirroring occurred)
                        test_failed <= '1';
                        test_passed <= '0';
                    else
                        -- If they are different, the chip successfully differentiated them!
                        test_passed <= '1';
                        test_failed <= '0';
                    end if;
                    
                    state <= IDLE;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;