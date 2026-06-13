LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;

-- Component: regn
-- Description: Generic N-bit synchronous register with an active-low asynchronous reset 
-- and an **active-low synchronous load enable (Loadn)**.
ENTITY regn IS
    GENERIC (
        N    : INTEGER := 8;
        -- INIT value is configured to be the default reset value
        INIT : STD_LOGIC_VECTOR(8-1 DOWNTO 0) := (OTHERS => '0')
    );
    PORT ( 
        D       : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0) ; -- Data Input
        Loadn   : IN  STD_LOGIC ;                      -- Load Enable (Active Low, only loads D when '0')
        Resetn  : IN  STD_LOGIC ;                      -- Asynchronous Reset (Active Low)
        Clock   : IN  STD_LOGIC ;                      -- Clock Input
        Q       : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)   -- Registered Data Output
    );
END ENTITY regn;

ARCHITECTURE behavioral OF regn IS
BEGIN
    PROCESS (Clock, Resetn)
    BEGIN
        IF Resetn = '0' THEN
            -- Asynchronous Reset
            Q <= INIT; 
        ELSIF rising_edge(Clock) THEN
            -- Synchronous Load controlled by Loadn
            IF Loadn = '0' THEN
                Q <= D;
            END IF;
        END IF;
    END PROCESS;
END behavioral;