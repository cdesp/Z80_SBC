--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.12 (64-bit)
--Part Number: GW5A-LV25MG121NC1/I0
--Device: GW5A-25
--Device Version: A
--Created Time: Sat Jun  6 16:33:06 2026

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component UART_MASTER_Top
	port (
		I_CLK: in std_logic;
		I_RESETN: in std_logic;
		I_TX_EN: in std_logic;
		I_WADDR: in std_logic_vector(2 downto 0);
		I_WDATA: in std_logic_vector(7 downto 0);
		I_RX_EN: in std_logic;
		I_RADDR: in std_logic_vector(2 downto 0);
		O_RDATA: out std_logic_vector(7 downto 0);
		SIN: in std_logic;
		RxRDYn: out std_logic;
		SOUT: out std_logic;
		TxRDYn: out std_logic;
		DDIS: out std_logic;
		INTR: out std_logic;
		DCDn: in std_logic;
		CTSn: in std_logic;
		DSRn: in std_logic;
		RIn: in std_logic;
		DTRn: out std_logic;
		RTSn: out std_logic
	);
end component;

your_instance_name: UART_MASTER_Top
	port map (
		I_CLK => I_CLK,
		I_RESETN => I_RESETN,
		I_TX_EN => I_TX_EN,
		I_WADDR => I_WADDR,
		I_WDATA => I_WDATA,
		I_RX_EN => I_RX_EN,
		I_RADDR => I_RADDR,
		O_RDATA => O_RDATA,
		SIN => SIN,
		RxRDYn => RxRDYn,
		SOUT => SOUT,
		TxRDYn => TxRDYn,
		DDIS => DDIS,
		INTR => INTR,
		DCDn => DCDn,
		CTSn => CTSn,
		DSRn => DSRn,
		RIn => RIn,
		DTRn => DTRn,
		RTSn => RTSn
	);

----------Copy end-------------------
