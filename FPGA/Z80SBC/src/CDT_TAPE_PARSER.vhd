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
        clk_fpga        : in  STD_LOGIC;
        -- fast fixed FPGA clock (decode + DMA)
        clk_z80         : in  STD_LOGIC;
        -- variable Z80-rate clock (real-time delivery)
        z80_clk_mhz     : in  STD_LOGIC_VECTOR(7 downto 0);
        -- current clk_z80 rate, whole MHz
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

    type pulse_action_t is (ACT_TOGGLE, ACT_FORCE_LOW, ACT_FORCE_HIGH);

    ------------------------------------------------------------------------
    -- ID FSM: the ONLY FSM which reads block IDs.  Once an ID is obtained,
    -- the corresponding block FSM owns the rest of that block completely.
    ------------------------------------------------------------------------
    type id_state_t is (ID_IDLE, ID_REQUEST, ID_WAIT, ID_DISPATCH);
    signal id_state      : id_state_t := ID_IDLE;
    signal current_id    : std_logic_vector(7 downto 0) := (others => '0');
    signal parser_run    : std_logic := '0';
    signal id_byte_req   : std_logic := '0';
    signal block_done    : std_logic := '0';
    signal b10_done,b11_done,b12_done,b13_done,b14_done,b15_done,b20_done,b21_done,b22_done,b23_done,b24_done,b25_done,b30_done,b32_done,b33_done,b35_done : std_logic := '0';

    ------------------------------------------------------------------------
    -- Shared DMA byte service.  Individual FSMs only assert *_byte_req for
    -- one clock and then wait for dma_done.  No parser state is involved in
    -- the DMA engine anymore.
    ------------------------------------------------------------------------
    type dma_state_type is (DMA_IDLE, DMA_WAIT_ACK, DMA_SET_ADDR,
                            DMA_WAIT, DMA_READ_BYTE, DMA_RELEASE);
    signal dma_state : dma_state_type := DMA_IDLE;
    signal dma_start  : std_logic := '0';
    signal dma_rewind : std_logic := '0';
    signal dma_seek   : std_logic := '0';
    signal dma_seek_addr : unsigned(19 downto 0) := (others => '0');
    signal dma_done   : std_logic := '0';
    signal dma_read_data : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_ptr : unsigned(19 downto 0) := (others => '0');
    signal wait_ctr : integer range 0 to 255 := 0;
    signal busack_sync1, busack_sync2 : std_logic := '1';

    signal id_dma_req, b10_dma_req, b11_dma_req, b12_dma_req,
           b13_dma_req, b14_dma_req, b15_dma_req, b20_dma_req,
           b21_dma_req, b23_dma_req, b24_dma_req, b30_dma_req,
           b32_dma_req, b33_dma_req, b35_dma_req : std_logic := '0';

    ------------------------------------------------------------------------
    -- Shared pulse service.  Block FSMs submit ONE pulse command and wait
    -- for pulse_done.  Pilot repetition is performed by the block FSM,
    -- while the actual CDC/tape pulse delivery is owned here.
    ------------------------------------------------------------------------
    type pulse_service_state_t is (PS_IDLE, PS_WAIT);
    signal pulse_service_state : pulse_service_state_t := PS_IDLE;
    signal pulse_req : std_logic := '0';
    signal pulse_done : std_logic := '0';
    signal pulse_duration_mux : unsigned(39 downto 0) := (others => '0');
    signal pulse_action_mux : pulse_action_t := ACT_TOGGLE;
    signal b10_pulse_req, b11_pulse_req, b12_pulse_req, b13_pulse_req,
           b14_pulse_req, b15_pulse_req, b20_pulse_req : std_logic := '0';
    signal b10_pulse_duration, b11_pulse_duration, b12_pulse_duration,
           b13_pulse_duration, b14_pulse_duration, b15_pulse_duration,
           b20_pulse_duration : unsigned(39 downto 0) := (others => '0');
    signal b10_pulse_action, b11_pulse_action, b12_pulse_action,
           b13_pulse_action, b14_pulse_action, b15_pulse_action,
           b20_pulse_action : pulse_action_t := ACT_TOGGLE;

    ------------------------------------------------------------------------
    -- Z80 real-time delivery / CDC handshake.
    ------------------------------------------------------------------------
    signal tape_started : std_logic := '0';
    signal tape_loaded  : std_logic := '0';
    signal tape_level   : std_logic := '0';
    signal tape_start_prev : std_logic := '0';
    type pb_state_t is (PB_WAIT, PB_RUN);
    signal pb_state : pb_state_t := PB_WAIT;
    signal pb_counter : unsigned(39 downto 0) := (others => '0');
    signal pb_action : pulse_action_t := ACT_TOGGLE;
    signal req_sync1, req_sync2, last_seen_req : std_logic := '0';
    signal pq_duration : unsigned(39 downto 0) := (others => '0');
    signal pq_action : pulse_action_t := ACT_TOGGLE;
    signal pq_req_toggle : std_logic := '0';
    signal pq_ack_toggle : std_logic := '0';
    signal ack_sync1, ack_sync2 : std_logic := '0';
    signal ts_sync1, ts_sync2, ts_prev : std_logic := '0';
    signal z80_clk_mhz_u : unsigned(7 downto 0);

    ------------------------------------------------------------------------
    -- $10 Standard Speed Data
    ------------------------------------------------------------------------
    type b10_state_t is (B10_ST_IDLE, B10_ST_PAUSE_LO_REQ, B10_ST_PAUSE_LO_WAIT,
        B10_ST_PAUSE_HI_REQ, B10_ST_PAUSE_HI_WAIT, B10_ST_LEN_LO_REQ, B10_ST_LEN_LO_WAIT,
        B10_ST_LEN_HI_REQ, B10_ST_LEN_HI_WAIT, B10_ST_FLAG_REQ, B10_ST_FLAG_WAIT,
        B10_ST_PILOT_START, B10_ST_PILOT_WAIT, B10_ST_SYNC1_START, B10_ST_SYNC1_WAIT,
        B10_ST_SYNC2_START, B10_ST_SYNC2_WAIT, B10_ST_FETCH, B10_ST_FETCH_WAIT,
        B10_ST_BIT_START, B10_ST_BIT_WAIT, B10_ST_PAUSE_START, B10_ST_PAUSE_WAIT, B10_ST_DONE);
    signal b10_state : b10_state_t := B10_ST_IDLE;
    signal b10_pause_ms : unsigned(15 downto 0) := (others=>'0');
    signal b10_data_bytes : unsigned(23 downto 0) := (others=>'0');
    signal b10_current_byte : std_logic_vector(7 downto 0) := (others=>'0');
    signal b10_pilot_count : unsigned(15 downto 0) := (others=>'0');
    signal b10_bit_index : integer range 0 to 7 := 7;
    signal b10_bit_phase : std_logic := '0';
    signal b10_last : std_logic := '0';
    signal b10_stop_idx : integer range 0 to 8 := 0;
    signal b10_tmp : std_logic_vector(7 downto 0) := (others=>'0');
    signal b10_preloaded : std_logic := '0';

    ------------------------------------------------------------------------
    -- $11 Turbo Speed Data -- all 18 header parameters are local to this FSM.
    ------------------------------------------------------------------------
    type b11_state_t is (
        B11_ST_IDLE,
        B11_ST_PILOT_LO_REQ, B11_ST_PILOT_LO_WAIT,
        B11_ST_PILOT_HI_REQ, B11_ST_PILOT_HI_WAIT,
        B11_ST_SYNC1_LO_REQ, B11_ST_SYNC1_LO_WAIT,
        B11_ST_SYNC1_HI_REQ, B11_ST_SYNC1_HI_WAIT,
        B11_ST_SYNC2_LO_REQ, B11_ST_SYNC2_LO_WAIT,
        B11_ST_SYNC2_HI_REQ, B11_ST_SYNC2_HI_WAIT,
        B11_ST_ZERO_LO_REQ, B11_ST_ZERO_LO_WAIT,
        B11_ST_ZERO_HI_REQ, B11_ST_ZERO_HI_WAIT,
        B11_ST_ONE_LO_REQ, B11_ST_ONE_LO_WAIT,
        B11_ST_ONE_HI_REQ, B11_ST_ONE_HI_WAIT,
        B11_ST_PILOTCNT_LO_REQ, B11_ST_PILOTCNT_LO_WAIT,
        B11_ST_PILOTCNT_HI_REQ, B11_ST_PILOTCNT_HI_WAIT,
        B11_ST_USEDBITS_REQ, B11_ST_USEDBITS_WAIT,
        B11_ST_PAUSE_LO_REQ, B11_ST_PAUSE_LO_WAIT,
        B11_ST_PAUSE_HI_REQ, B11_ST_PAUSE_HI_WAIT,
        B11_ST_LEN_LO_REQ, B11_ST_LEN_LO_WAIT,
        B11_ST_LEN_MID_REQ, B11_ST_LEN_MID_WAIT,
        B11_ST_LEN_HI_REQ, B11_ST_LEN_HI_WAIT,
        B11_ST_PILOT_START, B11_ST_PILOT_WAIT,
        B11_ST_SYNC1_START, B11_ST_SYNC1_WAIT,
        B11_ST_SYNC2_START, B11_ST_SYNC2_WAIT,
        B11_ST_FETCH, B11_ST_FETCH_WAIT,
        B11_ST_BIT_START, B11_ST_BIT_WAIT,
        B11_ST_PAUSE_START, B11_ST_PAUSE_WAIT, B11_ST_DONE);
    signal b11_state : b11_state_t := B11_ST_IDLE;
    signal b11_pilot_len, b11_sync1_len, b11_sync2_len,
           b11_zero_len, b11_one_len : unsigned(15 downto 0) := (others=>'0');
    signal b11_pilot_count : unsigned(15 downto 0) := (others=>'0');
    signal b11_used_bits : unsigned(3 downto 0) := to_unsigned(8,4);
    signal b11_pause_ms : unsigned(15 downto 0) := (others=>'0');
    signal b11_data_bytes : unsigned(23 downto 0) := (others=>'0');
    signal b11_tmp0, b11_tmp1 : std_logic_vector(7 downto 0) := (others=>'0');
    signal b11_current_byte : std_logic_vector(7 downto 0) := (others=>'0');
    signal b11_bit_index : integer range 0 to 7 := 7;
    signal b11_bit_phase : std_logic := '0';
    signal b11_last : std_logic := '0';
    signal b11_stop_idx : integer range 0 to 8 := 0;

    ------------------------------------------------------------------------
    -- $12 Pure Tone
    ------------------------------------------------------------------------
    type b12_state_t is (B12_ST_IDLE, B12_ST_LEN_LO_REQ, B12_ST_LEN_LO_WAIT,
        B12_ST_LEN_HI_REQ, B12_ST_LEN_HI_WAIT, B12_ST_COUNT_LO_REQ, B12_ST_COUNT_LO_WAIT,
        B12_ST_COUNT_HI_REQ, B12_ST_COUNT_HI_WAIT, B12_ST_PULSE_START, B12_ST_PULSE_WAIT, B12_ST_DONE);
    signal b12_state : b12_state_t := B12_ST_IDLE;
    signal b12_len, b12_count : unsigned(15 downto 0) := (others=>'0');
    signal b12_tmp : std_logic_vector(7 downto 0) := (others=>'0');

    ------------------------------------------------------------------------
    -- $13 Sequence of Pulses
    ------------------------------------------------------------------------
    type b13_state_t is (B13_ST_IDLE, B13_ST_COUNT_REQ, B13_ST_COUNT_WAIT, B13_ST_LEN_LO_REQ,
        B13_ST_LEN_LO_WAIT, B13_ST_LEN_HI_REQ, B13_ST_LEN_HI_WAIT, B13_ST_PULSE_START,
        B13_ST_PULSE_WAIT, B13_ST_DONE);
    signal b13_state : b13_state_t := B13_ST_IDLE;
    signal b13_count : unsigned(7 downto 0) := (others=>'0');
    signal b13_len : unsigned(15 downto 0) := (others=>'0');
    signal b13_tmp : std_logic_vector(7 downto 0) := (others=>'0');

    ------------------------------------------------------------------------
    -- $14 Pure Data
    ------------------------------------------------------------------------
    type b14_state_t is (B14_ST_IDLE, B14_ST_ZERO_LO_REQ, B14_ST_ZERO_LO_WAIT,
        B14_ST_ZERO_HI_REQ, B14_ST_ZERO_HI_WAIT, B14_ST_ONE_LO_REQ, B14_ST_ONE_LO_WAIT,
        B14_ST_ONE_HI_REQ, B14_ST_ONE_HI_WAIT, B14_ST_USEDBITS_REQ, B14_ST_USEDBITS_WAIT,
        B14_ST_PAUSE_LO_REQ, B14_ST_PAUSE_LO_WAIT, B14_ST_PAUSE_HI_REQ, B14_ST_PAUSE_HI_WAIT,
        B14_ST_LEN_LO_REQ, B14_ST_LEN_LO_WAIT, B14_ST_LEN_MID_REQ, B14_ST_LEN_MID_WAIT,
        B14_ST_LEN_HI_REQ, B14_ST_LEN_HI_WAIT, B14_ST_FETCH, B14_ST_FETCH_WAIT,
        B14_ST_BIT_START, B14_ST_BIT_WAIT, B14_ST_PAUSE_START, B14_ST_PAUSE_WAIT, B14_ST_DONE);
    signal b14_state : b14_state_t := B14_ST_IDLE;
    signal b14_zero_len, b14_one_len : unsigned(15 downto 0) := (others=>'0');
    signal b14_used_bits : unsigned(3 downto 0) := to_unsigned(8,4);
    signal b14_pause_ms : unsigned(15 downto 0) := (others=>'0');
    signal b14_data_bytes : unsigned(23 downto 0) := (others=>'0');
    signal b14_tmp0, b14_tmp1 : std_logic_vector(7 downto 0) := (others=>'0');
    signal b14_current_byte : std_logic_vector(7 downto 0) := (others=>'0');
    signal b14_bit_index : integer range 0 to 7 := 7;
    signal b14_bit_phase : std_logic := '0';
    signal b14_last : std_logic := '0';
    signal b14_stop_idx : integer range 0 to 8 := 0;

    ------------------------------------------------------------------------
    -- $15 Direct Recording
    ------------------------------------------------------------------------
    type b15_state_t is (B15_ST_IDLE, B15_ST_PERIOD_LO_REQ, B15_ST_PERIOD_LO_WAIT,
        B15_ST_PERIOD_HI_REQ, B15_ST_PERIOD_HI_WAIT, B15_ST_PAUSE_LO_REQ, B15_ST_PAUSE_LO_WAIT,
        B15_ST_PAUSE_HI_REQ, B15_ST_PAUSE_HI_WAIT, B15_ST_USEDBITS_REQ, B15_ST_USEDBITS_WAIT,
        B15_ST_LEN_LO_REQ, B15_ST_LEN_LO_WAIT, B15_ST_LEN_MID_REQ, B15_ST_LEN_MID_WAIT,
        B15_ST_LEN_HI_REQ, B15_ST_LEN_HI_WAIT, B15_ST_FETCH, B15_ST_FETCH_WAIT,
        B15_ST_SAMPLE_START, B15_ST_SAMPLE_WAIT, B15_ST_PAUSE_START, B15_ST_PAUSE_WAIT, B15_ST_DONE);
    signal b15_state : b15_state_t := B15_ST_IDLE;
    signal b15_period, b15_pause_ms : unsigned(15 downto 0) := (others=>'0');
    signal b15_used_bits : unsigned(3 downto 0) := to_unsigned(8,4);
    signal b15_data_bytes : unsigned(23 downto 0) := (others=>'0');
    signal b15_tmp0, b15_tmp1 : std_logic_vector(7 downto 0) := (others=>'0');
    signal b15_current_byte : std_logic_vector(7 downto 0) := (others=>'0');
    signal b15_bit_index : integer range 0 to 7 := 7;
    signal b15_last : std_logic := '0';
    signal b15_stop_idx : integer range 0 to 8 := 0;

    ------------------------------------------------------------------------
    -- Simple/administrative block FSMs
    ------------------------------------------------------------------------
    type b20_state_t is (B20_ST_IDLE,B20_ST_LO_REQ,B20_ST_LO_WAIT,B20_ST_HI_REQ,B20_ST_HI_WAIT,
                         B20_ST_DECIDE,B20_ST_PULSE_START,B20_ST_PULSE_WAIT,B20_ST_DONE);
    signal b20_state:b20_state_t:=B20_ST_IDLE;
    signal b20_pause:unsigned(15 downto 0):=(others=>'0');
    signal b20_tmp:std_logic_vector(7 downto 0):=(others=>'0');
    type b21_state_t is (B21_ST_IDLE,B21_ST_LEN_REQ,B21_ST_LEN_WAIT,B21_ST_SKIP,B21_ST_SKIP_WAIT,B21_ST_DONE);
    signal b21_state:b21_state_t:=B21_ST_IDLE;
    signal b21_skip:unsigned(31 downto 0):=(others=>'0');
    type b22_state_t is (B22_ST_IDLE,B22_ST_DONE);
    signal b22_state:b22_state_t:=B22_ST_IDLE;
    type b23_state_t is (B23_ST_IDLE,B23_ST_LO_REQ,B23_ST_LO_WAIT,B23_ST_HI_REQ,B23_ST_HI_WAIT,B23_ST_DONE);
    signal b23_state:b23_state_t:=B23_ST_IDLE;
    signal b23_tmp:std_logic_vector(7 downto 0):=(others=>'0');
    type b24_state_t is (B24_ST_IDLE,B24_ST_LO_REQ,B24_ST_LO_WAIT,B24_ST_HI_REQ,B24_ST_HI_WAIT,B24_ST_DONE);
    signal b24_state:b24_state_t:=B24_ST_IDLE;
    signal b24_tmp:std_logic_vector(7 downto 0):=(others=>'0');
    type b25_state_t is (B25_ST_IDLE,B25_ST_DECIDE,B25_ST_SEEK_WAIT,B25_ST_DONE);
    signal b25_state:b25_state_t:=B25_ST_IDLE;
    type b30_state_t is (B30_ST_IDLE,B30_ST_LEN_REQ,B30_ST_LEN_WAIT,B30_ST_SKIP,B30_ST_SKIP_WAIT,B30_ST_DONE);
    signal b30_state:b30_state_t:=B30_ST_IDLE;
    signal b30_skip:unsigned(31 downto 0):=(others=>'0');
    type b32_state_t is (B32_ST_IDLE,B32_ST_LO_REQ,B32_ST_LO_WAIT,B32_ST_HI_REQ,B32_ST_HI_WAIT,B32_ST_SKIP,B32_ST_SKIP_WAIT,B32_ST_DONE);
    signal b32_state:b32_state_t:=B32_ST_IDLE;
    signal b32_skip:unsigned(31 downto 0):=(others=>'0');
    signal b32_tmp:std_logic_vector(7 downto 0):=(others=>'0');
    type b33_state_t is (B33_ST_IDLE,B33_ST_COUNT_REQ,B33_ST_COUNT_WAIT,B33_ST_SKIP,B33_ST_SKIP_WAIT,B33_ST_DONE);
    signal b33_state:b33_state_t:=B33_ST_IDLE;
    signal b33_skip:unsigned(31 downto 0):=(others=>'0');
    type b35_state_t is (B35_ST_IDLE,B35_ST_SKIP_ID,B35_ST_SKIP_ID_REQ,B35_ST_SKIP_ID_WAIT,B35_ST_LEN0_REQ,B35_ST_LEN0_WAIT,B35_ST_LEN1_REQ,B35_ST_LEN1_WAIT,B35_ST_LEN2_REQ,B35_ST_LEN2_WAIT,B35_ST_LEN3_REQ,B35_ST_LEN3_WAIT,B35_ST_SKIP,B35_ST_SKIP_WAIT,B35_ST_DONE);
    signal b35_state:b35_state_t:=B35_ST_IDLE;
    signal b35_skip:unsigned(31 downto 0):=(others=>'0');
    signal b35_tmp0,b35_tmp1,b35_tmp2:std_logic_vector(7 downto 0):=(others=>'0');

    signal loop_start_addr : unsigned(19 downto 0) := (others=>'0');
    signal loop_count : unsigned(15 downto 0) := (others=>'0');
    signal b24_loop_load_req : std_logic := '0';
    signal b24_loop_count : unsigned(15 downto 0) := (others=>'0');
    signal b24_loop_addr : unsigned(19 downto 0) := (others=>'0');
    signal b25_seek_req : std_logic := '0';
    signal b25_seek_addr : unsigned(19 downto 0) := (others=>'0');
    signal b20_stop_req : std_logic := '0';

    function scale_pulse_rt(v : unsigned(15 downto 0);
    freq_mhz : unsigned(7 downto 0)) return unsigned is
        constant C_2 : unsigned(1 downto 0):=to_unsigned(2,2);
        constant C_7:unsigned(3 downto 0):=to_unsigned(7,4);
        variable step1:unsigned(23 downto 0);
        variable step2:unsigned(25 downto 0);
    begin step1:=v*freq_mhz;
    step2:=step1*C_2;
    return resize(step2/C_7,40);
    end function;

    function pause_cycles_rt(ms : unsigned(15 downto 0);
    freq_mhz : unsigned(7 downto 0)) return unsigned is
        constant C_1000:unsigned(9 downto 0):=to_unsigned(1000,10);
        variable step1:unsigned(23 downto 0);
        variable step2:unsigned(33 downto 0);
    begin step1:=ms*freq_mhz;
    step2:=step1*C_1000;
    return resize(step2,40);
    end function;

begin
    z80_clk_mhz_u <= unsigned(z80_clk_mhz);
    tape_started <= tape_ctrl(4);
    tape_loaded <= tape_ctrl(0);

    process(tape_started,tape_level)
    begin
        if tape_started='1' then
            if G_TAPE_ACTIVE_HIGH then tape_bit_out<=tape_level;
            else tape_bit_out<=not tape_level;
            end if;
        else tape_bit_out<='0';
        end if;
    end process;

    ------------------------------------------------------------------------
    -- Z80 pulse delivery: unchanged real-time semantics.
    ------------------------------------------------------------------------
    process(clk_z80,reset)
    begin
        if reset='1' then
            pb_state<=PB_WAIT;
            pb_counter<=(others=>'0');
            pb_action<=ACT_TOGGLE;
            tape_level<='0';
            tape_start_prev<='0';
            pq_ack_toggle<='0';
            req_sync1<='0';
            req_sync2<='0';
            last_seen_req<='0';
        elsif rising_edge(clk_z80) then
            req_sync1<=pq_req_toggle;
            req_sync2<=req_sync1;
            tape_start_prev<=tape_started;
            if tape_started='0' then
                if req_sync2/=last_seen_req then last_seen_req<=req_sync2;
                pq_ack_toggle<=not pq_ack_toggle;
                end if;
                pb_state<=PB_WAIT;
                pb_counter<=(others=>'0');
                tape_level<='0';
            elsif tape_start_prev='0' then
                pb_state<=PB_WAIT;
                pb_counter<=(others=>'0');
                tape_level<='0';
                last_seen_req<=req_sync2;
            else
                case pb_state is
                    when PB_WAIT =>
                        if req_sync2/=last_seen_req then
                            last_seen_req<=req_sync2;
                            pq_ack_toggle<=not pq_ack_toggle;
                            case pq_action is
                                when ACT_TOGGLE=>tape_level<=not tape_level;
                                when ACT_FORCE_LOW=>tape_level<='0';
                                when ACT_FORCE_HIGH=>tape_level<='1';
                            end case;
                            if pq_duration>1 then pb_counter<=pq_duration-1;
                            pb_state<=PB_RUN;
                            else pb_state<=PB_WAIT;
                            end if;
                        end if;
                    when PB_RUN => if pb_counter>1 then pb_counter<=pb_counter-1;
                    else pb_state<=PB_WAIT;
                    end if;
                end case;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- DMA request mux. Only the active FSM can request a byte.
    ------------------------------------------------------------------------
    dma_start <= id_dma_req or b10_dma_req or b11_dma_req or b12_dma_req or b13_dma_req or
                 b14_dma_req or b15_dma_req or b20_dma_req or b21_dma_req or b23_dma_req or
                 b24_dma_req or b30_dma_req or b32_dma_req or b33_dma_req or b35_dma_req;

    process(clk_fpga,reset)
    begin
        if reset='1' then
            dma_state<=DMA_IDLE;
            z80_busreq_n<='1';
            sram_oe_n<='1';
            sram_addr<=(others=>'0');
            dma_done<='0';
            dma_read_data<=(others=>'0');
            ram_ptr<=unsigned(G_CDT_BASE_ADDR)+10;
            wait_ctr<=0;
            busack_sync1<='1';
            busack_sync2<='1';
        elsif rising_edge(clk_fpga) then
            dma_done<='0';
            busack_sync1<=z80_busack_n;
            busack_sync2<=busack_sync1;
            case dma_state is
                when DMA_IDLE =>
                    sram_oe_n<='1';
                    if dma_rewind='1' then ram_ptr<=unsigned(G_CDT_BASE_ADDR)+10;
                    elsif dma_seek='1' then ram_ptr<=dma_seek_addr;
                    elsif dma_start='1' then z80_busreq_n<='0';
                    dma_state<=DMA_WAIT_ACK;
                    end if;
                when DMA_WAIT_ACK => if busack_sync2='0' then sram_addr<=std_logic_vector(ram_ptr);
                dma_state<=DMA_SET_ADDR;
                end if;
                when DMA_SET_ADDR => sram_oe_n<='0';
                wait_ctr<=G_SRAM_WAIT_CYCLES;
                dma_state<=DMA_WAIT;
                when DMA_WAIT => if wait_ctr=0 then dma_state<=DMA_READ_BYTE;
                else wait_ctr<=wait_ctr-1;
                end if;
                when DMA_READ_BYTE => dma_read_data<=sram_data;
                sram_oe_n<='1';
                ram_ptr<=ram_ptr+1;
                dma_state<=DMA_RELEASE;
                when DMA_RELEASE => z80_busreq_n<='1';
                dma_done<='1';
                dma_state<=DMA_IDLE;
            end case;
        end if;
    end process;

    block_done <= b10_done or b11_done or b12_done or b13_done or b14_done or b15_done or
                   b20_done or b21_done or b22_done or b23_done or b24_done or b25_done or b30_done or
                   b32_done or b33_done or b35_done;
    dma_seek <= b25_seek_req;
    dma_seek_addr <= b25_seek_addr;

    ------------------------------------------------------------------------
    -- Tape/load control and ID FSM.
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
        if reset='1' then
            id_state<=ID_IDLE;
            current_id<=(others=>'0');
            parser_run<='0';
            id_byte_req<='0';
            dma_rewind<='0';
            ack_sync1<='0';
            ack_sync2<='0';
            ts_sync1<='0';
            ts_sync2<='0';
            ts_prev<='0';
        elsif rising_edge(clk_fpga) then
            id_byte_req<='0';
            dma_rewind<='0';
            ack_sync1<=pq_ack_toggle;
            ack_sync2<=ack_sync1;
            ts_sync1<=tape_started;
            ts_sync2<=ts_sync1;
            if tape_loaded='0' then dma_rewind<='1';
            end if;
            if b20_stop_req='1' then parser_run<='0';
            id_state<=ID_IDLE;
            end if;
            if ts_sync2='1' and ts_prev='0' then
                parser_run<='1';
                id_state<=ID_REQUEST;
            elsif ts_sync2='0' and ts_prev='1' then
                parser_run<='0';
                id_state<=ID_IDLE;
            elsif parser_run='1' then
                case id_state is
                    when ID_IDLE => null;
                    when ID_REQUEST => id_byte_req<='1';
                    id_state<=ID_WAIT;
                    when ID_WAIT => if dma_done='1' then
                            current_id<=dma_read_data;
                            case dma_read_data is
                                when x"10"|x"11"|x"12"|x"13"|x"14"|x"15"|x"20"|x"21"|x"22"|x"23"|x"24"|x"25"|x"30"|x"32"|x"33"|x"35" => id_state<=ID_DISPATCH;
                                when others => parser_run<='0';
                                id_state<=ID_IDLE;
                            end case;
                        end if;
                    when ID_DISPATCH =>
                        if block_done='1' then id_state<=ID_REQUEST;
                        else id_state<=ID_DISPATCH;
                        end if;
                end case;
            end if;
            ts_prev<=ts_sync2;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- Pulse service FSM. This is the sole owner of PARSE_EMIT_START/
    -- PARSE_EMIT_WAIT functionality.
    ------------------------------------------------------------------------
    pulse_req <= b10_pulse_req or b11_pulse_req or b12_pulse_req or b13_pulse_req or
                 b14_pulse_req or b15_pulse_req or b20_pulse_req;
    process(current_id, b10_pulse_req, b11_pulse_req, b12_pulse_req, b13_pulse_req, b14_pulse_req, b15_pulse_req, b20_pulse_req,
            b10_pulse_duration, b11_pulse_duration, b12_pulse_duration, b13_pulse_duration,
            b14_pulse_duration, b15_pulse_duration, b20_pulse_duration,
            b10_pulse_action, b11_pulse_action, b12_pulse_action, b13_pulse_action,
            b14_pulse_action, b15_pulse_action, b20_pulse_action)
    begin
        pulse_duration_mux<=(others=>'0');
        pulse_action_mux<=ACT_TOGGLE;
        case current_id is
            when x"10"=>pulse_duration_mux<=b10_pulse_duration;
            pulse_action_mux<=b10_pulse_action;
            when x"11"=>pulse_duration_mux<=b11_pulse_duration;
            pulse_action_mux<=b11_pulse_action;
            when x"12"=>pulse_duration_mux<=b12_pulse_duration;
            pulse_action_mux<=b12_pulse_action;
            when x"13"=>pulse_duration_mux<=b13_pulse_duration;
            pulse_action_mux<=b13_pulse_action;
            when x"14"=>pulse_duration_mux<=b14_pulse_duration;
            pulse_action_mux<=b14_pulse_action;
            when x"15"=>pulse_duration_mux<=b15_pulse_duration;
            pulse_action_mux<=b15_pulse_action;
            when x"20"=>pulse_duration_mux<=b20_pulse_duration;
            pulse_action_mux<=b20_pulse_action;
            when others=>null;
        end case;
    end process;

    process(clk_fpga,reset)
    begin
        if reset='1' then pulse_service_state<=PS_IDLE;
        pulse_done<='0';
        pq_duration<=(others=>'0');
        pq_action<=ACT_TOGGLE;
        pq_req_toggle<='0';
        elsif rising_edge(clk_fpga) then
            pulse_done<='0';
            case pulse_service_state is
                when PS_IDLE =>
                    if pulse_req='1' then
                        pq_duration<=pulse_duration_mux;
                        pq_action<=pulse_action_mux;
                        pq_req_toggle<=not pq_req_toggle;
                        pulse_service_state<=PS_WAIT;
                    end if;
                when PS_WAIT =>
                    if ack_sync2=pq_req_toggle then pulse_done<='1';
                    pulse_service_state<=PS_IDLE;
                    end if;
            end case;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- $11 TURBO BLOCK FSM
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
        if reset='1' then
            b11_state<=B11_ST_IDLE;
            b11_pilot_len<=(others=>'0');
            b11_sync1_len<=(others=>'0');
            b11_sync2_len<=(others=>'0');
            b11_zero_len<=(others=>'0');
            b11_one_len<=(others=>'0');
            b11_pilot_count<=(others=>'0');
            b11_used_bits<=to_unsigned(8,4);
            b11_pause_ms<=(others=>'0');
            b11_data_bytes<=(others=>'0');
            b11_tmp0<=(others=>'0');
            b11_tmp1<=(others=>'0');
            b11_current_byte<=(others=>'0');
            b11_bit_index<=7;
            b11_bit_phase<='0';
            b11_last<='0';
            b11_stop_idx<=0;
            b11_dma_req<='0';
            b11_pulse_req<='0';
            b11_pulse_duration<=(others=>'0');
            b11_pulse_action<=ACT_TOGGLE;
        elsif rising_edge(clk_fpga) then
            b11_done<='0';
            b11_dma_req<='0';
            b11_pulse_req<='0';
            if parser_run='0' then b11_state<=B11_ST_IDLE;
            else
                case b11_state is
                    when B11_ST_IDLE => if current_id=x"11" then b11_state<=B11_ST_PILOT_LO_REQ;
                    end if;
                    when B11_ST_PILOT_LO_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_PILOT_LO_WAIT;
                    when B11_ST_PILOT_LO_WAIT => if dma_done='1' then b11_tmp0<=dma_read_data;
                    b11_state<=B11_ST_PILOT_HI_REQ;
                    end if;
                    when B11_ST_PILOT_HI_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_PILOT_HI_WAIT;
                    when B11_ST_PILOT_HI_WAIT => if dma_done='1' then b11_pilot_len<=unsigned(dma_read_data&b11_tmp0);
                    b11_state<=B11_ST_SYNC1_LO_REQ;
                    end if;
                    when B11_ST_SYNC1_LO_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_SYNC1_LO_WAIT;
                    when B11_ST_SYNC1_LO_WAIT => if dma_done='1' then b11_tmp0<=dma_read_data;
                    b11_state<=B11_ST_SYNC1_HI_REQ;
                    end if;
                    when B11_ST_SYNC1_HI_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_SYNC1_HI_WAIT;
                    when B11_ST_SYNC1_HI_WAIT => if dma_done='1' then b11_sync1_len<=unsigned(dma_read_data&b11_tmp0);
                    b11_state<=B11_ST_SYNC2_LO_REQ;
                    end if;
                    when B11_ST_SYNC2_LO_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_SYNC2_LO_WAIT;
                    when B11_ST_SYNC2_LO_WAIT => if dma_done='1' then b11_tmp0<=dma_read_data;
                    b11_state<=B11_ST_SYNC2_HI_REQ;
                    end if;
                    when B11_ST_SYNC2_HI_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_SYNC2_HI_WAIT;
                    when B11_ST_SYNC2_HI_WAIT => if dma_done='1' then b11_sync2_len<=unsigned(dma_read_data&b11_tmp0);
                    b11_state<=B11_ST_ZERO_LO_REQ;
                    end if;
                    when B11_ST_ZERO_LO_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_ZERO_LO_WAIT;
                    when B11_ST_ZERO_LO_WAIT => if dma_done='1' then b11_tmp0<=dma_read_data;
                    b11_state<=B11_ST_ZERO_HI_REQ;
                    end if;
                    when B11_ST_ZERO_HI_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_ZERO_HI_WAIT;
                    when B11_ST_ZERO_HI_WAIT => if dma_done='1' then b11_zero_len<=unsigned(dma_read_data&b11_tmp0);
                    b11_state<=B11_ST_ONE_LO_REQ;
                    end if;
                    when B11_ST_ONE_LO_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_ONE_LO_WAIT;
                    when B11_ST_ONE_LO_WAIT => if dma_done='1' then b11_tmp0<=dma_read_data;
                    b11_state<=B11_ST_ONE_HI_REQ;
                    end if;
                    when B11_ST_ONE_HI_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_ONE_HI_WAIT;
                    when B11_ST_ONE_HI_WAIT => if dma_done='1' then b11_one_len<=unsigned(dma_read_data&b11_tmp0);
                    b11_state<=B11_ST_PILOTCNT_LO_REQ;
                    end if;
                    when B11_ST_PILOTCNT_LO_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_PILOTCNT_LO_WAIT;
                    when B11_ST_PILOTCNT_LO_WAIT => if dma_done='1' then b11_tmp0<=dma_read_data;
                    b11_state<=B11_ST_PILOTCNT_HI_REQ;
                    end if;
                    when B11_ST_PILOTCNT_HI_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_PILOTCNT_HI_WAIT;
                    when B11_ST_PILOTCNT_HI_WAIT => if dma_done='1' then b11_pilot_count<=unsigned(dma_read_data&b11_tmp0);
                    b11_state<=B11_ST_USEDBITS_REQ;
                    end if;
                    when B11_ST_USEDBITS_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_USEDBITS_WAIT;
                    when B11_ST_USEDBITS_WAIT => if dma_done='1' then b11_used_bits<=unsigned(dma_read_data(3 downto 0));
                    b11_state<=B11_ST_PAUSE_LO_REQ;
                    end if;
                    when B11_ST_PAUSE_LO_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_PAUSE_LO_WAIT;
                    when B11_ST_PAUSE_LO_WAIT => if dma_done='1' then b11_tmp0<=dma_read_data;
                    b11_state<=B11_ST_PAUSE_HI_REQ;
                    end if;
                    when B11_ST_PAUSE_HI_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_PAUSE_HI_WAIT;
                    when B11_ST_PAUSE_HI_WAIT => if dma_done='1' then b11_pause_ms<=unsigned(dma_read_data&b11_tmp0);
                    b11_state<=B11_ST_LEN_LO_REQ;
                    end if;
                    when B11_ST_LEN_LO_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_LEN_LO_WAIT;
                    when B11_ST_LEN_LO_WAIT => if dma_done='1' then b11_tmp0<=dma_read_data;
                    b11_state<=B11_ST_LEN_MID_REQ;
                    end if;
                    when B11_ST_LEN_MID_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_LEN_MID_WAIT;
                    when B11_ST_LEN_MID_WAIT => if dma_done='1' then b11_tmp1<=dma_read_data;
                    b11_state<=B11_ST_LEN_HI_REQ;
                    end if;
                    when B11_ST_LEN_HI_REQ => b11_dma_req<='1';
                    b11_state<=B11_ST_LEN_HI_WAIT;
                    when B11_ST_LEN_HI_WAIT => if dma_done='1' then
                        b11_data_bytes<=unsigned(dma_read_data&b11_tmp1&b11_tmp0);
                        b11_bit_index<=7;
                        b11_bit_phase<='0';
                        b11_state<=B11_ST_PILOT_START;
                    end if;
                    when B11_ST_PILOT_START =>
                        if b11_pilot_count=0 then b11_state<=B11_ST_SYNC1_START;
                        else b11_pulse_duration<=scale_pulse_rt(b11_pilot_len,z80_clk_mhz_u);
                        b11_pulse_action<=ACT_TOGGLE;
                        b11_pulse_req<='1';
                        b11_state<=B11_ST_PILOT_WAIT;
                        end if;
                    when B11_ST_PILOT_WAIT => if pulse_done='1' then b11_pilot_count<=b11_pilot_count-1;
                    b11_state<=B11_ST_PILOT_START;
                    end if;
                    when B11_ST_SYNC1_START => b11_pulse_duration<=scale_pulse_rt(b11_sync1_len,z80_clk_mhz_u);
                    b11_pulse_action<=ACT_TOGGLE;
                    b11_pulse_req<='1';
                    b11_state<=B11_ST_SYNC1_WAIT;
                    when B11_ST_SYNC1_WAIT => if pulse_done='1' then b11_state<=B11_ST_SYNC2_START;
                    end if;
                    when B11_ST_SYNC2_START => b11_pulse_duration<=scale_pulse_rt(b11_sync2_len,z80_clk_mhz_u);
                    b11_pulse_action<=ACT_TOGGLE;
                    b11_pulse_req<='1';
                    b11_state<=B11_ST_SYNC2_WAIT;
                    when B11_ST_SYNC2_WAIT => if pulse_done='1' then b11_state<=B11_ST_FETCH;
                    end if;
                    when B11_ST_FETCH =>
                        if b11_data_bytes=0 then if b11_pause_ms>0 then b11_state<=B11_ST_PAUSE_START;
                        else b11_state<=B11_ST_DONE;
                        end if;
                        else b11_dma_req<='1';
                        b11_state<=B11_ST_FETCH_WAIT;
                        end if;
                    when B11_ST_FETCH_WAIT => if dma_done='1' then
                        b11_current_byte<=dma_read_data;
                        b11_bit_index<=7;
                        b11_bit_phase<='0';
                        if b11_data_bytes=1 then b11_last<='1';
                        b11_stop_idx<=8-to_integer(b11_used_bits);
                        else b11_last<='0';
                        end if;
                        b11_state<=B11_ST_BIT_START;
                        end if;
                    when B11_ST_BIT_START =>
                        if b11_current_byte(b11_bit_index)='1' then b11_pulse_duration<=scale_pulse_rt(b11_one_len,z80_clk_mhz_u);
                        else b11_pulse_duration<=scale_pulse_rt(b11_zero_len,z80_clk_mhz_u);
                        end if;
                        b11_pulse_action<=ACT_TOGGLE;
                        b11_pulse_req<='1';
                        b11_state<=B11_ST_BIT_WAIT;
                    when B11_ST_BIT_WAIT => if pulse_done='1' then
                        if b11_bit_phase='0' then b11_bit_phase<='1';
                        b11_state<=B11_ST_BIT_START;
                        elsif b11_bit_index>0 and not(b11_last='1' and b11_bit_index=b11_stop_idx) then b11_bit_phase<='0';
                        b11_bit_index<=b11_bit_index-1;
                        b11_state<=B11_ST_BIT_START;
                        else b11_bit_phase<='0';
                        b11_data_bytes<=b11_data_bytes-1;
                        b11_state<=B11_ST_FETCH;
                        end if;
                    end if;
                    when B11_ST_PAUSE_START => b11_pulse_duration<=pause_cycles_rt(b11_pause_ms,z80_clk_mhz_u);
                    b11_pulse_action<=ACT_FORCE_LOW;
                    b11_pulse_req<='1';
                    b11_state<=B11_ST_PAUSE_WAIT;
                    when B11_ST_PAUSE_WAIT => if pulse_done='1' then b11_state<=B11_ST_DONE;
                    end if;
                    when B11_ST_DONE => b11_done<='1';
                    b11_state<=B11_ST_IDLE;
                    when others=>b11_state<=B11_ST_IDLE;
                end case;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- $10, $12-$15 and administrative FSMs. Each is deliberately isolated.
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
        if reset='1' then b10_done<='0';
        b10_state<=B10_ST_IDLE;
        b10_pause_ms<=(others=>'0');
        b10_data_bytes<=(others=>'0');
        b10_current_byte<=(others=>'0');
        b10_pilot_count<=(others=>'0');
        b10_bit_index<=7;
        b10_bit_phase<='0';
        b10_last<='0';
        b10_stop_idx<=0;
        b10_tmp<=(others=>'0');
        b10_preloaded<='0';
        b10_dma_req<='0';
        b10_pulse_req<='0';
        b10_pulse_duration<=(others=>'0');
        b10_pulse_action<=ACT_TOGGLE;
        elsif rising_edge(clk_fpga) then
            b10_done<='0';
            b10_dma_req<='0';
            b10_pulse_req<='0';
            if parser_run='0' then b10_state<=B10_ST_IDLE;
            elsif current_id/=x"10" then b10_state<=B10_ST_IDLE;
            else case b10_state is
                when B10_ST_IDLE=>b10_state<=B10_ST_PAUSE_LO_REQ;
                when B10_ST_PAUSE_LO_REQ=>b10_dma_req<='1';
                b10_state<=B10_ST_PAUSE_LO_WAIT;
                when B10_ST_PAUSE_LO_WAIT=>if dma_done='1' then b10_tmp<=dma_read_data;
                b10_state<=B10_ST_PAUSE_HI_REQ;
                end if;
                when B10_ST_PAUSE_HI_REQ=>b10_dma_req<='1';
                b10_state<=B10_ST_PAUSE_HI_WAIT;
                when B10_ST_PAUSE_HI_WAIT=>if dma_done='1' then b10_pause_ms<=unsigned(dma_read_data&b10_tmp);
                b10_state<=B10_ST_LEN_LO_REQ;
                end if;
                when B10_ST_LEN_LO_REQ=>b10_dma_req<='1';
                b10_state<=B10_ST_LEN_LO_WAIT;
                when B10_ST_LEN_LO_WAIT=>if dma_done='1' then b10_tmp<=dma_read_data;
                b10_state<=B10_ST_LEN_HI_REQ;
                end if;
                when B10_ST_LEN_HI_REQ=>b10_dma_req<='1';
                b10_state<=B10_ST_LEN_HI_WAIT;
                when B10_ST_LEN_HI_WAIT=>if dma_done='1' then b10_data_bytes<=resize(unsigned(dma_read_data&b10_tmp),24);
                b10_state<=B10_ST_FLAG_REQ;
                end if;
                when B10_ST_FLAG_REQ=>b10_dma_req<='1';
                b10_state<=B10_ST_FLAG_WAIT;
                when B10_ST_FLAG_WAIT=>if dma_done='1' then b10_current_byte<=dma_read_data;
                b10_preloaded<='1';
                if unsigned(dma_read_data)<128 then b10_pilot_count<=to_unsigned(8063,16);
                else b10_pilot_count<=to_unsigned(3223,16);
                end if;
                b10_state<=B10_ST_PILOT_START;
                end if;
                when B10_ST_PILOT_START=>if b10_pilot_count=0 then b10_state<=B10_ST_SYNC1_START;
                else b10_pulse_duration<=scale_pulse_rt(to_unsigned(2168,16),z80_clk_mhz_u);
                b10_pulse_action<=ACT_TOGGLE;
                b10_pulse_req<='1';
                b10_state<=B10_ST_PILOT_WAIT;
                end if;
                when B10_ST_PILOT_WAIT=>if pulse_done='1' then b10_pilot_count<=b10_pilot_count-1;
                b10_state<=B10_ST_PILOT_START;
                end if;
                when B10_ST_SYNC1_START=>b10_pulse_duration<=scale_pulse_rt(to_unsigned(667,16),z80_clk_mhz_u);
                b10_pulse_action<=ACT_TOGGLE;
                b10_pulse_req<='1';
                b10_state<=B10_ST_SYNC1_WAIT;
                when B10_ST_SYNC1_WAIT=>if pulse_done='1' then b10_state<=B10_ST_SYNC2_START;
                end if;
                when B10_ST_SYNC2_START=>b10_pulse_duration<=scale_pulse_rt(to_unsigned(735,16),z80_clk_mhz_u);
                b10_pulse_action<=ACT_TOGGLE;
                b10_pulse_req<='1';
                b10_state<=B10_ST_SYNC2_WAIT;
                when B10_ST_SYNC2_WAIT=>if pulse_done='1' then b10_state<=B10_ST_FETCH;
                end if;
                when B10_ST_FETCH=>if b10_data_bytes=0 then if b10_pause_ms>0 then b10_state<=B10_ST_PAUSE_START;
                else b10_state<=B10_ST_DONE;
                end if;
                elsif b10_preloaded='1' then b10_preloaded<='0';
                b10_bit_index<=7;
                b10_bit_phase<='0';
                if b10_data_bytes=1 then b10_last<='1';
                b10_stop_idx<=0;
                else b10_last<='0';
                end if;
                b10_state<=B10_ST_BIT_START;
                else b10_dma_req<='1';
                b10_state<=B10_ST_FETCH_WAIT;
                end if;
                when B10_ST_BIT_START=>if b10_current_byte(b10_bit_index)='1' then b10_pulse_duration<=scale_pulse_rt(to_unsigned(1710,16),z80_clk_mhz_u);
                else b10_pulse_duration<=scale_pulse_rt(to_unsigned(855,16),z80_clk_mhz_u);
                end if;
                b10_pulse_action<=ACT_TOGGLE;
                b10_pulse_req<='1';
                b10_state<=B10_ST_BIT_WAIT;
                when B10_ST_BIT_WAIT=>if pulse_done='1' then if b10_bit_phase='0' then b10_bit_phase<='1';
                b10_state<=B10_ST_BIT_START;
                elsif b10_bit_index>0 and not(b10_last='1' and b10_bit_index=b10_stop_idx) then b10_bit_phase<='0';
                b10_bit_index<=b10_bit_index-1;
                b10_state<=B10_ST_BIT_START;
                else b10_bit_phase<='0';
                b10_data_bytes<=b10_data_bytes-1;
                b10_state<=B10_ST_FETCH;
                end if;
                end if;
                when B10_ST_PAUSE_START=>b10_pulse_duration<=pause_cycles_rt(b10_pause_ms,z80_clk_mhz_u);
                b10_pulse_action<=ACT_FORCE_LOW;
                b10_pulse_req<='1';
                b10_state<=B10_ST_PAUSE_WAIT;
                when B10_ST_PAUSE_WAIT=>if pulse_done='1' then b10_state<=B10_ST_DONE;
                end if;
                when B10_ST_DONE=>b10_done<='1';
                b10_state<=B10_ST_IDLE;
                when others=>null;
            end case;
            end if;
        end if;
    end process;

    process(clk_fpga,reset)
    begin
        if reset='1' then b12_done<='0';
        b12_state<=B12_ST_IDLE;
        b12_len<=(others=>'0');
        b12_count<=(others=>'0');
        b12_tmp<=(others=>'0');
        b12_dma_req<='0';
        b12_pulse_req<='0';
        b12_pulse_duration<=(others=>'0');
        b12_pulse_action<=ACT_TOGGLE;
        elsif rising_edge(clk_fpga) then b12_done<='0';
        b12_dma_req<='0';
        b12_pulse_req<='0';
        if parser_run='0' or current_id/=x"12" then b12_state<=B12_ST_IDLE;
        else case b12_state is
            when B12_ST_IDLE=>b12_state<=B12_ST_LEN_LO_REQ;
            when B12_ST_LEN_LO_REQ=>b12_dma_req<='1';
            b12_state<=B12_ST_LEN_LO_WAIT;
            when B12_ST_LEN_LO_WAIT=>if dma_done='1' then b12_tmp<=dma_read_data;
            b12_state<=B12_ST_LEN_HI_REQ;
            end if;
            when B12_ST_LEN_HI_REQ=>b12_dma_req<='1';
            b12_state<=B12_ST_LEN_HI_WAIT;
            when B12_ST_LEN_HI_WAIT=>if dma_done='1' then b12_len<=unsigned(dma_read_data&b12_tmp);
            b12_state<=B12_ST_COUNT_LO_REQ;
            end if;
            when B12_ST_COUNT_LO_REQ=>b12_dma_req<='1';
            b12_state<=B12_ST_COUNT_LO_WAIT;
            when B12_ST_COUNT_LO_WAIT=>if dma_done='1' then b12_tmp<=dma_read_data;
            b12_state<=B12_ST_COUNT_HI_REQ;
            end if;
            when B12_ST_COUNT_HI_REQ=>b12_dma_req<='1';
            b12_state<=B12_ST_COUNT_HI_WAIT;
            when B12_ST_COUNT_HI_WAIT=>if dma_done='1' then b12_count<=unsigned(dma_read_data&b12_tmp);
            b12_state<=B12_ST_PULSE_START;
            end if;
            when B12_ST_PULSE_START=>if b12_count=0 then b12_state<=B12_ST_DONE;
            else b12_pulse_duration<=scale_pulse_rt(b12_len,z80_clk_mhz_u);
            b12_pulse_action<=ACT_TOGGLE;
            b12_pulse_req<='1';
            b12_state<=B12_ST_PULSE_WAIT;
            end if;
            when B12_ST_PULSE_WAIT=>if pulse_done='1' then b12_count<=b12_count-1;
            b12_state<=B12_ST_PULSE_START;
            end if;
            when B12_ST_DONE=>b12_done<='1';
            b12_state<=B12_ST_IDLE;
            when others=>null;
        end case;
        end if;
        end if;
    end process;

    process(clk_fpga,reset)
    begin
        if reset='1' then b13_done<='0';
        b13_state<=B13_ST_IDLE;
        b13_count<=(others=>'0');
        b13_len<=(others=>'0');
        b13_tmp<=(others=>'0');
        b13_dma_req<='0';
        b13_pulse_req<='0';
        b13_pulse_duration<=(others=>'0');
        b13_pulse_action<=ACT_TOGGLE;
        elsif rising_edge(clk_fpga) then b13_done<='0';
        b13_dma_req<='0';
        b13_pulse_req<='0';
        if parser_run='0' or current_id/=x"13" then b13_state<=B13_ST_IDLE;
        else case b13_state is
            when B13_ST_IDLE=>b13_state<=B13_ST_COUNT_REQ;
            when B13_ST_COUNT_REQ=>b13_dma_req<='1';
            b13_state<=B13_ST_COUNT_WAIT;
            when B13_ST_COUNT_WAIT=>if dma_done='1' then b13_count<=unsigned(dma_read_data);
            b13_state<=B13_ST_LEN_LO_REQ;
            end if;
            when B13_ST_LEN_LO_REQ=>if b13_count=0 then b13_state<=B13_ST_DONE;
            else b13_dma_req<='1';
            b13_state<=B13_ST_LEN_LO_WAIT;
            end if;
            when B13_ST_LEN_LO_WAIT=>if dma_done='1' then b13_tmp<=dma_read_data;
            b13_state<=B13_ST_LEN_HI_REQ;
            end if;
            when B13_ST_LEN_HI_REQ=>b13_dma_req<='1';
            b13_state<=B13_ST_LEN_HI_WAIT;
            when B13_ST_LEN_HI_WAIT=>if dma_done='1' then b13_len<=unsigned(dma_read_data&b13_tmp);
            b13_state<=B13_ST_PULSE_START;
            end if;
            when B13_ST_PULSE_START=>b13_pulse_duration<=scale_pulse_rt(b13_len,z80_clk_mhz_u);
            b13_pulse_action<=ACT_TOGGLE;
            b13_pulse_req<='1';
            b13_state<=B13_ST_PULSE_WAIT;
            when B13_ST_PULSE_WAIT=>if pulse_done='1' then b13_count<=b13_count-1;
            b13_state<=B13_ST_LEN_LO_REQ;
            end if;
            when B13_ST_DONE=>b13_done<='1';
            b13_state<=B13_ST_IDLE;
            when others=>null;
        end case;
        end if;
        end if;
    end process;

    process(clk_fpga,reset)
    begin
        if reset='1' then
            b14_state<=B14_ST_IDLE;
            b14_zero_len<=(others=>'0');
            b14_one_len<=(others=>'0');
            b14_used_bits<=to_unsigned(8,4);
            b14_pause_ms<=(others=>'0');
            b14_data_bytes<=(others=>'0');
            b14_tmp0<=(others=>'0');
            b14_tmp1<=(others=>'0');
            b14_current_byte<=(others=>'0');
            b14_bit_index<=7;
            b14_bit_phase<='0';
            b14_last<='0';
            b14_stop_idx<=0;
            b14_dma_req<='0';
            b14_pulse_req<='0';
            b14_pulse_duration<=(others=>'0');
            b14_pulse_action<=ACT_TOGGLE;
        elsif rising_edge(clk_fpga) then
            b14_done<='0';
            b14_dma_req<='0';
            b14_pulse_req<='0';
            if parser_run='0' or current_id/=x"14" then b14_state<=B14_ST_IDLE;
            else case b14_state is
            when B14_ST_IDLE=>b14_state<=B14_ST_ZERO_LO_REQ;
            when B14_ST_ZERO_LO_REQ=>b14_dma_req<='1';
            b14_state<=B14_ST_ZERO_LO_WAIT;
            when B14_ST_ZERO_LO_WAIT=>if dma_done='1' then b14_tmp0<=dma_read_data;
            b14_state<=B14_ST_ZERO_HI_REQ;
            end if;
            when B14_ST_ZERO_HI_REQ=>b14_dma_req<='1';
            b14_state<=B14_ST_ZERO_HI_WAIT;
            when B14_ST_ZERO_HI_WAIT=>if dma_done='1' then b14_zero_len<=unsigned(dma_read_data&b14_tmp0);
            b14_state<=B14_ST_ONE_LO_REQ;
            end if;
            when B14_ST_ONE_LO_REQ=>b14_dma_req<='1';
            b14_state<=B14_ST_ONE_LO_WAIT;
            when B14_ST_ONE_LO_WAIT=>if dma_done='1' then b14_tmp0<=dma_read_data;
            b14_state<=B14_ST_ONE_HI_REQ;
            end if;
            when B14_ST_ONE_HI_REQ=>b14_dma_req<='1';
            b14_state<=B14_ST_ONE_HI_WAIT;
            when B14_ST_ONE_HI_WAIT=>if dma_done='1' then b14_one_len<=unsigned(dma_read_data&b14_tmp0);
            b14_state<=B14_ST_USEDBITS_REQ;
            end if;
            when B14_ST_USEDBITS_REQ=>b14_dma_req<='1';
            b14_state<=B14_ST_USEDBITS_WAIT;
            when B14_ST_USEDBITS_WAIT=>if dma_done='1' then b14_used_bits<=unsigned(dma_read_data(3 downto 0));
            b14_state<=B14_ST_PAUSE_LO_REQ;
            end if;
            when B14_ST_PAUSE_LO_REQ=>b14_dma_req<='1';
            b14_state<=B14_ST_PAUSE_LO_WAIT;
            when B14_ST_PAUSE_LO_WAIT=>if dma_done='1' then b14_tmp0<=dma_read_data;
            b14_state<=B14_ST_PAUSE_HI_REQ;
            end if;
            when B14_ST_PAUSE_HI_REQ=>b14_dma_req<='1';
            b14_state<=B14_ST_PAUSE_HI_WAIT;
            when B14_ST_PAUSE_HI_WAIT=>if dma_done='1' then b14_pause_ms<=unsigned(dma_read_data&b14_tmp0);
            b14_state<=B14_ST_LEN_LO_REQ;
            end if;
            when B14_ST_LEN_LO_REQ=>b14_dma_req<='1';
            b14_state<=B14_ST_LEN_LO_WAIT;
            when B14_ST_LEN_LO_WAIT=>if dma_done='1' then b14_tmp0<=dma_read_data;
            b14_state<=B14_ST_LEN_MID_REQ;
            end if;
            when B14_ST_LEN_MID_REQ=>b14_dma_req<='1';
            b14_state<=B14_ST_LEN_MID_WAIT;
            when B14_ST_LEN_MID_WAIT=>if dma_done='1' then b14_tmp1<=dma_read_data;
            b14_state<=B14_ST_LEN_HI_REQ;
            end if;
            when B14_ST_LEN_HI_REQ=>b14_dma_req<='1';
            b14_state<=B14_ST_LEN_HI_WAIT;
            when B14_ST_LEN_HI_WAIT=>if dma_done='1' then b14_data_bytes<=unsigned(dma_read_data&b14_tmp1&b14_tmp0);
            b14_state<=B14_ST_FETCH;
            end if;
            when B14_ST_FETCH=>if b14_data_bytes=0 then if b14_pause_ms>0 then b14_state<=B14_ST_PAUSE_START;
            else b14_state<=B14_ST_DONE;
            end if;
            else b14_dma_req<='1';
            b14_state<=B14_ST_FETCH_WAIT;
            end if;
            when B14_ST_FETCH_WAIT=>if dma_done='1' then b14_current_byte<=dma_read_data;
            b14_bit_index<=7;
            b14_bit_phase<='0';
            if b14_data_bytes=1 then b14_last<='1';
            b14_stop_idx<=8-to_integer(b14_used_bits);
            else b14_last<='0';
            end if;
            b14_state<=B14_ST_BIT_START;
            end if;
            when B14_ST_BIT_START=>if b14_current_byte(b14_bit_index)='1' then b14_pulse_duration<=scale_pulse_rt(b14_one_len,z80_clk_mhz_u);
            else b14_pulse_duration<=scale_pulse_rt(b14_zero_len,z80_clk_mhz_u);
            end if;
            b14_pulse_action<=ACT_TOGGLE;
            b14_pulse_req<='1';
            b14_state<=B14_ST_BIT_WAIT;
            when B14_ST_BIT_WAIT=>if pulse_done='1' then if b14_bit_phase='0' then b14_bit_phase<='1';
            b14_state<=B14_ST_BIT_START;
            elsif b14_bit_index>0 and not(b14_last='1' and b14_bit_index=b14_stop_idx) then b14_bit_phase<='0';
            b14_bit_index<=b14_bit_index-1;
            b14_state<=B14_ST_BIT_START;
            else b14_bit_phase<='0';
            b14_data_bytes<=b14_data_bytes-1;
            b14_state<=B14_ST_FETCH;
            end if;
            end if;
            when B14_ST_PAUSE_START=>b14_pulse_duration<=pause_cycles_rt(b14_pause_ms,z80_clk_mhz_u);
            b14_pulse_action<=ACT_FORCE_LOW;
            b14_pulse_req<='1';
            b14_state<=B14_ST_PAUSE_WAIT;
            when B14_ST_PAUSE_WAIT=>if pulse_done='1' then b14_state<=B14_ST_DONE;
            end if;
            when B14_ST_DONE=>b14_done<='1';
            b14_state<=B14_ST_IDLE;
            when others=>null;
            end case;
            end if;
            end if;
    end process;

    process(clk_fpga,reset)
    begin
        if reset='1' then b15_done<='0';
        b15_state<=B15_ST_IDLE;
        b15_period<=(others=>'0');
        b15_pause_ms<=(others=>'0');
        b15_used_bits<=to_unsigned(8,4);
        b15_data_bytes<=(others=>'0');
        b15_tmp0<=(others=>'0');
        b15_tmp1<=(others=>'0');
        b15_current_byte<=(others=>'0');
        b15_bit_index<=7;
        b15_last<='0';
        b15_stop_idx<=0;
        b15_dma_req<='0';
        b15_pulse_req<='0';
        b15_pulse_duration<=(others=>'0');
        b15_pulse_action<=ACT_TOGGLE;
        elsif rising_edge(clk_fpga) then
            b15_done<='0';
            b15_dma_req<='0';
            b15_pulse_req<='0';
            if parser_run='0' or current_id/=x"15" then b15_state<=B15_ST_IDLE;
            else case b15_state is
            when B15_ST_IDLE=>b15_state<=B15_ST_PERIOD_LO_REQ;
            when B15_ST_PERIOD_LO_REQ=>b15_dma_req<='1';
            b15_state<=B15_ST_PERIOD_LO_WAIT;
            when B15_ST_PERIOD_LO_WAIT=>if dma_done='1' then b15_tmp0<=dma_read_data;
            b15_state<=B15_ST_PERIOD_HI_REQ;
            end if;
            when B15_ST_PERIOD_HI_REQ=>b15_dma_req<='1';
            b15_state<=B15_ST_PERIOD_HI_WAIT;
            when B15_ST_PERIOD_HI_WAIT=>if dma_done='1' then b15_period<=unsigned(dma_read_data&b15_tmp0);
            b15_state<=B15_ST_PAUSE_LO_REQ;
            end if;
            when B15_ST_PAUSE_LO_REQ=>b15_dma_req<='1';
            b15_state<=B15_ST_PAUSE_LO_WAIT;
            when B15_ST_PAUSE_LO_WAIT=>if dma_done='1' then b15_tmp0<=dma_read_data;
            b15_state<=B15_ST_PAUSE_HI_REQ;
            end if;
            when B15_ST_PAUSE_HI_REQ=>b15_dma_req<='1';
            b15_state<=B15_ST_PAUSE_HI_WAIT;
            when B15_ST_PAUSE_HI_WAIT=>if dma_done='1' then b15_pause_ms<=unsigned(dma_read_data&b15_tmp0);
            b15_state<=B15_ST_USEDBITS_REQ;
            end if;
            when B15_ST_USEDBITS_REQ=>b15_dma_req<='1';
            b15_state<=B15_ST_USEDBITS_WAIT;
            when B15_ST_USEDBITS_WAIT=>if dma_done='1' then b15_used_bits<=unsigned(dma_read_data(3 downto 0));
            b15_state<=B15_ST_LEN_LO_REQ;
            end if;
            when B15_ST_LEN_LO_REQ=>b15_dma_req<='1';
            b15_state<=B15_ST_LEN_LO_WAIT;
            when B15_ST_LEN_LO_WAIT=>if dma_done='1' then b15_tmp0<=dma_read_data;
            b15_state<=B15_ST_LEN_MID_REQ;
            end if;
            when B15_ST_LEN_MID_REQ=>b15_dma_req<='1';
            b15_state<=B15_ST_LEN_MID_WAIT;
            when B15_ST_LEN_MID_WAIT=>if dma_done='1' then b15_tmp1<=dma_read_data;
            b15_state<=B15_ST_LEN_HI_REQ;
            end if;
            when B15_ST_LEN_HI_REQ=>b15_dma_req<='1';
            b15_state<=B15_ST_LEN_HI_WAIT;
            when B15_ST_LEN_HI_WAIT=>if dma_done='1' then b15_data_bytes<=unsigned(dma_read_data&b15_tmp1&b15_tmp0);
            b15_state<=B15_ST_FETCH;
            end if;
            when B15_ST_FETCH=>if b15_data_bytes=0 then if b15_pause_ms>0 then b15_state<=B15_ST_PAUSE_START;
            else b15_state<=B15_ST_DONE;
            end if;
            else b15_dma_req<='1';
            b15_state<=B15_ST_FETCH_WAIT;
            end if;
            when B15_ST_FETCH_WAIT=>if dma_done='1' then b15_current_byte<=dma_read_data;
            b15_bit_index<=7;
            if b15_data_bytes=1 then b15_last<='1';
            b15_stop_idx<=8-to_integer(b15_used_bits);
            else b15_last<='0';
            end if;
            b15_state<=B15_ST_SAMPLE_START;
            end if;
            when B15_ST_SAMPLE_START=>if b15_current_byte(b15_bit_index)='1' then b15_pulse_action<=ACT_FORCE_HIGH;
            else b15_pulse_action<=ACT_FORCE_LOW;
            end if;
            b15_pulse_duration<=scale_pulse_rt(b15_period,z80_clk_mhz_u);
            b15_pulse_req<='1';
            b15_state<=B15_ST_SAMPLE_WAIT;
            when B15_ST_SAMPLE_WAIT=>if pulse_done='1' then if b15_bit_index>0 and not(b15_last='1' and b15_bit_index=b15_stop_idx) then b15_bit_index<=b15_bit_index-1;
            b15_state<=B15_ST_SAMPLE_START;
            else b15_data_bytes<=b15_data_bytes-1;
            b15_state<=B15_ST_FETCH;
            end if;
            end if;
            when B15_ST_PAUSE_START=>b15_pulse_duration<=pause_cycles_rt(b15_pause_ms,z80_clk_mhz_u);
            b15_pulse_action<=ACT_FORCE_LOW;
            b15_pulse_req<='1';
            b15_state<=B15_ST_PAUSE_WAIT;
            when B15_ST_PAUSE_WAIT=>if pulse_done='1' then b15_state<=B15_ST_DONE;
            end if;
            when B15_ST_DONE=>b15_done<='1';
            b15_state<=B15_ST_IDLE;
            when others=>null;
            end case;
            end if;
            end if;
    end process;

    ------------------------------------------------------------------------
    -- $20 PAUSE / STOP
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
      if reset='1' then b20_done<='0';
      b20_stop_req<='0';
      b20_state<=B20_ST_IDLE;
      b20_pause<=(others=>'0');
      b20_tmp<=(others=>'0');
      b20_dma_req<='0';
      b20_pulse_req<='0';
      b20_pulse_duration<=(others=>'0');
      b20_pulse_action<=ACT_TOGGLE;
      elsif rising_edge(clk_fpga) then b20_done<='0';
      b20_stop_req<='0';
      b20_dma_req<='0';
      b20_pulse_req<='0';
      if parser_run='0' or current_id/=x"20" then b20_state<=B20_ST_IDLE;
      else case b20_state is
      when B20_ST_IDLE=>b20_state<=B20_ST_LO_REQ;
      when B20_ST_LO_REQ=>b20_dma_req<='1';
      b20_state<=B20_ST_LO_WAIT;
      when B20_ST_LO_WAIT=>if dma_done='1' then b20_tmp<=dma_read_data;
      b20_state<=B20_ST_HI_REQ;
      end if;
      when B20_ST_HI_REQ=>b20_dma_req<='1';
      b20_state<=B20_ST_HI_WAIT;
      when B20_ST_HI_WAIT=>if dma_done='1' then b20_pause<=unsigned(dma_read_data&b20_tmp);
      b20_state<=B20_ST_DECIDE;
      end if;
      when B20_ST_DECIDE=>if b20_pause=0 then b20_stop_req<='1';
      b20_state<=B20_ST_DONE;
      else b20_pulse_duration<=pause_cycles_rt(b20_pause,z80_clk_mhz_u);
      b20_pulse_action<=ACT_FORCE_LOW;
      b20_pulse_req<='1';
      b20_state<=B20_ST_PULSE_WAIT;
      end if;
      when B20_ST_PULSE_WAIT=>if pulse_done='1' then b20_state<=B20_ST_DONE;
      end if;
      when B20_ST_DONE=>b20_done<='1';
      b20_state<=B20_ST_IDLE;
      when others=>null;
      end case;
      end if;
      end if;
    end process;

    ------------------------------------------------------------------------
    -- $21 GROUP START: one-byte name length followed by name.
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
      if reset='1' then b21_done<='0';
      b21_state<=B21_ST_IDLE;
      b21_skip<=(others=>'0');
      b21_dma_req<='0';
      elsif rising_edge(clk_fpga) then b21_done<='0';
      b21_dma_req<='0';
      if parser_run='0' or current_id/=x"21" then b21_state<=B21_ST_IDLE;
      else case b21_state is
      when B21_ST_IDLE=>b21_state<=B21_ST_LEN_REQ;
      when B21_ST_LEN_REQ=>b21_dma_req<='1';
      b21_state<=B21_ST_LEN_WAIT;
      when B21_ST_LEN_WAIT=>if dma_done='1' then b21_skip<=resize(unsigned(dma_read_data),32);
      b21_state<=B21_ST_SKIP;
      end if;
      when B21_ST_SKIP=>if b21_skip=0 then b21_state<=B21_ST_DONE;
      else b21_dma_req<='1';
      b21_state<=B21_ST_SKIP_WAIT;
      end if;
      when B21_ST_SKIP_WAIT=>if dma_done='1' then b21_skip<=b21_skip-1;
      b21_state<=B21_ST_SKIP;
      end if;
      when B21_ST_DONE=>b21_done<='1';
      b21_state<=B21_ST_IDLE;
      when others=>null;
      end case;
      end if;
      end if;
    end process;

    ------------------------------------------------------------------------
    -- $22 GROUP END: no body.
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
      if reset='1' then b22_done<='0';
      b22_state<=B22_ST_IDLE;
      elsif rising_edge(clk_fpga) then
        b22_done<='0';
        if parser_run='0' or current_id/=x"22" then b22_state<=B22_ST_IDLE;
        else
          case b22_state is
            when B22_ST_IDLE => b22_state<=B22_ST_DONE;
            when B22_ST_DONE => b22_done<='1';
            b22_state<=B22_ST_IDLE;
            when others => null;
          end case;
        end if;
      end if;
    end process;

    ------------------------------------------------------------------------
    -- $23 JUMP: preserve the original implementation's documented linear
    -- continuation (read and discard the two-byte relative jump).
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
      if reset='1' then b23_done<='0';
      b23_state<=B23_ST_IDLE;
      b23_tmp<=(others=>'0');
      b23_dma_req<='0';
      elsif rising_edge(clk_fpga) then b23_done<='0';
      b23_dma_req<='0';
      if parser_run='0' or current_id/=x"23" then b23_state<=B23_ST_IDLE;
      else case b23_state is
      when B23_ST_IDLE=>b23_state<=B23_ST_LO_REQ;
      when B23_ST_LO_REQ=>b23_dma_req<='1';
      b23_state<=B23_ST_LO_WAIT;
      when B23_ST_LO_WAIT=>if dma_done='1' then b23_tmp<=dma_read_data;
      b23_state<=B23_ST_HI_REQ;
      end if;
      when B23_ST_HI_REQ=>b23_dma_req<='1';
      b23_state<=B23_ST_HI_WAIT;
      when B23_ST_HI_WAIT=>if dma_done='1' then b23_state<=B23_ST_DONE;
      end if;
      when B23_ST_DONE=>b23_done<='1';
      b23_state<=B23_ST_IDLE;
      when others=>null;
      end case;
      end if;
      end if;
    end process;

    ------------------------------------------------------------------------
    -- $24 LOOP START
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
      if reset='1' then b24_loop_load_req<='0';
      b24_done<='0';
      b24_state<=B24_ST_IDLE;
      b24_tmp<=(others=>'0');
      b24_dma_req<='0';
      elsif rising_edge(clk_fpga) then b24_done<='0';
      b24_loop_load_req<='0';
      b24_dma_req<='0';
      if parser_run='0' or current_id/=x"24" then b24_state<=B24_ST_IDLE;
      else case b24_state is
      when B24_ST_IDLE=>b24_state<=B24_ST_LO_REQ;
      when B24_ST_LO_REQ=>b24_dma_req<='1';
      b24_state<=B24_ST_LO_WAIT;
      when B24_ST_LO_WAIT=>if dma_done='1' then b24_tmp<=dma_read_data;
      b24_state<=B24_ST_HI_REQ;
      end if;
      when B24_ST_HI_REQ=>b24_dma_req<='1';
      b24_state<=B24_ST_HI_WAIT;
      when B24_ST_HI_WAIT=>if dma_done='1' then b24_loop_count<=unsigned(dma_read_data&b24_tmp);
      b24_loop_addr<=ram_ptr;
      b24_loop_load_req<='1';
      b24_state<=B24_ST_DONE;
      end if;
      when B24_ST_DONE=>b24_done<='1';
      b24_state<=B24_ST_IDLE;
      when others=>null;
      end case;
      end if;
      end if;
    end process;

    ------------------------------------------------------------------------
    -- $25 LOOP END
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
      if reset='1' then b25_done<='0';
      b25_seek_req<='0';
      b25_seek_addr<=(others=>'0');
      b25_state<=B25_ST_IDLE;
      elsif rising_edge(clk_fpga) then b25_done<='0';
      b25_seek_req<='0';
      if b24_loop_load_req='1' then loop_count<=b24_loop_count;
      loop_start_addr<=b24_loop_addr;
      end if;
      if parser_run='0' or current_id/=x"25" then b25_state<=B25_ST_IDLE;
      else case b25_state is
        when B25_ST_IDLE=>b25_state<=B25_ST_DECIDE;
        when B25_ST_DECIDE=>if loop_count<=1 then loop_count<=(others=>'0');
        b25_state<=B25_ST_DONE;
        else loop_count<=loop_count-1;
        b25_seek_req<='1';
        b25_seek_addr<=loop_start_addr;
        b25_state<=B25_ST_SEEK_WAIT;
        end if;
        when B25_ST_SEEK_WAIT=>b25_state<=B25_ST_DONE;
        when B25_ST_DONE=>b25_done<='1';
        b25_state<=B25_ST_IDLE;
        when others=>null;
      end case;
      end if;
      end if;
    end process;

    ------------------------------------------------------------------------
    -- $30 TEXT DESCRIPTION
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
      if reset='1' then b30_done<='0';
      b30_state<=B30_ST_IDLE;
      b30_skip<=(others=>'0');
      b30_dma_req<='0';
      elsif rising_edge(clk_fpga) then b30_done<='0';
      b30_dma_req<='0';
      if parser_run='0' or current_id/=x"30" then b30_state<=B30_ST_IDLE;
      else case b30_state is when B30_ST_IDLE=>b30_state<=B30_ST_LEN_REQ;
      when B30_ST_LEN_REQ=>b30_dma_req<='1';
      b30_state<=B30_ST_LEN_WAIT;
      when B30_ST_LEN_WAIT=>if dma_done='1' then b30_skip<=resize(unsigned(dma_read_data),32);
      b30_state<=B30_ST_SKIP;
      end if;
      when B30_ST_SKIP=>if b30_skip=0 then b30_state<=B30_ST_DONE;
      else b30_dma_req<='1';
      b30_state<=B30_ST_SKIP_WAIT;
      end if;
      when B30_ST_SKIP_WAIT=>if dma_done='1' then b30_skip<=b30_skip-1;
      b30_state<=B30_ST_SKIP;
      end if;
      when B30_ST_DONE=>b30_done<='1';
      b30_state<=B30_ST_IDLE;
      when others=>null;
      end case;
      end if;
      end if;
    end process;

    ------------------------------------------------------------------------
    -- $32 ARCHIVE INFO
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
      if reset='1' then b32_done<='0';
      b32_state<=B32_ST_IDLE;
      b32_skip<=(others=>'0');
      b32_tmp<=(others=>'0');
      b32_dma_req<='0';
      elsif rising_edge(clk_fpga) then b32_done<='0';
      b32_dma_req<='0';
      if parser_run='0' or current_id/=x"32" then b32_state<=B32_ST_IDLE;
      else case b32_state is when B32_ST_IDLE=>b32_state<=B32_ST_LO_REQ;
      when B32_ST_LO_REQ=>b32_dma_req<='1';
      b32_state<=B32_ST_LO_WAIT;
      when B32_ST_LO_WAIT=>if dma_done='1' then b32_tmp<=dma_read_data;
      b32_state<=B32_ST_HI_REQ;
      end if;
      when B32_ST_HI_REQ=>b32_dma_req<='1';
      b32_state<=B32_ST_HI_WAIT;
      when B32_ST_HI_WAIT=>if dma_done='1' then b32_skip<=resize(unsigned(dma_read_data&b32_tmp),32);
      b32_state<=B32_ST_SKIP;
      end if;
      when B32_ST_SKIP=>if b32_skip=0 then b32_state<=B32_ST_DONE;
      else b32_dma_req<='1';
      b32_state<=B32_ST_SKIP_WAIT;
      end if;
      when B32_ST_SKIP_WAIT=>if dma_done='1' then b32_skip<=b32_skip-1;
      b32_state<=B32_ST_SKIP;
      end if;
      when B32_ST_DONE=>b32_done<='1';
      b32_state<=B32_ST_IDLE;
      when others=>null;
      end case;
      end if;
      end if;
    end process;

    ------------------------------------------------------------------------
    -- $33 HARDWARE TYPE
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
      if reset='1' then b33_done<='0';
      b33_state<=B33_ST_IDLE;
      b33_skip<=(others=>'0');
      b33_dma_req<='0';
      elsif rising_edge(clk_fpga) then b33_done<='0';
      b33_dma_req<='0';
      if parser_run='0' or current_id/=x"33" then b33_state<=B33_ST_IDLE;
      else case b33_state is when B33_ST_IDLE=>b33_state<=B33_ST_COUNT_REQ;
      when B33_ST_COUNT_REQ=>b33_dma_req<='1';
      b33_state<=B33_ST_COUNT_WAIT;
      when B33_ST_COUNT_WAIT=>if dma_done='1' then b33_skip<=resize(unsigned(dma_read_data)*3,32);
      b33_state<=B33_ST_SKIP;
      end if;
      when B33_ST_SKIP=>if b33_skip=0 then b33_state<=B33_ST_DONE;
      else b33_dma_req<='1';
      b33_state<=B33_ST_SKIP_WAIT;
      end if;
      when B33_ST_SKIP_WAIT=>if dma_done='1' then b33_skip<=b33_skip-1;
      b33_state<=B33_ST_SKIP;
      end if;
      when B33_ST_DONE=>b33_done<='1';
      b33_state<=B33_ST_IDLE;
      when others=>null;
      end case;
      end if;
      end if;
    end process;

    ------------------------------------------------------------------------
    -- $35 CUSTOM INFO
    ------------------------------------------------------------------------
    process(clk_fpga,reset)
    begin
      if reset='1' then b35_done<='0';
      b35_state<=B35_ST_IDLE;
      b35_skip<=(others=>'0');
      b35_tmp0<=(others=>'0');
      b35_tmp1<=(others=>'0');
      b35_tmp2<=(others=>'0');
      b35_dma_req<='0';
      elsif rising_edge(clk_fpga) then b35_done<='0';
      b35_dma_req<='0';
      if parser_run='0' or current_id/=x"35" then b35_state<=B35_ST_IDLE;
      else case b35_state is
        when B35_ST_IDLE=>b35_state<=B35_ST_SKIP_ID;
        when B35_ST_SKIP_ID=>b35_skip<=to_unsigned(10,32);
        b35_state<=B35_ST_SKIP_ID_REQ;
        when B35_ST_SKIP_ID_REQ=>b35_dma_req<='1';
        b35_state<=B35_ST_SKIP_ID_WAIT;
        when B35_ST_SKIP_ID_WAIT=>if dma_done='1' then if b35_skip=1 then b35_skip<=(others=>'0');
        b35_state<=B35_ST_LEN0_REQ;
        else b35_skip<=b35_skip-1;
        b35_state<=B35_ST_SKIP_ID_REQ;
        end if;
        end if;
        when B35_ST_LEN0_REQ=>b35_dma_req<='1';
        b35_state<=B35_ST_LEN0_WAIT;
        when B35_ST_LEN0_WAIT=>if dma_done='1' then b35_tmp0<=dma_read_data;
        b35_state<=B35_ST_LEN1_REQ;
        end if;
        when B35_ST_LEN1_REQ=>b35_dma_req<='1';
        b35_state<=B35_ST_LEN1_WAIT;
        when B35_ST_LEN1_WAIT=>if dma_done='1' then b35_tmp1<=dma_read_data;
        b35_state<=B35_ST_LEN2_REQ;
        end if;
        when B35_ST_LEN2_REQ=>b35_dma_req<='1';
        b35_state<=B35_ST_LEN2_WAIT;
        when B35_ST_LEN2_WAIT=>if dma_done='1' then b35_tmp2<=dma_read_data;
        b35_state<=B35_ST_LEN3_REQ;
        end if;
        when B35_ST_LEN3_REQ=>b35_dma_req<='1';
        b35_state<=B35_ST_LEN3_WAIT;
        when B35_ST_LEN3_WAIT=>if dma_done='1' then b35_skip<=unsigned(dma_read_data&b35_tmp2&b35_tmp1&b35_tmp0);
        b35_state<=B35_ST_SKIP;
        end if;
        when B35_ST_SKIP=>if b35_skip=0 then b35_state<=B35_ST_DONE;
        else b35_dma_req<='1';
        b35_state<=B35_ST_SKIP_WAIT;
        end if;
        when B35_ST_SKIP_WAIT=>if dma_done='1' then b35_skip<=b35_skip-1;
        b35_state<=B35_ST_SKIP;
        end if;
        when B35_ST_DONE=>b35_done<='1';
        b35_state<=B35_ST_IDLE;
        when others=>null;
      end case;
      end if;
      end if;
    end process;

end architecture;
