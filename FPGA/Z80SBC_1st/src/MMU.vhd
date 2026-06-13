LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL; -- Standard VHDL library for arithmetic operations

ENTITY MMU IS
    PORT
    (
        -- New Mandatory Clock Input for Synchronous Registers
        CLK             :  IN  STD_LOGIC;     -- Z80 System Clock
        A13             :  IN  STD_LOGIC;
        A14             :  IN  STD_LOGIC;
        A15             :  IN  STD_LOGIC;
        nMREQ           :  IN  STD_LOGIC;
        nINTMMU         :  IN  STD_LOGIC;     -- I/O signal for Page Mapping Registers (OUT (c), a)
        nSET_RO         :  IN  STD_LOGIC;     -- NEW: I/O signal for Read-Only (OUT (protInt), PgNo)
        nSET_RW         :  IN  STD_LOGIC;     -- NEW: I/O signal for Read/Write (OUT (protInt+1), PgNo)
        nWR_CPU         :  IN  STD_LOGIC;     -- Z80 Write Strobe (Active Low)
        nRESET          :  IN  STD_LOGIC;
        DATA            :  IN  std_logic_vector(7 downto 0);  -- Data bus from CPU (PgNo for protection or mapping)
        EA              :  OUT std_logic_vector(20 downto 13);    -- Extended Address bus to mem chips (Page Number)
        nWR_OUT         :  OUT STD_LOGIC;     -- Protected Write Strobe to physical memory
        -- ROM/RAM CHIPS ENABLE SIGNALS (physical mapping below)
        nCE0            :  OUT STD_LOGIC; -- map to AS6C8008 LRAMEN3_N (SRAM, 1MB)
        nCE1            :  OUT STD_LOGIC; -- map to SST39LF040 LRAMEN2_N (Flash, 512KB)
        nCE2            :  OUT STD_LOGIC; -- internal dual-port video RAM (64KB)
        nCE3            :  OUT STD_LOGIC;
        nCE4            :  OUT STD_LOGIC
    );
END MMU;

ARCHITECTURE behavioral OF MMU IS

    -- Component for N-bit Page Registers
    COMPONENT regn
        GENERIC (
             N    : INTEGER := 8;
             INIT : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')
          );
        PORT ( D : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0) ;
               Loadn, Resetn, Clock : IN STD_LOGIC ;
               Q : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0) ) ;
    END COMPONENT;

    -- -------------------------------------------------------------
    -- Σήματα για τους 8 Καταχωρητές Χαρτογράφησης Σελίδων (8-bit)
    -- Signals for the 8 Page Mapping Registers (8-bit)
    -- -------------------------------------------------------------
    signal Bank0 :  std_logic_vector(7 downto 0);
    signal Bank1 :  std_logic_vector(7 downto 0);
    signal Bank2 :  std_logic_vector(7 downto 0);
    signal Bank3 :  std_logic_vector(7 downto 0);
    signal Bank4 :  std_logic_vector(7 downto 0);
    signal Bank5 :  std_logic_vector(7 downto 0);
    signal Bank6 :  std_logic_vector(7 downto 0);
    signal Bank7 :  std_logic_vector(7 downto 0);

    -- Write Strobe signals for Page Registers (Active Low)
    SIGNAL nSetBANK0: STD_LOGIC;
    SIGNAL nSetBANK1: STD_LOGIC;
    SIGNAL nSetBANK2: STD_LOGIC;
    SIGNAL nSetBANK3: STD_LOGIC;
    SIGNAL nSetBANK4: STD_LOGIC;
    SIGNAL nSetBANK5: STD_LOGIC;
    SIGNAL nSetBANK6: STD_LOGIC;
    SIGNAL nSetBANK7: STD_LOGIC;

    signal BANKNUM: std_logic_vector(2 downto 0);
    signal EXTADDR: std_logic_vector(20 downto 13);
    signal nRST: STD_LOGIC;

    -- -------------------------------------------------------------
    -- Λογική Προστασίας Σελίδων (256 x 1-bit flags)
    -- Page Protection Logic (256 x 1-bit flags)
    -- -------------------------------------------------------------
    -- '1' = Read-Only (RO), '0' = Read/Write (RW). Default is RW.
    TYPE T_PROT_FLAG_ARRAY IS ARRAY (0 TO 255) OF STD_LOGIC;
    SIGNAL Protection_Flags : T_PROT_FLAG_ARRAY := (OTHERS => '0');

    -- Μετατροπή σε integer για ευρετηρίαση. (Conversion to integer for indexing)
    SIGNAL Prot_Write_Page_Int : INTEGER RANGE 0 TO 255;
    SIGNAL Current_Mapped_Page_Int : INTEGER RANGE 0 TO 255;
    SIGNAL Write_Protected_Status : STD_LOGIC; -- Κατάσταση προστασίας της τρέχουσας σελίδας (0=RW, 1=RO)

BEGIN

    -- -------------------------------------------------------------
    -- 0. Setup and Constants
    -- -------------------------------------------------------------
    -- reset (active low)
    nRST <= nRESET;

    -- Bank number from A15..A13 (selects which bank register to write or which bank is being accessed)
    BANKNUM <= A15 & A14 & A13;
    
    -- Το Page Number (PgNo) από το DATA bus μετατρέπεται σε integer για χρήση στον πίνακα προστασίας     
    Prot_Write_Page_Int <= to_integer(unsigned(DATA));

    -- -------------------------------------------------------------
    -- 1. Process for Page-Level Protection Flags (Synchronous Write)
    -- -------------------------------------------------------------
    -- Αυτός ο process ενημερώνει τον πίνακα προστασίας (Protection_Flags) βάσει των I/O εντολών.
    PROCESS (nRST, nWR_CPU)
    BEGIN
        IF nRST = '0' THEN
            -- Reset: Όλες οι σελίδες είναι RW ('0')
            Protection_Flags <= (OTHERS => '0');
        ELSIF falling_edge(nWR_CPU) THEN
            -- Εγγραφή σε I/O θύρα προστασίας
            IF nSET_RO = '0' THEN -- OUT (protInt), PgNo -> Θέτει τη σελίδα ως Read-Only ('1')
                Protection_Flags(Prot_Write_Page_Int) <= '1';
            ELSIF nSET_RW = '0' THEN -- OUT (protInt+1), PgNo -> Θέτει τη σελίδα ως Read/Write ('0')
                Protection_Flags(Prot_Write_Page_Int) <= '0';
            END IF;
        END IF;
    END PROCESS;


    -- -------------------------------------------------------------
    -- 2. Page Mapping Registers (8-bit)
    -- -------------------------------------------------------------
    -- Generate write strobes for each bank when CPU writes to Page Mapping port (nINTMMU='0' and nWR_CPU='0')
    nSetBANK0 <= '0' WHEN BANKNUM="000" and nINTMMU ='0' AND nWR_CPU='0' ELSE '1';
    nSetBANK1 <= '0' WHEN BANKNUM="001" and nINTMMU ='0' AND nWR_CPU='0' ELSE '1';
    nSetBANK2 <= '0' WHEN BANKNUM="010" and nINTMMU ='0' AND nWR_CPU='0' ELSE '1';
    nSetBANK3 <= '0' WHEN BANKNUM="011" and nINTMMU ='0' AND nWR_CPU='0' ELSE '1';
    nSetBANK4 <= '0' WHEN BANKNUM="100" and nINTMMU ='0' AND nWR_CPU='0' ELSE '1';
    nSetBANK5 <= '0' WHEN BANKNUM="101" and nINTMMU ='0' AND nWR_CPU='0' ELSE '1';
    nSetBANK6 <= '0' WHEN BANKNUM="110" and nINTMMU ='0' AND nWR_CPU='0' ELSE '1';
    nSetBANK7 <= '0' WHEN BANKNUM="111" and nINTMMU ='0' AND nWR_CPU='0' ELSE '1';

    -- Instantiate 8-bit bank registers. (Synchronous, Load controlled by nSetBANKx)
    Bankreg0 : regn
        generic map ( N => 8, INIT => x"20")
        PORT MAP( D => DATA, Resetn => nRST, Loadn => nSetBANK0, Clock => CLK, Q => Bank0 );

    Bankreg1 : regn
        generic map ( N => 8, INIT => x"21")
        PORT MAP( D => DATA, Resetn => nRST, Loadn => nSetBANK1, Clock => CLK, Q => Bank1 );

    Bankreg2 : regn
        generic map ( N => 8, INIT => x"22")
        PORT MAP( D => DATA, Resetn => nRST, Loadn => nSetBANK2, Clock => CLK, Q => Bank2 );

    Bankreg3 : regn
        generic map ( N => 8, INIT => x"23")
        PORT MAP( D => DATA, Resetn => nRST, Loadn => nSetBANK3, Clock => CLK, Q => Bank3 );

    Bankreg4 : regn
        generic map ( N => 8, INIT => x"24")
        PORT MAP( D => DATA, Resetn => nRST, Loadn => nSetBANK4, Clock => CLK, Q => Bank4 );

    Bankreg5 : regn
        generic map ( N => 8, INIT => x"25")
        PORT MAP( D => DATA, Resetn => nRST, Loadn => nSetBANK5, Clock => CLK, Q => Bank5 );

    Bankreg6 : regn
        generic map ( N => 8, INIT => x"26")
        PORT MAP( D => DATA, Resetn => nRST, Loadn => nSetBANK6, Clock => CLK, Q => Bank6 );

    Bankreg7 : regn
        generic map ( N => 8, INIT => x"27")
        PORT MAP( D => DATA, Resetn => nRST, Loadn => nSetBANK7, Clock => CLK, Q => Bank7 );

    -- -------------------------------------------------------------
    -- 3. Extended Address (EA) Mapping
    -- -------------------------------------------------------------

    -- EXTADDR selects which 8-bit page is driven to the external address bus
    EXTADDR <= Bank0 WHEN BANKNUM="000"
               ELSE Bank1 WHEN BANKNUM="001"
               ELSE Bank2 WHEN BANKNUM="010"
               ELSE Bank3 WHEN BANKNUM="011"
               ELSE Bank4 WHEN BANKNUM="100"
               ELSE Bank5 WHEN BANKNUM="101"
               ELSE Bank6 WHEN BANKNUM="110"
               ELSE Bank7 WHEN BANKNUM="111"
               ELSE Bank0;

    -- Present extended address onto EA when memory request active (nMREQ='0')
    EA <= EXTADDR WHEN nMREQ='0' ELSE (others => '0');

    -- Μετατροπή του τρέχοντος χαρτογραφημένου Page Number (από το EA[20:13]) σε integer
    Current_Mapped_Page_Int <= to_integer(unsigned(EXTADDR(20 DOWNTO 13)));
    
    -- Λήψη της κατάστασης προστασίας για την τρέχουσα σελίδα από τον πίνακα Protection_Flags
    Write_Protected_Status <= Protection_Flags(Current_Mapped_Page_Int);


    -- -------------------------------------------------------------
    -- 4. Write Protection Logic (nWR_OUT)
    -- -------------------------------------------------------------
    -- nWR_OUT (Write Strobe to Memory) is Active (0) IFF:
    -- 1. CPU requests a memory write (nMREQ = '0' AND nWR_CPU = '0')
    -- 2. The currently selected page is NOT Write Protected (Write_Protected_Status = '0')
    
    nWR_OUT <= '1' WHEN (nMREQ = '0' AND Write_Protected_Status = '1') -- Block write if Protected (RO)
               ELSE nWR_CPU; -- Διαφορετικά, περνάει το nWR_CPU


    -- -------------------------------------------------------------
    -- 5. Chip Select Logic (nCEx) 
    -- -------------------------------------------------------------

    -- nCE0 : SRAM 1MB -> blocks 0..31  ("000000" .. "011111")
    nCE0 <= '0' WHEN EXTADDR(20 DOWNTO 15) >= "000000" AND EXTADDR(20 DOWNTO 15) <= "011111" AND nMREQ='0' ELSE '1';

    -- nCE1 : Flash 512KB -> blocks 32..47 ("100000" .. "101111")
    nCE1 <= '0' WHEN EXTADDR(20 DOWNTO 15) >= "100000" AND EXTADDR(20 DOWNTO 15) <= "101111" AND nMREQ='0' ELSE '1';

    -- nCE2 : Internal dual-port video RAM 64KB -> blocks 48..49 ("110000" .. "110001")
    nCE2 <= '0' WHEN EXTADDR(20 DOWNTO 15) >= "110000" AND EXTADDR(20 DOWNTO 15) <= "110001" AND nMREQ='0' ELSE '1';

    -- keep remaining CE lines inactive (can be used later)
    nCE3 <= '1';
    nCE4 <= '1';

END behavioral;