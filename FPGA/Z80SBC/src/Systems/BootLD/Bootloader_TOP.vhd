library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.defs_pkg.all; -- Package containing t_z80_to_system, t_system_to_z80, etc.
use work.VD_types_pkg.all;

entity Bootloader_Top is
    Port (
        CLK_FPGA        : in  std_logic;
        CLK             : in  std_logic;                  -- Z80 Operating Clock
        nRESET          : in  std_logic;
        SystemActive    : in  std_logic;                  -- System Clock Enable / Activity Flag

        Z80_In_raw      : in  t_z80_to_sys_raw;
        -- Record Interfaces
        Z80_In          : in  t_z80_to_system;
        Z80_Out         : out t_system_to_z80;
        OTSigs_in       : in  t_ot_sigs_to_system;
        OTSigs_out      : out t_ot_sigs_from_system;

        -- Video Stream Interfaces
        V_IN            : in  video_bus_in;
        V_OUT           : out video_bus_out;

        -- VRAM Interfaces
        VRAM_DATA       : in  std_logic_vector(7 downto 0);
        VRAM_ADDR       : out std_logic_vector(15 downto 0);

        -- MMU interface to set pages in banks
        MMU_INTF        : out t_mmu_intf; 

        -- MMU Banks info
        MMU_Banks       : in t_mmu_banks

    );
end entity Bootloader_Top;

architecture Structural of Bootloader_Top is

    -- Internal video register bus connecting Arbiter to Video Generator
    signal s_vd_regs  : t_video_regs;
    
    -- Internal copy of Z80_Out to drive both the top port and tap internal decodes
    signal s_z80_out  : t_system_to_z80;

begin
    MMU_Intf.FPGA_MMU_BANK <= "000";
    MMU_Intf.FPGA_MMU_PAGE <= x"00";
    MMU_Intf.FPGA_MMU_WE   <= '0'; --disabled
    -- Drive output record port
    Z80_Out <= s_z80_out;

    ------------------------------------------------------------------
    -- 1. Bootloader Bus Arbiter & Device Decoder
    ------------------------------------------------------------------
    u_Arbiter : entity work.Z80_BA_Bootloader
        port map (
            CLK_FPGA   => CLK_FPGA,
            CLK        => CLK,
            nRESET     => nRESET,
            Z80_In     => Z80_In,
            Z80_Out    => s_z80_out,
            OTSigs_in  => OTSigs_in,
            OTSigs_out => OTSigs_out,
            VDRegs_out => s_vd_regs
        );

    ------------------------------------------------------------------
    -- 2. Bootloader Video Output Core
    ------------------------------------------------------------------
    u_Video : entity work.BootLVideo
        port map (
            V_IN      => V_IN,
            V_OUT     => V_OUT,
            FPGA_CLK  => CLK_FPGA,
            Z80_CLK   => CLK,
            
            -- Tapped directly from Z80_In record
            Z80_WR_N  => Z80_In.Z80_WR_N,
            Z80_ADDR  => Z80_In.Z80_ADDR(3 downto 0),  -- 4-bit offset
            Z80_DATA  => Z80_In.Z80_Data,
            
            -- Tapped from internal Arbiter output (VD_DS_N is the decoded chip-select)
            REG_SEL_N => s_z80_out.VD_DS_N,
            
            -- Memory & Video Registers
            VRAM_DATA => VRAM_DATA,
            VRAM_ADDR => VRAM_ADDR,
            VDRegs    => s_vd_regs
        );

end architecture Structural;