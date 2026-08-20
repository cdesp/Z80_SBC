--------------------------------------------------------------------------------
-- Z80_Load_Interceptor.vhd
--
-- Purpose:
--   ZX Spectrum automated tool interceptor. Monitors the Z80 bus for an opcode
--   fetch at a targeted ROM Load address (e.g., $056B). When hit, it saves the 
--   live MMU context, intercepts Bank 0, and swaps it to the designated custom 
--   page ($8D). The module then waits for an explicit command indicator: an 
--   I/O write to port $E4 with a data payload of 127 ($7F). Only after this 
--   out instruction is processed does it arm its opcode monitor to look for a standard 
--   RET ($C9) instruction to cleanly restore the original bank structure.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE work.defs_pkg.ALL; -- Import  constants

entity Spectrum_Load_Interceptor is
    generic (
        -- Default target address corresponding to standard Spectrum ROM LD-BYTES ($0556)
        TARGET_LOAD_ADDR : std_logic_vector(15 downto 0) := x"0556"
    );
    port (
        -- Full-rate FPGA system clock (e.g., 50 MHz) for clean oversampling
        CLK_IN          : in  std_logic;
        reset_n         : in  std_logic;
        LOADER_ACTIVE   : in  std_logic; --Active high

        -- Z80 System Bus Signals
        Z80_In              : IN  t_z80_to_system;

        -- Session Control Outputs
        INTERCEPT_ACTIVE : out std_logic;

        -- MMU Interface (8 banks, byte-wide, simple control bus)
        MMU_ADDR        : out std_logic_vector(2 downto 0);
        MMU_DATA        : out std_logic_vector(7 downto 0);
        MMU_WE          : out std_logic;

        -- Live MMU input lines for initial dynamic context tracking
        MMU_BANK0_IN    : in  std_logic_vector(7 downto 0);
        MMU_BANK1_IN    : in  std_logic_vector(7 downto 0);
        MMU_BANK2_IN    : in  std_logic_vector(7 downto 0);
        MMU_BANK3_IN    : in  std_logic_vector(7 downto 0);
        MMU_BANK4_IN    : in  std_logic_vector(7 downto 0);
        MMU_BANK5_IN    : in  std_logic_vector(7 downto 0);
        MMU_BANK6_IN    : in  std_logic_vector(7 downto 0);
        MMU_BANK7_IN    : in  std_logic_vector(7 downto 0)
    );
end entity Spectrum_Load_Interceptor;

architecture rtl of Spectrum_Load_Interceptor is

    ----------------------------------------------------------------------
    -- Constants
    ----------------------------------------------------------------------
    constant C_SWAP_PAGE       : std_logic_vector(7 downto 0) := x"8A"; --WAS $8D
    constant C_TARGET_PORT     : std_logic_vector(7 downto 0) := x"E4";
    constant C_TARGET_IO_DATA  : std_logic_vector(7 downto 0) := x"7F"; -- 127 in decimal
    constant C_OPCODE_RET      : std_logic_vector(7 downto 0) := x"C9"; -- Standard RET

    ----------------------------------------------------------------------
    -- Internal Signals
    ----------------------------------------------------------------------
    -- Sequencer States
    type seq_state_t is (
        SEQ_IDLE,
        SEQ_SAVE_CTX,
        -- Swap Configuration states
        SEQ_SWAP_BANK0,
        SEQ_SWAP_BANK0_W,
        -- Waiting Condition states
        SEQ_WAIT_OUT_PORT,
        SEQ_WAIT_RET,
        -- Recovery states
        SEQ_RESTORE,
        SEQ_RESTORE_W
    );
    signal seq_state : seq_state_t := SEQ_IDLE;

    -- Context Save Registers
    type mmu_banks_t is array (0 to 7) of std_logic_vector(7 downto 0);
    signal saved_banks : mmu_banks_t := (others => (others => '0'));

    -- Synchronous Z80 Bus Detection Strobes
    signal load_addr_hit : std_logic := '0';
    signal out_port_hit  : std_logic := '0';
    
    -- Opcode Monitor registers
    signal m1_active      : std_logic := '0';
    signal m1_active_d    : std_logic := '0';
    signal opcode_shadow  : std_logic_vector(7 downto 0) := (others => '0');
    signal ret_detected   : std_logic := '0';
    signal ret_in_progress : std_logic := '0';

    -- MMU Sequencer Drive Registers
    signal mmu_wr_active  : std_logic := '0';
    signal restore_idx    : integer range 0 to 7 := 0;
    signal restore_active : std_logic := '0';
    signal restore_done   : std_logic := '0';

    signal CPU_A           : std_logic_vector(15 downto 0);
    signal CPU_D           : std_logic_vector(7 downto 0);
    signal CPU_M1_n        : std_logic;
    signal CPU_MREQ_n      : std_logic;
    signal CPU_IORQ_n      : std_logic;
    signal CPU_RD_n        : std_logic;
    signal CPU_WR_n        : std_logic;

begin

        CPU_A       <= z80_IN.Z80_ADDR;
        CPU_D       <= z80_IN.Z80_Data;
        CPU_M1_n    <= z80_IN.Z80_M1_N;
        CPU_MREQ_n  <= z80_IN.Z80_MREQ_N;
        CPU_IORQ_n  <= z80_IN.Z80_IORQ_N;
        CPU_RD_n    <= z80_IN.Z80_RD_N;
        CPU_WR_n    <= z80_IN.Z80_WR_N;


    ----------------------------------------------------------------------
    -- 1. Z80 Event Detectors
    ----------------------------------------------------------------------
    
    -- Detect when Z80 executes an opcode fetch from targeted ROM Load entry point
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            load_addr_hit <= '0';
        elsif rising_edge(CLK_IN) then
            if CPU_M1_n = '0' and CPU_MREQ_n = '0' and CPU_RD_n = '0' 
               and CPU_A = TARGET_LOAD_ADDR and LOADER_ACTIVE='1' then
                load_addr_hit <= '1';
            else
                load_addr_hit <= '0';
            end if;
        end if;
    end process;

    -- Detect specific out transaction: OUT ($E4), 127
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            out_port_hit <= '0';
        elsif rising_edge(CLK_IN) then
            -- Check for standard Z80 I/O write timing cycles 
            -- (lower 8 bits of address handle standard port mapping)
            if CPU_IORQ_n = '0' and CPU_WR_n = '0' 
               and CPU_A(7 downto 0) = C_TARGET_PORT 
               and CPU_D = C_TARGET_IO_DATA  then
                out_port_hit <= '1';
            else
                out_port_hit <= '0';
            end if;
        end if;
    end process;


----------------------------------------------------------------------
    -- 2. Opcode Fetch Monitor (Safe RET Execution)
    ----------------------------------------------------------------------
    m1_active <= '1' when (CPU_M1_n = '0' and CPU_MREQ_n = '0' and CPU_RD_n = '0' and LOADER_ACTIVE = '1') else '0';

    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            ret_detected   <= '0';
            opcode_shadow  <= (others => '0');
            m1_active_d    <= '0';
            ret_in_progress <= '0';
        elsif rising_edge(CLK_IN) then
            ret_detected <= '0';
            m1_active_d  <= m1_active;

            if seq_state = SEQ_WAIT_RET then
                -- Step A: Capture the RET opcode on M1 cycle
                if m1_active = '1' then
                    opcode_shadow <= CPU_D;
                elsif m1_active_d = '1' and m1_active = '0' then
                    -- Falling edge of M1 fetch cycle
                    if opcode_shadow = C_OPCODE_RET then
                        ret_in_progress <= '1'; -- Mark RET as fetched, waiting for execution to finish
                    end if;
                end if;

                -- Step B: Wait for RET to finish executing (Z80 pops stack), 
                -- then detect the NEXT M1 cycle starting.
                if ret_in_progress = '1' and m1_active = '1' then
                    ret_detected    <= '1'; -- NOW it is safe to trigger the MMU restore!
                    ret_in_progress <= '0';
                end if;
            else
                ret_in_progress <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- 3. MMU Storage Management
    ----------------------------------------------------------------------
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            saved_banks <= (others => (others => '0'));
        elsif rising_edge(CLK_IN) then
            if seq_state = SEQ_SAVE_CTX then
                saved_banks(0) <= MMU_BANK0_IN;
                saved_banks(1) <= MMU_BANK1_IN;
                saved_banks(2) <= MMU_BANK2_IN;
                saved_banks(3) <= MMU_BANK3_IN;
                saved_banks(4) <= MMU_BANK4_IN;
                saved_banks(5) <= MMU_BANK5_IN;
                saved_banks(6) <= MMU_BANK6_IN;
                saved_banks(7) <= MMU_BANK7_IN;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- 4. Restore Sequencer Logic
    ----------------------------------------------------------------------
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            restore_active <= '0';
            restore_idx    <= 0;
            restore_done   <= '0';
        elsif rising_edge(CLK_IN) then
            restore_done <= '0';

            if seq_state = SEQ_RESTORE then
                if restore_active = '0' then
                    restore_active <= '1';
                    restore_idx    <= 0;
                elsif restore_idx = 7 then
                    restore_active <= '0';
                    restore_done   <= '1';
                else
                    restore_idx    <= restore_idx + 1;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- 5. Shared Port MMU Multiplexer
    ----------------------------------------------------------------------
    process (seq_state,  restore_active, restore_idx, saved_banks)
    begin
        if seq_state = SEQ_SWAP_BANK0 then
            MMU_ADDR <= "000";          -- Target Bank 0 Rom slot
            MMU_DATA <= C_SWAP_PAGE;    -- Assign Target Custom Code Page $8D
            MMU_WE   <= '1';
        elsif seq_state = SEQ_SWAP_BANK0_W then
            MMU_ADDR <= "000";
            MMU_DATA <= C_SWAP_PAGE;
            MMU_WE   <= '1';
        elsif seq_state = SEQ_RESTORE and restore_active = '1' then
            MMU_ADDR <= std_logic_vector(to_unsigned(restore_idx, 3));
            MMU_DATA <= saved_banks(restore_idx);
            MMU_WE   <= '1';
        elsif seq_state = SEQ_RESTORE_W and restore_active = '1' then
            MMU_ADDR <= std_logic_vector(to_unsigned(restore_idx, 3));
            MMU_DATA <= saved_banks(restore_idx);
            MMU_WE   <= '0';
        else
            MMU_ADDR <= (others => '0');
            MMU_DATA <= (others => '0');
            MMU_WE   <= '0';
        end if;
    end process;

    ----------------------------------------------------------------------
    -- 6. Central Sequencer State Machine
    ----------------------------------------------------------------------
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            seq_state <= SEQ_IDLE;
        elsif rising_edge(CLK_IN) then
            case seq_state is
                when SEQ_IDLE =>
                    if load_addr_hit = '1' then
                        seq_state <= SEQ_SAVE_CTX;
                    end if;

                when SEQ_SAVE_CTX =>
                    seq_state <= SEQ_SWAP_BANK0;

                when SEQ_SWAP_BANK0 =>
                    seq_state <= SEQ_SWAP_BANK0_W;

                when SEQ_SWAP_BANK0_W =>
                    seq_state <= SEQ_WAIT_OUT_PORT;

                when SEQ_WAIT_OUT_PORT =>
                    -- Stay here until explicitly armed by the command out ($E4), 127
                    if out_port_hit = '1' then
                        seq_state <= SEQ_WAIT_RET;
                    end if;

                when SEQ_WAIT_RET =>
                    -- Safely watches for the standard instruction execution wrap-up
                    if ret_detected = '1' then
                        seq_state <= SEQ_RESTORE;
                    end if;

                when SEQ_RESTORE =>
                    seq_state <= SEQ_RESTORE_W;

                when SEQ_RESTORE_W =>
                    if restore_done = '1' then
                        seq_state <= SEQ_IDLE;
                    else 
                        seq_state <= SEQ_RESTORE;
                    end if;

                when others =>
                    seq_state <= SEQ_IDLE;
            end case;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- 7. Status Assignment Output
    ----------------------------------------------------------------------
    INTERCEPT_ACTIVE <= '0' when seq_state = SEQ_IDLE else '1';

end architecture rtl;