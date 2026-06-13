library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity z80_bridge_decoder is
    Port (
        clk          : in  STD_LOGIC;                     -- FPGA System Clock
        z80_addr     : in  STD_LOGIC_VECTOR (15 downto 0);-- Z80 Address Bus
        z80_data     : inout STD_LOGIC_VECTOR (7 downto 0);-- Z80 Data Bus
        z80_mreq_n   : in  STD_LOGIC;                     -- Z80 Memory Request
        z80_rd_n     : in  STD_LOGIC;                     -- Z80 Read
        z80_wr_n     : in  STD_LOGIC;                     -- Z80 Write
        
        LRAMEN3_N    : out STD_LOGIC                      -- External SRAM CE
    );
end z80_bridge_decoder;

architecture Behavioral of z80_bridge_decoder is

    -- Define an array type for the 8KB internal block (8192 x 8-bit)
    type ram_type is array (0 to 8191) of STD_LOGIC_VECTOR(7 downto 0);
    
    -- Optional: Function to preload your hex file into the VHDL block ram
    impure function init_ram_from_file (file_name : in string) return ram_type is
        file text_file       : text open read_mode is file_name;
        variable text_line   : line;
        variable ram_content : ram_type := (others => (others => '0'));
        variable hex_val     : bit_vector(7 downto 0);
    begin
        for i in 0 to 8191 loop
            if not endfile(text_file) then
                readline(text_file, text_line);
                hread(text_line, hex_val); -- Standard synthesis hex reader
                ram_content(i) := to_stdlogicvector(hex_val);
            else
                exit;
            end if;
        end loop;
        return ram_content;
    end function;

    -- Signal declarations
    signal internal_ram   : ram_type := init_ram_from_file("G:\_Programming\_DOCS\Schematics\NewbrainSBC\TANG25K\Z80SBC\z80_boot.hex");
    signal ram_read_data  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal addr_unsigned  : unsigned(15 downto 0);
    
    signal is_internal    : boolean;
    signal memory_active  : boolean;

begin

    -- Convert vector types to unsigned for direct integer comparison
    addr_unsigned <= unsigned(z80_addr);
    
    -- Decode parameters
    memory_active <= (z80_mreq_n = '0');
    is_internal   <= (addr_unsigned < 16#2000#); -- True if address is 0x0000 to 0x1FFF

    -- Synchronous Process: Handles Internal 8KB Block RAM Read/Writes
    process(clk)
    begin
        if rising_edge(clk) then
            if memory_active and is_internal then
                if z80_wr_n = '0' then
                    -- Write data to internal storage slot using the lower 13 bits (0 to 8191)
                    internal_ram(to_integer(addr_unsigned(12 downto 0))) <= z80_data;
                end if;
                -- Latched read execution
                ram_read_data <= internal_ram(to_integer(addr_unsigned(12 downto 0)));
            end if;
        end if;
    end process;

    -- Combinatorial Assignment: External SRAM Chip Enable Control
    -- Instantly activates low if the Z80 passes the 8192 boundary
    LRAMEN3_N <= '0' when (memory_active and not is_internal) else '1';

    -- Tri-state Bus Driver: Drive only when Z80 requests a read inside our 8KB map
    z80_data <= ram_read_data when (z80_mreq_n = '0' and z80_rd_n = '0' and is_internal) else (others => 'Z');

end Behavioral;