LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;
USE work.defs_pkg.ALL; -- Import MMU I/O address constants

ENTITY Z80_BA_Bootloader IS
    PORT (
        CLK_FPGA            : in  std_logic;
        -- Z80 Side
        CLK                 : IN STD_LOGIC;                     -- Z80 Operating Clock (e.g., 8MHz)
        nRESET              : IN STD_LOGIC;
       -- All Z80 inputs bundled together
        Z80_In              : IN  t_z80_to_system;
        -- All system outputs bundled together
        Z80_Out             : OUT t_system_to_z80;
        -- Other signals
        OTSigs_in           : IN t_ot_sigs_to_system;
        OTSigs_out          : OUT t_ot_sigs_from_system;
        -- Video registers
        VDRegs_out          : OUT t_video_regs
    );
END Z80_BA_Bootloader;

ARCHITECTURE behavioral OF Z80_BA_Bootloader IS
    
    -- Internal signal for I/O Address (A0-A7)
    SIGNAL Z80_IO_ADDR      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    -- Signal to hold current wait state logic (default is no wait, '1')
    SIGNAL internal_wait_n  : STD_LOGIC; 
    
    -- 2-bit vector to hold the calculated BA inputs for the 74LS139 (B=DEV2, A=DEV1)
    SIGNAL LS139_BA_OUT : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ISLS139 : STD_LOGIC :='1';
    signal io_strobe : std_logic;

BEGIN
    Z80_Out.Z80_BUSREQ_N <= '1';
    VDRegs_out <= DUMMY_VDREGS;

    process(all)
        variable v_out : t_ot_sigs_from_system;
    begin
        v_out := C_OT_SIGS_DEFAULT;
        v_out.SYS_SEL := OTSigs_in.SYS_SEL;
        OTSigs_out <= v_out;
    end process;

    -- Map lower 8 bits of Z80 address bus for I/O decoding
    Z80_IO_ADDR <= Z80_In.Z80_ADDR(7 DOWNTO 0);
    
                       
    -- ***************************************************************
    -- ** 1. 74LS138 INPUTS (DEV0-DEV2) - Configurable for Emulation **
    -- ***************************************************************
    
    -- This PROCESS implements the flexible I/O port mapping.
    -- When a specific Z80 I/O address is accessed, we calculate the required CBA input 
    -- to activate the desired Y output on the 74LS138.
    
    PROCESS (Z80_In.Z80_IORQ_N, Z80_IO_ADDR)
    BEGIN
        -- Default to unused Y0 (CBA = 000) when not performing an I/O request.
        -- This drives Y0 to active low, which is assumed not to be connected to a peripheral.
        LS139_BA_OUT <= B"00"; --pin 7 unconnected
        ISLS139 <='1';
        IF (Z80_In.Z80_IORQ_N = '0') THEN -- Only calculate if I/O Request is active
            CASE Z80_IO_ADDR IS
                -- Custom Decoding Examples (as per user request)
                WHEN C_LS139_Y1 => 
                    -- OUT (45h, Data) activates Y1 (BA = 01) 
                    LS139_BA_OUT <= B"01";   --pin 6 LAUD_MUX_N select ausio device d7=1 selects AY
                    ISLS139 <='0';
                WHEN C_LS139_Y2 => 
                    -- OUT (40h, Data) activates Y2 (CBA = 010)
                    LS139_BA_OUT <= B"10";   --pin 5 LAUD_CS_N this for sn76489 
                    ISLS139 <='0';
                WHEN C_LS139_Y2_1 => 
                    -- OUT (41h, Data) activates Y2 (CBA = 010)
                    LS139_BA_OUT <= B"10";   --pin 5 LAUD_CS_N this for ay38912 BCDIR=A0=1 BC1=A1=0
                    ISLS139 <='0';
                WHEN C_LS139_Y2_2 => 
                    -- OUT (42h, Data) activates Y2 (CBA = 010)
                    LS139_BA_OUT <= B"10";   --pin 5 LAUD_CS_N this for ay38912 BCDIR=A0=0 BC1=A1=1
                    ISLS139 <='0';
                WHEN C_LS139_Y2_3 => 
                    -- OUT (43h, Data) activates Y2 (CBA = 010)
                    LS139_BA_OUT <= B"10";   --pin 5 LAUD_CS_N this for ay38912 BCDIR=A0=1 BC1=A1=1
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
    
    io_strobe <= '1' when (Z80_In.Z80_IORQ_N = '0' and (Z80_In.Z80_WR_N = '0' or Z80_In.Z80_RD_N = '0')) 
                 else '0';

    Z80_Out.DEV2 <= LS139_BA_OUT(1) WHEN (io_strobe = '1' AND ISLS139 = '0') ELSE '0';  --B
    Z80_Out.DEV1 <= LS139_BA_OUT(0) WHEN (io_strobe = '1' AND ISLS139 = '0') ELSE '0';  --A
    
    -- ***************************************************************
    -- ** 2. MMU I/O PORT DECODING (Z80 OUT commands) **
    -- ***************************************************************
       
    
    -- Port 0: Write Page Mapping Registers (C_MMU_MAP_REG_ADDR = x"00")
    Z80_Out.MMU_nMAP_REG_N <= '0' WHEN (Z80_In.Z80_IORQ_N = '0'  AND Z80_In.Z80_WR_N = '0' AND Z80_IO_ADDR = C_MMU_MAP_REG_ADDR)
                      ELSE '1';

    -- Port 0: Read Page Mapping Registers (C_MMU_MAP_REG_ADDR = x"00")
    Z80_Out.MMU_nMAP_RD_N <= '0' WHEN (Z80_In.Z80_IORQ_N = '0'  AND Z80_In.Z80_RD_N = '0' AND Z80_IO_ADDR = C_MMU_MAP_REG_ADDR)
                      ELSE '1';

                      
    -- Port 1: Set Read-Only Protection (C_MMU_SET_RO_ADDR = x"01")
    Z80_Out.MMU_nSET_RO_N  <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_ADDR = C_MMU_SET_RO_ADDR)
                      ELSE '1';
                      
    -- Port 2: Set Read/Write Protection (C_MMU_SET_RW_ADDR = x"02")
    Z80_Out.MMU_nSET_RW_N  <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_ADDR = C_MMU_SET_RO_ADDR)
                      ELSE '1';
                      
    -- Z80 Clock Selection Register Write Strobe Generation
    -- This signal is active low when the Z80 reads/writes  to the I/O port (nIORQ=0)
    -- whose address matches the CLK_SEL_PORT_ADDR (x"80").
    Z80_Out.CLK_SEL_RG_N    <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_ADDR(7 downto 0) = CLK_SEL_PORT_ADDR)
                   else '1';

    Z80_Out.UART_CS_N       <= '0' when (Z80_In.Z80_IORQ_N = '0' and  Z80_IO_ADDR(7 downto 3) = UART_PORT_BASE(7 downto 3)) 
                  else '1';

    Z80_Out.PS2_DS_N        <= '0' when (Z80_In.Z80_IORQ_N = '0' and (Z80_IO_ADDR = C_PS2_PORT_ADDR OR Z80_IO_ADDR = std_logic_vector(unsigned(C_PS2_PORT_ADDR) + 1) ))
                  else '1';

    Z80_Out.VD_DS_N         <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_ADDR = C_VD_PORT_ADDR)
                  else '1';

    Z80_Out.I2C_CS_N        <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_ADDR(7 downto 3) =  C_I2C_PORT_ADDR_BASE(7 downto 3))
                  else '1';

    Z80_Out.SYS_CS_N        <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_ADDR = C_SYS_PORT_ADDR)
                  else '1';

    -- ***************************************************************
    -- ** 3. WAIT STATE GENERATION **
    -- ***************************************************************
    
    -- Placeholder: For the moment, assert Z80_WAIT_N high (no wait states)
    internal_wait_n <= '1';
    
    Z80_Out.Z80_WAIT_N <= internal_wait_n;

    Z80_Out.isDOut <= '1';
    Z80_Out.Dataout <= x"00";

    -- ***************************************************************
    -- ** 4. INTERRUPT MANAGEMENT **
    -- ***************************************************************
    
    -- Pass the master peripheral interrupt request directly to the Z80 (Active Low)
    Z80_Out.Z80_INT_N <= Z80_In.INT_REQ_N;
    
END behavioral;