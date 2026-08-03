library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CPC_MMU_Bank_Sequencer is
    Port (
        clk             : in  std_logic;                     -- 50 MHz FPGA Clock
        reset_n         : in  std_logic;
        
        -- Z80 Bus Controls
        Z80_MREQ_N      : in  std_logic;                     -- Memory Request
        Z80_RD_N        : in  std_logic;                     -- Read enable
        Z80_WR_N        : in  std_logic;                     -- Write enable
        Z80_ADDR        : in  std_logic_vector(15 downto 0); -- Z80 Address Bus
        
        -- Config inputs from Gate Array
        lower_rom_en    : in  std_logic;
        upper_rom_en    : in  std_logic;
        ram_page_bank0  : in  std_logic_vector(2 downto 0);
        ram_page_bank1  : in  std_logic_vector(2 downto 0);
        ram_page_bank2  : in  std_logic_vector(2 downto 0);
        ram_page_bank3  : in  std_logic_vector(2 downto 0);

        -- Interface to MMU controller
        FPGA_BANK_WE    : out std_logic;                     -- Strobe to update MMU bank
        FPGA_BANK_SEL   : out std_logic_vector(2 downto 0); -- Target Slot (0..7)
        FPGA_BANK_PAGE  : out std_logic_vector(7 downto 0); -- Physical Page ID
        UPDATE_ACTIVE   : out std_logic                      -- '1' while sequence is running
    );
end CPC_MMU_Bank_Sequencer;

architecture Behavioral of CPC_MMU_Bank_Sequencer is

    type state_type is (IDLE, SETUP_ADDR, SETUP_ADDR1, SETUP_ADDR2, SETUP_ADDR3, SETUP_BANK, STROBE_BANK, WAIT_BUS_RELEASE);
    signal state : state_type := IDLE;

    -- Latched signals for current cycle
    signal target_slot : std_logic_vector(2 downto 0);
    signal target_page : std_logic_vector(7 downto 0);

    -- Edge detection registers
    signal z80_mreq_d  : std_logic := '1';

    -- Target physical page lookup functions
    function get_low_8k_page(ram_block : std_logic_vector(2 downto 0)) return std_logic_vector is
    begin
        case ram_block is
            when "000"  => return X"0A";
            when "001"  => return X"02";
            when "010"  => return X"04";
            when "011"  => return X"C0";
            when "100"  => return X"16";
            when "101"  => return X"18";
            when "110"  => return X"1A";
            when "111"  => return X"1C";
            when others => return X"02";
        end case;
    end function;

    function get_high_8k_page(ram_block : std_logic_vector(2 downto 0)) return std_logic_vector is
    begin
        case ram_block is
            when "000"  => return X"0B";
            when "001"  => return X"03";
            when "010"  => return X"05";
            when "011"  => return X"C1";
            when "100"  => return X"17";
            when "101"  => return X"19";
            when "110"  => return X"1B";
            when "111"  => return X"1D";
            when others => return X"03";
        end case;
    end function;

begin

    -- -------------------------------------------------------------------------
    -- 1. COMBINATIONAL LOOKUP: Instantly determine active Slot & Page (0 ns delay)
    -- -------------------------------------------------------------------------
    process(Z80_ADDR, lower_rom_en, upper_rom_en, ram_page_bank0, ram_page_bank1, ram_page_bank2, ram_page_bank3, Z80_WR_N)
        variable active_cfg : std_logic_vector(2 downto 0);
    begin
        -- Determine MMU Bank Slot Index (0..7) based on A15..A13
        target_slot <= Z80_ADDR(15 downto 13);

        -- Map top 2 bits (A15..A14) to active 16K bank configuration
        case Z80_ADDR(15 downto 14) is
            when "00"   => active_cfg := ram_page_bank0;
            when "01"   => active_cfg := ram_page_bank1;
            when "10"   => active_cfg := ram_page_bank2;
            when "11"   => active_cfg := ram_page_bank3;
            when others => active_cfg := "000";
        end case;

    -- Resolve Physical Page Number
        -- Rule: If it's a WRITE (Z80_WR_N = '0'), ignore ROM overlays completely and map to RAM.
        if Z80_WR_N = '0' then
            -- Standard RAM Write Mapping
            if Z80_ADDR(13) = '0' then
                target_page <= get_low_8k_page(active_cfg);
            else
                target_page <= get_high_8k_page(active_cfg);
            end if;

        else
            -- READ CYCLES: Check if ROM overlays are active
            if (Z80_ADDR(15 downto 14) = "00" and lower_rom_en = '1') then
                -- Lower OS ROM Read
                if Z80_ADDR(13) = '0' then
                    target_page <= X"00";
                else
                    target_page <= X"01";
                end if;

            elsif (Z80_ADDR(15 downto 14) = "11" and upper_rom_en = '1') then
                -- Upper BASIC ROM Read
                if Z80_ADDR(13) = '0' then
                    target_page <= X"08";
                else
                    target_page <= X"09";
                end if;

            else
                -- Standard RAM Read Mapping
                if Z80_ADDR(13) = '0' then
                    target_page <= get_low_8k_page(active_cfg);
                else
                    target_page <= get_high_8k_page(active_cfg);
                end if;
            end if;
        end if;
    end process;


    -- -------------------------------------------------------------------------
    -- 2. ON-DEMAND SEQUENCER STATE MACHINE (Runs in 2 Clock Ticks / 40 ns)
    -- -------------------------------------------------------------------------
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state         <= IDLE;
            FPGA_BANK_WE  <= '0';
            UPDATE_ACTIVE <= '0';
        --    z80_mreq_d    <= '1';
        elsif rising_edge(clk) then
            
         --   z80_mreq_d <= Z80_MREQ_N;

            case state is

                when IDLE =>
                    FPGA_BANK_WE  <= '0';
                    UPDATE_ACTIVE <= '0';

                    -- Detect start of memory cycle: MREQ goes low, 
                    -- AND either RD or WR has stabilized to low.
                    if (Z80_MREQ_N = '0') and (Z80_RD_N = '0' or Z80_WR_N = '0') then
                        if Z80_RD_N = '0' then
                           state         <= SETUP_ADDR;
                        else
                           state         <= SETUP_ADDR2; 
                        end if;
                        UPDATE_ACTIVE <= '1';
                    end if;

                when SETUP_ADDR =>

                    state         <= SETUP_ADDR1;

                when SETUP_ADDR1 =>

                    state         <= SETUP_ADDR2;

                when SETUP_ADDR2 =>

                    state         <= SETUP_ADDR3;

                when SETUP_ADDR3 =>

                    state         <= SETUP_BANK;

                when SETUP_BANK =>
                    -- Clock Tick 1: Output Slot, Page, and assert WE
                    FPGA_BANK_SEL  <= target_slot;
                    FPGA_BANK_PAGE <= target_page;
                    FPGA_BANK_WE   <= '1'; -- Assert WE to trigger MMU register load
                    
                    state          <= STROBE_BANK;

                when STROBE_BANK =>
                    -- Clock Tick 2: De-assert WE (Data safely latched in MMU register)
                    FPGA_BANK_WE <= '0';
                    state        <= WAIT_BUS_RELEASE;

                when WAIT_BUS_RELEASE =>
                    -- Wait until Z80 finishes current MREQ cycle before looking for next access
                    if Z80_MREQ_N = '1' then
                        state <= IDLE;
                    end if;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

end Behavioral;