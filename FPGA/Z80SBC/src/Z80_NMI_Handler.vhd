--------------------------------------------------------------------------------
-- Z80_NMI_Handler.vhd
--
-- Purpose:
--   Amstrad CPC "tool switcher" front-end. Listens to a PS/2 keyboard byte
--   stream for F2 / F3 / F4 make codes, intercepts them so they never reach
--   the CPC's own keyboard handler, saves the live 8-bank MMU configuration,
--   forces bank 0 to the requested tool entry page, and fires a single NMI
--   pulse at the Z80. Once the Z80 acknowledges the NMI (fetch at $0066) the
--   module arms an opcode monitor that watches for "ED 45" (RETN). On RETN
--   it restores the previously saved MMU configuration. A TOOLS_ACTIVE
--   output is asserted for the whole duration of the session (from key
--   acceptance through to completed restore) so external logic can gate
--   or route MMU/PS2 signals accordingly.
--
-- Structure (matches the agreed outline):
--   entity
--     constants
--     signals
--     PS2 key receiver
--     Tool selector
--     MMU context save
--     NMI generator
--     $0066 vector detector
--     MMU write sequencer
--     Z80 opcode monitor (ED 45 / RETN)
--     MMU restore sequencer
--   architecture
--
-- Notes / assumptions (please adjust to match your board's actual bus naming
-- if it differs):
--   * sPS2_BTRDY is a one-clock strobe indicating a new PS/2 byte is present
--     on sPS2_DATA.
--   * The MMU exposes 8 bank registers, one byte each, written via a simple
--     addr/data/we bus (MMU_ADDR/MMU_DATA/MMU_WE). Replace this with your
--     actual MMU write protocol if it's different (e.g. I/O port writes).
--   * CPU_A/CPU_D are the Z80 address/data bus, CPU_M1_n/CPU_MREQ_n/CPU_RD_n
--     are active-low Z80 control signals, standard Z80 bus conventions.
--   * NMI_n is active-low, pulsed for a fixed number of clocks.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Z80_NMI_Handler is
    generic (
        NMI_PULSE_CYCLES : integer := 13   -- length of NMI_n low pulse, in CLK_IN cycles
    );
    port (
        -- Full-rate FPGA system clock (e.g. 50 MHz). Do NOT feed this a
        -- divided-down clock: the ED-45/RETN opcode monitor and the
        -- $0066 vector detector both need to reliably catch single Z80
        -- bus cycles (M1_n/MREQ_n/RD_n asserted together), and the NMI
        -- pulse timing is defined in CLK_IN cycles. Running at the full
        -- 50 MHz gives comfortable oversampling margin versus the Z80
        -- bus rate and avoids missed/metastable samples.
        CLK_IN        : in  std_logic;
        reset_n       : in  std_logic;

        -- PS/2 byte stream interface (level-held req/ack handshake):
        --   sPS2_BTRDY stays '1' while a byte is available on sPS2_DATA.
        --   To fetch the next byte, this module pulses sPS2_READ='1' for
        --   one CLK_IN cycle; sPS2_BTRDY then drops and rises again once
        --   the next byte has arrived.
        sPS2_BTRDY    : in  std_logic;                      -- byte-ready level
        sPS2_DATA     : in  std_logic_vector(7 downto 0);   -- received byte
        sPS2_READ     : out std_logic;                      -- ack pulse, 1 cycle

        -- Flag: high for one cycle whenever a byte is consumed by this
        -- module (F2/F3/F4 make codes) and must NOT be forwarded to the
        -- CPC keyboard handler.
        oKey_Consumed : out std_logic;

        -- Z80 bus (for $0066 vector fetch detection and ED 45 RETN detection)
        CPU_A         : in  std_logic_vector(15 downto 0);
        CPU_D         : in  std_logic_vector(7 downto 0);
        CPU_M1_n      : in  std_logic;
        CPU_MREQ_n    : in  std_logic;
        CPU_RD_n      : in  std_logic;

        -- NMI output to Z80
        NMI_n         : out std_logic;

        -- High from the moment a tool key (F2/F3/F4) is accepted until
        -- the MMU restore sequence completes and the module returns to
        -- idle. Use this to route/gate external MMU and PS/2 signals
        -- (e.g. force MMU bank visibility to the tool page, or block
        -- other PS/2-driven logic) while a tool session is in progress.
        TOOLS_ACTIVE  : out std_logic;

        -- MMU write interface (8 banks, byte-wide, simple addr/data/we bus)
        MMU_ADDR      : out std_logic_vector(2 downto 0);   -- bank index 0..7
        MMU_DATA      : out std_logic_vector(7 downto 0);   -- bank value to write
        MMU_WE        : out std_logic;                      -- write strobe

        -- Live MMU bank values, read continuously for context-save purposes.
        -- (Replace with actual readback signals from your MMU block.)
        MMU_BANK0_IN  : in  std_logic_vector(7 downto 0);
        MMU_BANK1_IN  : in  std_logic_vector(7 downto 0);
        MMU_BANK2_IN  : in  std_logic_vector(7 downto 0);
        MMU_BANK3_IN  : in  std_logic_vector(7 downto 0);
        MMU_BANK4_IN  : in  std_logic_vector(7 downto 0);
        MMU_BANK5_IN  : in  std_logic_vector(7 downto 0);
        MMU_BANK6_IN  : in  std_logic_vector(7 downto 0);
        MMU_BANK7_IN  : in  std_logic_vector(7 downto 0)
    );
end entity Z80_NMI_Handler;

architecture rtl of Z80_NMI_Handler is

    ----------------------------------------------------------------------
    -- constants
    ----------------------------------------------------------------------
    constant C_PS2_MAKE_F0     : std_logic_vector(7 downto 0) := x"F0"; -- break prefix
    
    constant C_PS2_F1          : std_logic_vector(7 downto 0) := x"05";
    constant C_PS2_F2          : std_logic_vector(7 downto 0) := x"06";
    constant C_PS2_F3          : std_logic_vector(7 downto 0) := x"04";
    constant C_PS2_F4          : std_logic_vector(7 downto 0) := x"0C";
    constant C_PS2_F5          : std_logic_vector(7 downto 0) := x"03";

    constant C_TOOL_PAGE_F2    : std_logic_vector(7 downto 0) := x"85";  --flash address for Atlas Debugger
    constant C_TOOL_PAGE_F3    : std_logic_vector(7 downto 0) := x"8A";  --flash page for spectrum $8A-$8E (5 Pages)
    constant C_TOOL_PAGE_F4    : std_logic_vector(7 downto 0) := x"8F";  --flash page for amstrad   

    constant C_NMI_VECTOR      : std_logic_vector(15 downto 0) := x"0066"; 

    constant C_OPCODE_ED       : std_logic_vector(7 downto 0) := x"ED";
    constant C_OPCODE_RETN     : std_logic_vector(7 downto 0) := x"45";

    ----------------------------------------------------------------------
    -- signals
    ----------------------------------------------------------------------
    -- PS/2 receiver
    --   ps2_hs_state drives the BTRDY/READ handshake itself.
    --   ps2_break_pending tracks whether the byte we are about to service
    --   is the break code following an F0 prefix (orthogonal to the
    --   handshake state machine).
    type ps2_hs_state_t is (PS2_S_WAIT, PS2_S_ACK, PS2_S_CLEAR);
    signal ps2_hs_state     : ps2_hs_state_t := PS2_S_WAIT;
    signal ps2_break_pending : std_logic := '0';

    -- Tool selector
    signal tool_page_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal tool_request     : std_logic := '0';  -- one-cycle pulse: valid F2/F3/F4 seen

    -- MMU context save (shadow copy of all 8 banks, latched at trigger time)
    type mmu_banks_t is array (0 to 7) of std_logic_vector(7 downto 0);
    signal saved_banks     : mmu_banks_t := (others => (others => '0'));
    signal context_valid   : std_logic := '0';

    -- NMI generator
    signal nmi_pulse_cnt   : integer range 0 to NMI_PULSE_CYCLES := 0;
    signal nmi_active      : std_logic := '0';
    signal nmi_request     : std_logic := '0'; -- one-cycle pulse requesting NMI start

    -- Top-level sequencer state
    type seq_state_t is (
        SEQ_IDLE,        -- waiting for a tool key
        SEQ_SAVE_CTX,    -- latch current MMU banks        
        SEQ_DO_NMI,
        SEQ_WAIT_VECTOR, -- wait for Z80 fetch at $0066 (NMI ack)
        SEQ_WR_BANK0,    -- write tool page into bank 0, fire NMI
        SEQ_WR_BANK0_W,   --wait to change bank        
        SEQ_WAIT_RETN,   -- monitor for ED 45 (RETN), tool is running
        SEQ_RESTORE,      -- write saved banks back
        SEQ_RESTORE_W
    );
    signal seq_state       : seq_state_t := SEQ_IDLE;

    -- $0066 vector detector
    signal nmi_vector_hit  : std_logic := '0';

    -- Z80 opcode monitor (ED 45 / RETN)
    signal m1_active       : std_logic := '0';
    signal m1_active_d     : std_logic := '0';
    signal opcode_shadow   : std_logic_vector(7 downto 0) := (others => '0');
    signal last_opcode     : std_logic_vector(7 downto 0) := (others => '0');
    signal saw_ed          : std_logic := '0';
    signal retn_detected   : std_logic := '0';

    -- MMU write sequencer (writes tool page to bank 0)
    signal mmu_wr_active   : std_logic := '0';
    signal mmu_wr_addr     : std_logic_vector(2 downto 0) := (others => '0');
    signal mmu_wr_data     : std_logic_vector(7 downto 0) := (others => '0');
    signal mmu_wr_strobe   : std_logic := '0';

    -- MMU restore sequencer (writes all 8 saved banks back, one per cycle)
    signal restore_idx     : integer range 0 to 7 := 0;
    signal restore_active  : std_logic := '0';
    signal restore_done    : std_logic := '0';

begin

    ----------------------------------------------------------------------
    -- PS2 key receiver
    --   Implements the level-held BTRDY / pulsed READ handshake:
    --     PS2_S_WAIT  - wait for sPS2_BTRDY = '1' (a byte is available).
    --                   Service it combinationally with the current
    --                   register values, then pulse sPS2_READ for one
    --                   cycle to tell the source to fetch the next byte.
    --     PS2_S_ACK   - drop sPS2_READ back to '0' (it was only asserted
    --                   for a single CLK_IN cycle).
    --     PS2_S_CLEAR - wait here until sPS2_BTRDY drops back to '0',
    --                   confirming the source has moved on, before
    --                   returning to PS2_S_WAIT to look for the next byte.
    --                   Without this wait we could re-latch the same byte
    --                   multiple times while BTRDY is still high.
    --
    --   Tracks break-code prefix (F0) so break codes are ignored.
    --   Only make codes for F2 (05) / F3 (0D) / F4 (0C) are consumed and
    --   turned into a tool_request pulse + tool_page_reg value. All other
    --   bytes (and all break codes) are NOT consumed, i.e. oKey_Consumed
    --   stays low and the byte is left for the normal CPC keyboard path.
    ----------------------------------------------------------------------
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            ps2_hs_state      <= PS2_S_WAIT;
            ps2_break_pending <= '0';
            tool_request      <= '0';
            tool_page_reg     <= (others => '0');
            oKey_Consumed     <= '0';
            sPS2_READ         <= '0';
        elsif rising_edge(CLK_IN) then
            -- defaults: pulses are one cycle wide
            tool_request  <= '0';
            oKey_Consumed <= '0';
            sPS2_READ     <= '0';

            case ps2_hs_state is
                when PS2_S_WAIT =>
                    if sPS2_BTRDY = '1' then
                        if ps2_break_pending = '0' then
                            if sPS2_DATA = C_PS2_MAKE_F0 then
                                -- break prefix incoming; the next byte
                                -- serviced will be the break code itself.
                                ps2_break_pending <= '1';
                            elsif sPS2_DATA = C_PS2_F2 then
                                tool_page_reg <= C_TOOL_PAGE_F2;
                                tool_request  <= '1';
                                oKey_Consumed <= '1';
                            elsif sPS2_DATA = C_PS2_F3 then
                                tool_page_reg <= C_TOOL_PAGE_F3;
                                tool_request  <= '1';
                                oKey_Consumed <= '1';
                            elsif sPS2_DATA = C_PS2_F4 then
                                tool_page_reg <= C_TOOL_PAGE_F4;
                                tool_request  <= '1';
                                oKey_Consumed <= '1';
                            end if;
                            -- any other make code: not consumed, falls
                            -- through to the normal keyboard handler.
                        else
                            -- this byte is the break code itself; ignore
                            -- it regardless of value, and do not consume
                            -- it (let the CPC keyboard handler see
                            -- releases normally), except releases of
                            -- F2/F3/F4 which we also swallow so the CPC
                            -- never sees them.
                            if sPS2_DATA = C_PS2_F2 or
                               sPS2_DATA = C_PS2_F3 or
                               sPS2_DATA = C_PS2_F4 then
                                oKey_Consumed <= '1';
                            end if;
                            ps2_break_pending <= '0';
                        end if;

                        -- byte serviced: pulse READ to advance to the
                        -- next byte, then wait for BTRDY to clear.
                        sPS2_READ    <= '1';
                        ps2_hs_state <= PS2_S_ACK;
                    end if;

                when PS2_S_ACK =>
                    -- sPS2_READ already deasserted by the default above;
                    -- this state just spends one cycle before waiting
                    -- for BTRDY to clear.
                    ps2_hs_state <= PS2_S_CLEAR;

                when PS2_S_CLEAR =>
                    if sPS2_BTRDY = '0' then
                        ps2_hs_state <= PS2_S_WAIT;
                    end if;
            end case;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- Tool selector
    --   tool_request / tool_page_reg from the PS2 receiver above are
    --   simply passed to the top-level sequencer, which is the only
    --   consumer. Kept as a distinct block per the agreed structure so it
    --   is easy to extend (e.g. debounce, key-repeat lockout) later.
    ----------------------------------------------------------------------
    -- (logic folded into seq_state process below; tool_request/tool_page_reg
    --  are the outputs of this stage)

    ----------------------------------------------------------------------
    -- MMU context save
    --   On entry to SEQ_SAVE_CTX, latch all 8 live bank values.
    ----------------------------------------------------------------------
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            saved_banks   <= (others => (others => '0'));
            context_valid <= '0';
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
                context_valid  <= '1';
            elsif seq_state = SEQ_IDLE then
                context_valid <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- NMI generator
    --   Generates a fixed-width active-low pulse on NMI_n whenever
    --   nmi_request is pulsed. Independent of the MMU write sequencer -
    --   both are kicked off together from SEQ_WR_BANK0 but run as separate
    --   pieces of logic.
    ----------------------------------------------------------------------
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            nmi_active    <= '0';
            nmi_pulse_cnt <= 0;
            NMI_n         <= '1';
        elsif rising_edge(CLK_IN) then
            if nmi_request = '1' and nmi_active = '0' then
                nmi_active    <= '1';
                nmi_pulse_cnt <= 0;
                NMI_n         <= '0';
            elsif nmi_active = '1' then
                if nmi_pulse_cnt = NMI_PULSE_CYCLES - 1 then
                    nmi_active <= '0';
                    NMI_n      <= '1';
                else
                    nmi_pulse_cnt <= nmi_pulse_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- $0066 vector detector
    --   Flags one cycle when the Z80 performs an opcode fetch (M1, MREQ,
    --   RD all active-low asserted) at address $0066, i.e. the CPU has
    --   accepted the NMI and jumped to its service routine.
    ----------------------------------------------------------------------
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            nmi_vector_hit <= '0';
        elsif rising_edge(CLK_IN) then
            if CPU_M1_n = '0' and CPU_MREQ_n = '0' and CPU_RD_n = '0'
               and CPU_A = C_NMI_VECTOR then
                nmi_vector_hit <= '1';
            else
                nmi_vector_hit <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- MMU write sequencer
    --   Writes the requested tool page into bank 0 only. Other banks are
    --   left untouched at this stage; the tool itself may remap further
    --   banks later through the normal MMU interface.
    ----------------------------------------------------------------------
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            mmu_wr_active <= '0';
            mmu_wr_strobe <= '0';
        elsif rising_edge(CLK_IN) then
            mmu_wr_strobe <= '0'; -- default: one-cycle strobe

            if seq_state = SEQ_WR_BANK0  and mmu_wr_active = '0' then
                mmu_wr_addr   <= "000";           -- bank 0
                mmu_wr_data   <= tool_page_reg;
                mmu_wr_strobe <= '1';
                mmu_wr_active <= '1';
            elsif seq_state = SEQ_WR_BANK0_W then   --wait the addresses
                mmu_wr_strobe <= '1';
            elsif seq_state /= SEQ_WR_BANK0 then
                mmu_wr_active <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- Z80 opcode monitor (ED 45 / RETN detector)
    --   Watches M1 opcode fetches. Detects the two-byte sequence ED 45
    --   (RETN). Only armed while seq_state = SEQ_WAIT_RETN.
    ----------------------------------------------------------------------
    m1_active <= '1' when (CPU_M1_n = '0' and CPU_MREQ_n = '0' and CPU_RD_n = '0')
                 else '0';

    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            saw_ed        <= '0';
            retn_detected <= '0';
            last_opcode   <= (others => '0');
            opcode_shadow <= (others => '0');
            m1_active_d   <= '0';
        elsif rising_edge(CLK_IN) then
            retn_detected <= '0'; -- default: one-cycle pulse
            m1_active_d   <= m1_active;

            if seq_state = SEQ_WAIT_RETN then
                if m1_active = '1' then
                    -- fetch cycle in progress; keep capturing the latest
                    -- sample, do NOT evaluate it yet.
                    opcode_shadow <= CPU_D;
                elsif m1_active_d = '1' and m1_active = '0' then
                    -- falling edge: the fetch cycle just ended, so
                    -- opcode_shadow now holds the final, settled byte.
                    last_opcode <= opcode_shadow;

                    if saw_ed = '1' and opcode_shadow = C_OPCODE_RETN then
                        retn_detected <= '1';
                        saw_ed        <= '0';
                    elsif opcode_shadow = C_OPCODE_ED then
                        saw_ed <= '1';
                    else
                        saw_ed <= '0';
                    end if;
                end if;
            else
                saw_ed <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- MMU restore sequencer
    --   On entry to SEQ_RESTORE, writes all 8 saved bank values back to
    --   the MMU, one bank per clock cycle, using the saved shadow copy
    --   (never live MMU values).
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
                    restore_idx <= restore_idx + 1;
                end if;
          --  else
          --      restore_active <= '0';
          --      restore_idx    <= 0;
            end if;
        end if;
    end process;

    -- MMU output bus mux: the write sequencer (bank 0, tool entry) and the
    -- restore sequencer (all 8 banks, saved context) share the single MMU
    -- write port. They are never active at the same time (mutually
    -- exclusive sequencer states), so a simple mux is sufficient.
    process (seq_state, mmu_wr_addr, mmu_wr_data, mmu_wr_strobe,
             restore_active, restore_idx, saved_banks)
    begin
        if seq_state = SEQ_WR_BANK0 or seq_state = SEQ_WR_BANK0_W then
            MMU_ADDR <= mmu_wr_addr;
            MMU_DATA <= mmu_wr_data;
            MMU_WE   <= mmu_wr_strobe;
        elsif seq_state = SEQ_RESTORE and restore_active = '1' then
            MMU_ADDR <= std_logic_vector(to_unsigned(restore_idx, 3));
            MMU_DATA <= saved_banks(restore_idx);
            MMU_WE   <= '1';
        elsif seq_state = SEQ_RESTORE_W and restore_active = '1' then   --wait 1 clock to settle the address
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
    -- Top-level sequencer
    --   Ties all the blocks above together:
    --     IDLE -> SAVE_CTX -> WR_BANK0 (+ NMI pulse) -> WAIT_VECTOR
    --           -> WAIT_RETN -> RESTORE -> IDLE
    ----------------------------------------------------------------------
    process (CLK_IN, reset_n)
    begin
        if reset_n = '0' then
            seq_state   <= SEQ_IDLE;
            nmi_request <= '0';
        elsif rising_edge(CLK_IN) then
            nmi_request <= '0'; -- default: one-cycle pulse

            case seq_state is
                when SEQ_IDLE =>
                    if tool_request = '1' then
                        seq_state <= SEQ_SAVE_CTX;
                    end if;

                when SEQ_SAVE_CTX =>
                    -- context_valid goes high this same cycle (see MMU
                    -- context save process); move on next cycle.
                    seq_state <= SEQ_DO_NMI;

                when SEQ_DO_NMI =>  --START THE NMI
                    -- kick the MMU write sequencer and the NMI generator
                    -- together; they run independently from here.                    
                    nmi_request <= '1';
                    seq_state <= SEQ_WAIT_VECTOR;

                when SEQ_WAIT_VECTOR =>
                    if nmi_vector_hit = '1' then
                        seq_state <= SEQ_WR_BANK0;
                    end if;

                when SEQ_WR_BANK0 =>
                    seq_state   <= SEQ_WR_BANK0_W;

                when SEQ_WR_BANK0_W =>
                    seq_state   <= SEQ_WAIT_RETN;

                when SEQ_WAIT_RETN =>
                    if retn_detected = '1' then
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
    -- TOOLS_ACTIVE output
    --   Combinational: high whenever the top-level sequencer is anywhere
    --   other than SEQ_IDLE, i.e. from the accepted tool key through to
    --   the completed MMU restore. Use this externally to gate/route MMU
    --   and PS/2 signals while a tool session is in progress.
    ----------------------------------------------------------------------
    TOOLS_ACTIVE <= '0' when seq_state = SEQ_IDLE else '1';

end architecture rtl;