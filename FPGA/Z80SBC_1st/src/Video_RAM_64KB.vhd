library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Define a 64KB (2^16 addresses) Dual-Port SRAM for Video RAM (VRAM).
-- Port A: CPU access (Synchronous to CLK_Z80, supports R/W).
-- Port B: Video Controller access (Synchronous to CLK_VIDEO, Read-Only).
entity Video_RAM_64KB is
    port (
        -- === Port A: CPU Interface (Z80) ===
        CLK_Z80     : in  std_logic;                                   -- Z80 Clock (used for synchronous R/W)
        nRESET      : in  std_logic;                                   -- Global Reset (Active Low)
        nCE_A       : in  std_logic;                                   -- Chip Enable (from MMU's nCE2, Active Low)
        nWE_A       : in  std_logic;                                   -- Write Enable (from MMU's nWR_OUT, Active Low)
        nRD_A       : in  std_logic;                                   -- Read Enable (from Z80 /RD_N, Active Low)
        ADDR_A      : in  std_logic_vector(15 downto 0);               -- Z80 Address Bus (A0-A15)
        DATA_IN_A   : in  std_logic_vector(7 downto 0);                -- Data Bus from Z80
        DATA_OUT_A  : out std_logic_vector(7 downto 0);                -- Data Bus to Z80

        -- === Port B: Video Controller Interface ===
        CLK_VIDEO   : in  std_logic;                                   -- High-speed Video Clock (for sequential Read)
        ADDR_B      : in  std_logic_vector(15 downto 0);               -- Video Scan Address (A0-A15)
        DATA_OUT_B  : out std_logic_vector(7 downto 0)                 -- Data Bus to Video Controller (Pixel Data)
    );
end Video_RAM_64KB;

architecture rtl of Video_RAM_64KB is

    -- The Memory Array Type: 65536 addresses x 8 bits
    type RAM_ARRAY is array (0 to 65535) of std_logic_vector(7 downto 0);
    signal RAM : RAM_ARRAY := (others => (others => '0')); -- Initialize memory content to zero

    -- Internal signal for synchronous CPU read data
    signal READ_DATA_A_REG : std_logic_vector(7 downto 0) := (others => '0');
    -- Internal signal for synchronous Video read data
    signal READ_DATA_B_REG : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- ***************************************************************
    -- ** PORT A: CPU Access Logic (Read/Write) **
    -- ***************************************************************

    process (CLK_Z80)
    begin
        if rising_edge(CLK_Z80) then
            -- 1. Asynchronous Reset (Resets the RAM content to all zeros)
            if nRESET = '0' then
                RAM <= (others => (others => '0'));
            
            -- 2. Write Operation (Synchronous write, active low control signals)
            elsif (nCE_A = '0') and (nWE_A = '0') then
                -- Perform write: convert address to integer and write data
                RAM(to_integer(unsigned(ADDR_A))) <= DATA_IN_A;
                
            -- 3. Read Operation (Synchronous read, active low control signals)
            -- Reads are pipeline registered for better timing in FPGAs (output available 1 cycle later)
            elsif (nCE_A = '0') and (nRD_A = '0') then
                -- Register the data from the memory location
                READ_DATA_A_REG <= RAM(to_integer(unsigned(ADDR_A)));
            end if;
        end if;
    end process;

    -- Output registered data to the Z80 data bus
    -- Data is only driven onto the bus if Chip Enable and Read are both active (Active Low)
    -- This acts as a tri-state, but FPGAs typically use output enables.
    -- Assuming a dedicated buffer or the Z80_DATA_OE signal (handled in the top level) 
    -- will manage the tri-state, here we just control the output data.
    DATA_OUT_A <= READ_DATA_A_REG when (nCE_A = '0' and nRD_A = '0') else (others => 'Z');


    -- ***************************************************************
    -- ** PORT B: Video Controller Access Logic (Read-Only) **
    -- ***************************************************************
    
    -- The Video Controller port is generally simpler and read-only.
    -- It is clocked by the high-frequency video clock (CLK_VIDEO).
    process (CLK_VIDEO)
    begin
        if rising_edge(CLK_VIDEO) then
            -- No write access from the video port.
            -- Read is always happening synchronously to the video clock.
            READ_DATA_B_REG <= RAM(to_integer(unsigned(ADDR_B)));
        end if;
    end process;
    
    -- Output registered data to the Video Controller
    DATA_OUT_B <= READ_DATA_B_REG;

end rtl;