library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VD_types_pkg.all;

entity hdmi_video_subsystem is
    port (
        CLK_PIXEL       : in  std_logic;
        CLK_TMDS        : in  std_logic;
        nRESET          : in  std_logic;

        -- Bus from the selected Video Producer
        VIDEO_BUS_IN    : in  video_bus_out;
        
        -- Timing Feedback to the Producer
        VIDEO_BUS_TIMING: out video_bus_in;

        -- HDMI Physical Pins
        CKP, CKN        : out std_logic;
        D0P, D0N        : out std_logic;
        D1P, D1N        : out std_logic;
        D2P, D2N        : out std_logic
    );
end entity hdmi_video_subsystem;

architecture RTL of hdmi_video_subsystem is
    -- 800x600 @ 60Hz Timing Constants
    constant CH_RES : integer := 800; constant CH_FP : integer := 40;
    constant CH_SYNC : integer := 128; constant CH_BP : integer := 88;
    constant CH_MAX : integer := 1056;

    constant CV_RES : integer := 600; constant CV_FP : integer := 1;
    constant CV_SYNC : integer := 4; constant CV_BP : integer := 23;
    constant CV_MAX : integer := 628;

    signal h_cnt : integer range 0 to CH_MAX-1 := 0;
    signal v_cnt : integer range 0 to CV_MAX-1 := 0;
    signal h_sync, v_sync, de : std_logic;

    component DVI_TX_Top
        port (
            I_rst_n : in std_logic; I_serial_clk : in std_logic; I_rgb_clk : in std_logic;
            I_rgb_vs : in std_logic; I_rgb_hs : in std_logic; I_rgb_de : in std_logic;
            I_rgb_r : in std_logic_vector(7 downto 0); I_rgb_g : in std_logic_vector(7 downto 0); I_rgb_b : in std_logic_vector(7 downto 0);
            O_tmds_clk_p, O_tmds_clk_n : out std_logic;
            O_tmds_data_p, O_tmds_data_n : out std_logic_vector(2 downto 0)
        );
    end component;

    signal tmds_p, tmds_n : std_logic_vector(2 downto 0);

begin
    -- 1. Master Timing Generator
    process(CLK_PIXEL)
    begin
        if rising_edge(CLK_PIXEL) then
            if h_cnt = CH_MAX - 1 then
                h_cnt <= 0;
                if v_cnt = CV_MAX - 1 then v_cnt <= 0; else v_cnt <= v_cnt + 1; end if;
            else
                h_cnt <= h_cnt + 1;
            end if;
            h_sync <= '0' when (h_cnt >= (CH_RES + CH_FP) and h_cnt < (CH_RES + CH_FP + CH_SYNC)) else '1';
            v_sync <= '0' when (v_cnt >= (CV_RES + CV_FP) and v_cnt < (CV_RES + CV_FP + CV_SYNC)) else '1';
            de     <= '1' when (h_cnt < CH_RES and v_cnt < CV_RES) else '0';
        end if;
    end process;

    -- Feedback to producers
    VIDEO_BUS_TIMING.clk_pixel <= CLK_PIXEL;
    VIDEO_BUS_TIMING.nreset    <= nRESET;
    VIDEO_BUS_TIMING.h_cnt     <= h_cnt;
    VIDEO_BUS_TIMING.v_cnt     <= v_cnt;

    -- 2. DVI Core Instantiation
    U_DVI : DVI_TX_Top
        port map (
            I_rst_n => nRESET, I_serial_clk => CLK_TMDS, I_rgb_clk => CLK_PIXEL,
            I_rgb_vs => v_sync, I_rgb_hs => h_sync, I_rgb_de => de,
            I_rgb_r => not VIDEO_BUS_IN.r_8, I_rgb_g => not VIDEO_BUS_IN.g_8, I_rgb_b => not VIDEO_BUS_IN.b_8,
            O_tmds_clk_p => CKP, O_tmds_clk_n => CKN,
            O_tmds_data_p => tmds_p, O_tmds_data_n => tmds_n
        );

    D0P <= tmds_p(0); D0N <= tmds_n(0);
    D1P <= tmds_p(1); D1N <= tmds_n(1);
    D2P <= tmds_p(2); D2N <= tmds_n(2);

end architecture RTL;