library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity cpu_top_level is
    generic (
        FLASH_BASE   : natural := 16#60000#;
        IMG_BYTES    : natural := 16384;
        -- Gowin BSRAM read mode of RV32_RAM:
        --   false = bypass (non-registered output)  -> data valid 1 cycle after address
        --   true  = pipeline (registered output)    -> data valid 2 cycles after address
        RAM_PIPELINE : boolean := false;
        -- false = original behaviour: addr/ce/oe/we are always driven by this module
        -- true  = release them to 'Z' while the Z80 owns the bus (BUSACK_N = '1')
        TRISTATE_EXT_BUS : boolean := false
    );
    port (
        clk_in       : in    std_logic;
        resetn_in    : in    std_logic;

        -- Request / grant for the shared peripherals (UART & I2C)
        RV32Master   : out   std_logic;
        RV32Grant    : in    std_logic;

        -- Multiplexed UART (NEORV32)
        uart_tx      : out   std_logic;
        uart_rx      : in    std_logic;

        -- Gowin I2C master
        i2c_tx_en    : out   std_logic;
        i2c_rx_en    : out   std_logic;
        i2c_addr     : out   std_logic_vector(2 downto 0);
        i2c_wdata    : out   std_logic_vector(7 downto 0);
        i2c_rdata    : in    std_logic_vector(7 downto 0);
        i2c_int      : in    std_logic;

        -- External parallel memory bus (8-bit SRAM and Flash), shared with the Z80
        -- NOTE: all lines go Hi-Z whenever the Z80 owns the bus (BUSACK_N = '1').
        --       CE#/OE#/WE# need external pull-ups.
        sram_addr    : out   std_logic_vector(19 downto 0);
        sram_dq      : inout std_logic_vector(7 downto 0);
        sram_ce_n    : out   std_logic;
        sram_oe_n    : out   std_logic;
        sram_we_n    : out   std_logic;

        -- Boot control
        START        : in    std_logic;
        DONE         : out   std_logic;

        -- Z80 bus arbitration
        BUSACK_N     : in    std_logic;
        BUSREQ_N     : out   std_logic;

        -- FPGA control registers (GPIO)
        sCDT_Reg     : in    std_logic_vector(7 downto 0);
        sCDT_Regout  : out   std_logic_vector(7 downto 0);

        dbg_cmd      : out   std_logic_vector(7 downto 0)
    );
end entity cpu_top_level;

architecture rtl of cpu_top_level is

    -- NEORV32 external bus (Wishbone-like)
    signal wb_addr     : std_logic_vector(31 downto 0);
    signal wb_data_in  : std_logic_vector(31 downto 0);
    signal wb_data_out : std_logic_vector(31 downto 0);
    signal wb_sel      : std_logic_vector(3 downto 0);
    signal wb_we       : std_logic;
    signal wb_stb      : std_logic;
    signal wb_cyc      : std_logic;
    signal wb_ack      : std_logic;
    signal bus_active  : std_logic;

    -- Address decode
    signal sel_ram     : std_logic;   -- 0x30000000 - 0x30007FFF (32 KB BSRAM)
    signal sel_ext     : std_logic;   -- 0x40000000 - 0x400FFFFF (1 MB ext. 8-bit SRAM/Flash)
    signal sel_per     : std_logic;   -- 0x50000000 - 0x50FFFFFF (shared I2C / UART regs)

    -- Reset & loader
    signal core_resetn : std_logic;
    signal loader_done : std_logic;

    -- Internal 32-bit BSRAM (32 KB = 8192 words)
    signal ram_cell_addr : std_logic_vector(12 downto 0);
    signal ram_cell_din  : std_logic_vector(31 downto 0);
    signal ram_cell_wre  : std_logic;
    signal ram_cell_dout : std_logic_vector(31 downto 0);
    signal ram_merged    : std_logic_vector(31 downto 0);
    signal ram_reset     : std_logic;

    -- Loader
    signal ld_busreq    : std_logic;
    signal ld_fl_addr   : std_logic_vector(19 downto 0);
    signal ld_fl_ce_n   : std_logic;
    signal ld_ram_addr  : std_logic_vector(12 downto 0);
    signal ld_ram_din   : std_logic_vector(31 downto 0);
    signal ld_ram_wre   : std_logic;

    -- NEORV32 type adaptation
    signal u_wb_adr     : std_ulogic_vector(31 downto 0);
    signal u_wb_dat_o   : std_ulogic_vector(31 downto 0);
    signal u_wb_dat_i   : std_ulogic_vector(31 downto 0);
    signal u_wb_sel     : std_ulogic_vector(3 downto 0);
    signal gpio_inputs  : std_ulogic_vector(31 downto 0);
    signal gpio_outputs : std_ulogic_vector(31 downto 0);

    signal core_uart_tx : std_logic;

    -- Z80 bus handshake
    signal busack_s     : std_logic_vector(1 downto 0);  -- 2-FF synchronizer
    signal busack_n_s   : std_logic;
    signal bus_own      : std_logic;                     -- FPGA may drive the external bus

    -- External bus output registers (gated to Hi-Z when the Z80 owns the bus)
    signal sram_addr_r  : std_logic_vector(19 downto 0);
    signal sram_ce_n_r  : std_logic;
    signal sram_oe_n_r  : std_logic;
    signal sram_we_n_r  : std_logic;
    signal dq_o         : std_logic_vector(7 downto 0);
    signal dq_oe        : std_logic;

    type ext_fsm_type is (
        EXT_IDLE,
        RAM_WAIT, RAM_RDY,                    -- internal BSRAM
        PER_REQ, PER_STB, PER_DATA,           -- shared peripherals
        EXT_REQ_BUS,                          -- wait for Z80 bus grant
        EXT_SETUP, EXT_STROBE, EXT_HOLD,      -- one byte of external memory
        EXT_ACK
    );
    signal ext_state  : ext_fsm_type;
    signal ext_idx    : integer range 0 to 3;
    signal ext_buf    : std_logic_vector(31 downto 0);
    signal ext_busreq : std_logic;
    signal master_hold : std_logic;   -- software-controlled RV32Master request

begin

    ---------------------------------------------------------------------------
    -- Reset / misc glue
    ---------------------------------------------------------------------------
    core_resetn <= resetn_in and loader_done;
    DONE        <= loader_done;
    ram_reset   <= not resetn_in;

    wb_addr     <= std_logic_vector(u_wb_adr);
    wb_data_out <= std_logic_vector(u_wb_dat_o);
    wb_sel      <= std_logic_vector(u_wb_sel);
    u_wb_dat_i  <= std_ulogic_vector(wb_data_in);

    bus_active  <= wb_stb and wb_cyc;
    dbg_cmd     <= wb_addr(9 downto 2);

    gpio_inputs(7 downto 0)  <= std_ulogic_vector(sCDT_Reg);
    gpio_inputs(31 downto 8) <= (others => '0');
    sCDT_Regout              <= std_logic_vector(gpio_outputs(7 downto 0));

    -- Address decode (exact 32 KB window for the BSRAM, no aliasing)
    sel_ram <= '1' when wb_addr(31 downto 15) = "00110000000000000" else '0';
    sel_ext <= '1' when wb_addr(31 downto 20) = x"400"             else '0';
    sel_per <= '1' when wb_addr(31 downto 24) = x"50"              else '0';

    -- Bus request towards the Z80 (loader copy or RV32 external access)
    BUSREQ_N <= '0' when (ld_busreq = '1' or ext_busreq = '1') else '1';

    -- Shared UART TX line: only driven while granted
    uart_tx <= core_uart_tx;-- when RV32Grant = '1' else 'Z';

    ---------------------------------------------------------------------------
    -- External bus pins: driven only while the Z80 has released the bus
    ---------------------------------------------------------------------------
    busack_n_s <= busack_s(1);
    bus_own    <= not busack_n_s;

    gen_tri: if TRISTATE_EXT_BUS generate
        sram_addr <= sram_addr_r when bus_own = '1' else (others => 'Z');
        sram_ce_n <= sram_ce_n_r when bus_own = '1' else 'Z';
        sram_oe_n <= sram_oe_n_r when bus_own = '1' else 'Z';
        sram_we_n <= sram_we_n_r when bus_own = '1' else 'Z';
        sram_dq   <= dq_o        when (bus_own = '1' and dq_oe = '1') else (others => 'Z');
    end generate;

    gen_drv: if not TRISTATE_EXT_BUS generate
        sram_addr <= sram_addr_r;
        sram_ce_n <= sram_ce_n_r;
        sram_oe_n <= sram_oe_n_r;
        sram_we_n <= sram_we_n_r;
        sram_dq   <= dq_o when dq_oe = '1' else (others => 'Z');
    end generate;

    ---------------------------------------------------------------------------
    -- 1. NEORV32 core
    ---------------------------------------------------------------------------
    neorv32_core_inst: entity neorv32.neorv32_top
        generic map (
            CLOCK_FREQUENCY  => 50000000,
            BOOT_MODE_SELECT => 1,
            BOOT_ADDR_CUSTOM => x"30000000",
            RISCV_ISA_C      => false,
            RISCV_ISA_M      => false,
            RISCV_ISA_Zicntr => true,
            IMEM_EN          => false,
            DMEM_EN          => false,
            XBUS_EN          => true,
            XBUS_TIMEOUT     => 0,
            IO_GPIO_NUM      => 8,
            IO_UART0_EN      => true
        )
        port map (
            clk_i       => std_ulogic(clk_in),
            rstn_i      => std_ulogic(core_resetn),
            uart0_txd_o => core_uart_tx,
            uart0_rxd_i => uart_rx,
            xbus_adr_o  => u_wb_adr,
            xbus_dat_i  => u_wb_dat_i,
            xbus_dat_o  => u_wb_dat_o,
            xbus_we_o   => wb_we,
            xbus_sel_o  => u_wb_sel,
            xbus_stb_o  => wb_stb,
            xbus_cyc_o  => wb_cyc,
            xbus_ack_i  => wb_ack,
            gpio_i      => gpio_inputs,
            gpio_o      => gpio_outputs
        );

    ---------------------------------------------------------------------------
    -- 2. Internal BSRAM (32 KB)
    --
    -- The RAM IP has no byte enables, so sub-word stores are done as
    -- read-modify-write: the word is read in the first cycle, merged with the
    -- new bytes (wb_sel) and written back in the cycle where dout is valid.
    ---------------------------------------------------------------------------
    gen_merge: for i in 0 to 3 generate
        ram_merged(8*i+7 downto 8*i) <= wb_data_out(8*i+7 downto 8*i) when wb_sel(i) = '1'
                                        else ram_cell_dout(8*i+7 downto 8*i);
    end generate;

    ram_cell_addr <= ld_ram_addr when loader_done = '0' else wb_addr(14 downto 2);
    ram_cell_din  <= ld_ram_din  when loader_done = '0' else ram_merged;
    -- single-cycle write pulse, issued from the state machine (never from bus_active)
    ram_cell_wre  <= ld_ram_wre  when loader_done = '0' else
                     '1' when (ext_state = RAM_RDY and wb_we = '1') else '0';

    RVRAM_Inst : entity work.RV32_RAM
        port map (
            dout  => ram_cell_dout,
            clk   => clk_in,
            oce   => '1',
            ce    => '1',
            reset => ram_reset,
            wre   => ram_cell_wre,
            ad    => ram_cell_addr,
            din   => ram_cell_din
        );

    ---------------------------------------------------------------------------
    -- 3. Bus sequencer
    --   0x30000000 - 0x30007FFF : internal BSRAM 32-bit (32 KB)
    --   0x40000000 - 0x400FFFFF : external SRAM / Flash 8-bit (1 MB)
    --   0x50000000 - 0x50FFFFFF : shared peripherals (I2C / UART), byte registers
    --                             addressed by wb_addr(2 downto 0). Use byte
    --                             accesses (lb/sb) from software.
    --   anything else           : acknowledged with zero data (no bus hang)
    ---------------------------------------------------------------------------
    process(clk_in, resetn_in)
        variable base : unsigned(19 downto 0);
    begin
        if resetn_in = '0' then
            busack_s    <= (others => '1');
            wb_ack      <= '0';
            wb_data_in  <= (others => '0');
            RV32Master  <= '0';
            master_hold <= '0';
            i2c_tx_en   <= '0';
            i2c_rx_en   <= '0';
            i2c_addr    <= (others => '0');
            i2c_wdata   <= (others => '0');

            ext_state   <= EXT_IDLE;
            ext_idx     <= 0;
            ext_busreq  <= '0';
            ext_buf     <= (others => '0');
            sram_addr_r <= (others => '0');
            sram_ce_n_r <= '1';
            sram_oe_n_r <= '1';
            sram_we_n_r <= '1';
            dq_o        <= (others => '0');
            dq_oe       <= '0';

        elsif rising_edge(clk_in) then
            busack_s  <= busack_s(0) & BUSACK_N;

            -- single-cycle defaults
            wb_ack      <= '0';
            i2c_tx_en   <= '0';
            i2c_rx_en   <= '0';
            sram_oe_n_r <= '1';
            sram_we_n_r <= '1';

            if loader_done = '0' then
                -- Loader drives the Flash pins
                sram_addr_r <= ld_fl_addr;
                sram_ce_n_r <= ld_fl_ce_n;
                sram_oe_n_r <= '0';
                dq_oe       <= '0';
                ext_state   <= EXT_IDLE;
            else
                -- word aligned base address; byte lanes are selected with ext_idx
                base := unsigned(wb_addr(19 downto 2)) & "00";

                case ext_state is

                    -----------------------------------------------------
                    -- IDLE: decode. A new access is only accepted when
                    -- wb_ack = '0', otherwise the access that was just
                    -- acknowledged (stb still high) would be repeated.
                    -----------------------------------------------------
                    when EXT_IDLE =>
                        sram_ce_n_r <= '1';
                        dq_oe       <= '0';
                        ext_idx     <= 0;
                        ext_buf     <= (others => '0');

                        -- keep the Z80 bus for back-to-back external accesses
                        if wb_ack = '0' then
                            ext_busreq <= '0';
                        end if;

                        -- RV32Master stays high as long as the CPU is on the
                        -- peripheral region (covers the whole access + ack cycle)
                        if not (bus_active = '1' and sel_per = '1') and master_hold = '0' then
                            RV32Master <= '0';
                        end if;

                        if bus_active = '1' and wb_ack = '0' then
                            if sel_ram = '1' then
                                if RAM_PIPELINE then
                                    ext_state <= RAM_WAIT;
                                else
                                    ext_state <= RAM_RDY;
                                end if;

                            elsif sel_per = '1' and wb_addr(4) = '1' then
                                -- Local control register 0x50000010 (no peripheral access)
                                --   write bit0 = 1 : request shared peripherals (hold RV32Master)
                                --   write bit0 = 0 : release them
                                --   read  bit0 = hold, bit1 = RV32Grant
                                if wb_we = '1' then
                                    master_hold <= wb_data_out(0);
                                    RV32Master  <= wb_data_out(0);
                                end if;
                                wb_data_in <= x"000000" & "000000" & RV32Grant & master_hold;
                                wb_ack     <= '1';

                            elsif sel_per = '1' then
                                RV32Master <= '1';
                                ext_state  <= PER_REQ;

                            elsif sel_ext = '1' then
                                ext_busreq <= '1';
                                ext_state  <= EXT_REQ_BUS;

                            else
                                wb_data_in <= (others => '0');
                                wb_ack     <= '1';
                            end if;
                        end if;

                    -----------------------------------------------------
                    -- Internal BSRAM
                    -----------------------------------------------------
                    when RAM_WAIT =>
                        ext_state <= RAM_RDY;

                    when RAM_RDY =>
                        -- dout is valid now; ram_cell_wre is high here for stores
                        wb_data_in <= ram_cell_dout;
                        wb_ack     <= '1';
                        ext_state  <= EXT_IDLE;

                    -----------------------------------------------------
                    -- Shared peripherals. RV32Master is held high from the
                    -- decode until the CPU leaves the region.
                    -----------------------------------------------------
                    when PER_REQ =>
                        if RV32Grant = '1' then
                            i2c_addr  <= wb_addr(2 downto 0);
                            i2c_wdata <= wb_data_out(7 downto 0);  -- sb replicates the byte
                            if wb_we = '1' then
                                i2c_tx_en <= '1';
                            else
                                i2c_rx_en <= '1';
                            end if;
                            ext_state <= PER_STB;
                        end if;

                    when PER_STB =>
                        -- strobe is visible to the peripheral during this cycle
                        ext_state <= PER_DATA;

                    when PER_DATA =>
                        -- replicate to all lanes so lb/lbu works for any addr(1:0)
                        wb_data_in <= i2c_rdata & i2c_rdata & i2c_rdata & i2c_rdata;
                        wb_ack     <= '1';
                        ext_state  <= EXT_IDLE;

                    -----------------------------------------------------
                    -- External memory: wait for the Z80 to release the bus
                    -----------------------------------------------------
                    when EXT_REQ_BUS =>
                        if busack_n_s = '0' then
                            sram_ce_n_r <= '0';
                            ext_state   <= EXT_SETUP;
                        end if;

                    -- SETUP: address (and write data) out, WE#/OE# still high
                    when EXT_SETUP =>
                        if wb_sel(ext_idx) = '0' then
                            -- lane not selected: skip
                            if ext_idx = 3 then
                                ext_state <= EXT_ACK;
                            else
                                ext_idx <= ext_idx + 1;
                            end if;
                        else
                            sram_addr_r <= std_logic_vector(base + to_unsigned(ext_idx, 20));
                            sram_ce_n_r <= '0';
                            if wb_we = '1' then
                                for i in 0 to 3 loop
                                    if i = ext_idx then
                                        dq_o <= wb_data_out(8*i+7 downto 8*i);
                                    end if;
                                end loop;
                                dq_oe <= '1';
                            else
                                dq_oe <= '0';
                            end if;
                            ext_state <= EXT_STROBE;
                        end if;

                    -- STROBE: WE# or OE# goes low (visible during the next cycle)
                    when EXT_STROBE =>
                        if wb_we = '1' then
                            sram_we_n_r <= '0';
                        else
                            sram_oe_n_r <= '0';
                        end if;
                        ext_state <= EXT_HOLD;

                    -- HOLD: WE#/OE# low now. Read data is sampled at the end of
                    -- this cycle; WE# rises with this edge, data/address are
                    -- held for one more cycle.
                    when EXT_HOLD =>
                        if wb_we = '0' then
                            for i in 0 to 3 loop
                                if i = ext_idx then
                                    ext_buf(8*i+7 downto 8*i) <= sram_dq;
                                end if;
                            end loop;
                        end if;
                        if ext_idx = 3 then
                            ext_state <= EXT_ACK;
                        else
                            ext_idx   <= ext_idx + 1;
                            ext_state <= EXT_SETUP;
                        end if;

                    when EXT_ACK =>
                        sram_ce_n_r <= '1';
                        dq_oe       <= '0';
                        wb_data_in  <= ext_buf;
                        wb_ack      <= '1';
                        ext_state   <= EXT_IDLE;
                        -- ext_busreq is released in IDLE unless a new external
                        -- access follows immediately

                end case;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Hardware boot loader (Flash -> BSRAM)
    ---------------------------------------------------------------------------
    u_loader: entity work.flash_to_ram_loader
        generic map ( FLASH_BASE => FLASH_BASE, IMG_BYTES => IMG_BYTES )
        port map (
            clk      => clk_in,
            resetn   => resetn_in,
            start    => START,
            done     => loader_done,
            busreq   => ld_busreq,
            busgrant => '1',
            busack_n => busack_n_s,
            fl_addr  => ld_fl_addr,
            fl_dq_i  => sram_dq,
            fl_ce_n  => ld_fl_ce_n,
            ram_addr => ld_ram_addr,
            ram_din  => ld_ram_din,
            ram_wre  => ld_ram_wre
        );

end architecture rtl;