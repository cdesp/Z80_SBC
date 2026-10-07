library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity flash_to_ram_loader is
    generic (
        FLASH_BASE : natural := 16#60000#;
        IMG_BYTES  : natural := 16384 -- 16KB κώδικα = 4096 λέξεις των 32-bit
    );
    port (
        clk        : in  std_logic;
        resetn     : in  std_logic;
        start      : in  std_logic;
        done       : out std_logic;
        
        -- Σύνδεση με το Z80/System Arbitration
        busreq     : out std_logic;
        busgrant   : in  std_logic;
        busack_n   : in  std_logic;
        
        -- Έλεγχος Parallel FlashRAM
        fl_addr    : out std_logic_vector(19 downto 0);
        fl_dq_i    : in  std_logic_vector(7 downto 0);
        fl_ce_n    : out std_logic; 
        
        -- Έλεγχος Εσωτερικής RAM 32-bit (8K x 32)
        ram_addr   : out std_logic_vector(12 downto 0);
        ram_din    : out std_logic_vector(31 downto 0);
        ram_wre    : out std_logic
    );
end entity flash_to_ram_loader;

architecture rtl of flash_to_ram_loader is
    type state_type is (
        IDLE, REQ_BUS, 
        SETUP_B0, WAIT_B0, READ_B0,
        SETUP_B1, WAIT_B1, READ_B1,
        SETUP_B2, WAIT_B2, READ_B2,
        SETUP_B3, WAIT_B3, READ_B3,
        WRITE_WORD, NEXT_WORD, FINISH
    );
    signal state : state_type;
    
    signal word_counter   : unsigned(12 downto 0);
    signal flash_addr_reg : unsigned(19 downto 0);
    signal wait_cnt       : integer range 0 to 7;
    signal word_buffer    : std_logic_vector(31 downto 0);
begin

    process(clk, resetn)
    begin
        if resetn = '0' then
            state          <= IDLE;
            word_counter   <= (others => '0');
            flash_addr_reg <= to_unsigned(FLASH_BASE, 20);
            busreq         <= '0';
            ram_wre        <= '0';
            done           <= '0';
            fl_addr        <= (others => '0');
            ram_addr       <= (others => '0');
            ram_din        <= (others => '0');
            fl_ce_n        <= '1';
            wait_cnt       <= 0;
            word_buffer    <= (others => '0');
        elsif rising_edge(clk) then
            ram_wre <= '0'; -- Default κατάσταση εγγραφής
            
            case state is
                when IDLE =>
                    done    <= '0';
                    fl_ce_n <= '1';
                    if start = '1' then
                        word_counter   <= (others => '0');
                        flash_addr_reg <= to_unsigned(FLASH_BASE, 20);
                        busreq         <= '1'; -- Ζητάμε το bus από το σύστημα
                        state          <= REQ_BUS;
                    end if;
                    
                when REQ_BUS =>
                    fl_ce_n <= '1';
                    if busgrant = '1' and busack_n = '0' then
                        state <= SETUP_B0;
                    end if;

                -- === ΑΝΑΓΝΩΣΗ BYTE 0 (Bits 7 downto 0) ===
                when SETUP_B0 =>
                    fl_addr  <= std_logic_vector(flash_addr_reg);
                    fl_ce_n  <= '0';
                    wait_cnt <= 0;
                    state    <= WAIT_B0;
                    
                when WAIT_B0 =>
                    if wait_cnt = 4 then
                        state <= READ_B0;
                    else
                        wait_cnt <= wait_cnt + 1;
                    end if;
                    
                when READ_B0 =>
                    word_buffer(7 downto 0) <= fl_dq_i;
                    flash_addr_reg         <= flash_addr_reg + 1;
                    fl_ce_n                <= '1'; -- Κλείνουμε τη Flash για 1 κύκλο
                    state                  <= SETUP_B1;

                -- === ΑΝΑΓΝΩΣΗ BYTE 1 (Bits 15 downto 8) ===
                when SETUP_B1 =>
                    fl_addr  <= std_logic_vector(flash_addr_reg);
                    fl_ce_n  <= '0';
                    wait_cnt <= 0;
                    state    <= WAIT_B1;
                    
                when WAIT_B1 =>
                    if wait_cnt = 4 then
                        state <= READ_B1;
                    else
                        wait_cnt <= wait_cnt + 1;
                    end if;
                    
                when READ_B1 =>
                    word_buffer(15 downto 8) <= fl_dq_i;
                    flash_addr_reg          <= flash_addr_reg + 1;
                    fl_ce_n                 <= '1';
                    state                   <= SETUP_B2;

                -- === ΑΝΑΓΝΩΣΗ BYTE 2 (Bits 23 downto 16) ===
                when SETUP_B2 =>
                    fl_addr  <= std_logic_vector(flash_addr_reg);
                    fl_ce_n  <= '0';
                    wait_cnt <= 0;
                    state    <= WAIT_B2;
                    
                when WAIT_B2 =>
                    if wait_cnt = 4 then
                        state <= READ_B2;
                    else
                        wait_cnt <= wait_cnt + 1;
                    end if;
                    
                when READ_B2 =>
                    word_buffer(23 downto 16) <= fl_dq_i;
                    flash_addr_reg           <= flash_addr_reg + 1;
                    fl_ce_n                  <= '1';
                    state                    <= SETUP_B3;

                -- === ΑΝΑΓΝΩΣΗ BYTE 3 (Bits 31 downto 24) ===
                when SETUP_B3 =>
                    fl_addr  <= std_logic_vector(flash_addr_reg);
                    fl_ce_n  <= '0';
                    wait_cnt <= 0;
                    state    <= WAIT_B3;
                    
                when WAIT_B3 =>
                    if wait_cnt = 4 then
                        state <= READ_B3;
                    else
                        wait_cnt <= wait_cnt + 1;
                    end if;
                    
                when READ_B3 =>
                    word_buffer(31 downto 24) <= fl_dq_i;
                    flash_addr_reg           <= flash_addr_reg + 1;
                    fl_ce_n                  <= '1';
                    state                    <= WRITE_WORD;

                -- === ΕΓΓΡΑΦΗ ΤΗΣ 32-bit ΛΕΞΗΣ ΣΤΗ RAM ===
                when WRITE_WORD =>
                    ram_addr <= std_logic_vector(word_counter);
                    ram_din  <= word_buffer;
                    ram_wre  <= '1'; -- Ενεργοποίηση εγγραφής για 1 κύκλο ρολογιού
                    state    <= NEXT_WORD;
                    
                when NEXT_WORD =>
                    -- 16KB κώδικα / 4 bytes ανά λέξη = 4096 λέξεις (0 έως 4095)
                    if to_integer(word_counter) = (IMG_BYTES/4) - 1 then
                        busreq <= '0'; -- Απελευθερώνουμε το εξωτερικό bus
                        state  <= FINISH;
                    else
                        word_counter <= word_counter + 1;
                        state        <= REQ_BUS; -- Συνεχίζουμε με την επόμενη 32-bit λέξη
                    end if;
                    
                when FINISH =>
                    done    <= '1';
                    fl_ce_n <= '1';
                    if start = '0' then
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end architecture rtl;
