library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

------------------------------------------------------------------------------
-- CDT/TZX tape controller, split across two clock domains:
--
--   clk_fpga  : fast, fixed FPGA system clock (e.g. 50 MHz). Drives the SRAM
--               DMA engine and the entire CDT block parser. Because this
--               domain is decoupled from real tape playback, header bytes,
--               skips, loop bookkeeping etc. all happen at full FPGA speed
--               instead of being paced to the Z80's own clock.
--
--   clk_z80   : the actual Z80 system clock. Its rate is whatever the rest
--               of the design currently has selected (2/4/8/... MHz) and can
--               change at runtime; z80_clk_mhz reports the current value in
--               whole MHz so pulse timings stay correct across the change.
--               Only this domain toggles tape_level and answers Z80 port
--               reads, because that is the only thing that actually needs to
--               happen in real time.
--
-- The two domains only ever exchange a single, self-contained "next pulse"
-- record (duration + action), passed through a two-phase (toggle) handshake:
-- that is the only CDC boundary in the design, plus a synchroniser on
-- busack_n (sampled by clk_fpga, driven by the Z80 on clk_z80) and one on
-- the tape_started flag (raised on clk_z80, consumed on clk_fpga).
------------------------------------------------------------------------------

entity cdt_tape_controller is
    generic (
        -- Byte address in the external SRAM where the CDT/TZX image begins.
        -- Example: with 4KB pages, "page $1A" = 16#1A000# = x"1A000".
        -- Example: with 8KB pages, "page $1A" = 16#34000# = x"34000".
        G_CDT_BASE_ADDR    : STD_LOGIC_VECTOR(19 downto 0) := x"34000";

        -- CLK_FPGA cycles between the SRAM address becoming valid and its
        -- data becoming valid. A fast async SRAM typically only needs 2.
        G_SRAM_WAIT_CYCLES : integer := 3;

        G_TAPE_ACTIVE_HIGH : boolean := true
    );
    Port (
        clk_fpga        : in  STD_LOGIC;   -- fast fixed FPGA clock (decode + DMA)
        clk_z80         : in  STD_LOGIC;   -- variable Z80-rate clock (real-time delivery)
        z80_clk_mhz     : in  STD_LOGIC_VECTOR(7 downto 0); -- current clk_z80 rate, whole MHz
        reset           : in  STD_LOGIC;

        -- Z80 Direct Memory Access (DMA) Interface
        z80_busreq_n    : out STD_LOGIC;
        z80_busack_n    : in  STD_LOGIC;

        -- External Async SRAM Interface
        sram_addr       : out STD_LOGIC_VECTOR(19 downto 0);
        sram_data       : in  STD_LOGIC_VECTOR(7 downto 0);
        sram_oe_n       : out STD_LOGIC;

        
        tape_ctrl       : in STD_LOGIC_VECTOR(7 downto 0);
        tape_bit_out    : out STD_LOGIC
    );
end cdt_tape_controller;

architecture Behavioral of cdt_tape_controller is

    ------------------------------------------------------------------------
    -- What a decoded "pulse" is: how long it lasts (in clk_z80 cycles) and
    -- what the delivery domain should do with tape_level when it elapses.
    ------------------------------------------------------------------------
    type pulse_action_t is (ACT_TOGGLE, ACT_FORCE_LOW, ACT_FORCE_HIGH);

    ------------------------------------------------------------------------
    -- CDT parser sub-FSM. One flat enumeration (a custom type can only have
    -- one driving process), grouped by the block ID that owns each state.
    -- Runs entirely in the clk_fpga domain, gated by parser_run.
    ------------------------------------------------------------------------
    type parser_state_type is (
        PARSE_INIT, PARSE_WAIT_BYTE, PARSE_READ_ID, PARSE_READ_ID_GOT,
        PARSE_EMIT_START, PARSE_EMIT_WAIT, PARSE_SKIP_ONE_BYTE, PARSE_SKIP_ONE_BYTE_GOT,
        PARSE_UNSUPPORTED,

        -- $10 : Standard Speed Data Block
        PARSE_10_PAUSE_LO, PARSE_10_PAUSE_LO_GOT, PARSE_10_PAUSE_HI_GOT,
        PARSE_10_LEN_LO_GOT, PARSE_10_LEN_HI_GOT, PARSE_10_FLAG_GOT,

        -- $11 : Turbo Speed Data Block (fully custom timings)
        PARSE_11_PILOT_LEN_LO, PARSE_11_PILOT_LEN_LO_GOT, PARSE_11_PILOT_LEN_HI_GOT,
        PARSE_11_SYNC1_LO_GOT, PARSE_11_SYNC1_HI_GOT,
        PARSE_11_SYNC2_LO_GOT, PARSE_11_SYNC2_HI_GOT,
        PARSE_11_ZERO_LO_GOT,  PARSE_11_ZERO_HI_GOT,
        PARSE_11_ONE_LO_GOT,   PARSE_11_ONE_HI_GOT,
        PARSE_11_PILOTCNT_LO_GOT, PARSE_11_PILOTCNT_HI_GOT,
        PARSE_11_USEDBITS_GOT,
        PARSE_11_PAUSE_LO_GOT, PARSE_11_PAUSE_HI_GOT,
        PARSE_11_LEN_LO_GOT, PARSE_11_LEN_MID_GOT, PARSE_11_LEN_HI_GOT,

        -- shared pilot / sync / bitstream emission ($10, $11, $14 reuse these)
        PARSE_PILOT, PARSE_SYNC1, PARSE_SYNC2,
        PARSE_FETCH_BYTE, PARSE_FETCH_BYTE_GOT, PARSE_EMIT_BIT,
        PARSE_PAUSE_PULSE,

        -- $12 : Pure Tone
        PARSE_12_LEN_LO, PARSE_12_LEN_LO_GOT, PARSE_12_LEN_HI_GOT,
        PARSE_12_COUNT_LO_GOT, PARSE_12_COUNT_HI_GOT,

        -- $13 : Sequence of Pulses
        PARSE_13_COUNT_FETCH, PARSE_13_COUNT_GOT,
        PARSE_13_PULSE_LO, PARSE_13_PULSE_LO_GOT, PARSE_13_PULSE_HI_GOT,
        PARSE_13_PULSE_EMIT,

        -- $14 : Pure Data Block (no pilot/sync, otherwise like $10/$11 data)
        PARSE_14_ZERO_LO, PARSE_14_ZERO_LO_GOT, PARSE_14_ZERO_HI_GOT,
        PARSE_14_ONE_LO_GOT, PARSE_14_ONE_HI_GOT,
        PARSE_14_USEDBITS_GOT,
        PARSE_14_PAUSE_LO_GOT, PARSE_14_PAUSE_HI_GOT,
        PARSE_14_LEN_LO_GOT, PARSE_14_LEN_MID_GOT, PARSE_14_LEN_HI_GOT,

        -- $15 : Direct Recording (raw 1-bit samples, no pilot/sync/bit-pairs)
        PARSE_15_PERIOD_LO, PARSE_15_PERIOD_LO_GOT, PARSE_15_PERIOD_HI_GOT,
        PARSE_15_PAUSE_LO_GOT, PARSE_15_PAUSE_HI_GOT,
        PARSE_15_USEDBITS_GOT,
        PARSE_15_LEN_LO_GOT, PARSE_15_LEN_MID_GOT, PARSE_15_LEN_HI_GOT,
        PARSE_15_FETCH_BYTE, PARSE_15_FETCH_BYTE_GOT, PARSE_15_EMIT_SAMPLE,

        -- $20 : Pause / Stop the Tape
        PARSE_20_PAUSE_LO, PARSE_20_PAUSE_LO_GOT, PARSE_20_PAUSE_HI_GOT, PARSE_20_DECIDE,

        -- $21 Group Start / $23 Jump / $24 Loop Start / $25 Loop End
        PARSE_21_LEN, PARSE_21_LEN_GOT,
        PARSE_23_JUMP_LO, PARSE_23_JUMP_LO_GOT, PARSE_23_JUMP_HI_GOT,
        PARSE_24_COUNT_LO, PARSE_24_COUNT_LO_GOT, PARSE_24_COUNT_HI_GOT,
        PARSE_25_DECIDE,

        -- $30 Text description / $32 Archive info / $33 Hardware type / $35 Custom info
        PARSE_30_LEN, PARSE_30_LEN_GOT,
        PARSE_32_LEN_LO, PARSE_32_LEN_LO_GOT, PARSE_32_LEN_HI_GOT,
        PARSE_33_COUNT, PARSE_33_COUNT_GOT,
        PARSE_35_SKIP_ID, PARSE_35_LEN0, PARSE_35_LEN0_GOT,
        PARSE_35_LEN1_GOT, PARSE_35_LEN2_GOT, PARSE_35_LEN3_GOT
    );
    signal parser_state        : parser_state_type := PARSE_INIT;
    signal parser_next_state   : parser_state_type := PARSE_INIT; -- resume point after a DMA byte wait
    signal parser_resume_state : parser_state_type := PARSE_INIT; -- resume point after a pulse handoff
    signal skip_return_state   : parser_state_type := PARSE_INIT; -- resume point after a generic byte-skip
    signal parser_run          : std_logic := '0';                -- decode enabled

    ------------------------------------------------------------------------
    -- DMA byte-fetch sub-FSM (clk_fpga domain). Sole owner of ram_ptr /
    -- sram_* / z80_busreq_n. Suspends the Z80, presents the address, counts
    -- out G_SRAM_WAIT_CYCLES, captures the byte, releases the bus, and
    -- pulses dma_done to tell the parser the byte is ready.
    ------------------------------------------------------------------------
    type dma_state_type is (
        DMA_IDLE, DMA_WAIT_ACK, DMA_SET_ADDR, DMA_WAIT, DMA_READ_BYTE, DMA_RELEASE
    );
    signal dma_state : dma_state_type := DMA_IDLE;

    signal dma_start     : std_logic := '0'; -- pulse: "fetch one byte please"
    signal dma_rewind    : std_logic := '0'; -- pulse: "reset file pointer to base"
    signal dma_seek      : std_logic := '0'; -- pulse: "set file pointer to dma_seek_addr" (loop back)
    signal dma_seek_addr : unsigned(19 downto 0) := (others => '0');
    signal dma_done      : std_logic := '0'; -- pulse: "byte is ready in dma_read_data"
    signal dma_read_data : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_ptr       : unsigned(19 downto 0) := (others => '0');
    signal wait_ctr       : integer range 0 to 255 := 0;

    signal busack_sync1, busack_sync2 : std_logic := '1';

    ------------------------------------------------------------------------
    -- Z80 intercept + real-time delivery (clk_z80 domain)
    ------------------------------------------------------------------------

    signal tape_started       : std_logic := '0';
    signal tape_loaded       : std_logic := '0';
    signal tape_level       : std_logic := '0';
    
    -- Previous sampled PPI Port C bit 4 (CASS_ON) level, clk_z80 domain.
    -- This is deliberately NOT a sticky latch: both edges matter.
    signal tape_start_prev  : std_logic := '0';

    type pb_state_t is (PB_WAIT, PB_RUN);
    signal pb_state   : pb_state_t := PB_WAIT;
    signal pb_counter : unsigned(39 downto 0) := (others => '0');
    signal pb_action  : pulse_action_t := ACT_TOGGLE;
    signal req_sync1, req_sync2, last_seen_req : std_logic := '0';

    ------------------------------------------------------------------------
    -- The single-entry handshake between the two domains (CDC boundary)
    ------------------------------------------------------------------------
    signal pq_duration   : unsigned(39 downto 0) := (others => '0'); -- written by clk_fpga, read by clk_z80
    signal pq_action     : pulse_action_t := ACT_TOGGLE;
    signal pq_req_toggle : std_logic := '0'; -- clk_fpga flips this when pq_* is valid & stable
    signal pq_ack_toggle : std_logic := '0'; -- clk_z80 flips this once it has latched pq_*

    signal ack_sync1, ack_sync2 : std_logic := '0'; -- clk_fpga's synchronised view of pq_ack_toggle
    -- Synchronised live level of PPI Port C bit 4 (CASS_ON).
    -- ts_sync2 is the current level; ts_prev is only the previous sample
    -- used for detecting BOTH rising and falling edges.
    signal ts_sync1, ts_sync2, ts_prev : std_logic := '0';

    signal pending_duration : unsigned(39 downto 0) := (others => '0'); -- staged, not yet handed off
    signal pending_action   : pulse_action_t := ACT_TOGGLE;

    signal z80_clk_mhz_u : unsigned(7 downto 0);

    ------------------------------------------------------------------------
    -- CDT block-header working registers, shared across block types that
    -- don't run concurrently with one another
    ------------------------------------------------------------------------
    signal pilot_pulse_len : unsigned(15 downto 0) := to_unsigned(2168, 16);
    signal sync1_pulse_len : unsigned(15 downto 0) := to_unsigned(667, 16);
    signal sync2_pulse_len : unsigned(15 downto 0) := to_unsigned(735, 16);
    signal zero_pulse_len  : unsigned(15 downto 0) := to_unsigned(855, 16);
    signal one_pulse_len   : unsigned(15 downto 0) := to_unsigned(1710, 16);
    signal sample_period_len : unsigned(15 downto 0) := (others => '0'); -- $15

    signal pilot_count       : unsigned(15 downto 0) := (others => '0');
    signal pilot_then_read_id: std_logic := '0'; -- '1' for $12 (tone only, no sync/data after)
    signal used_bits_last    : unsigned(3 downto 0)  := to_unsigned(8, 4);
    signal pause_ms           : unsigned(15 downto 0) := (others => '0');
    signal data_bytes_rem    : unsigned(23 downto 0) := (others => '0');
    signal seq_count         : unsigned(7 downto 0)  := (others => '0'); -- $13
    signal skip_count        : unsigned(31 downto 0) := (others => '0'); -- $21/$30/$32/$33/$35

    signal current_byte    : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_index       : integer range 0 to 7 := 7;
    signal bit_pulse_phase : std_logic := '0';   -- 0 = 1st pulse of bit, 1 = 2nd
    signal byte_preloaded  : std_logic := '0';   -- $10's flag byte is read early
    signal is_last_byte    : std_logic := '0';
    signal stop_bit_idx    : integer range 0 to 8 := 0;

    signal tmp_byte0, tmp_byte1, tmp_byte2 : std_logic_vector(7 downto 0) := (others => '0');

    signal loop_start_addr : unsigned(19 downto 0) := (others => '0'); -- $24/$25
    signal loop_count      : unsigned(15 downto 0) := (others => '0');

    ------------------------------------------------------------------------
    -- Rescale a T-state duration (@3.5MHz reference, as stored in the file)
    -- into clk_z80 cycles at whatever rate z80_clk_mhz currently reports:
    --   cycles = tstates * freq_MHz * 2 / 7        (since 3.5MHz = 7/2 MHz)
    -- Every intermediate width below is sized to the actual value range
    -- (not left to the unsigned*NATURAL "double-width" default) so this
    -- stays a modest combinational multiply/divide rather than a 64-bit one.
    -- NOTE: this is a synthesised divider; if timing closure is tight,
    -- pipeline it or restrict z80_clk_mhz to power-of-two-friendly ratios.
    ------------------------------------------------------------------------
    function scale_pulse_rt(v : unsigned(15 downto 0); freq_mhz : unsigned(7 downto 0)) return unsigned is
        constant C_2   : unsigned(1 downto 0) := to_unsigned(2, 2);
        constant C_7   : unsigned(3 downto 0) := to_unsigned(7, 4);
        variable step1 : unsigned(23 downto 0); -- v(16) * freq(8)      = 24 bits
        variable step2 : unsigned(25 downto 0); -- step1(24) * 2(2)    = 26 bits
    begin
        step1 := v * freq_mhz;
        step2 := step1 * C_2;
        return resize(step2 / C_7, 40);
    end function;

    -- Convert a millisecond PAUSE value into clk_z80 cycles: ms * MHz * 1000
    function pause_cycles_rt(ms : unsigned(15 downto 0); freq_mhz : unsigned(7 downto 0)) return unsigned is
        constant C_1000 : unsigned(9 downto 0) := to_unsigned(1000, 10);
        variable step1  : unsigned(23 downto 0); -- ms(16) * freq(8)      = 24 bits
        variable step2  : unsigned(33 downto 0); -- step1(24) * 1000(10) = 34 bits
    begin
        step1 := ms * freq_mhz;
        step2 := step1 * C_1000;
        return resize(step2, 40);
    end function;

begin

    z80_clk_mhz_u <= unsigned(z80_clk_mhz);
    tape_started <= tape_ctrl(4);
    tape_loaded <= tape_ctrl(0);
    ----------------------------------------------------------------------------
    -- 1. Z80 HARDWARE INTERCEPT (generic I/O decode -> single data bit)
    --    Purely combinational; entirely native to the clk_z80 domain since
    --    the Z80 itself is clocked by clk_z80, so no CDC is needed here.
    ----------------------------------------------------------------------------

    process(tape_started, tape_level)
    begin
            if tape_started = '1' then
                if G_TAPE_ACTIVE_HIGH then
                    tape_bit_out <= tape_level;
                else
                    tape_bit_out <= not tape_level;
                end if;
            else
                tape_bit_out <= '0';
            end if;
    end process;

    ----------------------------------------------------------------------------
    -- 2. REAL-TIME PULSE DELIVERY (clk_z80 domain)
    ----------------------------------------------------------------------------
    process(clk_z80, reset)
    begin
        if reset = '1' then
            pb_state        <= PB_WAIT;
            pb_counter      <= (others => '0');
            pb_action       <= ACT_TOGGLE;
            tape_level      <= '0';
            tape_start_prev <= '0';
            pq_ack_toggle   <= '0';
            req_sync1       <= '0';
            req_sync2       <= '0';
            last_seen_req   <= '0';

        elsif rising_edge(clk_z80) then
            req_sync1 <= pq_req_toggle;
            req_sync2 <= req_sync1;

            tape_start_prev <= tape_started;

            if tape_started = '0' then
                -- Motor Off: Force output LOW. ACK incoming requests so 
                -- the decoder domain does not deadlock in WAIT_ACK.
                if req_sync2 /= last_seen_req then
                    last_seen_req <= req_sync2;
                    pq_ack_toggle <= not pq_ack_toggle;
                end if;
                pb_state   <= PB_WAIT;
                pb_counter <= (others => '0');
                tape_level <= '0';

            elsif tape_start_prev = '0' then
                -- Motor Just Turned On: Clean state reset
                pb_state      <= PB_WAIT;
                pb_counter    <= (others => '0');
                tape_level    <= '0';
                last_seen_req <= req_sync2;

            else
                case pb_state is
                    when PB_WAIT =>
                        if req_sync2 /= last_seen_req then
                            last_seen_req <= req_sync2;
                            pq_ack_toggle <= not pq_ack_toggle; -- ACK immediately on latch

                            -- APPLY ACTION IMMEDIATELY AT PULSE START
                            case pq_action is
                                when ACT_TOGGLE     => tape_level <= not tape_level;
                                when ACT_FORCE_LOW  => tape_level <= '0';
                                when ACT_FORCE_HIGH => tape_level <= '1';
                            end case;

                            -- Account for 1 cycle spent in PB_WAIT
                            if pq_duration > 1 then
                                pb_counter <= pq_duration - 1;
                                pb_state   <= PB_RUN;
                            else
                                pb_state   <= PB_WAIT;
                            end if;
                        end if;

                    when PB_RUN =>
                        if pb_counter > 1 then
                            pb_counter <= pb_counter - 1;
                        else
                            pb_state <= PB_WAIT;
                        end if;
                end case;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 3. DMA BYTE-FETCH ENGINE (clk_fpga domain)
    ----------------------------------------------------------------------------
    process(clk_fpga, reset)
    begin
        if reset = '1' then
            dma_state     <= DMA_IDLE;
            z80_busreq_n  <= '1';
            sram_oe_n     <= '1';
            sram_addr     <= (others => '0');
            dma_done      <= '0';
            dma_read_data <= (others => '0');
            ram_ptr       <= unsigned(G_CDT_BASE_ADDR)+10;--skip ZXTape!
            wait_ctr      <= 0;
            busack_sync1  <= '1';
            busack_sync2  <= '1';

        elsif rising_edge(clk_fpga) then
            dma_done <= '0'; -- default: single-cycle "byte ready" pulse

            busack_sync1 <= z80_busack_n;
            busack_sync2 <= busack_sync1;

            case dma_state is

                when DMA_IDLE =>
                    sram_oe_n <= '1';
                    if dma_rewind = '1' then
                        ram_ptr <= unsigned(G_CDT_BASE_ADDR)+10;
                    elsif dma_seek = '1' then
                        ram_ptr <= dma_seek_addr;
                    elsif dma_start = '1' then
                        z80_busreq_n <= '0';         -- ask the Z80 to release the bus
                        dma_state    <= DMA_WAIT_ACK;
                    end if;

                when DMA_WAIT_ACK =>
                    if busack_sync2 = '0' then       -- Z80 confirms bus released (synchronised)
                        sram_addr <= std_logic_vector(ram_ptr);
                        dma_state <= DMA_SET_ADDR;
                    end if;

                when DMA_SET_ADDR =>
                    sram_oe_n <= '0';                -- enable SRAM output
                    wait_ctr  <= G_SRAM_WAIT_CYCLES;
                    dma_state <= DMA_WAIT;

                when DMA_WAIT =>
                    if wait_ctr = 0 then
                        dma_state <= DMA_READ_BYTE;
                    else
                        wait_ctr <= wait_ctr - 1;
                    end if;

                when DMA_READ_BYTE =>
                    dma_read_data <= sram_data;      -- capture the byte
                    sram_oe_n     <= '1';
                    ram_ptr       <= ram_ptr + 1;      -- advance the file pointer
                    dma_state     <= DMA_RELEASE;

                when DMA_RELEASE =>
                    z80_busreq_n <= '1';              -- give the bus back
                    dma_done     <= '1';               -- "byte ready" strobe to the parser
                    dma_state    <= DMA_IDLE;

            end case;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 4. CDT BLOCK PARSER (clk_fpga domain)
    --    PARSE_READ_ID is the single "landing point" every block returns to;
    --    from there dispatch fans out into one state group per block ID.
    ----------------------------------------------------------------------------
    process(clk_fpga, reset)
    begin
        if reset = '1' then
            parser_state        <= PARSE_INIT;
            parser_next_state   <= PARSE_INIT;
            parser_resume_state <= PARSE_INIT;
            skip_return_state   <= PARSE_INIT;
            parser_run          <= '0';
            dma_start           <= '0';
            dma_rewind          <= '0';
            dma_seek            <= '0';
            dma_seek_addr       <= (others => '0');
            ack_sync1           <= '0';
            ack_sync2           <= '0';
            ts_sync1            <= '0';
            ts_sync2            <= '0';
            ts_prev             <= '0';
            pq_req_toggle       <= '0';
            pending_duration    <= (others => '0');
            pending_action      <= ACT_TOGGLE;

            pilot_pulse_len   <= to_unsigned(2168, 16);
            sync1_pulse_len   <= to_unsigned(667, 16);
            sync2_pulse_len   <= to_unsigned(735, 16);
            zero_pulse_len    <= to_unsigned(855, 16);
            one_pulse_len     <= to_unsigned(1710, 16);
            sample_period_len <= (others => '0');
            pilot_count       <= (others => '0');
            pilot_then_read_id<= '0';
            used_bits_last    <= to_unsigned(8, 4);
            pause_ms          <= (others => '0');
            data_bytes_rem    <= (others => '0');
            seq_count         <= (others => '0');
            skip_count        <= (others => '0');
            current_byte      <= (others => '0');
            bit_index         <= 7;
            bit_pulse_phase   <= '0';
            byte_preloaded    <= '0';
            is_last_byte      <= '0';
            stop_bit_idx      <= 0;
            tmp_byte0         <= (others => '0');
            tmp_byte1         <= (others => '0');
            tmp_byte2         <= (others => '0');
            loop_start_addr   <= (others => '0');
            loop_count        <= (others => '0');

        elsif rising_edge(clk_fpga) then
            dma_start  <= '0'; -- default: single-cycle strobes
            dma_rewind <= '0';
            if tape_loaded='0' then dma_rewind<='1'; end if;

            dma_seek   <= '0';

            ack_sync1 <= pq_ack_toggle; ack_sync2 <= ack_sync1;

            -- Synchronise the LIVE PPI Port C bit 4 (CASS_ON) level.
            ts_sync1 <= tape_started;
            ts_sync2 <= ts_sync1;
            
            


            -- Detect BOTH edges of CASS_ON.  ts_sync2 is the current level;
            -- ts_prev is only the previous synchronized sample.
            if ts_sync2 = '1' and ts_prev = '0' then
                -- Rising edge: start from the position of the tape image.                
                parser_state <= PARSE_INIT;
                parser_run   <= '1';
            elsif ts_sync2 = '0' and ts_prev = '1' then
                -- Falling edge: stop the parser immediately.
                parser_run   <= '0';
                parser_state <= PARSE_INIT;
            end if;
            ts_prev <= ts_sync2;

            -- Do not execute one more parser state on a falling edge.
            if (ts_sync2 = '0' and ts_prev = '1') then
                null;
            elsif (ts_sync2 = '1' and ts_prev = '0') then
                null;
            elsif parser_run = '1' then
                case parser_state is

                    when PARSE_INIT =>
                        parser_state <= PARSE_READ_ID;

                    when PARSE_WAIT_BYTE =>
                        if dma_done = '1' then
                            parser_state <= parser_next_state;
                        end if;

  --------------------------------------------------------
                    -- HANDSHAKE STATES (Matches clk_z80 CDC process)
                    --------------------------------------------------------
                    when PARSE_EMIT_START =>
                        pq_duration   <= pending_duration;
                        pq_action     <= pending_action;
                        pq_req_toggle <= not pq_req_toggle; -- Toggle request to clk_z80
                        parser_state  <= PARSE_EMIT_WAIT;

                    when PARSE_EMIT_WAIT =>
                        -- Wait for clk_z80 process to acknowledge the latch
                        if ack_sync2 = pq_req_toggle then
                            parser_state <= parser_resume_state;
                        end if;

                    when PARSE_SKIP_ONE_BYTE =>
                        if skip_count = 0 then
                            parser_state <= skip_return_state;
                        else
                            dma_start <= '1'; parser_next_state <= PARSE_SKIP_ONE_BYTE_GOT;
                            parser_state <= PARSE_WAIT_BYTE;
                        end if;
                    when PARSE_SKIP_ONE_BYTE_GOT =>
                        skip_count   <= skip_count - 1;
                        parser_state <= PARSE_SKIP_ONE_BYTE;

                    --------------------------------------------------------
                    when PARSE_READ_ID =>
                        dma_start <= '1'; parser_next_state <= PARSE_READ_ID_GOT;
                        parser_state <= PARSE_WAIT_BYTE;

                    when PARSE_READ_ID_GOT =>
                        case dma_read_data is
                            when x"10"  => parser_state <= PARSE_10_PAUSE_LO;
                            when x"11"  => parser_state <= PARSE_11_PILOT_LEN_LO;
                            when x"12"  => parser_state <= PARSE_12_LEN_LO;
                            when x"13"  => parser_state <= PARSE_13_COUNT_FETCH;
                            when x"14"  => parser_state <= PARSE_14_ZERO_LO;
                            when x"15"  => parser_state <= PARSE_15_PERIOD_LO;
                            when x"20"  => parser_state <= PARSE_20_PAUSE_LO;
                            when x"21"  => parser_state <= PARSE_21_LEN;
                            when x"22"  => parser_state <= PARSE_READ_ID;      -- Group End: no body
                            when x"23"  => parser_state <= PARSE_23_JUMP_LO;
                            when x"24"  => parser_state <= PARSE_24_COUNT_LO;
                            when x"25"  => parser_state <= PARSE_25_DECIDE;
                            when x"30"  => parser_state <= PARSE_30_LEN;
                            when x"32"  => parser_state <= PARSE_32_LEN_LO;
                            when x"33"  => parser_state <= PARSE_33_COUNT;
                            when x"35"  => parser_state <= PARSE_35_SKIP_ID;
                            when others => parser_state <= PARSE_UNSUPPORTED;
                        end case;

                    --------------------------------------------------------
                    -- $10 : STANDARD SPEED DATA BLOCK
                    --------------------------------------------------------
                    when PARSE_10_PAUSE_LO =>
                        dma_start <= '1'; parser_next_state <= PARSE_10_PAUSE_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_10_PAUSE_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_10_PAUSE_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_10_PAUSE_HI_GOT =>
                        pause_ms  <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_10_LEN_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_10_LEN_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_10_LEN_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_10_LEN_HI_GOT =>
                        data_bytes_rem <= resize(unsigned(dma_read_data & tmp_byte0), 24);
                        dma_start <= '1'; parser_next_state <= PARSE_10_FLAG_GOT; -- peek the flag byte
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_10_FLAG_GOT =>
                        current_byte <= dma_read_data;
                        if unsigned(dma_read_data) < 128 then
                            pilot_count <= to_unsigned(8063, 16); -- header block
                        else
                            pilot_count <= to_unsigned(3223, 16); -- data block
                        end if;
                        pilot_pulse_len  <= to_unsigned(2168, 16);
                        sync1_pulse_len  <= to_unsigned(667, 16);
                        sync2_pulse_len  <= to_unsigned(735, 16);
                        zero_pulse_len   <= to_unsigned(855, 16);
                        one_pulse_len    <= to_unsigned(1710, 16);
                        used_bits_last   <= to_unsigned(8, 4);
                        byte_preloaded   <= '1';
                        pilot_then_read_id <= '0';
                        parser_state     <= PARSE_PILOT;

--------------------------------------------------------
                    -- $11 : TURBO SPEED DATA BLOCK
                    --------------------------------------------------------
                    when PARSE_11_PILOT_LEN_LO =>
                        dma_start <= '1'; parser_next_state <= PARSE_11_PILOT_LEN_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_PILOT_LEN_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_11_PILOT_LEN_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_PILOT_LEN_HI_GOT =>
                        pilot_pulse_len <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_11_SYNC1_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_SYNC1_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_11_SYNC1_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_SYNC1_HI_GOT =>
                        sync1_pulse_len <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_11_SYNC2_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_SYNC2_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_11_SYNC2_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_SYNC2_HI_GOT =>
                        sync2_pulse_len <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_11_ZERO_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_ZERO_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_11_ZERO_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_ZERO_HI_GOT =>
                        zero_pulse_len <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_11_ONE_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_ONE_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_11_ONE_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_ONE_HI_GOT =>
                        one_pulse_len <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_11_PILOTCNT_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_PILOTCNT_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_11_PILOTCNT_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_PILOTCNT_HI_GOT =>
                        pilot_count <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_11_USEDBITS_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_USEDBITS_GOT =>
                        used_bits_last <= unsigned(dma_read_data(3 downto 0));
                        dma_start <= '1'; parser_next_state <= PARSE_11_PAUSE_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_PAUSE_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_11_PAUSE_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_PAUSE_HI_GOT =>
                        pause_ms  <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_11_LEN_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_LEN_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_11_LEN_MID_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_LEN_MID_GOT =>
                        tmp_byte1 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_11_LEN_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_11_LEN_HI_GOT =>
                        data_bytes_rem <= unsigned(dma_read_data & tmp_byte1 & tmp_byte0);
                        byte_preloaded <= '0'; -- $11 has no pre-read flag byte
                        pilot_then_read_id <= '0';
                        parser_state   <= PARSE_PILOT;

                    --------------------------------------------------------
                    -- SHARED: pilot tone / sync pulses / bit serialisation
                    --------------------------------------------------------
                    when PARSE_PILOT =>
                        if pilot_count > 0 then
                            pending_duration     <= scale_pulse_rt(pilot_pulse_len, z80_clk_mhz_u);
                            pending_action       <= ACT_TOGGLE;
                            pilot_count          <= pilot_count - 1;
                            parser_resume_state  <= PARSE_PILOT;
                            parser_state         <= PARSE_EMIT_START ;
                        elsif pilot_then_read_id = '1' then
                            pilot_then_read_id <= '0';
                            parser_state       <= PARSE_READ_ID;         -- $12: tone only, done
                        else
                            parser_state <= PARSE_SYNC1;
                        end if;

                    when PARSE_SYNC1 =>
                        pending_duration    <= scale_pulse_rt(sync1_pulse_len, z80_clk_mhz_u);
                        pending_action      <= ACT_TOGGLE;
                        parser_resume_state <= PARSE_SYNC2;
                        parser_state        <= PARSE_EMIT_START ;

                    when PARSE_SYNC2 =>
                        pending_duration    <= scale_pulse_rt(sync2_pulse_len, z80_clk_mhz_u);
                        pending_action      <= ACT_TOGGLE;
                        parser_resume_state <= PARSE_FETCH_BYTE;
                        parser_state        <= PARSE_EMIT_START ;

                    when PARSE_FETCH_BYTE =>
                        if data_bytes_rem = 0 then
                            if pause_ms > 0 then
                                parser_state <= PARSE_PAUSE_PULSE;
                            else
                                parser_state <= PARSE_READ_ID;
                            end if;
                        elsif byte_preloaded = '1' then
                            byte_preloaded  <= '0';
                            bit_index       <= 7;
                            bit_pulse_phase <= '0';
                            if data_bytes_rem = 1 then
                                is_last_byte <= '1'; stop_bit_idx <= 8 - to_integer(used_bits_last);
                            else
                                is_last_byte <= '0';
                            end if;
                            parser_state <= PARSE_EMIT_BIT;
                        else
                            dma_start <= '1'; parser_next_state <= PARSE_FETCH_BYTE_GOT;
                            parser_state <= PARSE_WAIT_BYTE;
                        end if;

                    when PARSE_FETCH_BYTE_GOT =>
                        current_byte    <= dma_read_data;
                        bit_index       <= 7;
                        bit_pulse_phase <= '0';
                        if data_bytes_rem = 1 then
                            is_last_byte <= '1'; stop_bit_idx <= 8 - to_integer(used_bits_last);
                        else
                            is_last_byte <= '0';
                        end if;
                        parser_state <= PARSE_EMIT_BIT;

                    when PARSE_EMIT_BIT =>
                        if current_byte(bit_index) = '1' then
                            pending_duration <= scale_pulse_rt(one_pulse_len, z80_clk_mhz_u);
                        else
                            pending_duration <= scale_pulse_rt(zero_pulse_len, z80_clk_mhz_u);
                        end if;
                        pending_action <= ACT_TOGGLE;

                        if bit_pulse_phase = '0' then
                            bit_pulse_phase     <= '1';
                            parser_resume_state <= PARSE_EMIT_BIT;   -- 2nd pulse of the same bit
                        else
                            bit_pulse_phase <= '0';
                            if bit_index > 0 and not (is_last_byte = '1' and bit_index = stop_bit_idx) then
                                bit_index           <= bit_index - 1;
                                parser_resume_state  <= PARSE_EMIT_BIT;
                            else
                                data_bytes_rem       <= data_bytes_rem - 1;
                                parser_resume_state  <= PARSE_FETCH_BYTE;
                            end if;
                        end if;
                        parser_state <= PARSE_EMIT_START ;

                    when PARSE_PAUSE_PULSE =>
                        pending_duration     <= pause_cycles_rt(pause_ms, z80_clk_mhz_u);
                        pending_action       <= ACT_FORCE_LOW;
                        parser_resume_state  <= PARSE_READ_ID;
                        parser_state         <= PARSE_EMIT_START ;

                    --------------------------------------------------------
                    -- $12 : PURE TONE (reuses PARSE_PILOT as the emitter)
                    --------------------------------------------------------
                    when PARSE_12_LEN_LO =>
                        dma_start <= '1'; parser_next_state <= PARSE_12_LEN_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_12_LEN_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_12_LEN_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_12_LEN_HI_GOT =>
                        pilot_pulse_len <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_12_COUNT_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_12_COUNT_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_12_COUNT_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_12_COUNT_HI_GOT =>
                        pilot_count        <= unsigned(dma_read_data & tmp_byte0);
                        pilot_then_read_id <= '1';
                        parser_state       <= PARSE_PILOT;

                    --------------------------------------------------------
                    -- $13 : SEQUENCE OF PULSES
                    --------------------------------------------------------
                    when PARSE_13_COUNT_FETCH =>
                        dma_start <= '1'; parser_next_state <= PARSE_13_COUNT_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_13_COUNT_GOT =>
                        seq_count    <= unsigned(dma_read_data);
                        parser_state <= PARSE_13_PULSE_LO;
                    when PARSE_13_PULSE_LO =>
                        if seq_count = 0 then
                            parser_state <= PARSE_READ_ID;
                        else
                            dma_start <= '1'; parser_next_state <= PARSE_13_PULSE_LO_GOT;
                            parser_state <= PARSE_WAIT_BYTE;
                        end if;
                    when PARSE_13_PULSE_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_13_PULSE_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_13_PULSE_HI_GOT =>
                        pending_duration    <= scale_pulse_rt(unsigned(dma_read_data & tmp_byte0), z80_clk_mhz_u);
                        pending_action      <= ACT_TOGGLE;
                        parser_resume_state <= PARSE_13_PULSE_EMIT;
                        parser_state        <= PARSE_EMIT_START ;
                    when PARSE_13_PULSE_EMIT =>
                        seq_count    <= seq_count - 1;
                        parser_state <= PARSE_13_PULSE_LO;

                    --------------------------------------------------------
                    -- $14 : PURE DATA BLOCK (no pilot/sync)
                    --------------------------------------------------------
                    when PARSE_14_ZERO_LO =>
                        dma_start <= '1'; parser_next_state <= PARSE_14_ZERO_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_14_ZERO_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_14_ZERO_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_14_ZERO_HI_GOT =>
                        zero_pulse_len <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_14_ONE_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_14_ONE_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_14_ONE_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_14_ONE_HI_GOT =>
                        one_pulse_len <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_14_USEDBITS_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_14_USEDBITS_GOT =>
                        used_bits_last <= unsigned(dma_read_data(3 downto 0));
                        dma_start <= '1'; parser_next_state <= PARSE_14_PAUSE_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_14_PAUSE_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_14_PAUSE_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_14_PAUSE_HI_GOT =>
                        pause_ms  <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_14_LEN_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_14_LEN_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_14_LEN_MID_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_14_LEN_MID_GOT =>
                        tmp_byte1 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_14_LEN_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_14_LEN_HI_GOT =>
                        data_bytes_rem <= unsigned(dma_read_data & tmp_byte1 & tmp_byte0);
                        byte_preloaded <= '0';
                        parser_state   <= PARSE_FETCH_BYTE;  -- straight to data, no pilot/sync

                    --------------------------------------------------------
                    -- $15 : DIRECT RECORDING (raw samples, one pulse/bit)
                    --------------------------------------------------------
                    when PARSE_15_PERIOD_LO =>
                        dma_start <= '1'; parser_next_state <= PARSE_15_PERIOD_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_15_PERIOD_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_15_PERIOD_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_15_PERIOD_HI_GOT =>
                        sample_period_len <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_15_PAUSE_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_15_PAUSE_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_15_PAUSE_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_15_PAUSE_HI_GOT =>
                        pause_ms  <= unsigned(dma_read_data & tmp_byte0);
                        dma_start <= '1'; parser_next_state <= PARSE_15_USEDBITS_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_15_USEDBITS_GOT =>
                        used_bits_last <= unsigned(dma_read_data(3 downto 0));
                        dma_start <= '1'; parser_next_state <= PARSE_15_LEN_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_15_LEN_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_15_LEN_MID_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_15_LEN_MID_GOT =>
                        tmp_byte1 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_15_LEN_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_15_LEN_HI_GOT =>
                        data_bytes_rem <= unsigned(dma_read_data & tmp_byte1 & tmp_byte0);
                        parser_state   <= PARSE_15_FETCH_BYTE;

                    when PARSE_15_FETCH_BYTE =>
                        if data_bytes_rem = 0 then
                            if pause_ms > 0 then
                                parser_state <= PARSE_PAUSE_PULSE;
                            else
                                parser_state <= PARSE_READ_ID;
                            end if;
                        else
                            dma_start <= '1'; parser_next_state <= PARSE_15_FETCH_BYTE_GOT;
                            parser_state <= PARSE_WAIT_BYTE;
                        end if;
                    when PARSE_15_FETCH_BYTE_GOT =>
                        current_byte <= dma_read_data;
                        bit_index    <= 7;
                        if data_bytes_rem = 1 then
                            is_last_byte <= '1'; stop_bit_idx <= 8 - to_integer(used_bits_last);
                        else
                            is_last_byte <= '0';
                        end if;
                        parser_state <= PARSE_15_EMIT_SAMPLE;
                    when PARSE_15_EMIT_SAMPLE =>
                        if current_byte(bit_index) = '1' then
                            pending_action <= ACT_FORCE_HIGH;
                        else
                            pending_action <= ACT_FORCE_LOW;
                        end if;
                        pending_duration <= scale_pulse_rt(sample_period_len, z80_clk_mhz_u);
                        if bit_index > 0 and not (is_last_byte = '1' and bit_index = stop_bit_idx) then
                            bit_index           <= bit_index - 1;
                            parser_resume_state <= PARSE_15_EMIT_SAMPLE;
                        else
                            data_bytes_rem      <= data_bytes_rem - 1;
                            parser_resume_state <= PARSE_15_FETCH_BYTE;
                        end if;
                        parser_state <= PARSE_EMIT_START ;

                    --------------------------------------------------------
                    -- $20 : PAUSE (or "Stop the tape" if the value is 0)
                    --------------------------------------------------------
                    when PARSE_20_PAUSE_LO =>
                        dma_start <= '1'; parser_next_state <= PARSE_20_PAUSE_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_20_PAUSE_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_20_PAUSE_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_20_PAUSE_HI_GOT =>
                        pause_ms     <= unsigned(dma_read_data & tmp_byte0);
                        parser_state <= PARSE_20_DECIDE;
                    when PARSE_20_DECIDE =>
                        if pause_ms = 0 then
                            parser_run <= '0'; -- "Stop the tape": halt decode
                        else
                            pending_duration    <= pause_cycles_rt(pause_ms, z80_clk_mhz_u);
                            pending_action      <= ACT_FORCE_LOW;
                            parser_resume_state <= PARSE_READ_ID;
                            parser_state        <= PARSE_EMIT_START ;
                        end if;

                    --------------------------------------------------------
                    -- $21 : GROUP START (name is informational; just skip it)
                    --------------------------------------------------------
                    when PARSE_21_LEN =>
                        dma_start <= '1'; parser_next_state <= PARSE_21_LEN_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_21_LEN_GOT =>
                        skip_count        <= resize(unsigned(dma_read_data), 32);
                        skip_return_state <= PARSE_READ_ID;
                        parser_state      <= PARSE_SKIP_ONE_BYTE;

                    --------------------------------------------------------
                    -- $23 : JUMP TO BLOCK -- STUB, see note below.
                    -- The jump distance is defined in *blocks*, relative to
                    -- this block's own position. Resolving that correctly
                    -- (forward or backward) needs a table of every block's
                    -- start offset, built by an earlier scan of the file --
                    -- there isn't one here, so the value is read and
                    -- discarded and parsing simply continues linearly. Any
                    -- file that relies on $23 to loop will load once through
                    -- and stop looping, but won't hang or corrupt playback.
                    -- Real $24/$25 loops (the common case) are implemented
                    -- properly below, since those only need one remembered
                    -- address rather than a full block index.
                    --------------------------------------------------------
                    when PARSE_23_JUMP_LO =>
                        dma_start <= '1'; parser_next_state <= PARSE_23_JUMP_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_23_JUMP_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_23_JUMP_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_23_JUMP_HI_GOT =>
                        parser_state <= PARSE_READ_ID; -- see note above

                    --------------------------------------------------------
                    -- $24 : LOOP START -- remember where the loop body
                    -- begins (right after this header) and how many times
                    -- to repeat it.
                    --------------------------------------------------------
                    when PARSE_24_COUNT_LO =>
                        dma_start <= '1'; parser_next_state <= PARSE_24_COUNT_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_24_COUNT_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_24_COUNT_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_24_COUNT_HI_GOT =>
                        loop_count      <= unsigned(dma_read_data & tmp_byte0);
                        loop_start_addr <= ram_ptr; -- loop body starts right here
                        parser_state    <= PARSE_READ_ID;

                    --------------------------------------------------------
                    -- $25 : LOOP END -- seek back if repeats remain.
                    -- Convention used here: the $24 count is the *total*
                    -- number of passes (so count=1 behaves like no loop).
                    --------------------------------------------------------
                    when PARSE_25_DECIDE =>
                        if loop_count <= 1 then
                            loop_count   <= (others => '0');
                            parser_state <= PARSE_READ_ID;
                        else
                            loop_count    <= loop_count - 1;
                            dma_seek      <= '1';
                            dma_seek_addr <= loop_start_addr;
                            parser_state  <= PARSE_READ_ID;
                        end if;

                    --------------------------------------------------------
                    -- $30 : TEXT DESCRIPTION (1-byte length, ASCII, skip)
                    --------------------------------------------------------
                    when PARSE_30_LEN =>
                        dma_start <= '1'; parser_next_state <= PARSE_30_LEN_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_30_LEN_GOT =>
                        skip_count        <= resize(unsigned(dma_read_data), 32);
                        skip_return_state <= PARSE_READ_ID;
                        parser_state      <= PARSE_SKIP_ONE_BYTE;

                    --------------------------------------------------------
                    -- $32 : ARCHIVE INFO (2-byte length, skip)
                    --------------------------------------------------------
                    when PARSE_32_LEN_LO =>
                        dma_start <= '1'; parser_next_state <= PARSE_32_LEN_LO_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_32_LEN_LO_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_32_LEN_HI_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_32_LEN_HI_GOT =>
                        skip_count        <= resize(unsigned(dma_read_data & tmp_byte0), 32);
                        skip_return_state <= PARSE_READ_ID;
                        parser_state      <= PARSE_SKIP_ONE_BYTE;

                    --------------------------------------------------------
                    -- $33 : HARDWARE TYPE (1-byte count N, N*3 bytes, skip)
                    --------------------------------------------------------
                    when PARSE_33_COUNT =>
                        dma_start <= '1'; parser_next_state <= PARSE_33_COUNT_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_33_COUNT_GOT =>
                        skip_count        <= resize(unsigned(dma_read_data) * 3, 32);
                        skip_return_state <= PARSE_READ_ID;
                        parser_state      <= PARSE_SKIP_ONE_BYTE;

                    --------------------------------------------------------
                    -- $35 : CUSTOM INFO (10-byte ID + 4-byte length, skip)
                    --------------------------------------------------------
                    when PARSE_35_SKIP_ID =>
                        skip_count        <= to_unsigned(10, 32);
                        skip_return_state <= PARSE_35_LEN0;
                        parser_state      <= PARSE_SKIP_ONE_BYTE;
                    when PARSE_35_LEN0 =>
                        dma_start <= '1'; parser_next_state <= PARSE_35_LEN0_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_35_LEN0_GOT =>
                        tmp_byte0 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_35_LEN1_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_35_LEN1_GOT =>
                        tmp_byte1 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_35_LEN2_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_35_LEN2_GOT =>
                        tmp_byte2 <= dma_read_data;
                        dma_start <= '1'; parser_next_state <= PARSE_35_LEN3_GOT;
                        parser_state <= PARSE_WAIT_BYTE;
                    when PARSE_35_LEN3_GOT =>
                        skip_count        <= unsigned(dma_read_data & tmp_byte2 & tmp_byte1 & tmp_byte0);
                        skip_return_state <= PARSE_READ_ID;
                        parser_state      <= PARSE_SKIP_ONE_BYTE;

                    --------------------------------------------------------
                    when PARSE_UNSUPPORTED =>
                        -- Unknown/unimplemented block ID: halt cleanly.
                        parser_run <= '0';

                    when others =>
                        parser_state <= PARSE_UNSUPPORTED;

                end case;
            end if;
        end if;
    end process;

end architecture;