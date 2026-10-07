library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity cpu_top_level is
    generic (
        FLASH_BASE : natural := 16#60000#;
        IMG_BYTES  : natural := 16384
    );
    port (
        clk_in       : in    std_logic;
        resetn_in    : in    std_logic;

        -- Σήματα Αιτήματος/Έγκρισης για Κοινόχρηστα Περιφερειακά (UART & I2C)
        RV32Master   : out   std_logic;
        RV32Grant    : in    std_logic;

        -- Πολυπλεγμένο UART (NEORV32)
        uart_tx      : out   std_logic;
        uart_rx      : in    std_logic;
        
        -- Gowin I2C master
        i2c_tx_en    : out   std_logic;
        i2c_rx_en    : out   std_logic;
        i2c_addr     : out   std_logic_vector(2 downto 0);
        i2c_wdata    : out   std_logic_vector(7 downto 0);
        i2c_rdata    : in    std_logic_vector(7 downto 0);
        i2c_int      : in    std_logic; 

        -- External parallel memory bus (SRAM και FlashRAM 8-bit)
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

    -- Σήματα εσωτερικού Bus NEORV32 Wishbone
    signal wb_addr     : std_logic_vector(31 downto 0);
    signal wb_data_in  : std_logic_vector(31 downto 0);
    signal wb_data_out : std_logic_vector(31 downto 0);
    signal wb_we       : std_logic;
    signal wb_stb      : std_logic;
    signal wb_cyc      : std_logic;
    signal wb_ack      : std_logic;
    signal bus_active  : std_logic;
    
    -- Έλεγχος Reset & Loader
    signal core_resetn  : std_logic;
    signal loader_done  : std_logic;
    
    -- Εσωτερική 32-bit BSRAM (32KB)
    signal ram_cell_addr : std_logic_vector(12 downto 0);
    signal ram_cell_din  : std_logic_vector(31 downto 0);
    signal ram_cell_wre  : std_logic;
    signal ram_cell_dout : std_logic_vector(31 downto 0);
    signal ram_reset     : std_logic;
    
    -- Σήματα Loader
    signal ld_busreq    : std_logic;
    signal ld_fl_addr   : std_logic_vector(19 downto 0);
    signal ld_fl_ce_n   : std_logic; 
    signal ld_ram_addr  : std_logic_vector(12 downto 0);
    signal ld_ram_din   : std_logic_vector(31 downto 0);
    signal ld_ram_wre   : std_logic;

    -- Προσαρμογή Τύπων NEORV32
    signal u_wb_adr     : std_ulogic_vector(31 downto 0);
    signal u_wb_dat_o   : std_ulogic_vector(31 downto 0);
    signal u_wb_dat_i   : std_ulogic_vector(31 downto 0);
    signal gpio_inputs  : std_ulogic_vector(31 downto 0);
    signal gpio_outputs : std_ulogic_vector(31 downto 0);
    
    signal core_uart_tx : std_logic;

    -- FSM Μετατροπής 32-bit Wishbone σε 8-bit External Bus
    type ext_fsm_type is (
        EXT_IDLE, EXT_REQ_BUS, 
        BYTE0_SETUP, BYTE0_RW,
        BYTE1_SETUP, BYTE1_RW,
        BYTE2_SETUP, BYTE2_RW,
        BYTE3_SETUP, BYTE3_RW,
        EXT_ACK
    );
    signal ext_state  : ext_fsm_type;
    signal ext_buf    : std_logic_vector(31 downto 0);
    signal ext_busreq : std_logic;

begin

    -- Έλεγχος Reset: Ο επεξεργαστής παραμένει σε Reset μέχρι να ολοκληρωθεί η αντιγραφή (loader_done = '1')
    core_resetn <= resetn_in and loader_done;
    DONE        <= loader_done;
    ram_reset   <= not resetn_in;

    wb_addr     <= std_logic_vector(u_wb_adr);
    wb_data_out <= std_logic_vector(u_wb_dat_o);
    u_wb_dat_i  <= std_ulogic_vector(wb_data_in);

    bus_active  <= wb_stb and wb_cyc;
    dbg_cmd     <= wb_addr(9 downto 2);

    -- Διασύνδεση GPIO
    gpio_inputs(7 downto 0)  <= std_ulogic_vector(sCDT_Reg);
    gpio_inputs(31 downto 8) <= (others => '0');
    sCDT_Regout              <= std_logic_vector(gpio_outputs(7 downto 0));

    -- Αίτημα Bus προς Z80 (όταν ο loader αντιγράφει ή ο RV32 προσπελαύνει εξωτερική μνήμη)
    BUSREQ_N <= '0' when (ld_busreq = '1' or ext_busreq = '1') else '1';

    -- Πολυπλεξία γραμμής UART TX: Ενεργοποιείται μόνο όταν δοθεί άδεια (RV32Grant = '1')
    uart_tx <= core_uart_tx when RV32Grant = '1' else 'Z';

    -- -------------------------------------------------------------
    -- 1. INSTANTIATION NEORV32 CORE
    -- -------------------------------------------------------------
    neorv32_core_inst: entity neorv32.neorv32_top
        generic map (
            CLOCK_FREQUENCY  => 50000000, 
            BOOT_MODE_SELECT => 1,             -- Boot από BOOT_ADDR_CUSTOM
            BOOT_ADDR_CUSTOM => x"30000000",   -- Διεύθυνση έναρξης BSRAM
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
            xbus_sel_o  => open, 
            xbus_stb_o  => wb_stb, 
            xbus_cyc_o  => wb_cyc, 
            xbus_ack_i  => wb_ack,
            gpio_i      => gpio_inputs, 
            gpio_o      => gpio_outputs
        );

    -- -------------------------------------------------------------
    -- 2. ΠΟΛΥΠΛΕΞΙΑ & INSTANTIATION ΕΣΩΤΕΡΙΚΗΣ BSRAM (32KB)
    -- -------------------------------------------------------------
    ram_cell_addr <= ld_ram_addr when loader_done = '0' else wb_addr(14 downto 2);
    ram_cell_din  <= ld_ram_din  when loader_done = '0' else wb_data_out;
    ram_cell_wre  <= ld_ram_wre  when loader_done = '0' else 
                     (wb_we and bus_active when wb_addr(31 downto 16) = x"3000" else '0');

    DPVRAM_Inst : entity work.RV32_RAM
        port map (
            dout  => ram_cell_dout, clk => clk_in, oce => '1', ce => '1',
            reset => ram_reset, wre => ram_cell_wre, ad => ram_cell_addr, din => ram_cell_din
        );

    -- -------------------------------------------------------------
    -- 3. ΚΕΝΤΡΙΚΟΣ ΑΠΟΚΩΔΙΚΟΠΟΙΗΤΗΣ & SEQUENCER ΕΞΩΤΕΡΙΚΟΥ BUS
    -- Χάρτης Διευθύνσεων:
    --   0x30000000 - 0x30007FFF : Εσωτερική BSRAM 32-bit (32KB)
    --   0x40000000 - 0x400FFFFF : Εξωτερική SRAM / Flash 8-bit (1MB)
    --   0x50000000 - 0x500000FF : Κοινόχρηστα Περιφερειακά (I2C / UART control)
    -- -------------------------------------------------------------
    process(clk_in, resetn_in)
        variable addr_base : unsigned(19 downto 0);
    begin
        if resetn_in = '0' then
            wb_ack     <= '0';
            RV32Master <= '0';
            i2c_tx_en  <= '0';
            i2c_rx_en  <= '0';
            i2c_addr   <= (others => '0');
            i2c_wdata  <= (others => '0');
            wb_data_in <= (others => '0');
            
            ext_state  <= EXT_IDLE;
            ext_busreq <= '0';
            sram_ce_n  <= '1';
            sram_oe_n  <= '1';
            sram_we_n  <= '1';
            sram_addr  <= (others => '0');
            sram_dq    <= (others => 'Z');
            ext_buf    <= (others => '0');
            
        elsif rising_edge(clk_in) then
            wb_ack    <= '0';
            i2c_tx_en <= '0';
            i2c_rx_en <= '0';

            if loader_done = '0' then
                -- Ο Loader ελέγχει απευθείας τα pins της Flash
                sram_addr <= ld_fl_addr;
                sram_ce_n <= ld_fl_ce_n;
                sram_oe_n <= '0';
                sram_we_n <= '1';
                sram_dq   <= (others => 'Z');
            else
                addr_base := unsigned(wb_addr(19 downto 0));

                -- Επαναφορά του αίτηματος Master όταν το bus είναι ανενεργό
                if bus_active = '0' or wb_addr(31 downto 24) /= x"50" then
                    RV32Master <= '0';
                end if;

                sram_oe_n <= '1';
                sram_we_n <= '1';

                case ext_state is
                    
                    ----------------------------------------------------
                    -- IDLE: Αποκωδικοποίηση Περιοχής Διευθύνσεων
                    ----------------------------------------------------
                    when EXT_IDLE =>
                        sram_ce_n  <= '1';
                        sram_dq    <= (others => 'Z');
                        ext_busreq <= '0';

                        if bus_active = '1' then
                            
                            -- Περιοχή A: Εσωτερική BSRAM 32-bit (0x3000XXXX)
                            if wb_addr(31 downto 16) = x"3000" then
                                wb_data_in <= ram_cell_dout;
                                wb_ack     <= '1';

                            -- Περιοχή B: Κοινόχρηστα Περιφερειακά I2C / UART (0x5000XXXX)
                            elsif wb_addr(31 downto 24) = x"50" then
                                RV32Master <= '1'; -- Αίτημα πρόσβασης από το σύστημα
                                if RV32Grant = '1' then
                                    i2c_addr <= wb_addr(2 downto 0);
                                    if wb_we = '1' then
                                        i2c_tx_en <= '1';
                                        i2c_wdata <= wb_data_out(7 downto 0);
                                    else
                                        i2c_rx_en  <= '1';
                                        wb_data_in <= x"000000" & i2c_rdata;
                                    end if;
                                    wb_ack <= '1';
                                end if;

                            -- Περιοχή C: Εξωτερική 8-bit SRAM/Flash (0x4000XXXX)
                            elsif wb_addr(31 downto 20) = x"400" then
                                ext_busreq <= '1';
                                ext_state  <= EXT_REQ_BUS;
                            end if;
                        end if;

                    ----------------------------------------------------
                    -- Αναμονή για Παραχώρηση Bus από τον Z80 (BUSACK_N = '0')
                    ----------------------------------------------------
                    when EXT_REQ_BUS =>
                        if BUSACK_N = '0' then
                            sram_ce_n <= '0';
                            ext_state <= BYTE0_SETUP;
                        end if;

                    ----------------------------------------------------
                    -- BYTE 0 (Bits 7..0)
                    ----------------------------------------------------
                    when BYTE0_SETUP =>
                        sram_addr <= std_logic_vector(addr_base);
                        if wb_we = '1' then
                            sram_dq   <= wb_data_out(7 downto 0);
                            sram_we_n <= '0';
                        else
                            sram_oe_n <= '0';
                        end if;
                        ext_state <= BYTE0_RW;

                    when BYTE0_RW =>
                        if wb_we = '0' then
                            ext_buf(7 downto 0) <= sram_dq;
                        end if;
                        ext_state <= BYTE1_SETUP;

                    ----------------------------------------------------
                    -- BYTE 1 (Bits 15..8)
                    ----------------------------------------------------
                    when BYTE1_SETUP =>
                        sram_addr <= std_logic_vector(addr_base + 1);
                        if wb_we = '1' then
                            sram_dq   <= wb_data_out(15 downto 8);
                            sram_we_n <= '0';
                        else
                            sram_oe_n <= '0';
                        end if;
                        ext_state <= BYTE1_RW;

                    when BYTE1_RW =>
                        if wb_we = '0' then
                            ext_buf(15 downto 8) <= sram_dq;
                        end if;
                        ext_state <= BYTE2_SETUP;

                    ----------------------------------------------------
                    -- BYTE 2 (Bits 23..16)
                    ----------------------------------------------------
                    when BYTE2_SETUP =>
                        sram_addr <= std_logic_vector(addr_base + 2);
                        if wb_we = '1' then
                            sram_dq   <= wb_data_out(23 downto 16);
                            sram_we_n <= '0';
                        else
                            sram_oe_n <= '0';
                        end if;
                        ext_state <= BYTE2_RW;

                    when BYTE2_RW =>
                        if wb_we = '0' then
                            ext_buf(23 downto 16) <= sram_dq;
                        end if;
                        ext_state <= BYTE3_SETUP;

                    ----------------------------------------------------
                    -- BYTE 3 (Bits 31..24)
                    ----------------------------------------------------
                    when BYTE3_SETUP =>
                        sram_addr <= std_logic_vector(addr_base + 3);
                        if wb_we = '1' then
                            sram_dq   <= wb_data_out(31 downto 24);
                            sram_we_n <= '0';
                        else
                            sram_oe_n <= '0';
                        end if;
                        ext_state <= BYTE3_RW;

                    when BYTE3_RW =>
                        if wb_we = '0' then
                            ext_buf(31 downto 24) <= sram_dq;
                        end if;
                        ext_state <= EXT_ACK;

                    ----------------------------------------------------
                    -- Ολοκλήρωση Κύκλου Wishbone
                    ----------------------------------------------------
                    when EXT_ACK =>
                        sram_ce_n  <= '1';
                        sram_dq    <= (others => 'Z');
                        wb_data_in <= ext_buf;
                        wb_ack     <= '1';
                        ext_busreq <= '0';
                        ext_state  <= EXT_IDLE;

                end case;
            end if;
        end if;
    end process;

    -- Instantiation του Hardware Boot Loader
    u_loader: entity work.flash_to_ram_loader
        generic map ( FLASH_BASE => FLASH_BASE, IMG_BYTES => IMG_BYTES )
        port map (
            clk      => clk_in, 
            resetn   => resetn_in, 
            start    => START, 
            done     => loader_done,
            busreq   => ld_busreq, 
            busgrant => '1', 
            busack_n => BUSACK_N,
            fl_addr  => ld_fl_addr, 
            fl_dq_i  => sram_dq, 
            fl_ce_n  => ld_fl_ce_n,
            ram_addr => ld_ram_addr, 
            ram_din  => ld_ram_din, 
            ram_wre  => ld_ram_wre
        );

end architecture rtl;