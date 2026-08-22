library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.defs_pkg.all;
use work.VD_types_pkg.all;

entity System_TOP is
    Port (
        CLK_FPGA        : in  std_logic;
        CLK_Z80         : in  std_logic;
        nRESET          : in  std_logic;

        Z80_In_raw      : in  t_z80_to_sys_raw;

        -- Record Interfaces to Z80 / Top level
        Z80_In          : in  t_z80_to_system;
        Z80_Out         : out t_system_to_z80;
        OTSigs_in       : in  t_ot_sigs_to_system;
        OTSigs_out      : out t_ot_sigs_from_system;

        -- Video Stream Interfaces
        V_IN            : in  video_bus_in;
        V_OUT           : out video_bus_out;

        -- Shared VRAM Interfaces
        VRAM_DATA       : in  std_logic_vector(7 downto 0);
        VRAM_ADDR       : out std_logic_vector(15 downto 0);

        -- MMU interface to set pages in banks
        MMU_INTF        : out t_mmu_intf; 

        -- MMU Banks info
        MMU_Banks       : in t_mmu_banks
    );
end System_TOP;

architecture Structural of System_TOP is

    -- Active System Decoding Flags
    signal boot_active : std_logic;
    signal spec_active : std_logic;
    signal atla_active : std_logic;
    signal newb_active : std_logic;
    signal amst_active : std_logic;
   
    -- Bootloader (System 0) Signals
    signal boot_z80_out   : t_system_to_z80;
    signal boot_ot_out    : t_ot_sigs_from_system;
    signal boot_v_out     : video_bus_out;
    signal boot_vram_addr : std_logic_vector(15 downto 0);
    signal boot_MMU_INTF  : t_mmu_intf;

    -- Spectrum (System 1) Signals
    signal spec_z80_out   : t_system_to_z80;
    signal spec_ot_out    : t_ot_sigs_from_system;
    signal spec_v_out     : video_bus_out;
    signal spec_vram_addr : std_logic_vector(15 downto 0);
    signal spec_MMU_INTF  : t_mmu_intf;

    -- Atlas (System 2) Signals
    signal atla_z80_out   : t_system_to_z80;
    signal atla_ot_out    : t_ot_sigs_from_system;
    signal atla_v_out     : video_bus_out;
    signal atla_vram_addr : std_logic_vector(15 downto 0);
    signal atla_MMU_INTF  : t_mmu_intf;

    -- Newbrain (System 3) Signals
    signal newb_z80_out   : t_system_to_z80;
    signal newb_ot_out    : t_ot_sigs_from_system;
    signal newb_v_out     : video_bus_out;
    signal newb_vram_addr : std_logic_vector(15 downto 0);
    signal newb_MMU_INTF  : t_mmu_intf;

    -- Amstrad (System 4) Signals
    signal amst_z80_out   : t_system_to_z80;
    signal amst_ot_out    : t_ot_sigs_from_system;
    signal amst_v_out     : video_bus_out;
    signal amst_vram_addr : std_logic_vector(15 downto 0);
    signal amst_MMU_INTF  : t_mmu_intf;


--video
    signal video_selection : unsigned(3 downto 0) := (others => '0');
  --  signal reg_video_sel_n  : std_logic;
    signal VD_DSn           : std_logic; --for video registers

    --System select
    signal SYS_CSn          : std_logic; -- system select 
    signal reg_system_sel_n : std_logic; --register for system selection
    signal system_selection : unsigned(3 downto 0) := (others => '0');

    signal sAmstradEN       : std_logic :='0'; --active high 
    signal sAmstradTry      : std_logic :='0'; --active high this go high to signal we want to set amstrad sys
    signal amstrad_booted_flag : std_logic :='0'; --active high

begin

    ------------------------------------------------------------------
    -- 1. System Active Activity Flag Decoder
    ------------------------------------------------------------------
    boot_active <= '1' when system_selection = 0 else '0';
    atla_active <= '1' when system_selection = 1 else '0';
    newb_active <= '1' when system_selection = 2 else '0';
    spec_active <= '1' when system_selection = 3 else '0';  
    amst_active <= '1' when system_selection = 4 else '0';

    ------------------------------------------------------------------
    -- 2. Instantiate All Sub-Systems
    ------------------------------------------------------------------
    -- System 0: Bootloader
    u_Bootloader : entity work.Bootloader_Top
        port map (
            CLK_FPGA     => CLK_FPGA,
            CLK          => CLK_Z80,
            nRESET       => nRESET,
            SystemActive => boot_active,
            Z80_In_raw   => Z80_In_raw,    
            Z80_In       => Z80_In,
            Z80_Out      => boot_z80_out,
            OTSigs_in    => OTSigs_in,
            OTSigs_out   => boot_ot_out,
            V_IN         => V_IN,
            V_OUT        => boot_v_out,
            VRAM_DATA    => VRAM_DATA,
            VRAM_ADDR    => boot_vram_addr,
            MMU_INTF     => boot_MMU_INTF,
            MMU_Banks    => MMU_Banks
        );

    -- System 1: ZX Spectrum
    u_Spectrum : entity work.Spectrum_TOP
        port map (
            CLK_FPGA     => CLK_FPGA,
            CLK          => CLK_Z80,
            nRESET       => nRESET,
            SystemActive => spec_active,
            Z80_In_raw   => Z80_In_raw,
            Z80_In       => Z80_In,
            Z80_Out      => spec_z80_out,
            OTSigs_in    => OTSigs_in,
            OTSigs_out   => spec_ot_out,
            V_IN         => V_IN,
            V_OUT        => spec_v_out,
            VRAM_DATA    => VRAM_DATA,
            VRAM_ADDR    => spec_vram_addr,
            MMU_INTF     => spec_MMU_INTF,
            MMU_Banks    => MMU_Banks
        );

    -- System 2: Atlas
    u_Atlas : entity work.Atlas_TOP
        port map (
            CLK_FPGA     => CLK_FPGA,
            CLK          => CLK_Z80,
            nRESET       => nRESET,
            SystemActive => atla_active,
            Z80_In_raw   => Z80_In_raw,
            Z80_In       => Z80_In,
            Z80_Out      => atla_z80_out,
            OTSigs_in    => OTSigs_in,
            OTSigs_out   => atla_ot_out,
            V_IN         => V_IN,
            V_OUT        => atla_v_out,
            VRAM_DATA    => VRAM_DATA,
            VRAM_ADDR    => atla_vram_addr,
            MMU_INTF     => atla_MMU_INTF,
            MMU_Banks    => MMU_Banks
        );

    -- System 3: Newbrain
    u_Newbrain : entity work.Newbrain_TOP
        port map (
            CLK_FPGA     => CLK_FPGA,
            CLK          => CLK_Z80,
            nRESET       => nRESET,
            SystemActive => newb_active,
            Z80_In_raw   => Z80_In_raw,
            Z80_In       => Z80_In,
            Z80_Out      => newb_z80_out,
            OTSigs_in    => OTSigs_in,
            OTSigs_out   => newb_ot_out,
            V_IN         => V_IN,
            V_OUT        => newb_v_out,
            VRAM_DATA    => VRAM_DATA,
            VRAM_ADDR    => newb_vram_addr,
            MMU_INTF     => newb_MMU_INTF,
            MMU_Banks    => MMU_Banks
        );

    -- System 4: Amstrad CPC
    u_Amstrad : entity work.Amstrad_TOP
        port map (
            CLK_FPGA     => CLK_FPGA,
            CLK          => CLK_Z80,
            nRESET       => nRESET,
            SystemActive => amst_active,
            Z80_In_raw   => Z80_In_raw,
            Z80_In       => Z80_In,
            Z80_Out      => amst_z80_out,
            OTSigs_in    => OTSigs_in,
            OTSigs_out   => amst_ot_out,
            V_IN         => V_IN,
            V_OUT        => amst_v_out,
            VRAM_DATA    => VRAM_DATA,
            VRAM_ADDR    => amst_vram_addr,
            MMU_INTF     => amst_MMU_INTF,
            MMU_Banks    => MMU_Banks
        );

    ------------------------------------------------------------------
    -- 3. Output Multiplexer (Driven by OTSigs_in.SYS_SEL)
    ------------------------------------------------------------------
    process(system_selection, video_selection,
            boot_z80_out, boot_ot_out, boot_v_out, boot_vram_addr, boot_mmu_intf,
            atla_z80_out, atla_ot_out, atla_v_out, atla_vram_addr, atla_mmu_intf,
            newb_z80_out, newb_ot_out, newb_v_out, newb_vram_addr, newb_mmu_intf,
            spec_z80_out, spec_ot_out, spec_v_out, spec_vram_addr, spec_mmu_intf,
            amst_z80_out, amst_ot_out, amst_v_out, amst_vram_addr, amst_mmu_intf )     
    begin
        case to_integer(unsigned(system_selection)) is
            when 0 =>
                Z80_Out    <= boot_z80_out;
                OTSigs_out <= boot_ot_out;
                MMU_INTF   <= boot_MMU_INTF; 

            when 1 =>
                Z80_Out    <= atla_z80_out;
                OTSigs_out <= atla_ot_out;
                MMU_INTF   <= atla_MMU_INTF; 

            when 2 =>
                Z80_Out    <= newb_z80_out;
                OTSigs_out <= newb_ot_out;
                MMU_INTF   <= newb_MMU_INTF; 

            when 3 =>
                Z80_Out    <= spec_z80_out;
                OTSigs_out <= spec_ot_out;
                MMU_INTF   <= spec_MMU_INTF; 

            when 4 =>
                Z80_Out    <= amst_z80_out;
                OTSigs_out <= amst_ot_out;
                MMU_INTF   <= amst_MMU_INTF;     

            when others =>
                Z80_Out    <= boot_z80_out;
                OTSigs_out <= boot_ot_out;
                MMU_INTF   <= boot_MMU_INTF; 
        end case;

       case to_integer(unsigned(video_selection)) is
            when 0 =>
                V_OUT      <= boot_v_out;
                VRAM_ADDR  <= boot_vram_addr;

            when 1 =>
                V_OUT      <= atla_v_out;
                VRAM_ADDR  <= atla_vram_addr;

            when 2 =>
                V_OUT      <= newb_v_out;
                VRAM_ADDR  <= newb_vram_addr;

            when 3 =>
                V_OUT      <= spec_v_out;
                VRAM_ADDR  <= spec_vram_addr;

            when 4 =>
                V_OUT      <= amst_v_out;
                VRAM_ADDR  <= amst_vram_addr;

            when others =>
                V_OUT      <= boot_v_out;
                VRAM_ADDR  <= boot_vram_addr;
        end case;
       
        OTSigs_out.SYS_SEL <= std_logic_vector(system_selection);
    end process;




    --================================================
    -- system selection and video selection
    --================================================
    

    -- Video register from z80 is active
    --reg_video_sel_n <= '0' when (VD_DSn = '0' and LWR_N = '0') else  '1';
    reg_system_sel_n <= '0' when ( Z80_Out.SYS_CS_N = '0' and Z80_in.Z80_WR_N = '0') else  '1';

    process(CLK_FPGA, nRESET)
    begin
        if nRESET = '0' then
            video_selection     <= "0000";
            system_selection    <= "0000";
            sAmstradTry         <= '0';
            amstrad_booted_flag <= '0';
        elsif rising_edge(CLK_FPGA) then
            if reg_system_sel_n = '0' then
                -- Standard path for all non-Amstrad systems OR Amstrad after its first boot
                if Z80_In.Z80_Data(3 downto 0) /= "0100" or amstrad_booted_flag = '1' then  
                    system_selection <= unsigned(Z80_In.Z80_Data(3 downto 0));  
                    
                    -- High nibble rule: 
                    -- If high nibble is 0, update video to match system.
                    -- If high nibble is NOT 0 (e.g. loading), keep the original screen/video.
                    if Z80_In.Z80_Data(7 downto 4) = "0000" then 
                        video_selection <= unsigned(Z80_In.Z80_Data(3 downto 0));
                    end if;
                    
                    sAmstradTry <= '0';
                else 
                    -- First-time Amstrad selection: arm the trigger for the first OUT
                    sAmstradTry <= '1';
                    
                    -- High nibble check for initial selection if needed
                    if Z80_In.Z80_Data(7 downto 4) = "0000" then
                        video_selection <= "0100";                        
                    end if;
                end if;
                
            -- When Amstrad is armed for its very first boot, wait for the first OUT at x"7F89"
            elsif system_selection = 0 and sAmstradTry = '1' then
                if Z80_in.Z80_IORQ_N = '0' and Z80_in.Z80_WR_N = '0' and Z80_In.Z80_ADDR = x"7F89" then
                    system_selection    <= "0100";
                    video_selection <= "0100";                    
                    amstrad_booted_flag <= '1'; -- Mark that the first-time boot sequence is complete                    
                    sAmstradTry <= '0'; 
                end if;
            end if;            
        end if;
    end process;

end architecture Structural;