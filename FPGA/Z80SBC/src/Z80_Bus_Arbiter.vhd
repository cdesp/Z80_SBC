LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;
USE work.defs_pkg.ALL; -- Import MMU I/O address constants

ENTITY Z80_Bus_Arbiter IS
    PORT (
        -- Z80 Side
        CLK                 : IN STD_LOGIC;                     -- Z80 Operating Clock (e.g., 8MHz)
        nRESET              : IN STD_LOGIC;
        Z80_IORQ_N          : IN STD_LOGIC;                     -- Z80 I/O Request (Active Low)
        Z80_WR_N            : IN STD_LOGIC;                     -- Z80 Write Strobe (Active Low)
        Z80_RD_N            : IN STD_LOGIC;                     -- Z80 Read Strobe (Active Low)
        Z80_ADDR            : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- Full Z80 Address Bus (A0-A15)
        
        -- MMU Control Outputs (Generated from I/O Decode)
        MMU_nMAP_REG_N      : OUT STD_LOGIC;                    -- MMU Map Reg Port (OUT (00h), PageNo)
        MMU_nSET_RO_N       : OUT STD_LOGIC;                    -- MMU Set Read-Only Port (OUT (01h), PageNo)
        MMU_nSET_RW_N       : OUT STD_LOGIC;                    -- MMU Set Read/Write Port (OUT (02h), PageNo)
        
        -- Peripheral Decoding Outputs (Configurable for Emulation)
        DEV1                : OUT STD_LOGIC;                    -- 74LS139 Input A (L/S Bit)
        DEV2                : OUT STD_LOGIC;                    -- 74LS139 Input B (M/S Bit)
        -- LS138_nCS_N and LAY_SEL are removed, as the 74LS138 is assumed to be permanently enabled,
        -- and AY control logic is derived from 74LS138 outputs and Z80 address lines.
        CLK_SEL_RG_N        : OUT std_logic;                    -- for clock selection
        UART_CS_N           : OUT std_logic;                    -- for UART RS232 Selection
        PS2_DS_N            : OUT std_logic;                    -- for PS/2 Keyboard Device communication
        VD_DS_N             : OUT std_logic;                    -- for Video Device Communication
        -- Wait State Generation
        Z80_WAIT_N          : OUT STD_LOGIC;                    -- Z80 Wait Request (Active Low)
        
        -- Interrupt Management
        INT_REQ_N           : IN STD_LOGIC;                     -- Master Peripheral Interrupt Request (Active Low)
        Z80_INT_N           : OUT STD_LOGIC                     -- Z80 Interrupt Pin (Active Low)
    );
END Z80_Bus_Arbiter;

ARCHITECTURE behavioral OF Z80_Bus_Arbiter IS
    
    -- Internal signal for I/O Address (A0-A7)
    SIGNAL Z80_IO_ADDR      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    -- Signal to hold current wait state logic (default is no wait, '1')
    SIGNAL internal_wait_n  : STD_LOGIC; 
    
    -- 2-bit vector to hold the calculated BA inputs for the 74LS139 (B=DEV2, A=DEV1)
    SIGNAL LS139_BA_OUT : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ISLS139 : STD_LOGIC :='1';
BEGIN
    
    -- Map lower 8 bits of Z80 address bus for I/O decoding
    Z80_IO_ADDR <= Z80_ADDR(7 DOWNTO 0);
    
                       
    -- ***************************************************************
    -- ** 1. 74LS138 INPUTS (DEV0-DEV2) - Configurable for Emulation **
    -- ***************************************************************
    
    -- This PROCESS implements the flexible I/O port mapping.
    -- When a specific Z80 I/O address is accessed, we calculate the required CBA input 
    -- to activate the desired Y output on the 74LS138.
    
    PROCESS (Z80_IORQ_N, Z80_IO_ADDR)
    BEGIN
        -- Default to unused Y0 (CBA = 000) when not performing an I/O request.
        -- This drives Y0 to active low, which is assumed not to be connected to a peripheral.
        LS139_BA_OUT <= B"00"; --pin 7 unconnected
        ISLS139 <='1';
        IF (Z80_IORQ_N = '0') THEN -- Only calculate if I/O Request is active
            CASE Z80_IO_ADDR IS
                -- Custom Decoding Examples (as per user request)
                WHEN C_LS139_Y1 => 
                    -- OUT (40h, Data) activates Y1 (BA = 01) 
                    LS139_BA_OUT <= B"01";   --pin 6 LAUD_MUX_N
                    ISLS139 <='0';
                WHEN C_LS139_Y2 => 
                    -- OUT (41h, Data) activates Y2 (CBA = 010)
                    LS139_BA_OUT <= B"10";   --pin 5 LAUD_CS_N 
                    ISLS139 <='0';
                WHEN C_LS139_Y3_0 => 
                    -- OUT (30h, CMD) activates Y3 (CBA = 011)
                    LS139_BA_OUT <= B"11";   --pin 3 CH376_CS_N
                    ISLS139 <='0';
                WHEN C_LS139_Y3_1 => --NEEDS 2 ADDRESSES
                    -- OUT (31h, Data) activates Y3 (CBA = 011)
                    LS139_BA_OUT <= B"11";   --pin 3 CH376_CS_N
                    ISLS139 <='0';
                WHEN OTHERS => 
                    -- For all other addresses, we default to using the lowest 2 address bits pin 15 unconnected                    
                    LS139_BA_OUT <= B"00";
            END CASE;
        END IF;

    END PROCESS;
    
    -- Assign the calculated CBA outputs to the physical DEV pins
    DEV2 <= LS139_BA_OUT(1) WHEN (Z80_IORQ_N = '0'  AND ISLS139 = '0')
                      ELSE '0'; -- 74LS139 Input B
    DEV1 <= LS139_BA_OUT(0) WHEN (Z80_IORQ_N = '0'  AND ISLS139 = '0')
                      ELSE '0'; -- 74LS139 Input A
    
    -- ***************************************************************
    -- ** 2. MMU I/O PORT DECODING (Z80 OUT commands) **
    -- ***************************************************************
       
    -- Port 0: Write Page Mapping Registers (C_MMU_MAP_REG_ADDR = x"00")
    MMU_nMAP_REG_N <= '0' WHEN (Z80_IORQ_N = '0' AND Z80_WR_N = '0' AND Z80_IO_ADDR = C_MMU_MAP_REG_ADDR)
                      ELSE '1';
                      
    -- Port 1: Set Read-Only Protection (C_MMU_SET_RO_ADDR = x"01")
    MMU_nSET_RO_N  <= '0' WHEN (Z80_IORQ_N = '0' AND Z80_WR_N = '0' AND Z80_IO_ADDR = C_MMU_SET_RO_ADDR)
                      ELSE '1';
                      
    -- Port 2: Set Read/Write Protection (C_MMU_SET_RW_ADDR = x"02")
    MMU_nSET_RW_N  <= '0' WHEN (Z80_IORQ_N = '0' AND Z80_WR_N = '0' AND Z80_IO_ADDR = C_MMU_SET_RO_ADDR)
                      ELSE '1';
                      
    -- Z80 Clock Selection Register Write Strobe Generation
    -- This signal is active low when the Z80 reads/writes  to the I/O port (nIORQ=0)
    -- whose address matches the CLK_SEL_PORT_ADDR (x"80").
    CLK_SEL_RG_N <= '0' when (Z80_IORQ_N = '0' and Z80_IO_ADDR(7 downto 0) = CLK_SEL_PORT_ADDR)
                   else '1';

    UART_CS_N <= '0' when (Z80_IORQ_N = '0' and  Z80_IO_ADDR(7 downto 3) = UART_PORT_BASE(7 downto 3)) 
                  else '1';

    PS2_DS_N <= '0' when (Z80_IORQ_N = '0' and Z80_IO_ADDR = C_PS2_PORT_ADDR)
                  else '1';

    VD_DS_N <= '0' when (Z80_IORQ_N = '0' and Z80_IO_ADDR = C_VD_PORT_ADDR)
                  else '1';

    -- ***************************************************************
    -- ** 3. WAIT STATE GENERATION **
    -- ***************************************************************
    
    -- Placeholder: For the moment, assert Z80_WAIT_N high (no wait states)
    internal_wait_n <= '1';
    
    Z80_WAIT_N <= internal_wait_n;


    -- ***************************************************************
    -- ** 4. INTERRUPT MANAGEMENT **
    -- ***************************************************************
    
    -- Pass the master peripheral interrupt request directly to the Z80 (Active Low)
    Z80_INT_N <= INT_REQ_N;
    
END behavioral;