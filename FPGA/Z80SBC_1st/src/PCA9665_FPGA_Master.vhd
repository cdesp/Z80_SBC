-- pca9665_fpga_master.vhd
-- Controls bus arbitration (BUSRQ/BUSAK) and generates the precise control signals 
-- for the PCA9665 registers when the FPGA is bus master.

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity PCA9665_FPGA_Master is
    port (
        -- Global
        CLK             : in  std_logic;                                -- Z80 Clock
        nRESET          : in  std_logic;

        -- Bus Arbitration Interface
        BUSRQ_N_O       : out std_logic;                                -- Bus Request to Z80 (Active Low)
        BUSAK_N_I       : in  std_logic;                                -- Bus Acknowledge from Z80 (Active Low)

        -- FPGA Internal Command Interface (Start I2C Operation)
        CMD_START_I     : in  std_logic;                                -- Asserted high to start an I2C command
        CMD_REG_ADDR_I  : in  std_logic_vector(1 downto 0);             -- A1, A0 register address
        CMD_RW_I        : in  std_logic;                                -- '1' for Read, '0' for Write
        CMD_DATA_W_I    : in  std_logic_vector(7 downto 0);             -- Data to write
        CMD_DONE_O      : out std_logic;                                -- Pulse high for one cycle when command is complete
        CMD_DATA_R_O    : out std_logic_vector(7 downto 0);             -- NEW: Data read back from the PCA9665

        -- Z80 Data Bus Interface
        D_IN_I          : in  std_logic_vector(7 downto 0);             -- Data read from Z80 bus
        D_OUT_O         : out std_logic_vector(7 downto 0);             -- Data to drive onto Z80 bus
        D_OE_O          : out std_logic;                                -- Data Bus Output Enable ('1' to drive D_OUT_O)

        -- PCA9665 Control Signal Outputs (To be multiplexed by Arbiter)
        MASTER_ACTIVE_O : out std_logic;                                -- '1' when FPGA is master and driving controls
        DEV_CBA_O       : out std_logic_vector(2 downto 0);             -- DEV2, DEV1, DEV0 (LS138 Inputs)
        A0_O            : out std_logic;                                -- PCA9665 A0
        A1_O            : out std_logic;                                -- PCA9665 A1
        WR_N_O          : out std_logic;                                -- PCA9665 Write Strobe (Active Low)
        RD_N_O          : out std_logic                                 -- FPGA_I2CRD (Active Low)
    );
end entity PCA9665_FPGA_Master;

architecture BEHAVIORAL of PCA9665_FPGA_Master is
    -- States for the Arbitration/Command FSM
    type state_type is (S_IDLE, S_BUS_REQUEST, S_WAIT_GRANT, S_DRIVE_CONTROL, S_WAIT_STROBE, S_CAPTURE_DATA, S_FINISH_CMD);
    signal current_state : state_type;

    -- Constants for 74LS138 Decoding
    constant C_I2CSEL_CBA : std_logic_vector(2 downto 0) := "110"; -- Y6 (Pin 9: $LI2CSEL)
    constant C_FPGA_RD_CBA: std_logic_vector(2 downto 0) := "001"; -- Y1 (Pin 14: $FPGA_I2CRD)

    -- Internal Signals for Pulsing
    signal s_dev_cba     : std_logic_vector(2 downto 0);
    signal s_a0, s_a1    : std_logic;
    signal s_wr_n, s_rd_n: std_logic;
    signal s_busrq_n     : std_logic := '1'; -- Default inactive
    signal s_master_active : std_logic := '0';
    signal s_cmd_done    : std_logic := '0'; -- Internal done signal
    signal s_read_data   : std_logic_vector(7 downto 0) := (others => '0'); -- Captured data

begin

    -- Output Assignments
    BUSRQ_N_O       <= s_busrq_n;
    MASTER_ACTIVE_O <= s_master_active;
    DEV_CBA_O       <= s_dev_cba;
    A0_O            <= s_a0;
    A1_O            <= s_a1;
    WR_N_O          <= s_wr_n;
    RD_N_O          <= s_rd_n;
    D_OUT_O         <= CMD_DATA_W_I; -- Data is prepared for output
    CMD_DONE_O      <= s_cmd_done;
    CMD_DATA_R_O    <= s_read_data; -- output the captured data

    PROCESS (CLK, nRESET)
    BEGIN
        IF nRESET = '0' THEN
            current_state   <= S_IDLE;
            s_busrq_n       <= '1';
            s_master_active <= '0';
            s_dev_cba       <= "000";
            s_wr_n          <= '1';
            s_rd_n          <= '1';
            D_OE_O          <= '0';
            s_cmd_done      <= '0';
            s_read_data     <= (others => '0');
        ELSIF rising_edge(CLK) THEN
            -- Defaults: Inactive
            s_wr_n      <= '1';
            s_rd_n      <= '1';
            D_OE_O      <= '0'; -- Tristate data bus by default
            s_cmd_done  <= '0'; 

            CASE current_state IS
                WHEN S_IDLE =>
                    s_master_active <= '0';
                    s_busrq_n       <= '1';
                    IF CMD_START_I = '1' THEN
                        current_state <= S_BUS_REQUEST;
                    END IF;

                WHEN S_BUS_REQUEST =>
                    s_busrq_n     <= '0';
                    current_state <= S_WAIT_GRANT;

                WHEN S_WAIT_GRANT =>
                    IF BUSAK_N_I = '0' THEN
                        s_master_active <= '1';
                        current_state   <= S_DRIVE_CONTROL;
                    END IF;

                WHEN S_DRIVE_CONTROL =>
                    s_a0 <= CMD_REG_ADDR_I(0);
                    s_a1 <= CMD_REG_ADDR_I(1);
                    
                    IF CMD_RW_I = '0' THEN -- WRITE Cycle
                        s_dev_cba <= C_I2CSEL_CBA; 
                        D_OE_O <= '1'; -- Drive Data
                        current_state <= S_WAIT_STROBE;
                    ELSE -- READ Cycle
                        s_dev_cba <= C_FPGA_RD_CBA; 
                        D_OE_O <= '0'; -- Data Bus is Input
                        current_state <= S_WAIT_STROBE;
                    END IF;

                WHEN S_WAIT_STROBE =>
                    -- Assert the control strobe for one clock cycle
                    IF CMD_RW_I = '0' THEN
                        s_wr_n <= '0'; -- Active Low Write Pulse
                        current_state <= S_FINISH_CMD; -- Write completes faster
                    ELSE
                        s_rd_n <= '0'; -- Active Low Read Pulse
                        current_state <= S_CAPTURE_DATA; -- Read requires data capture
                    END IF;

                WHEN S_CAPTURE_DATA =>
                    -- Capture data from the bus after the read strobe has been asserted
                    s_read_data <= D_IN_I;
                    current_state <= S_FINISH_CMD;

                WHEN S_FINISH_CMD =>
                    s_busrq_n     <= '1'; 
                    s_master_active <= '0';
                    s_dev_cba     <= "000";
                    s_cmd_done    <= '1'; 
                    current_state <= S_IDLE; 
            END CASE;
        END IF;
    END PROCESS;

end architecture BEHAVIORAL;