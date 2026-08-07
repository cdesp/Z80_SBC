LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;
USE work.defs_pkg.ALL; -- Import MMU I/O address constants

ENTITY Z80_BA_Spectrum IS
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
END Z80_BA_Spectrum;

ARCHITECTURE behavioral OF Z80_BA_Spectrum IS
    
    -- Internal signal for I/O Address (A0-A7)
    SIGNAL Z80_IO_ADDR      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    -- Signal to hold current wait state logic (default is no wait, '1')
    SIGNAL internal_wait_n  : STD_LOGIC; 
    
    -- 2-bit vector to hold the calculated BA inputs for the 74LS139 (B=DEV2, A=DEV1)
    SIGNAL LS139_BA_OUT : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ISLS139 : STD_LOGIC :='1';
    signal io_strobe : std_logic;

---- SPECTRUM SPECIFIC
    CONSTANT C_ULA_PORT   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"FE"; --ULA

    SIGNAL KB_MAT   : STD_LOGIC_VECTOR(4 DOWNTO 0);
    signal ZXSpec_KEYB : STD_LOGIC_VECTOR(4 DOWNTO 0);
    signal Z80_INT_N    : std_logic;
    SIGNAL dOUT     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal kb_read :std_logic := '0';
    signal kb_read_clear :std_logic := '0';
    signal isULA_in:std_logic := '0';
    signal inCounter: unsigned(3 downto 0) := "0000";

           --spec keyboard
-- 8 half-rows, each 5 bits wide (bits 0 to 4)
    type t_ps2_matrix is array (0 to 7) of std_logic_vector(4 downto 0);
    signal kb_matrix : t_ps2_matrix := (others => (others => '1')); -- Default: all keys released ('1')
    signal ps2_rd_req : std_logic := '0';
    signal ps2_data_byte  : std_logic_vector(7 downto 0);


BEGIN

      
        
  
        -- Example INT_N pulse generator in your top-level FPGA module
        process(CLK_FPGA)
            variable int_cnt : integer range 0 to 500 := 0;
        begin
            if rising_edge(CLK_FPGA) then
                -- Trigger when video enters top-left of frame (V_IN.v_cnt = 0 and V_IN.h_cnt = 0)
                --if V_IN.v_cnt = 0 and V_IN.h_cnt = 0 then
                if OTSigs_in.FrameStart='1' then
                    int_cnt := 400; -- Hold low for 400 FPGA ticks (8 µs / 32 Z80 clocks) for 4Mhz
                elsif int_cnt > 0 then
                    int_cnt := int_cnt - 1;
                end if;

                if int_cnt > 0 then
                    Z80_INT_N <= '0';
                else
                    Z80_INT_N <= '1';
                end if;
            end if;
        end process;
 

    Z80_out.isDOut <= '0' WHEN Z80_In.Z80_IORQ_N='0' and Z80_In.Z80_RD_N='0' AND Z80_IO_ADDR=C_ULA_PORT --INTERRUPT SERVICE
	  ELSE '1';              

    Z80_out.DataOut <= dOUT WHEN Z80_In.Z80_IORQ_N='0' and Z80_In.Z80_RD_N='0'  AND  Z80_IO_ADDR=C_ULA_PORT
                else  "00000000";

--ZX Spectrum Keyboard Scanner
     -- to get another key from ps/2 keyboard
    OTSigs_out.PS2_KEYB_READ <= ps2_rd_req;
     
    --------------------------------------------------------------------------------
    -- Combinational: build the selected half-row(s) AND'ed together, and drive
    -- the ULA data bus bits directly from it every cycle. No latching needed.
    --------------------------------------------------------------------------------
    process(Z80_In.Z80_ADDR, kb_matrix)
        variable v_mat : std_logic_vector(4 downto 0);
    begin
        v_mat := "11111"; -- all keys released by default
     
        if Z80_In.Z80_ADDR(8)  = '0' then v_mat := v_mat and kb_matrix(0); end if;
        if Z80_In.Z80_ADDR(9)  = '0' then v_mat := v_mat and kb_matrix(1); end if;
        if Z80_In.Z80_ADDR(10) = '0' then v_mat := v_mat and kb_matrix(2); end if;
        if Z80_In.Z80_ADDR(11) = '0' then v_mat := v_mat and kb_matrix(3); end if;
        if Z80_In.Z80_ADDR(12) = '0' then v_mat := v_mat and kb_matrix(4); end if;
        if Z80_In.Z80_ADDR(13) = '0' then v_mat := v_mat and kb_matrix(5); end if;
        if Z80_In.Z80_ADDR(14) = '0' then v_mat := v_mat and kb_matrix(6); end if;
        if Z80_In.Z80_ADDR(15) = '0' then v_mat := v_mat and kb_matrix(7); end if;
     
        ZXSpec_KEYB <= v_mat;
    end process;
     
    --------------------------------------------------------------------------------
    -- PS/2 decode FSM (simplified to 2 states)
    --------------------------------------------------------------------------------
    process(CLK_FPGA, nRESET)
        type t_ps2_state is (IDLE, DECODE_BYTE);
        variable dec_state     : t_ps2_state := IDLE;
        variable release_flag  : std_logic := '0';
        variable extended_flag : std_logic := '0';
        variable val           : std_logic; -- '0' = pressed, '1' = released
    begin
        if nRESET = '0' then
            kb_matrix     <= (others => (others => '1'));
            dec_state     := IDLE;
            release_flag  := '0';
            extended_flag := '0';
            ps2_rd_req    <= '0';
     
        elsif rising_edge(CLK_FPGA) then
            ps2_rd_req <= '0'; -- pulse for 1 cycle when we pop a byte
     
            case dec_state is
                when IDLE =>
                    if OTSigs_in.PS2_KEYB_Int = '1' then
                        ps2_data_byte <= OTSigs_in.PS2_DATA;
                        ps2_rd_req    <= '1'; -- pop this byte from the PS/2 FIFO
                        dec_state     := DECODE_BYTE;
                    end if;
     
                when DECODE_BYTE =>
                    val := release_flag;
     
                    if ps2_data_byte = X"E0" then
                        extended_flag := '1';
     
                    elsif ps2_data_byte = X"F0" then
                        release_flag := '1';
     
                    else
                        if extended_flag = '1' then
                            -- Extended (E0-prefixed) keys
                            case ps2_data_byte is
                                when X"6B" => kb_matrix(0)(0) <= val; kb_matrix(3)(4) <= val; -- Left Arrow  = CS+5
                                when X"72" => kb_matrix(0)(0) <= val; kb_matrix(4)(4) <= val; -- Down Arrow  = CS+6
                                when X"75" => kb_matrix(0)(0) <= val; kb_matrix(4)(3) <= val; -- Up Arrow    = CS+7
                                when X"74" => kb_matrix(0)(0) <= val; kb_matrix(4)(2) <= val; -- Right Arrow = CS+8
                                when X"5A" => kb_matrix(6)(0) <= val; -- Numpad Enter
                                when X"14" | X"11" => kb_matrix(7)(1) <= val; -- Right Ctrl/Alt -> Symbol Shift
                                when others => null;
                            end case;
                            extended_flag := '0';
                        else
                            -- Standard (Set 2) keys
                            case ps2_data_byte is
                                -- Row 0 (A8): CAPS SHIFT, Z, X, C, V
                                when X"12" | X"59" => kb_matrix(0)(0) <= val;
                                when X"1A"         => kb_matrix(0)(1) <= val;
                                when X"22"         => kb_matrix(0)(2) <= val;
                                when X"21"         => kb_matrix(0)(3) <= val;
                                when X"2A"         => kb_matrix(0)(4) <= val;
     
                                -- Row 1 (A9): A, S, D, F, G
                                when X"1C" => kb_matrix(1)(0) <= val;
                                when X"1B" => kb_matrix(1)(1) <= val;
                                when X"23" => kb_matrix(1)(2) <= val;
                                when X"2B" => kb_matrix(1)(3) <= val;
                                when X"34" => kb_matrix(1)(4) <= val;
     
                                -- Row 2 (A10): Q, W, E, R, T
                                when X"15" => kb_matrix(2)(0) <= val;
                                when X"1D" => kb_matrix(2)(1) <= val;
                                when X"24" => kb_matrix(2)(2) <= val;
                                when X"2D" => kb_matrix(2)(3) <= val;
                                when X"2C" => kb_matrix(2)(4) <= val;
     
                                -- Row 3 (A11): 1, 2, 3, 4, 5
                                when X"16" => kb_matrix(3)(0) <= val;
                                when X"1E" => kb_matrix(3)(1) <= val;
                                when X"26" => kb_matrix(3)(2) <= val;
                                when X"25" => kb_matrix(3)(3) <= val;
                                when X"2E" => kb_matrix(3)(4) <= val;
     
                                -- Row 4 (A12): 0, 9, 8, 7, 6
                                when X"45" => kb_matrix(4)(0) <= val;
                                when X"46" => kb_matrix(4)(1) <= val;
                                when X"3E" => kb_matrix(4)(2) <= val;
                                when X"3D" => kb_matrix(4)(3) <= val;
                                when X"36" => kb_matrix(4)(4) <= val;
     
                                -- Row 5 (A13): P, O, I, U, Y
                                when X"4D" => kb_matrix(5)(0) <= val;
                                when X"44" => kb_matrix(5)(1) <= val;
                                when X"43" => kb_matrix(5)(2) <= val;
                                when X"3C" => kb_matrix(5)(3) <= val;
                                when X"35" => kb_matrix(5)(4) <= val;
     
                                -- Row 6 (A14): ENTER, L, K, J, H
                                when X"5A" => kb_matrix(6)(0) <= val;
                                when X"4B" => kb_matrix(6)(1) <= val;
                                when X"42" => kb_matrix(6)(2) <= val;
                                when X"3B" => kb_matrix(6)(3) <= val;
                                when X"33" => kb_matrix(6)(4) <= val;
     
                                -- Row 7 (A15): SPACE, SYMBOL SHIFT, M, N, B
                                when X"29"         => kb_matrix(7)(0) <= val;
                                when X"14" | X"11" => kb_matrix(7)(1) <= val; -- Ctrl/Alt -> Symbol Shift
                                when X"3A"         => kb_matrix(7)(2) <= val;
                                when X"31"         => kb_matrix(7)(3) <= val;
                                when X"32"         => kb_matrix(7)(4) <= val;
     
                                -- Backspace -> CAPS SHIFT + '0'
                                when X"66" =>
                                    kb_matrix(0)(0) <= val;
                                    kb_matrix(4)(0) <= val;
     
                                when others => null;
                            end case;
                        end if;
     
                        release_flag := '0'; -- consumed
                    end if;
     
                    dec_state := IDLE;
     
                when others =>
                    dec_state := IDLE;
            end case;
        end if;
    end process;
     
    --------------------------------------------------------------------------------
    -- Z80 bus interface -- ULA read/write, purely combinational on the read side
    --------------------------------------------------------------------------------
    PROCESS (CLK, nRESET) -- Z80 CLOCK
    BEGIN
        IF nRESET = '0' THEN
            VDRegs_out.REG1 <= "00000000";
        ELSIF rising_edge(CLK) THEN
            -- WRITE TO ULA
            IF Z80_In.Z80_IORQ_N = '0' and Z80_In.Z80_WR_N = '0' AND Z80_IO_ADDR = C_ULA_PORT THEN
                VDRegs_out.REG1 <= Z80_In.Z80_Data;
            END IF;
     
         --   isULA_in <= not (Z80_In.Z80_IORQ_N = '0' and Z80_In.Z80_RD_N = '0' and Z80_IO_ADDR = C_ULA_PORT);
        END IF;
    END PROCESS;
     
    -- READ FROM ULA (combinational, always reflects the currently addressed row)
    -- Bits 0-4: keyboard matrix, active-low (0 = pressed)
    -- Bit 5: unused (1)
    -- Bit 6: EAR input (tape)
    -- Bit 7: unused (1)
    dOUT <= "111" & ZXSpec_KEYB;


----------------------

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
    Z80_Out.MMU_nMAP_REG_N <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_ADDR = C_MMU_MAP_REG_ADDR)
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


    -- ***************************************************************
    -- ** 4. INTERRUPT MANAGEMENT **
    -- ***************************************************************
    
    --INTERRUPTS CLOCK OR KEYBOARD
    Z80_Out.Z80_INT_N <= Z80_In.INT_REQ_N and Z80_INT_N;
    
END behavioral;