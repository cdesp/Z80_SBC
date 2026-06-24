--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.12 (64-bit)
--Part Number: GW5A-LV25MG121NC1/I0
--Device: GW5A-25
--Device Version: A
--Created Time: Wed Jun 24 12:54:47 2026

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component DPVRAM
    port (
        douta: out std_logic_vector(7 downto 0);
        doutb: out std_logic_vector(7 downto 0);
        clka: in std_logic;
        ocea: in std_logic;
        cea: in std_logic;
        reseta: in std_logic;
        wrea: in std_logic;
        clkb: in std_logic;
        oceb: in std_logic;
        ceb: in std_logic;
        resetb: in std_logic;
        wreb: in std_logic;
        ada: in std_logic_vector(15 downto 0);
        dina: in std_logic_vector(7 downto 0);
        adb: in std_logic_vector(15 downto 0);
        dinb: in std_logic_vector(7 downto 0)
    );
end component;

your_instance_name: DPVRAM
    port map (
        douta => douta,
        doutb => doutb,
        clka => clka,
        ocea => ocea,
        cea => cea,
        reseta => reseta,
        wrea => wrea,
        clkb => clkb,
        oceb => oceb,
        ceb => ceb,
        resetb => resetb,
        wreb => wreb,
        ada => ada,
        dina => dina,
        adb => adb,
        dinb => dinb
    );

----------Copy end-------------------
