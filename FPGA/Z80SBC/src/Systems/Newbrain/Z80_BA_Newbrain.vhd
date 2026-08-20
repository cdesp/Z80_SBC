LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
USE work.defs_pkg.ALL; -- Import MMU I/O address constants

ENTITY Z80_BA_Newbrain IS
    PORT (
        CLK_FPGA            : IN std_logic;
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
END Z80_BA_Newbrain;

ARCHITECTURE behavioral OF Z80_BA_Newbrain IS
    
    -- Internal signal for I/O Address (A0-A7)
    SIGNAL Z80_IO_ADDR      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    -- Signal to hold current wait state logic (default is no wait, '1')
    SIGNAL internal_wait_n  : STD_LOGIC; 
    
    -- 2-bit vector to hold the calculated BA inputs for the 74LS139 (B=DEV2, A=DEV1)
    SIGNAL LS139_BA_OUT : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ISLS139 : STD_LOGIC :='1';

signal DATAin       :std_logic_vector(8-1 downto 0);
SIGNAL DATAout      : std_logic_vector(8-1 downto 0); --byte to be read by the CPU in cmd
SIGNAL snd_clk      : STD_LOGIC;
SIGNAL cpu_clk      : STD_LOGIC;
SIGNAL NB20_clk     : STD_LOGIC;
SIGNAL NB13_clk     : STD_LOGIC;
SIGNAL nINTMMU      :  STD_LOGIC:='1';
SIGNAL outputData   :  STD_LOGIC:='1';  --if we should ouput data to databus
SIGNAL FRMinton     :  STD_LOGIC:='1';
--INTERRUPTS
SIGNAL FRMint       :  STD_LOGIC:='1';  --drive the main INT z80 signal
SIGNAL COPint       :  STD_LOGIC:='1';  --drive the main INT z80 signal

--REGISTERS
signal COPCTL :  std_logic_vector(8-1 downto 0);    
signal COPCTL2 :  std_logic_vector(8-1 downto 0);  --COP STATUS
signal COPCMD :  std_logic_vector(8-1 downto 0);    --COP COMMAND
signal ENABLEREG :  std_logic_vector(8-1 downto 0);
signal VIDCTRsig :  std_logic_vector(8-1 downto 0);
signal staddr :  std_logic_vector(8-1 downto 0);
Signal svideo9:std_logic:='0'; 
Signal CLRCOP:std_logic:='1';                      --
Signal CLRCOPnxt:std_logic:='1'; 
Signal CLRFRM:std_logic:='1';                      --
Signal INTEN:std_logic:='1';    
Signal NBEN:std_logic:='1';                       --
signal COPcount : std_logic_vector(4 DOWNTO 0);      -- counter to receive bytes for cop (lcd)

Signal KB_Stop:std_logic:='0';                      --STOP KEY PRESSED FROM KEYB
Signal KBint:std_logic:='1';                      --
signal KBcount : std_logic_vector(2 DOWNTO 0);      -- counter to check the keyboard
Signal CLRKBD:std_logic:='1';                      --
Signal CLRKBDnxt:std_logic:='1';                      --CLRKBDnxt
SIGNAL rtvon:std_logic:='0';
SIGNAL CTS:std_logic:='0';
SIGNAL RTS:std_logic:='0';
SIGNAL TX:std_logic:='0';

signal nIORQin : STD_LOGIC; 
signal nIntout : STD_LOGIC; 
signal nWRin    : std_logic;
signal nRDin    : std_logic;
signal ADDRin   : std_logic_vector(8-1 downto 0);
signal kbintIN  : std_logic;
signal kbData   : std_logic_vector(8-1 downto 0); 
SIGNAL MYCPUCLK:std_logic:='0';  --Main Cpu Clock
SIGNAL cpu_speed : integer range 0 to 255:=0;  --cpu_speed set by out 128,n

signal s_20ms_ce : std_logic;
signal s_13ms_ce : std_logic;

CONSTANT MAINCLOCK:INTEGER :=12; --CHANGE IT ON CPU_OSC.VHD ALSO

signal io_strobe : std_logic;
signal sVideo9_pre : std_logic;

--DEBUG
Signal capture: std_logic :='1';

component Clock_Divider
   generic (
        CYCLE_COUNT : integer := 650000 -- Default to 13ms at 50MHz
    );
    port (
       clk: in std_logic; --50mhz fpga clock
       reset: in std_logic;
       clock_out: out std_logic
    );
end component;


BEGIN
    OTSigs_out.PS2_KEYB_READ <= '0'; --notused

    Datain <= Z80_In.Z80_Data;
    nIORQin <= Z80_In.Z80_IORQ_N;
    nWRin   <= Z80_In.Z80_WR_N;
    nRDin   <= Z80_In.Z80_RD_N;
    ADDRin  <= Z80_IO_ADDR;
    kbintIN <= OTSigs_in.PS2_KEYB_Int;
 --   kbData  <= OTSigs_in.PS2_DATA; --not needed
    MYCPUCLK <= CLK;
    cpu_speed <= to_integer(unsigned(otsigs_in.CPU_SPEED));

    Z80_out.isDOut  <= outputData;
    Z80_out.DataOut <= DATAout;

    VDRegs_out.Reg1 <= ENABLEREG;
    VDRegs_out.Reg2 <= VidCTRsig;
    VDRegs_out.Reg3 <= "0000000"&sVideo9;
    VDRegs_out.Reg4 <= STADDR;
    --VDRegs_out.Reg5 <=


    CLK20: Clock_Divider
    generic map ( CYCLE_COUNT => 1000000 )
    port map (
        clk => clk_FPGA,
        reset => nReset,
        clock_out => s_20ms_ce   
    );                         

    CLK13: Clock_Divider
    generic map ( CYCLE_COUNT => 650000 )
    port map (
        clk => clk_FPGA,
        reset => nReset,
        clock_out => s_13ms_ce  
    );        

    process (CLK_FPGA, nRESET) -- Driven by the real, hardware global 50MHz clock
    begin
        if nRESET = '0' then
            FRMint <= '0';
            
        elsif rising_edge(CLK_FPGA) then -- Checks 50 million times per second
        
            -- 1. Your override conditions (Check every single 50MHz cycle)
            if (CLRFRM = '0') or (FRMinton = '1') then
                FRMint <= '1';
                
            -- 2. This replaces falling_edge(NB20_clk). 
            -- It only evaluates true once every 20ms!
            elsif s_20ms_ce = '1' then  
                if FRMinton = '0' then
                    FRMint <= '0';         
                end if;
            end if;
            
        end if;
    end process;                  



    -- Run this safely on your global 50MHz master system clock
    process (MYCPUCLK, nRESET)
    begin
        if nRESET = '0' then
            COPint  <= '1'; -- Match default state when resets occur
            KBint   <= '1';
            KBcount <= (others => '0');
            
        elsif rising_edge(MYCPUCLK) then
            
            -- 1. Asynchronous-style clear overrides (Checked 50 million times a second)
            if CLRCOP = '0' then
                COPint <= '1';
            elsif CLRKBD = '0' then
                KBint <= '1';
                
            -- 2. Synchronous clock enable replacing falling_edge(NB13_clk)
            -- This block only evaluates to TRUE once every 13ms
            elsif s_13ms_ce = '1' then
                COPint  <= '0';                  
                KBcount <= KBcount + 1;    
                 KBint <= '1';
                if KBcount = "000" then 
                    KBint <= '0';
                end if;
            end if;
            
        end if;
    end process;

    PROCESS (MYCPUCLK, nRESET)
    BEGIN
        IF nRESET='0' THEN
            INTEN      <= '1';
            NBEN       <= '1';
            CLRCOP     <= '1';
            CLRKBD     <= '1';
            CLRCOPnxt  <= '1';
            CLRKBDnxt  <= '1';

        ELSIF rising_edge(MYCPUCLK) THEN

            -----------------------------------------------------------------
            -- Port E0
            -----------------------------------------------------------------
            IF nIORQin='0' AND nWRin='0' AND ADDRin=x"E0" THEN
                INTEN <= DATAIN(0);
                NBEN  <= DATAIN(1);
            END IF;

            -----------------------------------------------------------------
            -- Delay clear signals one clock
            -----------------------------------------------------------------
            IF nIORQin='1' THEN
                CLRCOP <= CLRCOPnxt;
                CLRKBD <= CLRKBDnxt;
            END IF;

            CLRCOPnxt <= '1';

            IF nIORQin='0' AND nWRin='0' AND
               ADDRin=x"06" AND DATAIN=x"D0" THEN
                CLRCOPnxt <= '0';
            END IF;

            CLRKBDnxt <= '1';

            IF nIORQin='0' AND nRDin='0' AND
               ADDRin=x"06" THEN
                CLRKBDnxt <= '0';
               -- if CLRKBD='0' then 
                 --   CLRKBDnxt <= '1';
               -- end if;
            END IF;


            -----------------------------------------------------------------
            -- Enable register
            -----------------------------------------------------------------
            IF nIORQin='0' AND nWRin='0' AND ADDRin=x"07" THEN
                NBEN <= '0';
                ENABLEREG <= DATAIN;
            END IF;


            capture <='1';
            -----------------------------------------------------------------
            -- Video registers
            -----------------------------------------------------------------
            IF nIORQin='0' AND nWRin='0' THEN

                CASE ADDRin IS

                    WHEN x"08" =>
                        sVideo9 <= '1';
                        sVideo9_pre <= '1';
                        STADDR <= DATAIN;


                    WHEN x"09" =>
                        sVideo9 <= sVideo9_pre;
                        sVideo9_pre <= '0';
                        STADDR <= DATAIN;
                  

                    WHEN x"0C" |
                         x"0D" |
                         x"0E" |
                         x"0F" =>
                        VidCTRsig <= DATAIN;

                    WHEN OTHERS =>
                        NULL;

                END CASE;

            END IF;

            -----------------------------------------------------------------
            -- COP command register
            -----------------------------------------------------------------
            IF nIORQin='0' AND nWRin='0' AND ADDRin=x"06" THEN

                IF COPCMD=x"A0" OR COPCMD=x"B0" THEN
                    COPcount <= COPcount + 1;
                ELSE
                    COPcount <= (OTHERS=>'0');
                END IF;

                IF COPcount=0 THEN
                    COPCMD <= DATAIN;
                END IF;

                IF COPCMD/=x"A0" THEN
                    COPCTL <= DATAIN;
                END IF;

            END IF;

        END IF;
    END PROCESS;


  -- kbint is for rs232 keyboard input fires every several ms low enabled
    -- kbintIN is the real keyboard input interrupt low enabled
    -- BITS 4-6 SELECTS REGINT,CASSER,CASSIN,KBD INTERRUPT
    -- WHEN BITS 4-6 IS 000=REGINT, 001=CASSERR, 010=CASSIN, 011=KBD, 100=CASSOUT 
    -- if BIT 3 is 1 then we have a keyboard key else regint
	COPCTL2<= 		  "00111"&KB_Stop&"00" WHEN nIORQin='0' and nRDin='0' AND  ADDRin=x"06" AND kbintin='1' --3X AND COP80='0' --KEYB iNTERRUPT IN 6 ==3X at bits 4-7 mean kbdint on IN 6
                ELSE  "00110"&KB_Stop&"00" WHEN nIORQin='0' and nRDin='0' AND  ADDRin=x"06" AND KBint='0' -- regint if bit 3 is 0 --3X AND COP80='0' --KEYB iNTERRUPT IN 6 ==3X at bits 4-7 mean kbdint on IN 6  
   			    ELSE  "00000"&KB_Stop&"00" WHEN nIORQin='0' and nRDin='0' AND  ADDRin=x"06" AND KBInt='1'  AND COPCMD=x"80"	 --0X  0 at bits 4-7 means regint IN 6
				ELSE  "00000"&KB_Stop&"00" WHEN nIORQin='0' and nRDin='0' AND  ADDRin=x"06" AND KBInt='1'  AND COPCMD/=x"80" -- all others 1x 2x 4x are for cassette control
				ELSE  "00000000";


--BRKKEY	EQU 2
--BRKOK	EQU 3	;IF RES ALLOWS BREAK
--TIMER0	EQU 0
--CBRK	EQU 1	;BREAK KEY BIT

    FRMinton <= ENABLEREG(0);
    rtvon    <= ENABLEREG(2);
    RTS      <= ENABLEREG(4);
    TX       <= ENABLEREG(5);



    nINTout <= FRMint and COPINT WHEN INTEN='0' ELSE '1';

    outputData <= '0' WHEN nIORQin='0' and nRDin='0' AND (ADDRin=x"06" OR ADDRin=x"14"  OR ADDRin=x"03" OR ADDRin=x"16" or ADDRin=x"80") -- WE GIVE DATA on ports 6,20,22 ,72(KB),3
	  ELSE '1';              

    DATAout <= --kbData when WHEN nIORQin='0' and nRDin='0'  AND  ADDRin=x"48"
			 COPCTL2 WHEN nIORQin='0' and nRDin='0'  AND  ADDRin=x"06"
	  --ELSE mydata WHEN IRQ='0' AND RDin='0' AND ADDRin=KBPORT -- from ps/2 data	
	  ELSE COPint&'1'&FRMint&"11101" WHEN nIORQin='0' and nRDin='0' AND  ADDRin=x"14" --IN 20 STATUS REGISTER 9/9/2016
--COPINTBAR	EQU 7		;COP status bit
--CLKINTBAR	EQU 5		;Frame Clock status bit
--ACINTBAR	EQU 6       ;1 NOT INT
--UPTINTBAR	EQU 4       ;1 NOT INT
--POWTEST	EQU 1       ;0 FOR POWER
--EXTEST	EQU 0       ;1 MEANS 24
       ELSE std_logic_vector(to_unsigned(MAINCLOCK /(2**cpu_speed), DATAout'length)) WHEN  nIORQin='0' and nRDin='0' AND  ADDRin=x"80" -- READ THE CPU CLOCK BY IN 128,A

																				--bit 1 is pwrup should be 0 when we are ready
    -- ELSE COPCTL WHEN nIORQin='0' and nRDin='0' AND ADDRin=x"03"	
	 -- ELSE "101000"&CTS&RX WHEN commIN='0' AND ADDRin=x"16"	--IN 22 GET V24 SIGNALS (ZEROES NOT USED)
      else  "00000000";


 
    

   CLRFRM<='0' WHEN nIORQin='0'  AND  ADDRin=x"04" 
       ELSE '1';





--------------------------------------------------------------------------------------------------
    
    -- Map lower 8 bits of Z80 address bus for I/O decoding
    Z80_IO_ADDR <= Z80_In.Z80_ADDR(7 DOWNTO 0);
    
                       
    -- ***************************************************************
    -- ** 1. 74LS138 INPUTS (DEV0-DEV2) - Configurable for Emulation **
    -- ***************************************************************
    
    -- This PROCESS implements the flexible I/O port mapping.
    -- When a specific Z80 I/O address is accessed, we calculate the required BA input 
    -- to activate the desired Y output on the 74LS139.
    
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
    Z80_Out.MMU_nSET_RO_N  <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_ADDR = x"E3")
                      ELSE '1';
                      
    -- Port 2: Set Read/Write Protection (C_MMU_SET_RW_ADDR = x"02")
    Z80_Out.MMU_nSET_RW_N  <= '0' WHEN (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_WR_N = '0' AND Z80_IO_ADDR = x"E4")
                      ELSE '1';
                      
    -- Z80 Clock Selection Register Write Strobe Generation
    -- This signal is active low when the Z80 reads/writes  to the I/O port (nIORQ=0)
    -- whose address matches the CLK_SEL_PORT_ADDR (x"80").
    Z80_Out.CLK_SEL_RG_N    <= '0' when (Z80_In.Z80_IORQ_N = '0' and Z80_IO_ADDR(7 downto 0) = CLK_SEL_PORT_ADDR)
                   else '1';

    Z80_Out.UART_CS_N       <= '0' when (Z80_In.Z80_IORQ_N = '0' and  Z80_IO_ADDR(7 downto 3) = UART_PORT_BASE(7 downto 3)) 
                  else '1';

--newbrain only read until we change the 8000 rom
    Z80_Out.PS2_DS_N        <= '0' when (Z80_In.Z80_IORQ_N = '0' AND Z80_In.Z80_RD_N = '0' and Z80_IO_ADDR = C_PS2_PORT_ADDR  )
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
    
    -- interrupt 
    Z80_Out.Z80_INT_N <= Z80_In.INT_REQ_N and nINTout;
    
END behavioral;