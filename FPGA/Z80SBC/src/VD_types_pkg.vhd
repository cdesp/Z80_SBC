library ieee;
use ieee.std_logic_1164.all;

package VD_types_pkg is
    -- Standardized output from any Video System module
    type video_bus_out is record
        r_8    : std_logic_vector(7 downto 0);
        g_8    : std_logic_vector(7 downto 0);
        b_8    : std_logic_vector(7 downto 0);
        h_sync : std_logic;
        v_sync : std_logic;
        de     : std_logic; -- Data Enable (Active Video)
    end record;

    -- Standardized input to any Video System module
    type video_bus_in is record
        clk_pixel : std_logic;
        nreset    : std_logic;
        h_cnt     : integer range 0 to 2047;
        v_cnt     : integer range 0 to 2047;
    end record;
end package;