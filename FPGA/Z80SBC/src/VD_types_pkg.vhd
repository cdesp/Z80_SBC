library ieee;
use ieee.std_logic_1164.all;

package VD_types_pkg is

    -- Constant declarations (place these before 'begin' in your architecture)
    constant VGA_BLACK        : integer := 0;
    constant VGA_BLUE         : integer := 1;
    constant VGA_GREEN        : integer := 2;
    constant VGA_CYAN         : integer := 3;
    constant VGA_RED          : integer := 4;
    constant VGA_MAGENTA      : integer := 5;
    constant VGA_BROWN        : integer := 6;
    constant VGA_LIGHTGRAY    : integer := 7;
    constant VGA_DARKGRAY     : integer := 8;
    constant VGA_LIGHTBLUE    : integer := 9;
    constant VGA_LIGHTGREEN   : integer := 10;
    constant VGA_LIGHTCYAN    : integer := 11;
    constant VGA_LIGHTRED     : integer := 12;
    constant VGA_LIGHTMAGENTA : integer := 13;
    constant VGA_YELLOW       : integer := 14;
    constant VGA_WHITE        : integer := 15;

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
        h_sync    : std_logic;
        v_sync    : std_logic;
        de        : std_logic; -- Data Enable (Active Video)
    end record;
end package;