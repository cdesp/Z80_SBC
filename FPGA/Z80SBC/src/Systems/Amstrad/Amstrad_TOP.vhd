library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.defs_pkg.all;
use work.VD_types_pkg.all;

entity Amstrad_TOP is
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
end entity Amstrad_TOP;

architecture Structural of Amstrad_TOP is

    -- Internal video register bus connecting Arbiter to Video Generator
    signal s_vd_regs  : t_video_regs;
    
    -- Internal copy of Z80_Out to drive top port and tap internal decodes
    signal s_z80_out  : t_system_to_z80;

    signal s_am_sigs  : t_amstrad_sigs;

    signal sMMU_INTF_LD  : t_mmu_intf; 
    signal sMMU_INTF_CPC  : t_mmu_intf; 

    signal sInterActive : std_logic := '0';
    signal sOTSigs_out : t_ot_sigs_from_system;

    signal ams_wait : std_logic :='1'; --active low   trigger wait states to z80
    signal sMMU_UPD : std_logic :='0'; --active high  trigger wait states to z80

begin


    ------------------------------------------------------------------
    -- 1. Amstrad Bus Arbiter & Device Decoder
    ------------------------------------------------------------------
    u_Arbiter : entity work.Z80_BA_Amstrad
        port map (
            CLK_FPGA   => CLK_FPGA,
            CLK        => CLK,
            nRESET     => nRESET,
            Z80_In     => Z80_In,
            Z80_Out    => s_z80_out,
            OTSigs_in  => OTSigs_in,
            OTSigs_out => sOTSigs_out,
            VDRegs_out => s_vd_regs,
                   --Amstrad signals
            amst_Sigs => s_am_sigs      --from BA_Amstrad
        );

    ------------------------------------------------------------------
    -- 2. Amstrad Video Output Core
    ------------------------------------------------------------------
    u_Video : entity work.AmstradVideo
        port map (
            V_IN      => V_IN,
            V_OUT     => V_OUT,
            FPGA_CLK  => CLK_FPGA,
            Z80_CLK   => CLK,
            
            -- Tapped directly from Z80_In record
            Z80_WR_N  => Z80_In.Z80_WR_N,
            Z80_ADDR  => Z80_In.Z80_ADDR(3 downto 0),  -- 4-bit register offset
            Z80_DATA  => Z80_In.Z80_Data,
            
            -- Tapped from internal Arbiter output (VD_DS_N is the decoded chip-select)
            REG_SEL_N => s_z80_out.VD_DS_N,
            
            -- Memory & Video Registers
            VRAM_DATA => VRAM_DATA,
            VRAM_ADDR => VRAM_ADDR,
            VDRegs    => s_vd_regs
        );

    CPC_MMU_Inst : entity work.CPC_MMU_Bank_Sequencer 
        Port map (
            clk             => CLK_FPGA,                   -- 50 MHz FPGA Clock
            reset_n         => nReset,
            
            -- Z80 Bus Controls
            Z80_MREQ_N      => Z80_In_raw.Z80_MREQ_N_raw,  --L_MREQ_N,
            Z80_RD_N        => Z80_In_raw.Z80_RD_N_raw,  --L_RD_N,          --raw signals we need to be quick
            Z80_WR_N        => Z80_In_raw.Z80_WR_N_raw,  --LWR_CPU_N,       --raw signals we need to be quick
            Z80_ADDR        => Z80_In_raw.Z80_ADDR_raw,  --Z80_LA_BUS_INT,
            
            -- Config inputs from Gate Array
            amst_Sigs       => s_am_sigs,       --to CPC_MMU

            -- Interface to your MMU controller
            mmu_intf        => sMMU_INTF_CPC,        --to top 
            UPDATE_ACTIVE   => sMMU_UPD              -- '1' while sequence is running
        );

    MMU_INTF <= sMMU_INTF_LD when sInterActive='1' 
             else sMMU_INTF_CPC;

    u_loader : entity work.CPC_Load_Interceptor
            generic map (
                TARGET_ADDR_1 => x"2392",
                TARGET_ADDR_2 => x"24AB"                
            )
            port map (
                CLK_IN           => CLK_FPGA,
                reset_n          => nRESET,
                LOADER_ACTIVE    => SystemActive and not OTSigs_in.TapeReg(0), -- tapereg(0) should be 0
                CPU_WAIT         => ams_wait,
                Z80_In_raw       => Z80_In_raw,  --raw signals ****
                INTERCEPT_ACTIVE => sInterActive,
                MMU_Intf         => sMMU_INTF_LD,
                MMU_Banks        => mmu_banks
            );
     

    process (all)
    variable v_out : t_ot_sigs_from_system;
    begin
      v_out := sOTSigs_out;  
      v_out.LDIntceptAct := sInterActive;          
      OTSigs_out <= v_out;
    end process;

    process (all)
    variable v_out : t_system_to_z80;
    begin
      v_out := s_z80_out;  
      if sMMU_UPD = '1' then
         v_out.Z80_WAIT_N := '0';
      else
         v_out.Z80_WAIT_N := ams_wait;
      end if;       
      Z80_Out <= v_out;
    end process;



end architecture Structural;