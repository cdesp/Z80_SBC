library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_div_18432 is
    port (
        clk_in   : in  std_logic; -- 50 MHz Main FPGA clock
        rst      : in  std_logic; -- Active high master reset
        clk_out  : out std_logic  -- Average 1.8432 MHz output clock
    );
end clk_div_18432;

architecture rtl of clk_div_18432 is
    -- 16-bit phase accumulator. 
    -- Step value (M) = round((1.8432 MHz / 50 MHz) * 2^16) = 2416
    constant INC_VALUE   : unsigned(15 downto 0) := to_unsigned(2416, 16);
    signal accumulator   : unsigned(15 downto 0) := (others => '0');
    signal clk_toggle    : std_logic := '0';
begin

    process(clk_in)
    begin
        if rising_edge(clk_in) then
            if rst = '1' then
                accumulator <= (others => '0');
                clk_toggle  <= '0';
            else
                accumulator <= accumulator + INC_VALUE;
                
                -- Use the most significant bit (MSB) as a 50% duty cycle clock
                clk_toggle <= accumulator(15);
            end if;
        end if;
    end process;

    clk_out <= clk_toggle;

end rtl;
