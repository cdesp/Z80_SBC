--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: IP file
--Tool Version: V1.9.12 (64-bit)
--Part Number: GW5A-LV25MG121NC1/I0
--Device: GW5A-25
--Device Version: A
--Created Time: Wed Oct  7 18:03:21 2026

library IEEE;
use IEEE.std_logic_1164.all;

entity RV32_RAM is
    port (
        dout: out std_logic_vector(31 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        wre: in std_logic;
        ad: in std_logic_vector(12 downto 0);
        din: in std_logic_vector(31 downto 0)
    );
end RV32_RAM;

architecture Behavioral of RV32_RAM is

    signal spx9_inst_0_dout_w: std_logic_vector(26 downto 0);
    signal spx9_inst_0_dout: std_logic_vector(8 downto 0);
    signal spx9_inst_1_dout_w: std_logic_vector(26 downto 0);
    signal spx9_inst_1_dout: std_logic_vector(8 downto 0);
    signal spx9_inst_2_dout_w: std_logic_vector(26 downto 0);
    signal spx9_inst_2_dout: std_logic_vector(8 downto 0);
    signal spx9_inst_3_dout_w: std_logic_vector(26 downto 0);
    signal spx9_inst_3_dout: std_logic_vector(8 downto 0);
    signal spx9_inst_4_dout_w: std_logic_vector(26 downto 0);
    signal spx9_inst_4_dout: std_logic_vector(17 downto 9);
    signal spx9_inst_5_dout_w: std_logic_vector(26 downto 0);
    signal spx9_inst_5_dout: std_logic_vector(17 downto 9);
    signal spx9_inst_6_dout_w: std_logic_vector(26 downto 0);
    signal spx9_inst_6_dout: std_logic_vector(17 downto 9);
    signal spx9_inst_7_dout_w: std_logic_vector(26 downto 0);
    signal spx9_inst_7_dout: std_logic_vector(17 downto 9);
    signal sp_inst_8_dout_w: std_logic_vector(29 downto 0);
    signal sp_inst_9_dout_w: std_logic_vector(29 downto 0);
    signal sp_inst_10_dout_w: std_logic_vector(29 downto 0);
    signal sp_inst_11_dout_w: std_logic_vector(29 downto 0);
    signal sp_inst_12_dout_w: std_logic_vector(29 downto 0);
    signal sp_inst_13_dout_w: std_logic_vector(29 downto 0);
    signal sp_inst_14_dout_w: std_logic_vector(29 downto 0);
    signal dff_q_0: std_logic;
    signal dff_q_1: std_logic;
    signal mux_o_0: std_logic;
    signal mux_o_1: std_logic;
    signal mux_o_3: std_logic;
    signal mux_o_4: std_logic;
    signal mux_o_6: std_logic;
    signal mux_o_7: std_logic;
    signal mux_o_9: std_logic;
    signal mux_o_10: std_logic;
    signal mux_o_12: std_logic;
    signal mux_o_13: std_logic;
    signal mux_o_15: std_logic;
    signal mux_o_16: std_logic;
    signal mux_o_18: std_logic;
    signal mux_o_19: std_logic;
    signal mux_o_21: std_logic;
    signal mux_o_22: std_logic;
    signal mux_o_24: std_logic;
    signal mux_o_25: std_logic;
    signal mux_o_27: std_logic;
    signal mux_o_28: std_logic;
    signal mux_o_30: std_logic;
    signal mux_o_31: std_logic;
    signal mux_o_33: std_logic;
    signal mux_o_34: std_logic;
    signal mux_o_36: std_logic;
    signal mux_o_37: std_logic;
    signal mux_o_39: std_logic;
    signal mux_o_40: std_logic;
    signal mux_o_42: std_logic;
    signal mux_o_43: std_logic;
    signal mux_o_45: std_logic;
    signal mux_o_46: std_logic;
    signal mux_o_48: std_logic;
    signal mux_o_49: std_logic;
    signal mux_o_51: std_logic;
    signal mux_o_52: std_logic;
    signal ce_w: std_logic;
    signal gw_gnd: std_logic;
    signal spx9_inst_0_BLKSEL_i: std_logic_vector(2 downto 0);
    signal spx9_inst_0_AD_i: std_logic_vector(13 downto 0);
    signal spx9_inst_0_DI_i: std_logic_vector(35 downto 0);
    signal spx9_inst_0_DO_o: std_logic_vector(35 downto 0);
    signal spx9_inst_1_BLKSEL_i: std_logic_vector(2 downto 0);
    signal spx9_inst_1_AD_i: std_logic_vector(13 downto 0);
    signal spx9_inst_1_DI_i: std_logic_vector(35 downto 0);
    signal spx9_inst_1_DO_o: std_logic_vector(35 downto 0);
    signal spx9_inst_2_BLKSEL_i: std_logic_vector(2 downto 0);
    signal spx9_inst_2_AD_i: std_logic_vector(13 downto 0);
    signal spx9_inst_2_DI_i: std_logic_vector(35 downto 0);
    signal spx9_inst_2_DO_o: std_logic_vector(35 downto 0);
    signal spx9_inst_3_BLKSEL_i: std_logic_vector(2 downto 0);
    signal spx9_inst_3_AD_i: std_logic_vector(13 downto 0);
    signal spx9_inst_3_DI_i: std_logic_vector(35 downto 0);
    signal spx9_inst_3_DO_o: std_logic_vector(35 downto 0);
    signal spx9_inst_4_BLKSEL_i: std_logic_vector(2 downto 0);
    signal spx9_inst_4_AD_i: std_logic_vector(13 downto 0);
    signal spx9_inst_4_DI_i: std_logic_vector(35 downto 0);
    signal spx9_inst_4_DO_o: std_logic_vector(35 downto 0);
    signal spx9_inst_5_BLKSEL_i: std_logic_vector(2 downto 0);
    signal spx9_inst_5_AD_i: std_logic_vector(13 downto 0);
    signal spx9_inst_5_DI_i: std_logic_vector(35 downto 0);
    signal spx9_inst_5_DO_o: std_logic_vector(35 downto 0);
    signal spx9_inst_6_BLKSEL_i: std_logic_vector(2 downto 0);
    signal spx9_inst_6_AD_i: std_logic_vector(13 downto 0);
    signal spx9_inst_6_DI_i: std_logic_vector(35 downto 0);
    signal spx9_inst_6_DO_o: std_logic_vector(35 downto 0);
    signal spx9_inst_7_BLKSEL_i: std_logic_vector(2 downto 0);
    signal spx9_inst_7_AD_i: std_logic_vector(13 downto 0);
    signal spx9_inst_7_DI_i: std_logic_vector(35 downto 0);
    signal spx9_inst_7_DO_o: std_logic_vector(35 downto 0);
    signal sp_inst_8_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_8_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_8_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_8_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_9_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_9_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_9_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_9_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_10_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_10_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_10_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_10_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_11_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_11_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_11_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_11_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_12_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_12_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_12_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_12_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_13_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_13_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_13_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_13_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_14_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_14_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_14_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_14_DO_o: std_logic_vector(31 downto 0);

    --component declaration
    component SPX9
        generic (
            READ_MODE: in bit := '0';
            WRITE_MODE: in bit_vector := "00";
            BIT_WIDTH: in integer := 9;
            BLK_SEL: in bit_vector := "000";
            RESET_MODE: in string := "SYNC";
            INIT_RAM_00: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_01: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_02: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_03: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_04: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_05: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_06: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_07: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_08: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_09: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0A: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0B: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0C: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0D: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0E: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0F: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_10: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_11: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_12: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_13: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_14: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_15: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_16: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_17: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_18: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_19: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1A: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1B: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1C: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1D: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1E: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1F: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_20: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_21: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_22: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_23: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_24: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_25: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_26: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_27: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_28: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_29: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2A: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2B: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2C: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2D: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2E: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2F: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_30: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_31: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_32: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_33: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_34: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_35: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_36: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_37: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_38: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_39: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3A: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3B: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3C: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3D: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3E: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3F: in bit_vector := X"000000000000000000000000000000000000000000000000000000000000000000000000"
        );
        port (
            DO: out std_logic_vector(35 downto 0);
            CLK: in std_logic;
            OCE: in std_logic;
            CE: in std_logic;
            RESET: in std_logic;
            WRE: in std_logic;
            BLKSEL: in std_logic_vector(2 downto 0);
            AD: in std_logic_vector(13 downto 0);
            DI: in std_logic_vector(35 downto 0)
        );
    end component;

    --component declaration
    component SP
        generic (
            READ_MODE: in bit := '0';
            WRITE_MODE: in bit_vector := "00";
            BIT_WIDTH: in integer := 32;
            BLK_SEL: in bit_vector := "000";
            RESET_MODE: in string := "SYNC";
            INIT_RAM_00: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_01: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_02: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_03: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_04: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_05: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_06: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_07: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_08: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_09: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_10: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_11: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_12: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_13: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_14: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_15: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_16: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_17: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_18: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_19: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_20: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_21: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_22: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_23: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_24: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_25: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_26: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_27: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_28: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_29: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_30: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_31: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_32: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_33: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_34: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_35: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_36: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_37: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_38: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_39: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000"
        );
        port (
            DO: out std_logic_vector(31 downto 0);
            CLK: in std_logic;
            OCE: in std_logic;
            CE: in std_logic;
            RESET: in std_logic;
            WRE: in std_logic;
            BLKSEL: in std_logic_vector(2 downto 0);
            AD: in std_logic_vector(13 downto 0);
            DI: in std_logic_vector(31 downto 0)
        );
    end component;

    -- component declaration
    component DFFRE
        port (
            Q: out std_logic;
            D: in std_logic;
            CLK: in std_logic;
            CE: in std_logic;
            RESET: in std_logic
        );
    end component;

    -- component declaration
    component MUX2
        port (
            O: out std_logic;
            I0: in std_logic;
            I1: in std_logic;
            S0: in std_logic
        );
    end component;

begin
    gw_gnd <= '0';

    ce_w <= not wre and ce;
    spx9_inst_0_BLKSEL_i <= gw_gnd & ad(12) & ad(11);
    spx9_inst_0_AD_i <= ad(10 downto 0) & gw_gnd & gw_gnd & gw_gnd;
    spx9_inst_0_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(8 downto 0);
    spx9_inst_0_dout(8 downto 0) <= spx9_inst_0_DO_o(8 downto 0) ;
    spx9_inst_0_dout_w(26 downto 0) <= spx9_inst_0_DO_o(35 downto 9) ;
    spx9_inst_1_BLKSEL_i <= gw_gnd & ad(12) & ad(11);
    spx9_inst_1_AD_i <= ad(10 downto 0) & gw_gnd & gw_gnd & gw_gnd;
    spx9_inst_1_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(8 downto 0);
    spx9_inst_1_dout(8 downto 0) <= spx9_inst_1_DO_o(8 downto 0) ;
    spx9_inst_1_dout_w(26 downto 0) <= spx9_inst_1_DO_o(35 downto 9) ;
    spx9_inst_2_BLKSEL_i <= gw_gnd & ad(12) & ad(11);
    spx9_inst_2_AD_i <= ad(10 downto 0) & gw_gnd & gw_gnd & gw_gnd;
    spx9_inst_2_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(8 downto 0);
    spx9_inst_2_dout(8 downto 0) <= spx9_inst_2_DO_o(8 downto 0) ;
    spx9_inst_2_dout_w(26 downto 0) <= spx9_inst_2_DO_o(35 downto 9) ;
    spx9_inst_3_BLKSEL_i <= gw_gnd & ad(12) & ad(11);
    spx9_inst_3_AD_i <= ad(10 downto 0) & gw_gnd & gw_gnd & gw_gnd;
    spx9_inst_3_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(8 downto 0);
    spx9_inst_3_dout(8 downto 0) <= spx9_inst_3_DO_o(8 downto 0) ;
    spx9_inst_3_dout_w(26 downto 0) <= spx9_inst_3_DO_o(35 downto 9) ;
    spx9_inst_4_BLKSEL_i <= gw_gnd & ad(12) & ad(11);
    spx9_inst_4_AD_i <= ad(10 downto 0) & gw_gnd & gw_gnd & gw_gnd;
    spx9_inst_4_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(17 downto 9);
    spx9_inst_4_dout(17 downto 9) <= spx9_inst_4_DO_o(8 downto 0) ;
    spx9_inst_4_dout_w(26 downto 0) <= spx9_inst_4_DO_o(35 downto 9) ;
    spx9_inst_5_BLKSEL_i <= gw_gnd & ad(12) & ad(11);
    spx9_inst_5_AD_i <= ad(10 downto 0) & gw_gnd & gw_gnd & gw_gnd;
    spx9_inst_5_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(17 downto 9);
    spx9_inst_5_dout(17 downto 9) <= spx9_inst_5_DO_o(8 downto 0) ;
    spx9_inst_5_dout_w(26 downto 0) <= spx9_inst_5_DO_o(35 downto 9) ;
    spx9_inst_6_BLKSEL_i <= gw_gnd & ad(12) & ad(11);
    spx9_inst_6_AD_i <= ad(10 downto 0) & gw_gnd & gw_gnd & gw_gnd;
    spx9_inst_6_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(17 downto 9);
    spx9_inst_6_dout(17 downto 9) <= spx9_inst_6_DO_o(8 downto 0) ;
    spx9_inst_6_dout_w(26 downto 0) <= spx9_inst_6_DO_o(35 downto 9) ;
    spx9_inst_7_BLKSEL_i <= gw_gnd & ad(12) & ad(11);
    spx9_inst_7_AD_i <= ad(10 downto 0) & gw_gnd & gw_gnd & gw_gnd;
    spx9_inst_7_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(17 downto 9);
    spx9_inst_7_dout(17 downto 9) <= spx9_inst_7_DO_o(8 downto 0) ;
    spx9_inst_7_dout_w(26 downto 0) <= spx9_inst_7_DO_o(35 downto 9) ;
    sp_inst_8_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_8_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_8_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(19 downto 18);
    dout(19 downto 18) <= sp_inst_8_DO_o(1 downto 0) ;
    sp_inst_8_dout_w(29 downto 0) <= sp_inst_8_DO_o(31 downto 2) ;
    sp_inst_9_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_9_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_9_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(21 downto 20);
    dout(21 downto 20) <= sp_inst_9_DO_o(1 downto 0) ;
    sp_inst_9_dout_w(29 downto 0) <= sp_inst_9_DO_o(31 downto 2) ;
    sp_inst_10_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_10_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_10_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(23 downto 22);
    dout(23 downto 22) <= sp_inst_10_DO_o(1 downto 0) ;
    sp_inst_10_dout_w(29 downto 0) <= sp_inst_10_DO_o(31 downto 2) ;
    sp_inst_11_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_11_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_11_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(25 downto 24);
    dout(25 downto 24) <= sp_inst_11_DO_o(1 downto 0) ;
    sp_inst_11_dout_w(29 downto 0) <= sp_inst_11_DO_o(31 downto 2) ;
    sp_inst_12_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_12_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_12_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(27 downto 26);
    dout(27 downto 26) <= sp_inst_12_DO_o(1 downto 0) ;
    sp_inst_12_dout_w(29 downto 0) <= sp_inst_12_DO_o(31 downto 2) ;
    sp_inst_13_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_13_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_13_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(29 downto 28);
    dout(29 downto 28) <= sp_inst_13_DO_o(1 downto 0) ;
    sp_inst_13_dout_w(29 downto 0) <= sp_inst_13_DO_o(31 downto 2) ;
    sp_inst_14_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_14_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_14_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(31 downto 30);
    dout(31 downto 30) <= sp_inst_14_DO_o(1 downto 0) ;
    sp_inst_14_dout_w(29 downto 0) <= sp_inst_14_DO_o(31 downto 2) ;

    spx9_inst_0: SPX9
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 9,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => spx9_inst_0_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => spx9_inst_0_BLKSEL_i,
            AD => spx9_inst_0_AD_i,
            DI => spx9_inst_0_DI_i
        );

    spx9_inst_1: SPX9
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 9,
            RESET_MODE => "SYNC",
            BLK_SEL => "001"
        )
        port map (
            DO => spx9_inst_1_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => spx9_inst_1_BLKSEL_i,
            AD => spx9_inst_1_AD_i,
            DI => spx9_inst_1_DI_i
        );

    spx9_inst_2: SPX9
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 9,
            RESET_MODE => "SYNC",
            BLK_SEL => "010"
        )
        port map (
            DO => spx9_inst_2_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => spx9_inst_2_BLKSEL_i,
            AD => spx9_inst_2_AD_i,
            DI => spx9_inst_2_DI_i
        );

    spx9_inst_3: SPX9
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 9,
            RESET_MODE => "SYNC",
            BLK_SEL => "011"
        )
        port map (
            DO => spx9_inst_3_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => spx9_inst_3_BLKSEL_i,
            AD => spx9_inst_3_AD_i,
            DI => spx9_inst_3_DI_i
        );

    spx9_inst_4: SPX9
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 9,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => spx9_inst_4_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => spx9_inst_4_BLKSEL_i,
            AD => spx9_inst_4_AD_i,
            DI => spx9_inst_4_DI_i
        );

    spx9_inst_5: SPX9
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 9,
            RESET_MODE => "SYNC",
            BLK_SEL => "001"
        )
        port map (
            DO => spx9_inst_5_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => spx9_inst_5_BLKSEL_i,
            AD => spx9_inst_5_AD_i,
            DI => spx9_inst_5_DI_i
        );

    spx9_inst_6: SPX9
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 9,
            RESET_MODE => "SYNC",
            BLK_SEL => "010"
        )
        port map (
            DO => spx9_inst_6_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => spx9_inst_6_BLKSEL_i,
            AD => spx9_inst_6_AD_i,
            DI => spx9_inst_6_DI_i
        );

    spx9_inst_7: SPX9
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 9,
            RESET_MODE => "SYNC",
            BLK_SEL => "011"
        )
        port map (
            DO => spx9_inst_7_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => spx9_inst_7_BLKSEL_i,
            AD => spx9_inst_7_AD_i,
            DI => spx9_inst_7_DI_i
        );

    sp_inst_8: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_8_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_8_BLKSEL_i,
            AD => sp_inst_8_AD_i,
            DI => sp_inst_8_DI_i
        );

    sp_inst_9: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_9_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_9_BLKSEL_i,
            AD => sp_inst_9_AD_i,
            DI => sp_inst_9_DI_i
        );

    sp_inst_10: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_10_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_10_BLKSEL_i,
            AD => sp_inst_10_AD_i,
            DI => sp_inst_10_DI_i
        );

    sp_inst_11: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_11_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_11_BLKSEL_i,
            AD => sp_inst_11_AD_i,
            DI => sp_inst_11_DI_i
        );

    sp_inst_12: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_12_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_12_BLKSEL_i,
            AD => sp_inst_12_AD_i,
            DI => sp_inst_12_DI_i
        );

    sp_inst_13: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_13_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_13_BLKSEL_i,
            AD => sp_inst_13_AD_i,
            DI => sp_inst_13_DI_i
        );

    sp_inst_14: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_14_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_14_BLKSEL_i,
            AD => sp_inst_14_AD_i,
            DI => sp_inst_14_DI_i
        );

    dff_inst_0: DFFRE
        port map (
            Q => dff_q_0,
            D => ad(12),
            CLK => clk,
            CE => ce_w,
            RESET => gw_gnd
        );

    dff_inst_1: DFFRE
        port map (
            Q => dff_q_1,
            D => ad(11),
            CLK => clk,
            CE => ce_w,
            RESET => gw_gnd
        );

    mux_inst_0: MUX2
        port map (
            O => mux_o_0,
            I0 => spx9_inst_0_dout(0),
            I1 => spx9_inst_1_dout(0),
            S0 => dff_q_1
        );

    mux_inst_1: MUX2
        port map (
            O => mux_o_1,
            I0 => spx9_inst_2_dout(0),
            I1 => spx9_inst_3_dout(0),
            S0 => dff_q_1
        );

    mux_inst_2: MUX2
        port map (
            O => dout(0),
            I0 => mux_o_0,
            I1 => mux_o_1,
            S0 => dff_q_0
        );

    mux_inst_3: MUX2
        port map (
            O => mux_o_3,
            I0 => spx9_inst_0_dout(1),
            I1 => spx9_inst_1_dout(1),
            S0 => dff_q_1
        );

    mux_inst_4: MUX2
        port map (
            O => mux_o_4,
            I0 => spx9_inst_2_dout(1),
            I1 => spx9_inst_3_dout(1),
            S0 => dff_q_1
        );

    mux_inst_5: MUX2
        port map (
            O => dout(1),
            I0 => mux_o_3,
            I1 => mux_o_4,
            S0 => dff_q_0
        );

    mux_inst_6: MUX2
        port map (
            O => mux_o_6,
            I0 => spx9_inst_0_dout(2),
            I1 => spx9_inst_1_dout(2),
            S0 => dff_q_1
        );

    mux_inst_7: MUX2
        port map (
            O => mux_o_7,
            I0 => spx9_inst_2_dout(2),
            I1 => spx9_inst_3_dout(2),
            S0 => dff_q_1
        );

    mux_inst_8: MUX2
        port map (
            O => dout(2),
            I0 => mux_o_6,
            I1 => mux_o_7,
            S0 => dff_q_0
        );

    mux_inst_9: MUX2
        port map (
            O => mux_o_9,
            I0 => spx9_inst_0_dout(3),
            I1 => spx9_inst_1_dout(3),
            S0 => dff_q_1
        );

    mux_inst_10: MUX2
        port map (
            O => mux_o_10,
            I0 => spx9_inst_2_dout(3),
            I1 => spx9_inst_3_dout(3),
            S0 => dff_q_1
        );

    mux_inst_11: MUX2
        port map (
            O => dout(3),
            I0 => mux_o_9,
            I1 => mux_o_10,
            S0 => dff_q_0
        );

    mux_inst_12: MUX2
        port map (
            O => mux_o_12,
            I0 => spx9_inst_0_dout(4),
            I1 => spx9_inst_1_dout(4),
            S0 => dff_q_1
        );

    mux_inst_13: MUX2
        port map (
            O => mux_o_13,
            I0 => spx9_inst_2_dout(4),
            I1 => spx9_inst_3_dout(4),
            S0 => dff_q_1
        );

    mux_inst_14: MUX2
        port map (
            O => dout(4),
            I0 => mux_o_12,
            I1 => mux_o_13,
            S0 => dff_q_0
        );

    mux_inst_15: MUX2
        port map (
            O => mux_o_15,
            I0 => spx9_inst_0_dout(5),
            I1 => spx9_inst_1_dout(5),
            S0 => dff_q_1
        );

    mux_inst_16: MUX2
        port map (
            O => mux_o_16,
            I0 => spx9_inst_2_dout(5),
            I1 => spx9_inst_3_dout(5),
            S0 => dff_q_1
        );

    mux_inst_17: MUX2
        port map (
            O => dout(5),
            I0 => mux_o_15,
            I1 => mux_o_16,
            S0 => dff_q_0
        );

    mux_inst_18: MUX2
        port map (
            O => mux_o_18,
            I0 => spx9_inst_0_dout(6),
            I1 => spx9_inst_1_dout(6),
            S0 => dff_q_1
        );

    mux_inst_19: MUX2
        port map (
            O => mux_o_19,
            I0 => spx9_inst_2_dout(6),
            I1 => spx9_inst_3_dout(6),
            S0 => dff_q_1
        );

    mux_inst_20: MUX2
        port map (
            O => dout(6),
            I0 => mux_o_18,
            I1 => mux_o_19,
            S0 => dff_q_0
        );

    mux_inst_21: MUX2
        port map (
            O => mux_o_21,
            I0 => spx9_inst_0_dout(7),
            I1 => spx9_inst_1_dout(7),
            S0 => dff_q_1
        );

    mux_inst_22: MUX2
        port map (
            O => mux_o_22,
            I0 => spx9_inst_2_dout(7),
            I1 => spx9_inst_3_dout(7),
            S0 => dff_q_1
        );

    mux_inst_23: MUX2
        port map (
            O => dout(7),
            I0 => mux_o_21,
            I1 => mux_o_22,
            S0 => dff_q_0
        );

    mux_inst_24: MUX2
        port map (
            O => mux_o_24,
            I0 => spx9_inst_0_dout(8),
            I1 => spx9_inst_1_dout(8),
            S0 => dff_q_1
        );

    mux_inst_25: MUX2
        port map (
            O => mux_o_25,
            I0 => spx9_inst_2_dout(8),
            I1 => spx9_inst_3_dout(8),
            S0 => dff_q_1
        );

    mux_inst_26: MUX2
        port map (
            O => dout(8),
            I0 => mux_o_24,
            I1 => mux_o_25,
            S0 => dff_q_0
        );

    mux_inst_27: MUX2
        port map (
            O => mux_o_27,
            I0 => spx9_inst_4_dout(9),
            I1 => spx9_inst_5_dout(9),
            S0 => dff_q_1
        );

    mux_inst_28: MUX2
        port map (
            O => mux_o_28,
            I0 => spx9_inst_6_dout(9),
            I1 => spx9_inst_7_dout(9),
            S0 => dff_q_1
        );

    mux_inst_29: MUX2
        port map (
            O => dout(9),
            I0 => mux_o_27,
            I1 => mux_o_28,
            S0 => dff_q_0
        );

    mux_inst_30: MUX2
        port map (
            O => mux_o_30,
            I0 => spx9_inst_4_dout(10),
            I1 => spx9_inst_5_dout(10),
            S0 => dff_q_1
        );

    mux_inst_31: MUX2
        port map (
            O => mux_o_31,
            I0 => spx9_inst_6_dout(10),
            I1 => spx9_inst_7_dout(10),
            S0 => dff_q_1
        );

    mux_inst_32: MUX2
        port map (
            O => dout(10),
            I0 => mux_o_30,
            I1 => mux_o_31,
            S0 => dff_q_0
        );

    mux_inst_33: MUX2
        port map (
            O => mux_o_33,
            I0 => spx9_inst_4_dout(11),
            I1 => spx9_inst_5_dout(11),
            S0 => dff_q_1
        );

    mux_inst_34: MUX2
        port map (
            O => mux_o_34,
            I0 => spx9_inst_6_dout(11),
            I1 => spx9_inst_7_dout(11),
            S0 => dff_q_1
        );

    mux_inst_35: MUX2
        port map (
            O => dout(11),
            I0 => mux_o_33,
            I1 => mux_o_34,
            S0 => dff_q_0
        );

    mux_inst_36: MUX2
        port map (
            O => mux_o_36,
            I0 => spx9_inst_4_dout(12),
            I1 => spx9_inst_5_dout(12),
            S0 => dff_q_1
        );

    mux_inst_37: MUX2
        port map (
            O => mux_o_37,
            I0 => spx9_inst_6_dout(12),
            I1 => spx9_inst_7_dout(12),
            S0 => dff_q_1
        );

    mux_inst_38: MUX2
        port map (
            O => dout(12),
            I0 => mux_o_36,
            I1 => mux_o_37,
            S0 => dff_q_0
        );

    mux_inst_39: MUX2
        port map (
            O => mux_o_39,
            I0 => spx9_inst_4_dout(13),
            I1 => spx9_inst_5_dout(13),
            S0 => dff_q_1
        );

    mux_inst_40: MUX2
        port map (
            O => mux_o_40,
            I0 => spx9_inst_6_dout(13),
            I1 => spx9_inst_7_dout(13),
            S0 => dff_q_1
        );

    mux_inst_41: MUX2
        port map (
            O => dout(13),
            I0 => mux_o_39,
            I1 => mux_o_40,
            S0 => dff_q_0
        );

    mux_inst_42: MUX2
        port map (
            O => mux_o_42,
            I0 => spx9_inst_4_dout(14),
            I1 => spx9_inst_5_dout(14),
            S0 => dff_q_1
        );

    mux_inst_43: MUX2
        port map (
            O => mux_o_43,
            I0 => spx9_inst_6_dout(14),
            I1 => spx9_inst_7_dout(14),
            S0 => dff_q_1
        );

    mux_inst_44: MUX2
        port map (
            O => dout(14),
            I0 => mux_o_42,
            I1 => mux_o_43,
            S0 => dff_q_0
        );

    mux_inst_45: MUX2
        port map (
            O => mux_o_45,
            I0 => spx9_inst_4_dout(15),
            I1 => spx9_inst_5_dout(15),
            S0 => dff_q_1
        );

    mux_inst_46: MUX2
        port map (
            O => mux_o_46,
            I0 => spx9_inst_6_dout(15),
            I1 => spx9_inst_7_dout(15),
            S0 => dff_q_1
        );

    mux_inst_47: MUX2
        port map (
            O => dout(15),
            I0 => mux_o_45,
            I1 => mux_o_46,
            S0 => dff_q_0
        );

    mux_inst_48: MUX2
        port map (
            O => mux_o_48,
            I0 => spx9_inst_4_dout(16),
            I1 => spx9_inst_5_dout(16),
            S0 => dff_q_1
        );

    mux_inst_49: MUX2
        port map (
            O => mux_o_49,
            I0 => spx9_inst_6_dout(16),
            I1 => spx9_inst_7_dout(16),
            S0 => dff_q_1
        );

    mux_inst_50: MUX2
        port map (
            O => dout(16),
            I0 => mux_o_48,
            I1 => mux_o_49,
            S0 => dff_q_0
        );

    mux_inst_51: MUX2
        port map (
            O => mux_o_51,
            I0 => spx9_inst_4_dout(17),
            I1 => spx9_inst_5_dout(17),
            S0 => dff_q_1
        );

    mux_inst_52: MUX2
        port map (
            O => mux_o_52,
            I0 => spx9_inst_6_dout(17),
            I1 => spx9_inst_7_dout(17),
            S0 => dff_q_1
        );

    mux_inst_53: MUX2
        port map (
            O => dout(17),
            I0 => mux_o_51,
            I1 => mux_o_52,
            S0 => dff_q_0
        );

end Behavioral; --RV32_RAM
