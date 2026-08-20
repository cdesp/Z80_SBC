library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SRAM_PAGE_CLEAR is
    generic (
        ADDR_WIDTH   : integer := 20;
        PAGE_WIDTH   : integer := 7;
        OFFSET_WIDTH : integer := 13;
        WRITE_CYCLES : integer := 3
    );

    port (
        CLK             : in  std_logic;
        RESET_N         : in  std_logic;

        -- Clear request
        START           : in  std_logic;
        PAGE_NUMBER     : in  std_logic_vector(PAGE_WIDTH-1 downto 0);

        -- Z80 bus arbitration
        BUSACK_N        : in  std_logic;
        BUSREQ_N        : out std_logic;

        -- SRAM control
        SRAM_ADDR       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        SRAM_DATA       : out std_logic_vector(7 downto 0);
        SRAM_CE_N       : out std_logic;
        SRAM_WE_N       : out std_logic;

        -- Status
        BUSY            : out std_logic;
        DONE            : out std_logic
    );
end entity;


architecture RTL of SRAM_PAGE_CLEAR is

    type STATE_TYPE is (
        IDLE,
        REQUEST_BUS,
        WAIT_BUSACK,
        WRITE_SETUP,
        WRITE_ACTIVE,
        WRITE_HOLD,
        RELEASE_BUS,
        WAIT_BUS_RELEASE
    );

    signal state : STATE_TYPE := IDLE;

    signal page_reg   : std_logic_vector(PAGE_WIDTH-1 downto 0);
    signal offset_reg : unsigned(OFFSET_WIDTH-1 downto 0);

    signal cycle_count : integer range 0 to WRITE_CYCLES-1 := 0;

    signal addr_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);

begin

    --------------------------------------------------------------------
    -- Address
    --
    -- A19..A13 = page
    -- A12..A0  = byte offset
    --------------------------------------------------------------------

    addr_reg <= page_reg & std_logic_vector(offset_reg);

    SRAM_ADDR <= addr_reg;

    --------------------------------------------------------------------
    -- Always write zero
    --------------------------------------------------------------------

    SRAM_DATA <= x"00";

    --------------------------------------------------------------------
    -- BUSREQ
    --
    -- Assert only while we are waiting for /BUSACK or using the bus.
    --------------------------------------------------------------------

    BUSREQ_N <= '0'
        when state = REQUEST_BUS
          or state = WAIT_BUSACK
          or state = WRITE_SETUP
          or state = WRITE_ACTIVE
          or state = WRITE_HOLD
        else '1';


    --------------------------------------------------------------------
    -- SRAM CE#
    --
    -- IMPORTANT:
    -- SRAM is only enabled AFTER Z80 has acknowledged BUSREQ.
    --------------------------------------------------------------------

    SRAM_CE_N <= '0'
        when state = WRITE_SETUP
          or state = WRITE_ACTIVE
          or state = WRITE_HOLD
        else '1';


    --------------------------------------------------------------------
    -- SRAM WE#
    --------------------------------------------------------------------

    SRAM_WE_N <= '0'
        when state = WRITE_ACTIVE
        else '1';


    --------------------------------------------------------------------
    -- BUSY
    --
    -- BUSY means FPGA currently owns the SRAM bus.
    -- Therefore it only becomes active after BUSACK.
    --------------------------------------------------------------------

    BUSY <= '1'
        when state = WRITE_SETUP
          or state = WRITE_ACTIVE
          or state = WRITE_HOLD
        else '0';


    --------------------------------------------------------------------
    -- DONE
    --------------------------------------------------------------------

    DONE <= '1'
        when state = WAIT_BUS_RELEASE
        and BUSACK_N = '1'
        else '0';


    --------------------------------------------------------------------
    -- Main FSM
    --------------------------------------------------------------------

    process(CLK, RESET_N)
    begin
        if RESET_N = '0' then

            state       <= IDLE;
            page_reg    <= (others => '0');
            offset_reg  <= (others => '0');
            cycle_count <= 0;

        elsif rising_edge(CLK) then

            case state is

                --------------------------------------------------------
                -- Idle
                --------------------------------------------------------

                when IDLE =>

                    if START = '1' then

                        page_reg   <= PAGE_NUMBER;
                        offset_reg <= (others => '0');

                        cycle_count <= 0;

                        state <= REQUEST_BUS;

                    end if;


                --------------------------------------------------------
                -- BUSREQ assertion
                --------------------------------------------------------

                when REQUEST_BUS =>

                    state <= WAIT_BUSACK;


                --------------------------------------------------------
                -- Wait for Z80 to release bus
                --------------------------------------------------------

                when WAIT_BUSACK =>

                    if BUSACK_N = '0' then

                        state <= WRITE_SETUP;

                    end if;


                --------------------------------------------------------
                -- SRAM address setup
                --------------------------------------------------------

                when WRITE_SETUP =>

                    cycle_count <= 0;

                    state <= WRITE_ACTIVE;


                --------------------------------------------------------
                -- SRAM write pulse
                --------------------------------------------------------

                when WRITE_ACTIVE =>

                    if cycle_count = WRITE_CYCLES-1 then

                        cycle_count <= 0;

                        state <= WRITE_HOLD;

                    else

                        cycle_count <= cycle_count + 1;

                    end if;


                --------------------------------------------------------
                -- Finish current write
                --------------------------------------------------------

                when WRITE_HOLD =>

                    if offset_reg =
                       to_unsigned(8191, OFFSET_WIDTH) then

                        state <= RELEASE_BUS;

                    else

                        offset_reg <= offset_reg + 1;

                        state <= WRITE_SETUP;

                    end if;


                --------------------------------------------------------
                -- Release Z80 bus
                --------------------------------------------------------

                when RELEASE_BUS =>

                    state <= WAIT_BUS_RELEASE;


                --------------------------------------------------------
                -- Wait for Z80 to remove BUSACK
                --------------------------------------------------------

                when WAIT_BUS_RELEASE =>

                    if BUSACK_N = '1' then

                        state <= IDLE;

                    end if;


            end case;

        end if;
    end process;

end architecture;