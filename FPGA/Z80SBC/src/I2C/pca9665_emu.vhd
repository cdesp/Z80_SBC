library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pca9665_wrapper is
    port (
        clk      : in std_logic;
        reset_n  : in std_logic;

        cs       : in std_logic;
        rd       : in std_logic;
        wr       : in std_logic;
        din      : in std_logic_vector(7 downto 0);
        addr     : in std_logic_vector(1 downto 0);
        dout     : out std_logic_vector(7 downto 0);

        SCL      : inout std_logic;
        SDA      : inout std_logic
    );
end entity;

architecture rtl of pca9665_wrapper is

    --------------------------------------------------------------------
    -- Gowin I2C IP
    --------------------------------------------------------------------
    component I2C_MASTER_Top
        port (
            I_CLK     : in std_logic;
            I_RESETN  : in std_logic;

            I_TX_EN   : in std_logic;
            I_WADDR   : in std_logic_vector(2 downto 0);
            I_WDATA   : in std_logic_vector(7 downto 0);

            I_RX_EN   : in std_logic;
            I_RADDR   : in std_logic_vector(2 downto 0);

            O_RDATA   : out std_logic_vector(7 downto 0);
            O_IIC_INT : out std_logic;

            SCL       : inout std_logic;
            SDA       : inout std_logic
        );
    end component;

    --------------------------------------------------------------------
    -- IP signals
    --------------------------------------------------------------------
    signal o_rdata  : std_logic_vector(7 downto 0);
    signal o_int    : std_logic;

    signal i_tx_en  : std_logic := '0';
    signal i_waddr  : std_logic_vector(2 downto 0) := (others=>'0');
    signal i_wdata  : std_logic_vector(7 downto 0) := (others=>'0');

    signal i_rx_en  : std_logic := '1';
    signal i_raddr  : std_logic_vector(2 downto 0) := "100";

    --------------------------------------------------------------------
    -- PCA9665 emulation registers
    --------------------------------------------------------------------
    signal reg_dat     : std_logic_vector(7 downto 0) := (others=>'0');

    --------------------------------------------------------------------
    -- Command handshake
    --------------------------------------------------------------------
    signal req_reg   : std_logic_vector(2 downto 0) := (others=>'0');
    signal req_data  : std_logic_vector(7 downto 0) := (others=>'0');
    signal req_send  : std_logic := '0';

    signal busy      : std_logic := '0';

    --------------------------------------------------------------------
    -- FSM
    --------------------------------------------------------------------
    type fsm_t is (IDLE, ISSUE, WAIT_DONE);
    signal fsm : fsm_t := IDLE;

    constant STA_REG : std_logic_vector(1 downto 0) := "00"; --READ
    constant INDPTR_REG : std_logic_vector(1 downto 0) := "00"; --WRITE
    constant DAT_REG : std_logic_vector(1 downto 0) := "01";
    constant CON_REG : std_logic_vector(1 downto 0) := "11";
    constant INDIR_REG : std_logic_vector(1 downto 0) := "10";

    --------------------------------------------------
    -- PCA9665 INDIRECT REGISTERS
    --------------------------------------------------

    constant IR_COUNT   : std_logic_vector(2 downto 0) := "000";
    constant IR_ADR     : std_logic_vector(2 downto 0) := "001";

    constant IR_SCLL    : std_logic_vector(2 downto 0) := "010";
    constant IR_SCLH    : std_logic_vector(2 downto 0) := "011";

    constant IR_TO      : std_logic_vector(2 downto 0) := "100";
    constant IR_PRESET  : std_logic_vector(2 downto 0) := "101";
    constant IR_MODE    : std_logic_vector(2 downto 0) := "110";

    --------------------------------------------------
    -- PCA9665 STATUS CODES
    --------------------------------------------------

    constant ILLEGAL_START_STOP : std_logic_vector(7 downto 0) := x"00";

    constant MASTER_START_TXed   : std_logic_vector(7 downto 0) := x"08";
    constant MASTER_RESTART_TXed : std_logic_vector(7 downto 0) := x"10";

    constant MASTER_SLA_W_ACK    : std_logic_vector(7 downto 0) := x"18";
    constant MASTER_SLA_W_NAK    : std_logic_vector(7 downto 0) := x"20";

    constant MASTER_DATA_W_ACK   : std_logic_vector(7 downto 0) := x"28";
    constant MASTER_DATA_W_NAK   : std_logic_vector(7 downto 0) := x"30";

    constant MASTER_ARB_LOST     : std_logic_vector(7 downto 0) := x"38";

    constant MASTER_SLA_R_ACK    : std_logic_vector(7 downto 0) := x"40";
    constant MASTER_SLA_R_NAK    : std_logic_vector(7 downto 0) := x"48";

    constant MASTER_DATA_R_ACK   : std_logic_vector(7 downto 0) := x"50";
    constant MASTER_DATA_R_NAK   : std_logic_vector(7 downto 0) := x"58";

    constant I2C_IDLE                : std_logic_vector(7 downto 0) := x"F8";

    signal INDPTR_REG_data  : std_logic_vector(7 downto 0) := (others=>'0');

    type i2c_state_t is (
        IDLE,
        STARTED,
        SLA_PHASE,
        DATA_PHASE,
        STOPPED
    );
    signal i2c_state  : i2c_state_t := IDLE;

    signal status_reg : std_logic_vector(7 downto 0) := I2C_IDLE;


  type bridge_state_t is (
        IDLE,
        START_CMD,
        SEND_ADDR,
        SEND_DATA,
        WAIT_SLA,
        WAIT_ACK,        
        DATA_PHASE,
        STOP_CMD,
        ERROR_STATE,
        WAIT_NEXT_CMD
    );

    signal reg_count : std_logic_vector(7 downto 0) := x"00";
    signal reg_addr : std_logic_vector(7 downto 0) := x"00";
    signal reg_scll : std_logic_vector(7 downto 0) := x"00";
    signal reg_sclh : std_logic_vector(7 downto 0) := x"00";
    signal reg_timeout : std_logic_vector(7 downto 0) := x"00";
    signal reg_preset : std_logic_vector(7 downto 0) := x"00";
    signal reg_mode : std_logic_vector(7 downto 0) := x"00";
    signal reg_ptr : std_logic_vector(7 downto 0) := x"00";
    signal reg_con : std_logic_vector(7 downto 0) := x"00";
    signal si_flag : std_logic;
    signal bridge_state : bridge_state_t := IDLE;
    signal bridge_start : std_logic := '0';


begin

    --------------------------------------------------------------------
    -- IP INSTANCE
    --------------------------------------------------------------------
    U1: I2C_MASTER_Top
        port map (
            I_CLK     => clk,
            I_RESETN  => reset_n,

            I_TX_EN   => i_tx_en,

            I_WADDR   => i_waddr,
            I_WDATA   => i_wdata,

            I_RX_EN   => i_rx_en,
            I_RADDR   => i_raddr,

            O_RDATA   => o_rdata,
            O_IIC_INT => o_int,

            SCL       => SCL,
            SDA       => SDA
        );

    --------------------------------------------------------------------
    -- Z80 READ
    --------------------------------------------------------------------
    process(all)
    begin

        dout <= (others => '0');

        case addr is

            --------------------------------------------------
            -- STATUS REGISTER
            --------------------------------------------------
            when STA_REG =>
                dout <= status_reg;

            --------------------------------------------------
            -- DATA REGISTER
            --------------------------------------------------
            when DAT_REG =>
                dout <= o_rdata;

            --------------------------------------------------
            -- INDIRECT REGISTER
            --------------------------------------------------
            when INDIR_REG =>

                case reg_ptr is

                    when IR_COUNT =>
                        dout <= reg_count;

                    when IR_ADR =>
                        dout <= reg_addr;        -- not needed

                    when IR_SCLL =>
                        dout <= reg_scll;

                    when IR_SCLH =>
                        dout <= reg_sclh; 

                    when IR_TO =>
                        dout <= reg_timeout;

                    when IR_PRESET =>
                        dout <= reg_preset;

                    when IR_MODE =>
                        dout <= reg_mode;

                     when others =>
                        dout <= (others=>'0');

                end case;

            --------------------------------------------------
            -- CONTROL REGISTER
            --------------------------------------------------
            when CON_REG =>

                dout <= reg_con;
                dout(3) <= si_flag;

            when others =>
                null;

        end case;

    end process;


  
    --------------------------------------------------------------------
    -- Z80 WRITE → PCA9665 COMMAND DECODER
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            --------------------------------------------------------------------
            -- RESET
            --------------------------------------------------------------------
            if reset_n = '0' then

                si_flag     <= '0';
                status_reg  <= I2C_IDLE;
                i2c_state   <= IDLE;

            else

                ----------------------------------------------------------------
                -- IP EVENT: set SI
                ----------------------------------------------------------------
                if o_int = '1' then
                    si_flag <= '1';
                end if;

                ----------------------------------------------------------------
                -- CPU WRITE
                ----------------------------------------------------------------
                if cs='1' and wr='1' then

                    case addr is

                        --------------------------------------------------------
                        -- DATA REGISTER
                        --------------------------------------------------------
                        when DAT_REG =>
                            reg_dat <= din;

                        --------------------------------------------------------
                        -- CONTROL REGISTER (CON)
                        --------------------------------------------------------
                        when CON_REG =>

                            -- ANY write clears SI (PCA9665 behavior)
                            si_flag <= '0';

                            ----------------------------------------------------------------
                            -- STATUS GENERATOR FSM (YOUR REQUESTED LOGIC)
                            ----------------------------------------------------------------
                            case din is

                                ------------------------------------------------
                                when x"60" =>  -- START
                                    i2c_state  <= STARTED;
                                    status_reg <= MASTER_START_TXed; -- START TX
                                ------------------------------------------------
                                when x"40" =>  -- CONTINUE
                                    if i2c_state = STARTED then
                                        status_reg <= MASTER_SLA_W_ACK; -- SLA+W ACK
                                        i2c_state  <= SLA_PHASE;
                                    else
                                        status_reg <= MASTER_DATA_W_ACK; -- DATA ACK
                                        i2c_state  <= DATA_PHASE;
                                    end if;

                                ------------------------------------------------
                                when x"50" =>  -- STOP
                                    i2c_state  <= STOPPED;
                                    status_reg <= I2C_IDLE;

                                ------------------------------------------------
                                when others =>
                                    null;

                            end case;

                        --------------------------------------------------------
                        -- INDIRECT POINTER
                        --------------------------------------------------------
                        when INDPTR_REG =>
                            reg_ptr <= din(2 downto 0);

                        --------------------------------------------------------
                        -- INDIRECT REGISTER ACCESS
                        --------------------------------------------------------
                        when INDIR_REG =>
                            case reg_ptr is

                                when IR_SCLL =>
                                    reg_scll <= din;

                                    if din = x"9D" and reg_sclh = x"86" then
                                        req_reg  <= "000";
                                        req_data <= x"63";
                                        req_send <= '1';
                                    end if;

                                when IR_SCLH =>
                                    reg_sclh <= din;

                                    if reg_scll = x"9D" and din = x"86" then
                                        req_reg  <= "000";
                                        req_data <= x"63";
                                        req_send <= '1';
                                    end if;

                                when IR_MODE =>
                                    reg_mode <= din;

                                    if din = x"00" then
                                        req_reg  <= "000";
                                        req_data <= x"63";
                                        req_send <= '1';
                                    end if;

                                when others =>
                                    null;

                            end case;

                        when others =>
                            null;

                    end case;
                end if;

            end if;
        end if;
    end process;


    process(clk)
    begin
        if rising_edge(clk) then

            if reset_n = '0' then
                bridge_state <= IDLE;
                req_send <= '0';

            else

                -- default pulse
                req_send <= '0';

                case bridge_state is

                ------------------------------------------------------------
                when IDLE =>
                    null;

                ------------------------------------------------------------
                when STARTED =>
                    -- wait for IP to finish START
                    if o_status_tip = '0' then
                        bridge_state <= WAIT_SLA;
                    end if;

                ------------------------------------------------------------
                when WAIT_SLA =>
                    -- send SLA+W or SLA+R via TX register
                    req_reg  <= TX_REG;
                    req_data <= reg_dat;
                    req_send <= '1';

                    bridge_state <= WAIT_ACK;

                ------------------------------------------------------------
                when WAIT_ACK =>
                    if o_status_tip = '0' then

                        if o_status_ack = '1' then
                            bridge_state <= DATA_PHASE;
                        else
                            bridge_state <= ERROR_STATE;
                        end if;

                    end if;

                ------------------------------------------------------------
                when DATA_PHASE =>
                    if o_status_tip = '0' then
                        -- ready for next byte
                        bridge_state <= WAIT_NEXT_CMD;
                    end if;

                ------------------------------------------------------------
                when WAIT_NEXT_CMD =>
                    null;

                ------------------------------------------------------------
                when STOPPED =>
                    if o_status_tip = '0' then
                        bridge_state <= IDLE;
                    end if;

                end case;

            end if;
        end if;
    end process;


    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                reg_dat  <= (others=>'0');
                reg_ptr  <= (others=>'0');

            elsif cs='1' and wr='1' then

                case addr is

                    when DAT_REG =>
                        reg_dat <= din;

                    when INDPTR_REG =>
                        reg_ptr <= din(2 downto 0);

                    when CON_REG =>
                        reg_con <= din;

                        -- ONLY signal bridge trigger (NOT IP directly)
                        bridge_start <= '1';

                    when others =>
                        null;
                end case;

            else
                bridge_start <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- TRANSACTION FSM → GOWIN IP
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            if reset_n = '0' then
                fsm <= IDLE;
                i_tx_en <= '0';
                busy <= '0';

            else

                case fsm is

                    ----------------------------------------------------
                    when IDLE =>
                        i_tx_en <= '0';

                        if req_send = '1' and busy = '0' then
                            busy <= '1';
                            fsm <= ISSUE;
                        end if;

                    ----------------------------------------------------
                    when ISSUE =>
                        i_waddr <= req_reg;
                        i_wdata <= req_data;
                        i_tx_en <= '1';

                        req_send <= '0';
                        fsm <= WAIT_DONE;

                    ----------------------------------------------------
                    when WAIT_DONE =>
                        i_tx_en <= '0';

                        if o_int = '1' then
                            busy <= '0';
                            status_reg <= x"28";
                            fsm <= IDLE;
                        end if;

                end case;
            end if;
        end if;
    end process;

end architecture;