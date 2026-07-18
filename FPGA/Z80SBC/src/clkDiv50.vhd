library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
  
entity Clock_Divider  is
    generic (
        CYCLE_COUNT : integer := 650000 -- Default to 13ms at 50MHz
    );
    port ( 
        clk        : in  std_logic;
        reset      : in  std_logic;
        clock_out  : out std_logic -- High for exactly 1 clock cycle every period
    );
end Clock_Divider ;
  
architecture rtl of Clock_Divider  is
    -- Limit the integer range to save FPGA logic gates
    signal count : integer range 0 to CYCLE_COUNT := 0;
begin
  
    process(clk, reset)
    begin
        if reset = '0' then
            count      <= 0;
            clock_out <= '0';
        elsif rising_edge(clk) then
            -- Default state
            clock_out <= '0';
            
            if count >= (CYCLE_COUNT - 1) then
                count      <= 0;
                clock_out <= '1'; -- Strobe triggers for exactly 1 clock cycle
            else
                count      <= count + 1;
            end if;
        end if;
    end process;
  
end rtl;