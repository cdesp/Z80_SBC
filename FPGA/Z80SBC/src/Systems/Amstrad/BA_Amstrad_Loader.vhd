--------------------------------------------------------------------------------
-- CPC_Load_Interceptor.vhd
--
-- Purpose:
--   Amstrad CPC automated tool interceptor. Monitors the Z80 bus for an opcode
--   fetch at either of two targeted firmware jumpblock addresses:
--     - CAS IN OPEN   ($BC77) - open/find a file, read its header
--     - CAS IN DIRECT ($BC83) - read the whole file into memory
--   When either is hit, it saves the live MMU context, intercepts the 8K slot
--   that contains both addresses, and swaps it to a designated custom page
--   ($8B). The module then waits for an explicit command indicator: an I/O
--   write to the target port with a data payload matching C_TARGET_IO_DATA.
--   Only after this out instruction is processed does it arm its opcode
--   monitor to look for a standard RET ($C9) instruction to cleanly restore
--   the original bank structure.
--
-- PORTING NOTES (Spectrum -> CPC):
--
--   1. ROM vs RAM trap target
--      On the Spectrum, $0556 (LD-BYTES) lives in ROM: nothing else of value
--      lives there, so swapping the whole 8K slot away and back is free.
--      On the CPC, the firmware jumpblock lives in RAM ($BB00-$BD5D), inside
--      an 8K window ($A000-$BFFF) that ALSO holds live firmware/BASIC
--      workspace and buffers outside the jumpblock itself. Swapping the
--      entire slot to a different physical page therefore hides that live
--      data for the duration of the intercept. Two ways to handle this:
--        a) Build C_SWAP_PAGE as a byte-for-byte mirror of the real slot 5
--           contents, with only the JP stubs patched in at the two known
--           jumpblock offsets (see below). This is what this module assumes.
--        b) Skip page-swapping entirely and instead have your boot-time
--           logic directly overwrite the 3-byte JP at $BC77/$BC83 in real
--           RAM with a JP to a stub placed in genuinely unused RAM, and
--           drop the MMU swap/restore state machine altogether. Simpler and
--           safer for the CPC's memory model, but is a different design
--           than the one ported here - ask if you want that version instead.
--
--   2. Both trap addresses share one MMU slot
--      $BC77 and $BC83 both fall in slot 5 ($A000-$BFFF, addr(15 downto 13)
--      = "101"), so a single bank-swap covers both firmware calls. The two
--      stub entry points must sit in C_SWAP_PAGE at the SAME offsets they'd
--      have in real memory:
--        CAS IN OPEN   stub -> offset $1C77 ($BC77 - $A000)
--        CAS IN DIRECT stub -> offset $1C83 ($BC83 - $A000)
--      If you add a third trap point outside this slot (e.g. CAS IN CHAR at
--      $BC80 is ALSO in slot 5 and fits for free; something outside
--      $A000-$BFFF would not), you'll need a second slot/swap pair.
--
--   3. I/O port decode
--      CPC peripherals decode ports mostly off the HIGH address byte (Gate
--      Array ~$7Fxx, CRTC ~$BCxx-$BFxx, PPI ~$F4xx-$F7xx, FDC $FA7E/$FB7E).
--      The original Spectrum module only compared the low byte (matching
--      "OUT (n),A" / ULA-style decoding, which ignores the address bus).
--      That is NOT safe on the CPC. This version compares the FULL 16-bit
--      port address, and defaults to an arbitrary port in an unused range
--      ($FBE4) - your stub must therefore use "OUT (C),A" with BC loaded as
--      a 16-bit port address, not the 8-bit immediate form. Verify $FBE4
--      (or whatever you pick) against your actual system's full port map
--      before relying on it.
--
--   4. TRAP_ID output (new)
--      Unlike LD-BYTES, which does one job, CAS IN OPEN and CAS IN DIRECT
--      have different entry/exit register conventions and your companion
--      loading logic needs to know which one fired. TRAP_ID is latched when
--      load_addr_hit occurs and stays valid until the intercept completes.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE work.defs_pkg.ALL; -- Import constants / shared record types

entity CPC_Load_Interceptor is
    generic (
        -- CAS IN OPEN - open/find a file, read its header
        TARGET_ADDR_1    : std_logic_vector(15 downto 0) := x"2392"; --BC77
        -- CAS IN DIRECT - read the whole file into memory
        TARGET_ADDR_2    : std_logic_vector(15 downto 0) := x"24AB"; --BC83
        -- Set false if you only want to trap CAS IN OPEN
        ENABLE_ADDR_2    : boolean := true
    );
    port (
        -- Full-rate FPGA system clock (e.g., 50 MHz) for clean oversampling
        CLK_IN          : in  std_logic;
        reset_n         : in  std_logic;
        LOADER_ACTIVE   : in  std_logic; -- Active high

        -- Z80 System Bus Signals _RAW *****
        Z80_In_raw          : in  t_z80_to_sys_raw;

        -- Session Control Outputs
        INTERCEPT_ACTIVE: out std_logic;
        -- '0' = CAS IN OPEN fired, '1' = CAS IN DIRECT fired. Valid while
        -- INTERCEPT_ACTIVE = '1'.
        TRAP_ID         : out std_logic;
        CPU_WAIT        : out std_logic;

        -- MMU Interface (8 banks, byte-wide, simple control bus)
        MMU_Intf        : out t_mmu_intf;

        -- Live MMU input lines for initial dynamic context tracking
        MMU_Banks       : in t_mmu_banks
    );
end entity CPC_Load_Interceptor;

architecture rtl of CPC_Load_Interceptor is

    ----------------------------------------------------------------------
    -- Constants
    ----------------------------------------------------------------------
    constant C_SWAP_PAGE       : std_logic_vector(7 downto 0)  := x"90";
    -- Full 16-bit port compare (see porting note 3) - verify before use.
    constant C_TARGET_PORT     : std_logic_vector(15 downto 0) := x"FBE4";
    constant C_TARGET_IO_DATA  : std_logic_vector(7 downto 0)  := x"7F"; -- 127
    constant C_OPCODE_RET      : std_logic_vector(7 downto 0)  := x"C9";

    -- Both trap addresses must share an 8K MMU slot (see porting note 2).
    -- Slot is derived from TARGET_ADDR_1; TARGET_ADDR_2 is expected to fall
    -- in the same slot when ENABLE_ADDR_2 = true.
    constant C_TARGET_SLOT     : std_logic_vector(2 downto 0) := TARGET_ADDR_1(15 downto 13);

    ----------------------------------------------------------------------
    -- Internal Signals
    ----------------------------------------------------------------------
    type seq_state_t is (
        SEQ_IDLE,
        SEQ_SAVE_CTX,
        SEQ_SWAP_BANK0,
        SEQ_SWAP_BANK0_W,
        SEQ_WAIT_OUT_PORT,
        SEQ_WAIT_RET,
        SEQ_RESTORE,
        SEQ_RESTORE_W
    );
    signal seq_state : seq_state_t := SEQ_IDLE;

    type mmu_banks_t is array (0 to 7) of std_logic_vector(7 downto 0);
    signal saved_banks : mmu_banks_t := (others => (others => '0'));

    signal load_addr_hit : std_logic := '0';
    signal trap_id_i     : std_logic := '0';
    signal out_port_hit  : std_logic := '0';

    signal m1_active      : std_logic := '0';
    signal m1_active_d    : std_logic := '0';
    signal opcode_shadow  : std_logic_vector(7 downto 0) := (others => '0');
    signal ret_detected   : std_logic := '0';
    signal ret_in_progress : std_logic := '0';

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

    signal   MMU_BANK0_IN  : std_logic_vector(7 downto 0);
    signal   MMU_BANK1_IN  : std_logic_vector(7 downto 0);
    signal   MMU_BANK2_IN  : std_logic_vector(7 downto 0);
    signal   MMU_BANK3_IN  : std_logic_vector(7 downto 0);
    signal   MMU_BANK4_IN  : std_logic_vector(7 downto 0);
    signal   MMU_BANK5_IN  : std_logic_vector(7 downto 0);
    signal   MMU_BANK6_IN  : std_logic_vector(7 downto 0);
    signal   MMU_BANK7_IN  : std_logic_vector(7 downto 0);

    signal   MMU_ADDR      : std_logic_vector(2 downto 0);
    signal   MMU_DATA      : std_logic_vector(7 downto 0);
    signal   MMU_WE        : std_logic;

begin

        MMU_BANK0_IN <= MMU_Banks.BANK0;
        MMU_BANK1_IN <= MMU_Banks.BANK1;
        MMU_BANK2_IN <= MMU_Banks.BANK2;
        MMU_BANK3_IN <= MMU_Banks.BANK3;
        MMU_BANK4_IN <= MMU_Banks.BANK4;
        MMU_BANK5_IN <= MMU_Banks.BANK5;
        MMU_BANK6_IN <= MMU_Banks.BANK6;
        MMU_BANK7_IN <= MMU_Banks.BANK7;

        MMU_Intf.FPGA_MMU_BANK <= MMU_ADDR;
        MMU_Intf.FPGA_MMU_PAGE <= MMU_DATA;
        MMU_Intf.FPGA_MMU_WE   <= MMU_WE;

        CPU_A       <= Z80_In_raw.Z80_ADDR_raw;
        CPU_D       <= Z80_In_raw.Z80_Data_raw;
        CPU_M1_n    <= Z80_In_raw.Z80_M1_N_raw;
        CPU_MREQ_n  <= Z80_In_raw.Z80_MREQ_N_raw;
        CPU_IORQ_n  <= Z80_In_raw.Z80_IORQ_N_raw;
        CPU_RD_n    <= Z80_In_raw.Z80_RD_N_raw;
        CPU_WR_n    <= Z80_In_raw.Z80_WR_N_raw;

    ----------------------------------------------------------------------
    -- 1. Z80 Event Detectors
    ----------------------------------------------------------------------

    -- Detect an opcode fetch from either targeted firmware jumpblock entry.
    -- Latches TRAP_ID so downstream logic knows which routine was called.
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            load_addr_hit <= '0';
            trap_id_i     <= '0';
        elsif rising_edge(CLK_IN) then
            if CPU_M1_n = '0' and CPU_MREQ_n = '0' and CPU_RD_n = '0'
               and LOADER_ACTIVE = '1' then
                if CPU_A = TARGET_ADDR_1 then
                    load_addr_hit <= '1';
                    trap_id_i     <= '0'; -- CAS IN OPEN
                elsif ENABLE_ADDR_2 and CPU_A = TARGET_ADDR_2 then
                    load_addr_hit <= '1';
                    trap_id_i     <= '1'; -- CAS IN DIRECT
                else
                    load_addr_hit <= '0';
                end if;
            else
                load_addr_hit <= '0';
            end if;
        end if;
    end process;

    -- Detect specific out transaction: OUT (C), A with BC = C_TARGET_PORT
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            out_port_hit <= '0';
        elsif rising_edge(CLK_IN) then
            if CPU_IORQ_n = '0' and CPU_WR_n = '0'
               and CPU_A = C_TARGET_PORT
               and CPU_D = C_TARGET_IO_DATA then
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
                if m1_active = '1' then
                    opcode_shadow <= CPU_D;
                elsif m1_active_d = '1' and m1_active = '0' then
                    if opcode_shadow = C_OPCODE_RET then
                        ret_in_progress <= '1';
                    end if;
                end if;

                if ret_in_progress = '1' and m1_active = '1' then
                    ret_detected    <= '1';
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
    process (seq_state, restore_active, restore_idx, saved_banks)
    begin
        if seq_state = SEQ_SWAP_BANK0 then
            MMU_ADDR <= C_TARGET_SLOT;  -- Slot containing both trap addresses
            MMU_DATA <= C_SWAP_PAGE;
            MMU_WE   <= '1';
        elsif seq_state = SEQ_SWAP_BANK0_W then
            MMU_ADDR <= C_TARGET_SLOT;
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
                    if out_port_hit = '1' then
                        seq_state <= SEQ_WAIT_RET;
                    end if;

                when SEQ_WAIT_RET =>
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
    TRAP_ID          <= trap_id_i;
    CPU_WAIT         <= '0' when seq_state = SEQ_RESTORE or seq_state = SEQ_RESTORE_W else '1';

end architecture rtl;