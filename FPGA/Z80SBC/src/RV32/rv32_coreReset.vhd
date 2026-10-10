library ieee;
use ieee.std_logic_1164.all;

entity core_reset_gen is
    port (
        clk         : in  std_logic;
        loader_done : in  std_logic; -- Signals loader completion
        core_resetn : out std_logic  -- One-cycle active-low reset pulse to core
    );
end entity core_reset_gen;

architecture rtl of core_reset_gen is
    signal loader_done_d : std_logic := '0';
    signal pulse_n       : std_logic := '1';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Register loader_done to catch its rising edge
            loader_done_d <= loader_done;

            -- Detect rising edge: loader_done is '1' now, was '0' last cycle
            if (loader_done = '1' and loader_done_d = '0') then
                pulse_n <= '0'; -- Trigger 1-cycle active-low pulse
            else
                pulse_n <= '1'; -- Return high
            end if;
        end if;
    end process;

    -- Core is held in reset while loader runs (loader_done = '0'),
    -- pulsed low for 1 cycle when done, then released high ('1').
    core_resetn <= loader_done and pulse_n;

end architecture rtl;