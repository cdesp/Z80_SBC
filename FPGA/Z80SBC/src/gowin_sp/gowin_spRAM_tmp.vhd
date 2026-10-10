--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.12 (64-bit)
--Part Number: GW5A-LV25MG121NC1/I0
--Device: GW5A-25
--Device Version: A
--Created Time: Thu Oct  8 18:36:25 2026

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_SPRAM
    port (
        dout: out std_logic_vector(7 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        wre: in std_logic;
        ad: in std_logic_vector(2 downto 0);
        din: in std_logic_vector(7 downto 0)
    );
end component;

your_instance_name: Gowin_SPRAM
    port map (
        dout => dout,
        clk => clk,
        oce => oce,
        ce => ce,
        reset => reset,
        wre => wre,
        ad => ad,
        din => din
    );

----------Copy end-------------------
