--
--Written by GowinSynthesis
--Tool Version "V1.9.12 (64-bit)"
--Sat Jun  6 16:33:06 2026

--Source file index table:
--file0 "\C:/Gowin/Gowin_V1.9.12_x64/IDE/ipcore/UARTMASTER/data/uart_master_top.v"
--file1 "\C:/Gowin/Gowin_V1.9.12_x64/IDE/ipcore/UARTMASTER/data/uart_master_encrypt.v"
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library gw5a;
use gw5a.components.all;

entity UART_MASTER_Top is
port(
  I_CLK :  in std_logic;
  I_RESETN :  in std_logic;
  I_TX_EN :  in std_logic;
  I_WADDR :  in std_logic_vector(2 downto 0);
  I_WDATA :  in std_logic_vector(7 downto 0);
  I_RX_EN :  in std_logic;
  I_RADDR :  in std_logic_vector(2 downto 0);
  O_RDATA :  out std_logic_vector(7 downto 0);
  SIN :  in std_logic;
  RxRDYn :  out std_logic;
  SOUT :  out std_logic;
  TxRDYn :  out std_logic;
  DDIS :  out std_logic;
  INTR :  out std_logic;
  DCDn :  in std_logic;
  CTSn :  in std_logic;
  DSRn :  in std_logic;
  RIn :  in std_logic;
  DTRn :  out std_logic;
  RTSn :  out std_logic);
end UART_MASTER_Top;
architecture beh of UART_MASTER_Top is
  signal i4_u_uart_sram_TxBreak : std_logic ;
  signal i4_u_uart_sram_ParityStick : std_logic ;
  signal i4_u_uart_sram_ParityEven : std_logic ;
  signal i4_u_uart_sram_ParityEnable : std_logic ;
  signal i4_u_uart_sram_I_RX_EN_dl : std_logic ;
  signal i4_u_uart_sram_ThrWRn_re_Z : std_logic ;
  signal i4_u_uart_sram_LsrRDn_re_Z : std_logic ;
  signal i4_u_uart_sram_IirRDn_re : std_logic ;
  signal i4_u_uart_sram_MsrRDn_re_Z : std_logic ;
  signal i4_U_Modem_DSRn1 : std_logic ;
  signal i4_U_Modem_DCDn1 : std_logic ;
  signal i4_U_Modem_RIn1 : std_logic ;
  signal i4_U_Modem_CTSn1 : std_logic ;
  signal i4_U_Rxcver_RxIdle_r_2 : std_logic ;
  signal i4_U_Rxcver_RxClkEn : std_logic ;
  signal i4_U_Rxcver_RxRDY : std_logic ;
  signal i4_U_Rxcver_SIN1_r : std_logic ;
  signal i4_U_Rxcver_SIN1_rr : std_logic ;
  signal i4_U_Rxcver_SIN1_rrr : std_logic ;
  signal i4_U_Rxcver_RxFrmErr1_r : std_logic ;
  signal i4_U_Rxcver_RxIdle1_r : std_logic ;
  signal i4_U_Rxcver_ParityErr : std_logic ;
  signal i4_U_Rxcver_FrameErr : std_logic ;
  signal i4_U_Rxcver_BreakInt : std_logic ;
  signal i4_U_Rxcver_RxIdle_r_1 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_full : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_empty : std_logic ;
  signal i4_U_Txmitt_fifo_rd2 : std_logic ;
  signal i4_U_Txmitt_fifo_rd3 : std_logic ;
  signal i4_U_Txmitt_TxParity_r : std_logic ;
  signal i4_U_Txmitt_TxInShiftState1 : std_logic ;
  signal i4_U_Txmitt_TxInStopState1 : std_logic ;
  signal i4_U_Txmitt_TxInShiftState : std_logic ;
  signal i4_U_Txmitt_TxInStopState : std_logic ;
  signal i4_U_Txmitt_TxClkEnA : std_logic ;
  signal i4_U_Txmitt_fifo_rd1 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_full : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty : std_logic ;
  signal i4_u_uart_sram_OE_re_Z : std_logic ;
  signal i4_u_uart_sram_PE_re_Z : std_logic ;
  signal i4_u_uart_sram_FE_re_Z : std_logic ;
  signal i4_u_uart_sram_BI_re_Z : std_logic ;
  signal i4_U_Rxcver_Hunt_r : std_logic ;
  signal i4_U_Rxcver_HuntOne_r : std_logic ;
  signal i4_U_Rxcver_RxPrtyErr : std_logic ;
  signal i4_U_Rxcver_RxFrmErr : std_logic ;
  signal i4_U_Rxcver_OverrunErr : std_logic ;
  signal i4_U_Txmitt_fifo_rd : std_logic ;
  signal i4_U_Txmitt_TsrEmpty : std_logic ;
  signal i4_U_Txmitt_THRE : std_logic ;
  signal i4_U_Txmitt_TxOutput : std_logic ;
  signal i4_u_baudset_rxclk_Z : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO31 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO30 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO29 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO28 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO27 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO26 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO25 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO24 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO23 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO22 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO21 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO20 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO19 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO18 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO17 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO16 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO15 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO14 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO13 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO12 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO11 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO10 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO9 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO8 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO31 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO30 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO29 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO28 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO27 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO26 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO25 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO24 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO23 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO22 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO21 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO20 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO19 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO18 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO17 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO16 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO15 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO14 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO13 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO12 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO11 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO10 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO9 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO8 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n50 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n50_3 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n51 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n51_3 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n52 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n52_3 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n53 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n53_3 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n50 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n50_3 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n51 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n51_3 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n52 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n52_3 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n53 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n53_3 : std_logic ;
  signal i4_u_uart_sram_n360 : std_logic ;
  signal i4_u_uart_sram_n367 : std_logic ;
  signal i4_u_uart_sram_n371 : std_logic ;
  signal i4_u_uart_sram_n378 : std_logic ;
  signal i4_u_uart_sram_n173 : std_logic ;
  signal i4_u_uart_sram_n192 : std_logic ;
  signal i4_U_Rxcver_n18 : std_logic ;
  signal i4_U_Rxcver_n336 : std_logic ;
  signal i4_U_Rxcver_n43 : std_logic ;
  signal i4_U_Rxcver_n189 : std_logic ;
  signal i4_U_Rxcver_n273 : std_logic ;
  signal i4_U_Rxcver_n274 : std_logic ;
  signal i4_U_Rxcver_n275 : std_logic ;
  signal i4_U_Rxcver_n284 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_n22 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val : std_logic ;
  signal i4_U_Txmitt_fifo_wr : std_logic ;
  signal i4_U_Txmitt_rise_edge_fifo_rd : std_logic ;
  signal i4_U_Txmitt_n119 : std_logic ;
  signal i4_U_Txmitt_n185 : std_logic ;
  signal i4_U_Txmitt_n214 : std_logic ;
  signal i4_U_Txmitt_n237 : std_logic ;
  signal i4_U_Txmitt_n262 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val : std_logic ;
  signal i4_U_Rxcver_n195 : std_logic ;
  signal i4_U_Rxcver_n196 : std_logic ;
  signal i4_U_Rxcver_n197 : std_logic ;
  signal i4_U_Rxcver_n198 : std_logic ;
  signal i4_U_Txmitt_n145 : std_logic ;
  signal i4_U_Txmitt_n146 : std_logic ;
  signal i4_U_Txmitt_n147 : std_logic ;
  signal i4_U_Txmitt_n148 : std_logic ;
  signal i4_U_Txmitt_n149 : std_logic ;
  signal i4_U_Txmitt_n152 : std_logic ;
  signal i4_U_Txmitt_n153 : std_logic ;
  signal i4_U_Txmitt_n154 : std_logic ;
  signal i4_U_Txmitt_n155 : std_logic ;
  signal i4_U_Txmitt_n156 : std_logic ;
  signal i4_U_Txmitt_n157 : std_logic ;
  signal i4_U_Txmitt_n158 : std_logic ;
  signal i4_u_uart_sram_OE_re : std_logic ;
  signal i4_u_uart_sram_PE_re : std_logic ;
  signal i4_u_uart_sram_FE_re : std_logic ;
  signal i4_u_uart_sram_BI_re : std_logic ;
  signal i4_U_Rxcver_HuntOne_r_8 : std_logic ;
  signal i4_U_Rxcver_RSR_7 : std_logic ;
  signal i4_U_Rxcver_RxPrtyErr_8 : std_logic ;
  signal i4_U_Txmitt_TSR_6 : std_logic ;
  signal i4_U_Txmitt_TsrEmpty_8 : std_logic ;
  signal i4_U_Txmitt_ThrEmpty : std_logic ;
  signal i4_u_baudset_rxclk : std_logic ;
  signal i4_u_uart_sram_Int_State_0 : std_logic ;
  signal i4_u_uart_sram_n280 : std_logic ;
  signal i4_U_Txmitt_n151 : std_logic ;
  signal i4_U_Txmitt_n160 : std_logic ;
  signal i4_U_Txmitt_n159 : std_logic ;
  signal i4_U_Rxcver_n210 : std_logic ;
  signal i4_U_Rxcver_n209 : std_logic ;
  signal i4_U_Rxcver_n208 : std_logic ;
  signal i4_U_Rxcver_n207 : std_logic ;
  signal i4_U_Rxcver_n206 : std_logic ;
  signal i4_U_Rxcver_n205 : std_logic ;
  signal i4_U_Rxcver_n204 : std_logic ;
  signal i4_U_Rxcver_n203 : std_logic ;
  signal i4_U_Rxcver_n202 : std_logic ;
  signal i4_U_Rxcver_n201 : std_logic ;
  signal i4_U_Rxcver_n200 : std_logic ;
  signal i4_U_Rxcver_n199 : std_logic ;
  signal i4_U_Rxcver_n195_15 : std_logic ;
  signal i4_u_baudset_n36 : std_logic ;
  signal i4_u_baudset_n33 : std_logic ;
  signal i4_u_baudset_n32 : std_logic ;
  signal i4_U_Txmitt_n271 : std_logic ;
  signal i4_U_Txmitt_n270 : std_logic ;
  signal i4_U_Txmitt_n269 : std_logic ;
  signal i4_U_Rxcver_n42 : std_logic ;
  signal i4_U_Rxcver_n41 : std_logic ;
  signal i4_U_Rxcver_n40 : std_logic ;
  signal i4_U_Modem_n34 : std_logic ;
  signal i4_U_Modem_n33 : std_logic ;
  signal i4_U_Modem_n32 : std_logic ;
  signal i4_U_Modem_n31 : std_logic ;
  signal i4_u_uart_sram_n257 : std_logic ;
  signal i4_u_uart_sram_n258 : std_logic ;
  signal i4_u_baudset_n31 : std_logic ;
  signal i4_u_baudset_n37 : std_logic ;
  signal i4_u_baudset_n35 : std_logic ;
  signal i4_u_baudset_n34 : std_logic ;
  signal i4_U_Txmitt_Tx_State_0 : std_logic ;
  signal i4_U_Txmitt_Tx_State_1 : std_logic ;
  signal i4_u_uart_sram_RbrRDn_re_Z : std_logic ;
  signal i4_u_uart_sram_n165 : std_logic ;
  signal i4_u_uart_sram_n201 : std_logic ;
  signal i4_u_uart_sram_INTR_d : std_logic ;
  signal i4_U_Rxcver_n336_4 : std_logic ;
  signal i4_U_Rxcver_n189_4 : std_logic ;
  signal i4_U_Rxcver_n273_4 : std_logic ;
  signal i4_U_Rxcver_n273_5 : std_logic ;
  signal i4_U_Rxcver_n284_4 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_2 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_3 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_4 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_5 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_6 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_7 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_0 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_3 : std_logic ;
  signal i4_U_Txmitt_n119_5 : std_logic ;
  signal i4_U_Txmitt_n237_4 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_4 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_5 : std_logic ;
  signal i4_U_Rxcver_n195_16 : std_logic ;
  signal i4_U_Rxcver_n198_10 : std_logic ;
  signal i4_U_Rxcver_n198_11 : std_logic ;
  signal i4_U_Rxcver_RBR_r_5 : std_logic ;
  signal i4_U_Rxcver_RBR_r_4 : std_logic ;
  signal i4_U_Rxcver_RBR_r_3 : std_logic ;
  signal i4_U_Rxcver_RBR_r_2 : std_logic ;
  signal i4_U_Rxcver_RBR_r_1 : std_logic ;
  signal i4_U_Rxcver_RBR_r_0 : std_logic ;
  signal i4_U_Txmitt_n145_20 : std_logic ;
  signal i4_U_Txmitt_n146_17 : std_logic ;
  signal i4_U_Txmitt_n147_31 : std_logic ;
  signal i4_U_Txmitt_n147_32 : std_logic ;
  signal i4_U_Txmitt_n148_25 : std_logic ;
  signal i4_U_Txmitt_n148_26 : std_logic ;
  signal i4_U_Txmitt_n149_14 : std_logic ;
  signal i4_U_Txmitt_n149_15 : std_logic ;
  signal i4_U_Txmitt_n149_16 : std_logic ;
  signal i4_U_Txmitt_n158_13 : std_logic ;
  signal i4_u_baudset_rxclk_6 : std_logic ;
  signal i4_u_uart_sram_Int_State_0_12 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_3 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_1 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_3 : std_logic ;
  signal i4_u_uart_sram_n280_31 : std_logic ;
  signal i4_u_uart_sram_n280_32 : std_logic ;
  signal i4_U_Rxcver_n207_11 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_0 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_0_8 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_1 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_2 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_2_8 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_3 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_4 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_5 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_6 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_6_8 : std_logic ;
  signal i4_u_baudset_n33_8 : std_logic ;
  signal i4_U_Rxcver_n40_8 : std_logic ;
  signal i4_u_uart_sram_n258_7 : std_logic ;
  signal i4_u_baudset_n31_8 : std_logic ;
  signal i4_U_Txmitt_Tx_State_1_10 : std_logic ;
  signal i4_U_Rxcver_n189_5 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_8 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_6 : std_logic ;
  signal i4_U_Txmitt_n147_33 : std_logic ;
  signal i4_U_Txmitt_n147_34 : std_logic ;
  signal i4_U_Txmitt_n148_27 : std_logic ;
  signal i4_U_Txmitt_n148_28 : std_logic ;
  signal i4_u_baudset_rxclk_7 : std_logic ;
  signal i4_u_uart_sram_Int_State_0_13 : std_logic ;
  signal i4_u_uart_sram_Int_State_0_15 : std_logic ;
  signal i4_u_uart_sram_n280_33 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_1_8 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_2_9 : std_logic ;
  signal i4_u_uart_sram_n257_8 : std_logic ;
  signal i4_u_uart_sram_Int_State_0_16 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_1_9 : std_logic ;
  signal i4_u_uart_sram_n257_10 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_0 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_0 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_1 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_0 : std_logic ;
  signal i4_U_Rxcver_Hunt_r_10 : std_logic ;
  signal i4_U_Rxcver_n43_6 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_1 : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_0 : std_logic ;
  signal i4_u_uart_sram_n258_10 : std_logic ;
  signal i4_u_uart_sram_Int_State_0_18 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_0 : std_logic ;
  signal i4_u_uart_sram_n201_6 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_3_10 : std_logic ;
  signal i4_u_uart_sram_n165_6 : std_logic ;
  signal i4_u_uart_sram_reg_data_out_7 : std_logic ;
  signal i4_u_uart_sram_RbrRDn_re_Z_5 : std_logic ;
  signal i4_U_Rxcver_RxIdle_r : std_logic ;
  signal i4_U_Txmitt_n161 : std_logic ;
  signal i4_U_Txmitt_TxCNT_r_2 : std_logic ;
  signal i4_U_Modem_n26 : std_logic ;
  signal i4_U_Modem_n26_18 : std_logic ;
  signal i4_U_Modem_n26_21 : std_logic ;
  signal i4_U_Modem_n26_24 : std_logic ;
  signal i4_U_Rxcver_n99 : std_logic ;
  signal i4_U_Rxcver_n99_12 : std_logic ;
  signal i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rempty_val : std_logic ;
  signal i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rempty_val : std_logic ;
  signal i4_U_Rxcver_OverrunErr_r : std_logic ;
  signal i4_u_uart_sram_n14 : std_logic ;
  signal i4_U_Txmitt_n272 : std_logic ;
  signal i4_U_Rxcver_n82 : std_logic ;
  signal i4_U_Rxcver_n74 : std_logic ;
  signal i4_U_Txmitt_n200 : std_logic ;
  signal i4_u_baudset_n38 : std_logic ;
  signal GND_0 : std_logic ;
  signal VCC_0 : std_logic ;
  signal \i4/u_uart_sram/THR_Z\ : std_logic_vector(7 downto 0);
  signal \i4/u_uart_sram/IER\ : std_logic_vector(3 downto 0);
  signal \i4/u_uart_sram/LCR\ : std_logic_vector(2 downto 2);
  signal \i4/u_uart_sram/DataBits\ : std_logic_vector(1 downto 0);
  signal \i4/u_uart_sram/MCR_Z\ : std_logic_vector(1 downto 0);
  signal \i4/u_uart_sram/Int_State\ : std_logic_vector(2 downto 0);
  signal \i4/U_Modem/MSR\ : std_logic_vector(7 downto 0);
  signal \i4/U_Rxcver/CNT_r\ : std_logic_vector(3 downto 0);
  signal \i4/U_Rxcver/RSR\ : std_logic_vector(7 downto 0);
  signal \i4/U_Rxcver/NumDataBitReceived_r\ : std_logic_vector(3 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\ : std_logic_vector(4 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\ : std_logic_vector(4 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\ : std_logic_vector(4 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\ : std_logic_vector(4 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\ : std_logic_vector(3 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin\ : std_logic_vector(4 downto 4);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\ : std_logic_vector(3 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\ : std_logic_vector(3 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbin\ : std_logic_vector(4 downto 4);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\ : std_logic_vector(3 downto 0);
  signal \i4/U_Txmitt/TxCNT_r\ : std_logic_vector(2 downto 0);
  signal \i4/U_Txmitt/TSR\ : std_logic_vector(6 downto 0);
  signal \i4/U_Txmitt/Tx_State\ : std_logic_vector(2 downto 0);
  signal \i4/U_Txmitt/Count_vr\ : std_logic_vector(3 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\ : std_logic_vector(4 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\ : std_logic_vector(4 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\ : std_logic_vector(4 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\ : std_logic_vector(4 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\ : std_logic_vector(3 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbin\ : std_logic_vector(4 downto 4);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\ : std_logic_vector(3 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\ : std_logic_vector(3 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbin\ : std_logic_vector(4 downto 4);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\ : std_logic_vector(3 downto 0);
  signal \i4/u_baudset/cnt1\ : std_logic_vector(6 downto 0);
  signal \i4/U_Rxcver/Rx_State\ : std_logic_vector(1 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/RBR\ : std_logic_vector(7 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\ : std_logic_vector(7 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\ : std_logic_vector(3 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\ : std_logic_vector(3 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\ : std_logic_vector(3 downto 0);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\ : std_logic_vector(3 downto 0);
  signal \i4/U_Rxcver/RBR_r\ : std_logic_vector(7 downto 0);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\ : std_logic_vector(4 downto 1);
  signal \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\ : std_logic_vector(4 downto 1);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\ : std_logic_vector(4 downto 1);
  signal \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\ : std_logic_vector(4 downto 1);
  signal \i4/u_uart_sram/reg_data_out\ : std_logic_vector(7 downto 0);
  signal NN : std_logic;
begin
\i4/u_uart_sram/THR_6_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/THR_Z\(6),
  D => I_WDATA(6),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n360);
\i4/u_uart_sram/THR_5_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/THR_Z\(5),
  D => I_WDATA(5),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n360);
\i4/u_uart_sram/THR_4_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/THR_Z\(4),
  D => I_WDATA(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n360);
\i4/u_uart_sram/THR_3_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/THR_Z\(3),
  D => I_WDATA(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n360);
\i4/u_uart_sram/THR_2_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/THR_Z\(2),
  D => I_WDATA(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n360);
\i4/u_uart_sram/THR_1_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/THR_Z\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n360);
\i4/u_uart_sram/THR_0_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/THR_Z\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n360);
\i4/u_uart_sram/IER_3_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/IER\(3),
  D => I_WDATA(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n367);
\i4/u_uart_sram/IER_2_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/IER\(2),
  D => I_WDATA(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n367);
\i4/u_uart_sram/IER_1_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/IER\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n367);
\i4/u_uart_sram/IER_0_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/IER\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n367);
\i4/u_uart_sram/LCR_6_s0\: DFFCE
port map (
  Q => i4_u_uart_sram_TxBreak,
  D => I_WDATA(6),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n371);
\i4/u_uart_sram/LCR_5_s0\: DFFCE
port map (
  Q => i4_u_uart_sram_ParityStick,
  D => I_WDATA(5),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n371);
\i4/u_uart_sram/LCR_4_s0\: DFFCE
port map (
  Q => i4_u_uart_sram_ParityEven,
  D => I_WDATA(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n371);
\i4/u_uart_sram/LCR_3_s0\: DFFCE
port map (
  Q => i4_u_uart_sram_ParityEnable,
  D => I_WDATA(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n371);
\i4/u_uart_sram/LCR_2_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/LCR\(2),
  D => I_WDATA(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n371);
\i4/u_uart_sram/LCR_0_s0\: DFFPE
port map (
  Q => \i4/u_uart_sram/DataBits\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n371);
\i4/u_uart_sram/MCR_1_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/MCR_Z\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n378);
\i4/u_uart_sram/MCR_0_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/MCR_Z\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n378);
\i4/u_uart_sram/I_RX_EN_dl_s0\: DFFCE
port map (
  Q => i4_u_uart_sram_I_RX_EN_dl,
  D => I_RX_EN,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_uart_sram/rdata_7_s0\: DFFCE
port map (
  Q => O_RDATA(7),
  D => \i4/u_uart_sram/reg_data_out\(7),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_I_RX_EN_dl);
\i4/u_uart_sram/rdata_6_s0\: DFFCE
port map (
  Q => O_RDATA(6),
  D => \i4/u_uart_sram/reg_data_out\(6),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_I_RX_EN_dl);
\i4/u_uart_sram/rdata_5_s0\: DFFCE
port map (
  Q => O_RDATA(5),
  D => \i4/u_uart_sram/reg_data_out\(5),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_I_RX_EN_dl);
\i4/u_uart_sram/rdata_4_s0\: DFFCE
port map (
  Q => O_RDATA(4),
  D => \i4/u_uart_sram/reg_data_out\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_I_RX_EN_dl);
\i4/u_uart_sram/rdata_3_s0\: DFFCE
port map (
  Q => O_RDATA(3),
  D => \i4/u_uart_sram/reg_data_out\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_I_RX_EN_dl);
\i4/u_uart_sram/rdata_2_s0\: DFFCE
port map (
  Q => O_RDATA(2),
  D => \i4/u_uart_sram/reg_data_out\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_I_RX_EN_dl);
\i4/u_uart_sram/rdata_1_s0\: DFFCE
port map (
  Q => O_RDATA(1),
  D => \i4/u_uart_sram/reg_data_out\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_I_RX_EN_dl);
\i4/u_uart_sram/rdata_0_s0\: DFFCE
port map (
  Q => O_RDATA(0),
  D => \i4/u_uart_sram/reg_data_out\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_I_RX_EN_dl);
\i4/u_uart_sram/ThrWRn_re_s0\: DFFCE
port map (
  Q => i4_u_uart_sram_ThrWRn_re_Z,
  D => i4_u_uart_sram_n360,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_uart_sram/LsrRDn_re_s0\: DFFCE
port map (
  Q => i4_u_uart_sram_LsrRDn_re_Z,
  D => i4_u_uart_sram_n165_6,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_uart_sram/IirRDn_re_s0\: DFFCE
port map (
  Q => i4_u_uart_sram_IirRDn_re,
  D => i4_u_uart_sram_n192,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_uart_sram/MsrRDn_re_s0\: DFFCE
port map (
  Q => i4_u_uart_sram_MsrRDn_re_Z,
  D => i4_u_uart_sram_n201_6,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_uart_sram/Int_State_2_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/Int_State\(2),
  D => i4_u_uart_sram_n257,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_uart_sram/Int_State_1_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/Int_State\(1),
  D => i4_u_uart_sram_n258,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_uart_sram/THR_7_s0\: DFFCE
port map (
  Q => \i4/u_uart_sram/THR_Z\(7),
  D => I_WDATA(7),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n360);
\i4/u_uart_sram/LCR_1_s0\: DFFPE
port map (
  Q => \i4/u_uart_sram/DataBits\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_n371);
\i4/U_Modem/MSReg_6_s0\: DFFCE
port map (
  Q => \i4/U_Modem/MSR\(6),
  D => i4_U_Modem_n32,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/MSReg_5_s0\: DFFCE
port map (
  Q => \i4/U_Modem/MSR\(5),
  D => i4_U_Modem_n33,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/MSReg_4_s0\: DFFCE
port map (
  Q => \i4/U_Modem/MSR\(4),
  D => i4_U_Modem_n34,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/DSRn1_s0\: DFFPE
port map (
  Q => i4_U_Modem_DSRn1,
  D => DSRn,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/DCDn1_s0\: DFFPE
port map (
  Q => i4_U_Modem_DCDn1,
  D => DCDn,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/RIn1_s0\: DFFPE
port map (
  Q => i4_U_Modem_RIn1,
  D => RIn,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/MSReg_7_s0\: DFFCE
port map (
  Q => \i4/U_Modem/MSR\(7),
  D => i4_U_Modem_n31,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/CTSn1_s0\: DFFPE
port map (
  Q => i4_U_Modem_CTSn1,
  D => CTSn,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/RxIdle_r_2_s0\: DFFSE
port map (
  Q => i4_U_Rxcver_RxIdle_r_2,
  D => i4_U_Rxcver_RxIdle_r_1,
  CLK => I_CLK,
  SET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/RxClkEn_s0\: DFFCE
port map (
  Q => i4_U_Rxcver_RxClkEn,
  D => i4_U_Rxcver_n18,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/CNT_r_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/CNT_r\(3),
  D => i4_U_Rxcver_n40,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/CNT_r_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/CNT_r\(2),
  D => i4_U_Rxcver_n41,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/CNT_r_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/CNT_r\(1),
  D => i4_U_Rxcver_n42,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/CNT_r_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/CNT_r\(0),
  D => i4_U_Rxcver_n43,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/RbrDataRDY_s0\: DFFCE
port map (
  Q => i4_U_Rxcver_RxRDY,
  D => i4_U_Rxcver_n82,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/RSR_7_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/RSR\(7),
  D => i4_U_Rxcver_n199,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/RSR_6_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/RSR\(6),
  D => i4_U_Rxcver_n200,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/RSR_5_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/RSR\(5),
  D => i4_U_Rxcver_n201,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/RSR_4_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/RSR\(4),
  D => i4_U_Rxcver_n202,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/RSR_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/RSR\(3),
  D => i4_U_Rxcver_n203,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/RSR_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/RSR\(2),
  D => i4_U_Rxcver_n204,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/RSR_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/RSR\(1),
  D => i4_U_Rxcver_n205,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/RSR_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/RSR\(0),
  D => i4_U_Rxcver_n206,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/NumDataBitReceived_r_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/NumDataBitReceived_r\(3),
  D => i4_U_Rxcver_n207,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/NumDataBitReceived_r_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/NumDataBitReceived_r\(2),
  D => i4_U_Rxcver_n208,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/NumDataBitReceived_r_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/NumDataBitReceived_r\(1),
  D => i4_U_Rxcver_n209,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/NumDataBitReceived_r_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/NumDataBitReceived_r\(0),
  D => i4_U_Rxcver_n210,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RSR_7);
\i4/U_Rxcver/SIN1_r_s0\: DFFCE
port map (
  Q => i4_U_Rxcver_SIN1_r,
  D => SIN,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/SIN1_rr_s0\: DFFCE
port map (
  Q => i4_U_Rxcver_SIN1_rr,
  D => i4_U_Rxcver_SIN1_r,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/SIN1_rrr_s0\: DFFCE
port map (
  Q => i4_U_Rxcver_SIN1_rrr,
  D => i4_U_Rxcver_SIN1_rr,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/RxFrmErr1_r_s0\: DFFPE
port map (
  Q => i4_U_Rxcver_RxFrmErr1_r,
  D => i4_U_Rxcver_RxFrmErr,
  CLK => i4_u_baudset_rxclk_Z,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/RxIdle1_r_s0\: DFFPE
port map (
  Q => i4_U_Rxcver_RxIdle1_r,
  D => i4_U_Rxcver_RxIdle_r,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/ParityErr_r_s0\: DFFCE
port map (
  Q => i4_U_Rxcver_ParityErr,
  D => i4_U_Rxcver_n273,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/FrameErr_r_s0\: DFFCE
port map (
  Q => i4_U_Rxcver_FrameErr,
  D => i4_U_Rxcver_n274,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/BreakInt_r_s0\: DFFCE
port map (
  Q => i4_U_Rxcver_BreakInt,
  D => i4_U_Rxcver_n275,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/RxIdle_r_1_s0\: DFFSE
port map (
  Q => i4_U_Rxcver_RxIdle_r_1,
  D => i4_U_Rxcver_RxIdle_r,
  CLK => I_CLK,
  SET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(3),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(2),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(1),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(0),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_4_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(4),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(3),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(2),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(1),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(0),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr_4_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(4),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbin\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(3),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(2),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(1),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(0),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_4_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(4),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(3),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(2),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(1),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(0),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr_4_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(4),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(3),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(2),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(1),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(0),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin_4_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin\(4),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(0),
  D => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_0,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wfull_s0\: DFFCE
port map (
  Q => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_full,
  D => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(3),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(2),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(1),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(0),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbin_4_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbin\(4),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbin_3_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(3),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbin_2_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbin_1_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  D => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbin_0_s0\: DFFCE
port map (
  Q => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(0),
  D => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_0,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rempty_s0\: DFFPE
port map (
  Q => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  D => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rempty_val,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/fifo_rd2_s0\: DFFRE
port map (
  Q => i4_U_Txmitt_fifo_rd2,
  D => i4_U_Txmitt_fifo_rd1,
  CLK => I_CLK,
  RESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/fifo_rd3_s0\: DFFRE
port map (
  Q => i4_U_Txmitt_fifo_rd3,
  D => i4_U_Txmitt_fifo_rd2,
  CLK => I_CLK,
  RESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/TxCNT_r_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/TxCNT_r\(2),
  D => i4_U_Txmitt_n159,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TxCNT_r_2);
\i4/U_Txmitt/TxCNT_r_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/TxCNT_r\(1),
  D => i4_U_Txmitt_n160,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TxCNT_r_2);
\i4/U_Txmitt/TSR_6_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/TSR\(6),
  D => i4_U_Txmitt_n151,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TSR_6);
\i4/U_Txmitt/TSR_5_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/TSR\(5),
  D => i4_U_Txmitt_n152,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TSR_6);
\i4/U_Txmitt/TSR_4_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/TSR\(4),
  D => i4_U_Txmitt_n153,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TSR_6);
\i4/U_Txmitt/TSR_3_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/TSR\(3),
  D => i4_U_Txmitt_n154,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TSR_6);
\i4/U_Txmitt/TSR_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/TSR\(2),
  D => i4_U_Txmitt_n155,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TSR_6);
\i4/U_Txmitt/TSR_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/TSR\(1),
  D => i4_U_Txmitt_n156,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TSR_6);
\i4/U_Txmitt/TSR_0_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/TSR\(0),
  D => i4_U_Txmitt_n157,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TSR_6);
\i4/U_Txmitt/TxParity_r_s0\: DFFPE
port map (
  Q => i4_U_Txmitt_TxParity_r,
  D => i4_U_Txmitt_n158,
  CLK => i4_u_baudset_rxclk_Z,
  PRESET => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TSR_6);
\i4/U_Txmitt/Tx_State_2_s0\: DFFPE
port map (
  Q => \i4/U_Txmitt/Tx_State\(2),
  D => i4_U_Txmitt_n146,
  CLK => i4_u_baudset_rxclk_Z,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/TxInShiftState1_s0\: DFFPE
port map (
  Q => i4_U_Txmitt_TxInShiftState1,
  D => i4_U_Txmitt_TxInShiftState,
  CLK => i4_u_baudset_rxclk_Z,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/TxInStopState1_s0\: DFFPE
port map (
  Q => i4_U_Txmitt_TxInStopState1,
  D => i4_U_Txmitt_TxInStopState,
  CLK => i4_u_baudset_rxclk_Z,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/TxInShiftState_s0\: DFFCE
port map (
  Q => i4_U_Txmitt_TxInShiftState,
  D => i4_U_Txmitt_n214,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/TxInStopState_s0\: DFFCE
port map (
  Q => i4_U_Txmitt_TxInStopState,
  D => i4_U_Txmitt_n237,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Count_vr_3_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Count_vr\(3),
  D => i4_U_Txmitt_n269,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Count_vr_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Count_vr\(2),
  D => i4_U_Txmitt_n270,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Count_vr_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Count_vr\(1),
  D => i4_U_Txmitt_n271,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Count_vr_0_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Count_vr\(0),
  D => i4_U_Txmitt_n272,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/TxClkEnA_s0\: DFFCE
port map (
  Q => i4_U_Txmitt_TxClkEnA,
  D => i4_U_Txmitt_n262,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/fifo_rd1_s0\: DFFRE
port map (
  Q => i4_U_Txmitt_fifo_rd1,
  D => i4_U_Txmitt_fifo_rd,
  CLK => I_CLK,
  RESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(3),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(2),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(1),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(0),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_4_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(4),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(3),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(2),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(1),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(0),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr_4_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq1_rptr\(4),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbin\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(3),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(2),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(1),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(0),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_4_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(4),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(3),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(2),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(1),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(0),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr_4_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq1_wptr\(4),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbin\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(3),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(2),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(1),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wptr_Z\(0),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbin_4_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbin\(4),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbin_3_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbin_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbin_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbin_0_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(0),
  D => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_0,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wfull_s0\: DFFCE
port map (
  Q => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_full,
  D => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_3_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(3),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(2),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(1),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_0_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rptr_Z\(0),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(0),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbin_4_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbin\(4),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(4),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbin_3_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(3),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(3),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbin_2_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(2),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbin_1_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  D => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(1),
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbin_0_s0\: DFFCE
port map (
  Q => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(0),
  D => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_0,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rempty_s0\: DFFPE
port map (
  Q => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  D => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rempty_val,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_baudset/cnt1_5_s0\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/u_baudset/cnt1\(5),
  D => i4_u_baudset_n33,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_baudset/cnt1_4_s0\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/u_baudset/cnt1\(4),
  D => i4_u_baudset_n34,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_baudset/cnt1_3_s0\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/u_baudset/cnt1\(3),
  D => i4_u_baudset_n35,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_baudset/cnt1_2_s0\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/u_baudset/cnt1\(2),
  D => i4_u_baudset_n36,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_baudset/cnt1_1_s0\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/u_baudset/cnt1\(1),
  D => i4_u_baudset_n37,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_baudset/cnt1_0_s0\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/u_baudset/cnt1\(0),
  D => i4_u_baudset_n38,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_baudset/cnt1_6_s0\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/u_baudset/cnt1\(6),
  D => i4_u_baudset_n32,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/u_uart_sram/OE_re_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => i4_u_uart_sram_OE_re_Z,
  D => i4_u_uart_sram_n173,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_OE_re);
\i4/u_uart_sram/PE_re_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => i4_u_uart_sram_PE_re_Z,
  D => i4_u_uart_sram_n173,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_PE_re);
\i4/u_uart_sram/FE_re_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => i4_u_uart_sram_FE_re_Z,
  D => i4_u_uart_sram_n173,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_FE_re);
\i4/u_uart_sram/BI_re_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => i4_u_uart_sram_BI_re_Z,
  D => i4_u_uart_sram_n173,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_BI_re);
\i4/u_uart_sram/Int_State_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/u_uart_sram/Int_State\(0),
  D => i4_u_uart_sram_n280,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_u_uart_sram_Int_State_0);
\i4/U_Rxcver/Hunt_r_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => i4_U_Rxcver_Hunt_r,
  D => i4_U_Rxcver_n336,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_Hunt_r_10);
\i4/U_Rxcver/HuntOne_r_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => i4_U_Rxcver_HuntOne_r,
  D => i4_U_Rxcver_n74,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_HuntOne_r_8);
\i4/U_Rxcver/RxPrtyErr_s1\: DFFPE
generic map (
  INIT => '1'
)
port map (
  Q => i4_U_Rxcver_RxPrtyErr,
  D => i4_U_Rxcver_n198,
  CLK => i4_u_baudset_rxclk_Z,
  PRESET => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_RxPrtyErr_8);
\i4/U_Rxcver/RxFrmErr_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => i4_U_Rxcver_RxFrmErr,
  D => i4_U_Rxcver_n195_15,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_n195);
\i4/U_Rxcver/Rx_State_1_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/U_Rxcver/Rx_State\(1),
  D => i4_U_Rxcver_n196,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_n189);
\i4/U_Rxcver/Rx_State_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/U_Rxcver/Rx_State\(0),
  D => i4_U_Rxcver_n197,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_n189);
\i4/U_Rxcver/OverrunErr_r_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => i4_U_Rxcver_OverrunErr,
  D => i4_U_Rxcver_n284,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Rxcver_OverrunErr_r);
\i4/U_Txmitt/fifo_rd_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => i4_U_Txmitt_fifo_rd,
  D => \i4/U_Txmitt/Tx_State\(2),
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_n145);
\i4/U_Txmitt/TsrEmpty_s1\: DFFPE
generic map (
  INIT => '1'
)
port map (
  Q => i4_U_Txmitt_TsrEmpty,
  D => i4_U_Txmitt_n185,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_TsrEmpty_8);
\i4/U_Txmitt/ThrEmpty_s1\: DFFPE
generic map (
  INIT => '1'
)
port map (
  Q => i4_U_Txmitt_THRE,
  D => i4_U_Txmitt_n200,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_ThrEmpty);
\i4/U_Txmitt/TxOutput_s1\: DFFPE
generic map (
  INIT => '1'
)
port map (
  Q => i4_U_Txmitt_TxOutput,
  D => i4_U_Txmitt_n149,
  CLK => i4_u_baudset_rxclk_Z,
  PRESET => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_n119);
\i4/u_baudset/rxclk_s1\: DFFPE
generic map (
  INIT => '1'
)
port map (
  Q => i4_u_baudset_rxclk_Z,
  D => i4_u_baudset_n31,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => i4_u_baudset_rxclk);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/mem_mem_0_0_s\: SDPB
generic map (
  BIT_WIDTH_0 => 8,
  BIT_WIDTH_1 => 8,
  READ_MODE => '0',
  RESET_MODE => "SYNC",
  BLK_SEL_0 => "000",
  BLK_SEL_1 => "000"
)
port map (
  DO(31) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO31,
  DO(30) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO30,
  DO(29) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO29,
  DO(28) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO28,
  DO(27) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO27,
  DO(26) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO26,
  DO(25) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO25,
  DO(24) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO24,
  DO(23) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO23,
  DO(22) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO22,
  DO(21) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO21,
  DO(20) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO20,
  DO(19) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO19,
  DO(18) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO18,
  DO(17) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO17,
  DO(16) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO16,
  DO(15) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO15,
  DO(14) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO14,
  DO(13) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO13,
  DO(12) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO12,
  DO(11) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO11,
  DO(10) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO10,
  DO(9) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO9,
  DO(8) => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO8,
  DO(7 downto 0) => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/RBR\(7 downto 0),
  CLKA => I_CLK,
  CEA => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_n22,
  CLKB => I_CLK,
  CEB => i4_u_uart_sram_RbrRDn_re_Z_5,
  OCE => GND_0,
  RESET => GND_0,
  ADA(13) => GND_0,
  ADA(12) => GND_0,
  ADA(11) => GND_0,
  ADA(10) => GND_0,
  ADA(9) => GND_0,
  ADA(8) => GND_0,
  ADA(7) => GND_0,
  ADA(6 downto 3) => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3 downto 0),
  ADA(2) => GND_0,
  ADA(1) => GND_0,
  ADA(0) => GND_0,
  ADB(13) => GND_0,
  ADB(12) => GND_0,
  ADB(11) => GND_0,
  ADB(10) => GND_0,
  ADB(9) => GND_0,
  ADB(8) => GND_0,
  ADB(7) => GND_0,
  ADB(6 downto 3) => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(3 downto 0),
  ADB(2) => GND_0,
  ADB(1) => GND_0,
  ADB(0) => GND_0,
  DI(31) => GND_0,
  DI(30) => GND_0,
  DI(29) => GND_0,
  DI(28) => GND_0,
  DI(27) => GND_0,
  DI(26) => GND_0,
  DI(25) => GND_0,
  DI(24) => GND_0,
  DI(23) => GND_0,
  DI(22) => GND_0,
  DI(21) => GND_0,
  DI(20) => GND_0,
  DI(19) => GND_0,
  DI(18) => GND_0,
  DI(17) => GND_0,
  DI(16) => GND_0,
  DI(15) => GND_0,
  DI(14) => GND_0,
  DI(13) => GND_0,
  DI(12) => GND_0,
  DI(11) => GND_0,
  DI(10) => GND_0,
  DI(9) => GND_0,
  DI(8) => GND_0,
  DI(7 downto 0) => \i4/U_Rxcver/RBR_r\(7 downto 0),
  BLKSELA(2) => GND_0,
  BLKSELA(1) => GND_0,
  BLKSELA(0) => GND_0,
  BLKSELB(2) => GND_0,
  BLKSELB(1) => GND_0,
  BLKSELB(0) => GND_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/mem_mem_0_0_s\: SDPB
generic map (
  BIT_WIDTH_0 => 8,
  BIT_WIDTH_1 => 8,
  READ_MODE => '0',
  RESET_MODE => "SYNC",
  BLK_SEL_0 => "000",
  BLK_SEL_1 => "000"
)
port map (
  DO(31) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO31,
  DO(30) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO30,
  DO(29) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO29,
  DO(28) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO28,
  DO(27) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO27,
  DO(26) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO26,
  DO(25) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO25,
  DO(24) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO24,
  DO(23) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO23,
  DO(22) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO22,
  DO(21) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO21,
  DO(20) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO20,
  DO(19) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO19,
  DO(18) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO18,
  DO(17) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO17,
  DO(16) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO16,
  DO(15) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO15,
  DO(14) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO14,
  DO(13) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO13,
  DO(12) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO12,
  DO(11) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO11,
  DO(10) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO10,
  DO(9) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO9,
  DO(8) => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_fifomem_mem_mem_0_0_0_DO8,
  DO(7 downto 0) => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\(7 downto 0),
  CLKA => I_CLK,
  CEA => i4_U_Txmitt_fifo_wr,
  CLKB => I_CLK,
  CEB => i4_U_Txmitt_rise_edge_fifo_rd,
  OCE => GND_0,
  RESET => GND_0,
  ADA(13) => GND_0,
  ADA(12) => GND_0,
  ADA(11) => GND_0,
  ADA(10) => GND_0,
  ADA(9) => GND_0,
  ADA(8) => GND_0,
  ADA(7) => GND_0,
  ADA(6 downto 3) => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3 downto 0),
  ADA(2) => GND_0,
  ADA(1) => GND_0,
  ADA(0) => GND_0,
  ADB(13) => GND_0,
  ADB(12) => GND_0,
  ADB(11) => GND_0,
  ADB(10) => GND_0,
  ADB(9) => GND_0,
  ADB(8) => GND_0,
  ADB(7) => GND_0,
  ADB(6 downto 3) => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(3 downto 0),
  ADB(2) => GND_0,
  ADB(1) => GND_0,
  ADB(0) => GND_0,
  DI(31) => GND_0,
  DI(30) => GND_0,
  DI(29) => GND_0,
  DI(28) => GND_0,
  DI(27) => GND_0,
  DI(26) => GND_0,
  DI(25) => GND_0,
  DI(24) => GND_0,
  DI(23) => GND_0,
  DI(22) => GND_0,
  DI(21) => GND_0,
  DI(20) => GND_0,
  DI(19) => GND_0,
  DI(18) => GND_0,
  DI(17) => GND_0,
  DI(16) => GND_0,
  DI(15) => GND_0,
  DI(14) => GND_0,
  DI(13) => GND_0,
  DI(12) => GND_0,
  DI(11) => GND_0,
  DI(10) => GND_0,
  DI(9) => GND_0,
  DI(8) => GND_0,
  DI(7 downto 0) => \i4/u_uart_sram/THR_Z\(7 downto 0),
  BLKSELA(2) => GND_0,
  BLKSELA(1) => GND_0,
  BLKSELA(0) => GND_0,
  BLKSELB(2) => GND_0,
  BLKSELB(1) => GND_0,
  BLKSELB(0) => GND_0);
\i4/U_Txmitt/Tx_State_1_s1\: DFFPE
port map (
  Q => \i4/U_Txmitt/Tx_State\(1),
  D => i4_U_Txmitt_n147,
  CLK => i4_u_baudset_rxclk_Z,
  PRESET => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_Tx_State_1);
\i4/U_Txmitt/Tx_State_0_s1\: DFFPE
port map (
  Q => \i4/U_Txmitt/Tx_State\(0),
  D => i4_U_Txmitt_n148,
  CLK => i4_u_baudset_rxclk_Z,
  PRESET => i4_u_uart_sram_n14,
  CE => i4_U_Txmitt_Tx_State_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/n50_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n50,
  COUT => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n50_3,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(0),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(0),
  I3 => GND_0,
  CIN => GND_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/n51_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n51,
  COUT => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n51_3,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(1),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(1),
  I3 => GND_0,
  CIN => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n50_3);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/n52_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n52,
  COUT => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n52_3,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(2),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(2),
  I3 => GND_0,
  CIN => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n51_3);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/n53_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n53,
  COUT => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n53_3,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(3),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(3),
  I3 => GND_0,
  CIN => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n52_3);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/n50_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n50,
  COUT => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n50_3,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(0),
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(0),
  I3 => GND_0,
  CIN => GND_0);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/n51_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n51,
  COUT => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n51_3,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(1),
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(1),
  I3 => GND_0,
  CIN => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n50_3);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/n52_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n52,
  COUT => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n52_3,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(2),
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(2),
  I3 => GND_0,
  CIN => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n51_3);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/n53_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n53,
  COUT => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n53_3,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(3),
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(3),
  I3 => GND_0,
  CIN => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n52_3);
\i4/u_uart_sram/n360_s0\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => i4_u_uart_sram_n360,
  I0 => I_WADDR(0),
  I1 => I_WADDR(1),
  I2 => I_WADDR(2),
  I3 => I_TX_EN);
\i4/u_uart_sram/n367_s0\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => i4_u_uart_sram_n367,
  I0 => I_WADDR(1),
  I1 => I_WADDR(2),
  I2 => I_WADDR(0),
  I3 => I_TX_EN);
\i4/u_uart_sram/n371_s0\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => i4_u_uart_sram_n371,
  I0 => I_WADDR(2),
  I1 => I_WADDR(1),
  I2 => I_WADDR(0),
  I3 => I_TX_EN);
\i4/u_uart_sram/n378_s0\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => i4_u_uart_sram_n378,
  I0 => I_WADDR(0),
  I1 => I_WADDR(1),
  I2 => I_WADDR(2),
  I3 => I_TX_EN);
\i4/u_uart_sram/n173_s0\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => i4_u_uart_sram_n173,
  I0 => I_WADDR(1),
  I1 => I_WADDR(0),
  I2 => I_WADDR(2),
  I3 => I_TX_EN);
\i4/u_uart_sram/n192_s0\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => i4_u_uart_sram_n192,
  I0 => I_RADDR(0),
  I1 => I_RADDR(2),
  I2 => I_RADDR(1),
  I3 => I_RX_EN);
\i4/U_Rxcver/n18_s2\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => i4_U_Rxcver_n18,
  I0 => \i4/U_Rxcver/CNT_r\(2),
  I1 => \i4/U_Rxcver/CNT_r\(3),
  I2 => \i4/U_Rxcver/CNT_r\(0),
  I3 => \i4/U_Rxcver/CNT_r\(1));
\i4/U_Rxcver/n336_s0\: LUT4
generic map (
  INIT => X"00F8"
)
port map (
  F => i4_U_Rxcver_n336,
  I0 => i4_U_Rxcver_SIN1_rrr,
  I1 => i4_U_Rxcver_n99_12,
  I2 => i4_U_Rxcver_n336_4,
  I3 => i4_U_Rxcver_SIN1_rr);
\i4/U_Rxcver/n43_s0\: LUT4
generic map (
  INIT => X"440F"
)
port map (
  F => i4_U_Rxcver_n43,
  I0 => i4_U_Rxcver_SIN1_rr,
  I1 => i4_U_Rxcver_n336_4,
  I2 => \i4/U_Rxcver/CNT_r\(0),
  I3 => i4_U_Rxcver_n43_6);
\i4/U_Rxcver/n189_s0\: LUT4
generic map (
  INIT => X"FE00"
)
port map (
  F => i4_U_Rxcver_n189,
  I0 => \i4/U_Rxcver/Rx_State\(1),
  I1 => i4_U_Rxcver_n195,
  I2 => i4_U_Rxcver_n189_4,
  I3 => i4_U_Rxcver_RxClkEn);
\i4/U_Rxcver/n273_s0\: LUT4
generic map (
  INIT => X"D044"
)
port map (
  F => i4_U_Rxcver_n273,
  I0 => i4_U_Rxcver_n273_4,
  I1 => i4_U_Rxcver_ParityErr,
  I2 => i4_u_uart_sram_ParityEnable,
  I3 => i4_U_Rxcver_n273_5);
\i4/U_Rxcver/n274_s0\: LUT4
generic map (
  INIT => X"FA30"
)
port map (
  F => i4_U_Rxcver_n274,
  I0 => i4_U_Rxcver_RxFrmErr,
  I1 => i4_u_uart_sram_FE_re_Z,
  I2 => i4_U_Rxcver_FrameErr,
  I3 => i4_U_Rxcver_n273_5);
\i4/U_Rxcver/n275_s0\: LUT4
generic map (
  INIT => X"F530"
)
port map (
  F => i4_U_Rxcver_n275,
  I0 => i4_U_Rxcver_HuntOne_r,
  I1 => i4_u_uart_sram_BI_re_Z,
  I2 => i4_U_Rxcver_BreakInt,
  I3 => i4_U_Rxcver_n273_5);
\i4/U_Rxcver/n284_s0\: LUT3
generic map (
  INIT => X"F8"
)
port map (
  F => i4_U_Rxcver_n284,
  I0 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I1 => i4_u_uart_sram_RbrRDn_re_Z_5,
  I2 => i4_U_Rxcver_n284_4);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/n22_s1\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_n22,
  I0 => i4_U_Rxcver_RxIdle_r_2,
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_full,
  I2 => i4_U_Rxcver_RxIdle_r_1);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_0_s0\: LUT2
generic map (
  INIT => X"9"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(0),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_2_s0\: LUT4
generic map (
  INIT => X"07F8"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(2),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_2,
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  I3 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_3_s0\: LUT2
generic map (
  INIT => X"9"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(3),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin\(4),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_3);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wfull_val_s0\: LUT4
generic map (
  INIT => X"0002"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val,
  I0 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_4,
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_5,
  I2 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_6,
  I3 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_7);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext_0_s0\: LUT3
generic map (
  INIT => X"1E"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(0),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(0),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_0,
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext_1_s0\: LUT4
generic map (
  INIT => X"07F8"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(1),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(0),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_0,
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  I3 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext_2_s0\: LUT3
generic map (
  INIT => X"36"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(2),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(3),
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(2));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext_3_s0\: LUT3
generic map (
  INIT => X"1E"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(3),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(3),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_3,
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbin\(4));
\i4/U_Txmitt/fifo_wr_s1\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_U_Txmitt_fifo_wr,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_full,
  I1 => i4_u_uart_sram_ThrWRn_re_Z);
\i4/U_Txmitt/rise_edge_fifo_rd_s0\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_U_Txmitt_rise_edge_fifo_rd,
  I0 => i4_U_Txmitt_fifo_rd3,
  I1 => i4_U_Txmitt_fifo_rd2);
\i4/U_Txmitt/n119_s1\: LUT4
generic map (
  INIT => X"D780"
)
port map (
  F => i4_U_Txmitt_n119,
  I0 => i4_U_Txmitt_n119_5,
  I1 => \i4/U_Txmitt/Tx_State\(2),
  I2 => \i4/U_Txmitt/Tx_State\(0),
  I3 => i4_U_Txmitt_TxClkEnA);
\i4/U_Txmitt/n185_s0\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => i4_U_Txmitt_n185,
  I0 => i4_U_Txmitt_TxInStopState1,
  I1 => i4_U_Txmitt_TxInStopState,
  I2 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty);
\i4/U_Txmitt/n214_s1\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => i4_U_Txmitt_n214,
  I0 => \i4/U_Txmitt/Tx_State\(2),
  I1 => \i4/U_Txmitt/Tx_State\(1),
  I2 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/n237_s0\: LUT4
generic map (
  INIT => X"0018"
)
port map (
  F => i4_U_Txmitt_n237,
  I0 => \i4/u_uart_sram/LCR\(2),
  I1 => \i4/U_Txmitt/Tx_State\(2),
  I2 => \i4/U_Txmitt/Tx_State\(1),
  I3 => i4_U_Txmitt_n237_4);
\i4/U_Txmitt/n262_s1\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => i4_U_Txmitt_n262,
  I0 => \i4/U_Txmitt/Count_vr\(3),
  I1 => \i4/U_Txmitt/Count_vr\(1),
  I2 => \i4/U_Txmitt/Count_vr\(2),
  I3 => \i4/U_Txmitt/Count_vr\(0));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_1_s0\: LUT2
generic map (
  INIT => X"9"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(1),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_1);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wfull_val_s0\: LUT4
generic map (
  INIT => X"1001"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_4,
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_5,
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(0),
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(0));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext_3_s0\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(3),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(3),
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(4));
\i4/U_Rxcver/n195_s7\: LUT4
generic map (
  INIT => X"C200"
)
port map (
  F => i4_U_Rxcver_n195,
  I0 => i4_U_Rxcver_n195_16,
  I1 => \i4/U_Rxcver/Rx_State\(0),
  I2 => \i4/U_Rxcver/Rx_State\(1),
  I3 => i4_U_Rxcver_RxClkEn);
\i4/U_Rxcver/n196_s6\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => i4_U_Rxcver_n196,
  I0 => \i4/U_Rxcver/Rx_State\(0),
  I1 => \i4/U_Rxcver/Rx_State\(1));
\i4/U_Rxcver/n197_s8\: LUT3
generic map (
  INIT => X"1F"
)
port map (
  F => i4_U_Rxcver_n197,
  I0 => \i4/U_Rxcver/Rx_State\(1),
  I1 => i4_u_uart_sram_ParityEnable,
  I2 => \i4/U_Rxcver/Rx_State\(0));
\i4/U_Rxcver/n198_s5\: LUT4
generic map (
  INIT => X"35CA"
)
port map (
  F => i4_U_Rxcver_n198,
  I0 => i4_U_Rxcver_n198_10,
  I1 => i4_U_Rxcver_RxPrtyErr,
  I2 => i4_U_Rxcver_n198_11,
  I3 => i4_U_Rxcver_SIN1_rr);
\i4/U_Rxcver/RBR_r_5_s3\: LUT4
generic map (
  INIT => X"0F88"
)
port map (
  F => \i4/U_Rxcver/RBR_r\(5),
  I0 => \i4/u_uart_sram/DataBits\(0),
  I1 => \i4/U_Rxcver/RSR\(7),
  I2 => i4_U_Rxcver_RBR_r_5,
  I3 => \i4/u_uart_sram/DataBits\(1));
\i4/U_Rxcver/RBR_r_4_s3\: LUT4
generic map (
  INIT => X"A0CF"
)
port map (
  F => \i4/U_Rxcver/RBR_r\(4),
  I0 => \i4/U_Rxcver/RSR\(5),
  I1 => \i4/U_Rxcver/RSR\(4),
  I2 => \i4/u_uart_sram/DataBits\(1),
  I3 => i4_U_Rxcver_RBR_r_4);
\i4/U_Rxcver/RBR_r_3_s3\: LUT4
generic map (
  INIT => X"A0CF"
)
port map (
  F => \i4/U_Rxcver/RBR_r\(3),
  I0 => \i4/U_Rxcver/RSR\(4),
  I1 => \i4/U_Rxcver/RSR\(3),
  I2 => \i4/u_uart_sram/DataBits\(1),
  I3 => i4_U_Rxcver_RBR_r_3);
\i4/U_Rxcver/RBR_r_2_s3\: LUT4
generic map (
  INIT => X"A0CF"
)
port map (
  F => \i4/U_Rxcver/RBR_r\(2),
  I0 => \i4/U_Rxcver/RSR\(2),
  I1 => \i4/U_Rxcver/RSR\(3),
  I2 => \i4/u_uart_sram/DataBits\(1),
  I3 => i4_U_Rxcver_RBR_r_2);
\i4/U_Rxcver/RBR_r_1_s4\: LUT4
generic map (
  INIT => X"A0CF"
)
port map (
  F => \i4/U_Rxcver/RBR_r\(1),
  I0 => \i4/U_Rxcver/RSR\(1),
  I1 => \i4/U_Rxcver/RSR\(2),
  I2 => \i4/u_uart_sram/DataBits\(1),
  I3 => i4_U_Rxcver_RBR_r_1);
\i4/U_Rxcver/RBR_r_0_s4\: LUT4
generic map (
  INIT => X"A0CF"
)
port map (
  F => \i4/U_Rxcver/RBR_r\(0),
  I0 => \i4/U_Rxcver/RSR\(0),
  I1 => \i4/U_Rxcver/RSR\(1),
  I2 => \i4/u_uart_sram/DataBits\(1),
  I3 => i4_U_Rxcver_RBR_r_0);
\i4/U_Txmitt/n145_s13\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_U_Txmitt_n145,
  I0 => i4_U_Txmitt_n145_20,
  I1 => i4_U_Txmitt_TxClkEnA);
\i4/U_Txmitt/n146_s10\: LUT3
generic map (
  INIT => X"BC"
)
port map (
  F => i4_U_Txmitt_n146,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I1 => i4_U_Txmitt_n146_17,
  I2 => \i4/U_Txmitt/Tx_State\(2));
\i4/U_Txmitt/n147_s22\: LUT3
generic map (
  INIT => X"4F"
)
port map (
  F => i4_U_Txmitt_n147,
  I0 => i4_U_Txmitt_n147_31,
  I1 => i4_U_Txmitt_n214,
  I2 => i4_U_Txmitt_n147_32);
\i4/U_Txmitt/n148_s18\: LUT4
generic map (
  INIT => X"40FF"
)
port map (
  F => i4_U_Txmitt_n148,
  I0 => \i4/U_Txmitt/Tx_State\(2),
  I1 => \i4/U_Txmitt/Tx_State\(0),
  I2 => i4_U_Txmitt_n148_25,
  I3 => i4_U_Txmitt_n148_26);
\i4/U_Txmitt/n149_s9\: LUT4
generic map (
  INIT => X"3533"
)
port map (
  F => i4_U_Txmitt_n149,
  I0 => i4_U_Txmitt_n149_14,
  I1 => i4_U_Txmitt_n149_15,
  I2 => \i4/U_Txmitt/Tx_State\(2),
  I3 => i4_U_Txmitt_n149_16);
\i4/U_Txmitt/n152_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => i4_U_Txmitt_n152,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\(6),
  I1 => \i4/U_Txmitt/TSR\(6),
  I2 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/n153_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => i4_U_Txmitt_n153,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\(5),
  I1 => \i4/U_Txmitt/TSR\(5),
  I2 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/n154_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => i4_U_Txmitt_n154,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\(4),
  I1 => \i4/U_Txmitt/TSR\(4),
  I2 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/n155_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => i4_U_Txmitt_n155,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\(3),
  I1 => \i4/U_Txmitt/TSR\(3),
  I2 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/n156_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => i4_U_Txmitt_n156,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\(2),
  I1 => \i4/U_Txmitt/TSR\(2),
  I2 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/n157_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => i4_U_Txmitt_n157,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\(1),
  I1 => \i4/U_Txmitt/TSR\(1),
  I2 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/n158_s8\: LUT4
generic map (
  INIT => X"AAC3"
)
port map (
  F => i4_U_Txmitt_n158,
  I0 => i4_U_Txmitt_n158_13,
  I1 => i4_u_uart_sram_ParityEven,
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\(0),
  I3 => \i4/U_Txmitt/Tx_State\(0));
\i4/u_uart_sram/OE_re_s3\: LUT2
generic map (
  INIT => X"B"
)
port map (
  F => i4_u_uart_sram_OE_re,
  I0 => I_WDATA(1),
  I1 => i4_u_uart_sram_n173);
\i4/u_uart_sram/PE_re_s3\: LUT2
generic map (
  INIT => X"B"
)
port map (
  F => i4_u_uart_sram_PE_re,
  I0 => I_WDATA(2),
  I1 => i4_u_uart_sram_n173);
\i4/u_uart_sram/FE_re_s3\: LUT2
generic map (
  INIT => X"B"
)
port map (
  F => i4_u_uart_sram_FE_re,
  I0 => I_WDATA(3),
  I1 => i4_u_uart_sram_n173);
\i4/u_uart_sram/BI_re_s3\: LUT2
generic map (
  INIT => X"B"
)
port map (
  F => i4_u_uart_sram_BI_re,
  I0 => I_WDATA(4),
  I1 => i4_u_uart_sram_n173);
\i4/U_Rxcver/HuntOne_r_s3\: LUT4
generic map (
  INIT => X"FF40"
)
port map (
  F => i4_U_Rxcver_HuntOne_r_8,
  I0 => i4_U_Rxcver_RxIdle_r,
  I1 => i4_U_Rxcver_SIN1_rr,
  I2 => \i4/U_Rxcver/CNT_r\(2),
  I3 => i4_U_Rxcver_Hunt_r);
\i4/U_Rxcver/RSR_7_s3\: LUT4
generic map (
  INIT => X"0E00"
)
port map (
  F => i4_U_Rxcver_RSR_7,
  I0 => i4_U_Rxcver_n195_16,
  I1 => \i4/U_Rxcver/Rx_State\(0),
  I2 => \i4/U_Rxcver/Rx_State\(1),
  I3 => i4_U_Rxcver_RxClkEn);
\i4/U_Rxcver/RxPrtyErr_s3\: LUT4
generic map (
  INIT => X"3E00"
)
port map (
  F => i4_U_Rxcver_RxPrtyErr_8,
  I0 => i4_U_Rxcver_n195_16,
  I1 => \i4/U_Rxcver/Rx_State\(0),
  I2 => \i4/U_Rxcver/Rx_State\(1),
  I3 => i4_U_Rxcver_RxClkEn);
\i4/U_Txmitt/TSR_6_s4\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => i4_U_Txmitt_TSR_6,
  I0 => \i4/U_Txmitt/Tx_State\(2),
  I1 => \i4/U_Txmitt/Tx_State\(1),
  I2 => i4_U_Txmitt_TxClkEnA);
\i4/U_Txmitt/TsrEmpty_s3\: LUT3
generic map (
  INIT => X"F4"
)
port map (
  F => i4_U_Txmitt_TsrEmpty_8,
  I0 => i4_U_Txmitt_TxInShiftState1,
  I1 => i4_U_Txmitt_TxInShiftState,
  I2 => i4_U_Txmitt_n185);
\i4/U_Txmitt/ThrEmpty_s3\: LUT4
generic map (
  INIT => X"FF40"
)
port map (
  F => i4_U_Txmitt_ThrEmpty,
  I0 => i4_U_Txmitt_TxInShiftState1,
  I1 => i4_U_Txmitt_TxInShiftState,
  I2 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I3 => i4_u_uart_sram_ThrWRn_re_Z);
\i4/u_baudset/rxclk_s3\: LUT2
generic map (
  INIT => X"B"
)
port map (
  F => i4_u_baudset_rxclk,
  I0 => i4_u_baudset_rxclk_6,
  I1 => i4_u_baudset_n31);
\i4/u_uart_sram/Int_State_0_s6\: LUT4
generic map (
  INIT => X"BBF0"
)
port map (
  F => i4_u_uart_sram_Int_State_0,
  I0 => i4_u_uart_sram_MsrRDn_re_Z,
  I1 => i4_u_uart_sram_INTR_d,
  I2 => i4_u_uart_sram_Int_State_0_12,
  I3 => \i4/u_uart_sram/Int_State\(2));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_1_s3\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(1),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_2);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_2_s3\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(2),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_2,
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_3_s3\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(3),
  I0 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_3,
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_3);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_4_s2\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(4),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin\(4),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_3);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_1_s3\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(1),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(0),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_0,
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_2_s3\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(2),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(0),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  I2 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_0,
  I3 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_3_s3\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(3),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(3),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_3);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_4_s2\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(4),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(3),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_3,
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbin\(4));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_1_s3\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(1),
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_1,
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_1);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_2_s3\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(2),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_1);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_3_s3\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(3),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_1,
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_4_s2\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(4),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3),
  I2 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_1,
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbin\(4));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_1_s3\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(1),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_1);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_2_s3\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(2),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_1,
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_4_s2\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(4),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(3),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_1,
  I2 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_3,
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbin\(4));
\i4/u_uart_sram/n280_s24\: LUT4
generic map (
  INIT => X"0E00"
)
port map (
  F => i4_u_uart_sram_n280,
  I0 => i4_u_uart_sram_n280_31,
  I1 => i4_u_uart_sram_n280_32,
  I2 => \i4/u_uart_sram/Int_State\(2),
  I3 => i4_u_uart_sram_INTR_d);
\i4/U_Txmitt/n151_s10\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_U_Txmitt_n151,
  I0 => \i4/U_Txmitt/Tx_State\(0),
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\(7));
\i4/U_Txmitt/n160_s9\: LUT3
generic map (
  INIT => X"60"
)
port map (
  F => i4_U_Txmitt_n160,
  I0 => \i4/U_Txmitt/TxCNT_r\(0),
  I1 => \i4/U_Txmitt/TxCNT_r\(1),
  I2 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/n159_s9\: LUT4
generic map (
  INIT => X"7800"
)
port map (
  F => i4_U_Txmitt_n159,
  I0 => \i4/U_Txmitt/TxCNT_r\(0),
  I1 => \i4/U_Txmitt/TxCNT_r\(1),
  I2 => \i4/U_Txmitt/TxCNT_r\(2),
  I3 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Rxcver/n210_s5\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_U_Rxcver_n210,
  I0 => \i4/U_Rxcver/NumDataBitReceived_r\(0),
  I1 => \i4/U_Rxcver/Rx_State\(0));
\i4/U_Rxcver/n209_s4\: LUT3
generic map (
  INIT => X"60"
)
port map (
  F => i4_U_Rxcver_n209,
  I0 => \i4/U_Rxcver/NumDataBitReceived_r\(0),
  I1 => \i4/U_Rxcver/NumDataBitReceived_r\(1),
  I2 => \i4/U_Rxcver/Rx_State\(0));
\i4/U_Rxcver/n208_s4\: LUT4
generic map (
  INIT => X"7800"
)
port map (
  F => i4_U_Rxcver_n208,
  I0 => \i4/U_Rxcver/NumDataBitReceived_r\(0),
  I1 => \i4/U_Rxcver/NumDataBitReceived_r\(1),
  I2 => \i4/U_Rxcver/NumDataBitReceived_r\(2),
  I3 => \i4/U_Rxcver/Rx_State\(0));
\i4/U_Rxcver/n207_s4\: LUT3
generic map (
  INIT => X"60"
)
port map (
  F => i4_U_Rxcver_n207,
  I0 => i4_U_Rxcver_n207_11,
  I1 => \i4/U_Rxcver/NumDataBitReceived_r\(3),
  I2 => \i4/U_Rxcver/Rx_State\(0));
\i4/U_Rxcver/n206_s4\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => i4_U_Rxcver_n206,
  I0 => \i4/U_Rxcver/Rx_State\(0),
  I1 => \i4/U_Rxcver/RSR\(1));
\i4/U_Rxcver/n205_s4\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => i4_U_Rxcver_n205,
  I0 => \i4/U_Rxcver/Rx_State\(0),
  I1 => \i4/U_Rxcver/RSR\(2));
\i4/U_Rxcver/n204_s4\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => i4_U_Rxcver_n204,
  I0 => \i4/U_Rxcver/Rx_State\(0),
  I1 => \i4/U_Rxcver/RSR\(3));
\i4/U_Rxcver/n203_s4\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => i4_U_Rxcver_n203,
  I0 => \i4/U_Rxcver/Rx_State\(0),
  I1 => \i4/U_Rxcver/RSR\(4));
\i4/U_Rxcver/n202_s4\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => i4_U_Rxcver_n202,
  I0 => \i4/U_Rxcver/Rx_State\(0),
  I1 => \i4/U_Rxcver/RSR\(5));
\i4/U_Rxcver/n201_s4\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => i4_U_Rxcver_n201,
  I0 => \i4/U_Rxcver/Rx_State\(0),
  I1 => \i4/U_Rxcver/RSR\(6));
\i4/U_Rxcver/n200_s4\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => i4_U_Rxcver_n200,
  I0 => \i4/U_Rxcver/Rx_State\(0),
  I1 => \i4/U_Rxcver/RSR\(7));
\i4/U_Rxcver/n199_s4\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => i4_U_Rxcver_n199,
  I0 => i4_U_Rxcver_SIN1_rr,
  I1 => \i4/U_Rxcver/Rx_State\(0));
\i4/U_Rxcver/n195_s8\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_U_Rxcver_n195_15,
  I0 => i4_U_Rxcver_SIN1_rr,
  I1 => \i4/U_Rxcver/Rx_State\(1));
\i4/U_Rxcver/RBR_r_6_s4\: LUT4
generic map (
  INIT => X"AC00"
)
port map (
  F => \i4/U_Rxcver/RBR_r\(6),
  I0 => \i4/U_Rxcver/RSR\(6),
  I1 => \i4/U_Rxcver/RSR\(7),
  I2 => \i4/u_uart_sram/DataBits\(0),
  I3 => \i4/u_uart_sram/DataBits\(1));
\i4/U_Rxcver/RBR_r_7_s5\: LUT3
generic map (
  INIT => X"80"
)
port map (
  F => \i4/U_Rxcver/RBR_r\(7),
  I0 => \i4/U_Rxcver/RSR\(7),
  I1 => \i4/u_uart_sram/DataBits\(0),
  I2 => \i4/u_uart_sram/DataBits\(1));
\i4/u_uart_sram/reg_data_out_0_s1\: LUT4
generic map (
  INIT => X"4F00"
)
port map (
  F => \i4/u_uart_sram/reg_data_out\(0),
  I0 => I_RADDR(0),
  I1 => i4_u_uart_sram_reg_data_out_0,
  I2 => i4_u_uart_sram_reg_data_out_0_8,
  I3 => I_RESETN);
\i4/u_uart_sram/reg_data_out_1_s1\: LUT4
generic map (
  INIT => X"F800"
)
port map (
  F => \i4/u_uart_sram/reg_data_out\(1),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/RBR\(1),
  I1 => i4_u_uart_sram_RbrRDn_re_Z,
  I2 => i4_u_uart_sram_reg_data_out_1,
  I3 => I_RESETN);
\i4/u_uart_sram/reg_data_out_2_s1\: LUT4
generic map (
  INIT => X"4F00"
)
port map (
  F => \i4/u_uart_sram/reg_data_out\(2),
  I0 => I_RADDR(0),
  I1 => i4_u_uart_sram_reg_data_out_2,
  I2 => i4_u_uart_sram_reg_data_out_2_8,
  I3 => I_RESETN);
\i4/u_uart_sram/reg_data_out_3_s1\: LUT4
generic map (
  INIT => X"F100"
)
port map (
  F => \i4/u_uart_sram/reg_data_out\(3),
  I0 => I_RADDR(0),
  I1 => i4_u_uart_sram_reg_data_out_3,
  I2 => i4_u_uart_sram_reg_data_out_3_10,
  I3 => I_RESETN);
\i4/u_uart_sram/reg_data_out_4_s1\: LUT4
generic map (
  INIT => X"8F00"
)
port map (
  F => \i4/u_uart_sram/reg_data_out\(4),
  I0 => \i4/U_Modem/MSR\(4),
  I1 => i4_u_uart_sram_n201,
  I2 => i4_u_uart_sram_reg_data_out_4,
  I3 => I_RESETN);
\i4/u_uart_sram/reg_data_out_5_s1\: LUT4
generic map (
  INIT => X"8F00"
)
port map (
  F => \i4/u_uart_sram/reg_data_out\(5),
  I0 => \i4/U_Modem/MSR\(5),
  I1 => i4_u_uart_sram_n201,
  I2 => i4_u_uart_sram_reg_data_out_5,
  I3 => I_RESETN);
\i4/u_uart_sram/reg_data_out_6_s1\: LUT3
generic map (
  INIT => X"D0"
)
port map (
  F => \i4/u_uart_sram/reg_data_out\(6),
  I0 => i4_u_uart_sram_reg_data_out_6,
  I1 => i4_u_uart_sram_reg_data_out_6_8,
  I2 => I_RESETN);
\i4/u_uart_sram/reg_data_out_7_s1\: LUT4
generic map (
  INIT => X"F800"
)
port map (
  F => \i4/u_uart_sram/reg_data_out\(7),
  I0 => \i4/U_Modem/MSR\(7),
  I1 => i4_u_uart_sram_n201,
  I2 => i4_u_uart_sram_reg_data_out_7,
  I3 => I_RESETN);
\i4/u_baudset/n36_s2\: LUT4
generic map (
  INIT => X"0708"
)
port map (
  F => i4_u_baudset_n36,
  I0 => \i4/u_baudset/cnt1\(0),
  I1 => \i4/u_baudset/cnt1\(1),
  I2 => i4_u_baudset_rxclk_6,
  I3 => \i4/u_baudset/cnt1\(2));
\i4/u_baudset/n33_s2\: LUT4
generic map (
  INIT => X"0708"
)
port map (
  F => i4_u_baudset_n33,
  I0 => \i4/u_baudset/cnt1\(4),
  I1 => i4_u_baudset_n33_8,
  I2 => i4_u_baudset_rxclk,
  I3 => \i4/u_baudset/cnt1\(5));
\i4/u_baudset/n32_s2\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => i4_u_baudset_n32,
  I0 => \i4/u_baudset/cnt1\(4),
  I1 => \i4/u_baudset/cnt1\(5),
  I2 => i4_u_baudset_n33_8,
  I3 => \i4/u_baudset/cnt1\(6));
\i4/U_Txmitt/SOUT_d_s\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => SOUT,
  I0 => i4_u_uart_sram_TxBreak,
  I1 => i4_U_Txmitt_TxOutput);
\i4/U_Txmitt/n271_s2\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => i4_U_Txmitt_n271,
  I0 => \i4/U_Txmitt/Count_vr\(0),
  I1 => \i4/U_Txmitt/Count_vr\(1));
\i4/U_Txmitt/n270_s2\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => i4_U_Txmitt_n270,
  I0 => \i4/U_Txmitt/Count_vr\(0),
  I1 => \i4/U_Txmitt/Count_vr\(1),
  I2 => \i4/U_Txmitt/Count_vr\(2));
\i4/U_Txmitt/n269_s2\: LUT4
generic map (
  INIT => X"7F00"
)
port map (
  F => i4_U_Txmitt_n269,
  I0 => \i4/U_Txmitt/Count_vr\(1),
  I1 => \i4/U_Txmitt/Count_vr\(2),
  I2 => \i4/U_Txmitt/Count_vr\(0),
  I3 => \i4/U_Txmitt/Count_vr\(3));
\i4/U_Rxcver/n42_s2\: LUT3
generic map (
  INIT => X"14"
)
port map (
  F => i4_U_Rxcver_n42,
  I0 => i4_U_Rxcver_n43_6,
  I1 => \i4/U_Rxcver/CNT_r\(0),
  I2 => \i4/U_Rxcver/CNT_r\(1));
\i4/U_Rxcver/n41_s2\: LUT4
generic map (
  INIT => X"0708"
)
port map (
  F => i4_U_Rxcver_n41,
  I0 => \i4/U_Rxcver/CNT_r\(0),
  I1 => \i4/U_Rxcver/CNT_r\(1),
  I2 => i4_U_Rxcver_n43_6,
  I3 => \i4/U_Rxcver/CNT_r\(2));
\i4/U_Rxcver/n40_s2\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => i4_U_Rxcver_n40,
  I0 => i4_U_Rxcver_n40_8,
  I1 => i4_U_Rxcver_n43_6,
  I2 => \i4/U_Rxcver/CNT_r\(3));
\i4/U_Modem/n34_s2\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => i4_U_Modem_n34,
  I0 => CTSn,
  I1 => i4_u_uart_sram_MsrRDn_re_Z);
\i4/U_Modem/n33_s2\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => i4_U_Modem_n33,
  I0 => DSRn,
  I1 => i4_u_uart_sram_MsrRDn_re_Z);
\i4/U_Modem/n32_s2\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => i4_U_Modem_n32,
  I0 => RIn,
  I1 => i4_u_uart_sram_MsrRDn_re_Z);
\i4/U_Modem/n31_s2\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => i4_U_Modem_n31,
  I0 => DCDn,
  I1 => i4_u_uart_sram_MsrRDn_re_Z);
\i4/u_uart_sram/n257_s1\: LUT4
generic map (
  INIT => X"5C00"
)
port map (
  F => i4_u_uart_sram_n257,
  I0 => i4_u_uart_sram_MsrRDn_re_Z,
  I1 => i4_u_uart_sram_n257_10,
  I2 => \i4/u_uart_sram/Int_State\(2),
  I3 => i4_u_uart_sram_INTR_d);
\i4/u_uart_sram/n258_s1\: LUT4
generic map (
  INIT => X"050C"
)
port map (
  F => i4_u_uart_sram_n258,
  I0 => i4_u_uart_sram_n258_7,
  I1 => i4_u_uart_sram_n258_10,
  I2 => \i4/u_uart_sram/Int_State\(2),
  I3 => \i4/u_uart_sram/Int_State\(1));
\i4/u_baudset/n31_s2\: LUT4
generic map (
  INIT => X"EFFF"
)
port map (
  F => i4_u_baudset_n31,
  I0 => \i4/u_baudset/cnt1\(0),
  I1 => \i4/u_baudset/cnt1\(2),
  I2 => \i4/u_baudset/cnt1\(1),
  I3 => i4_u_baudset_n31_8);
\i4/u_baudset/n37_s1\: LUT3
generic map (
  INIT => X"14"
)
port map (
  F => i4_u_baudset_n37,
  I0 => i4_u_baudset_rxclk_6,
  I1 => \i4/u_baudset/cnt1\(0),
  I2 => \i4/u_baudset/cnt1\(1));
\i4/u_baudset/n35_s1\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => i4_u_baudset_n35,
  I0 => \i4/u_baudset/cnt1\(0),
  I1 => \i4/u_baudset/cnt1\(1),
  I2 => \i4/u_baudset/cnt1\(2),
  I3 => \i4/u_baudset/cnt1\(3));
\i4/u_baudset/n34_s1\: LUT3
generic map (
  INIT => X"14"
)
port map (
  F => i4_u_baudset_n34,
  I0 => i4_u_baudset_rxclk_6,
  I1 => \i4/u_baudset/cnt1\(4),
  I2 => i4_u_baudset_n33_8);
\i4/U_Txmitt/Tx_State_0_s3\: LUT3
generic map (
  INIT => X"EF"
)
port map (
  F => i4_U_Txmitt_Tx_State_0,
  I0 => i4_U_Txmitt_TxClkEnA,
  I1 => \i4/U_Txmitt/Tx_State\(2),
  I2 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/Tx_State_1_s4\: LUT4
generic map (
  INIT => X"8FEE"
)
port map (
  F => i4_U_Txmitt_Tx_State_1,
  I0 => i4_U_Txmitt_Tx_State_1_10,
  I1 => i4_U_Txmitt_TxClkEnA,
  I2 => \i4/U_Txmitt/Tx_State\(0),
  I3 => \i4/U_Txmitt/Tx_State\(1));
\i4/u_uart_sram/RbrRDn_re_Z_s0\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => i4_u_uart_sram_RbrRDn_re_Z,
  I0 => I_RADDR(0),
  I1 => I_RADDR(1),
  I2 => I_RADDR(2));
\i4/u_uart_sram/n165_s1\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => i4_u_uart_sram_n165,
  I0 => I_RADDR(1),
  I1 => I_RADDR(0),
  I2 => I_RADDR(2));
\i4/u_uart_sram/n201_s1\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => i4_u_uart_sram_n201,
  I0 => I_RADDR(0),
  I1 => I_RADDR(1),
  I2 => I_RADDR(2));
\i4/u_uart_sram/INTR_d_s0\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => i4_u_uart_sram_INTR_d,
  I0 => \i4/u_uart_sram/Int_State\(0),
  I1 => \i4/u_uart_sram/Int_State\(1));
\i4/U_Rxcver/n336_s1\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => i4_U_Rxcver_n336_4,
  I0 => i4_U_Rxcver_RxFrmErr1_r,
  I1 => i4_U_Rxcver_RxFrmErr,
  I2 => i4_U_Rxcver_HuntOne_r,
  I3 => I_RESETN);
\i4/U_Rxcver/n189_s1\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => i4_U_Rxcver_n189_4,
  I0 => \i4/U_Rxcver/NumDataBitReceived_r\(3),
  I1 => \i4/U_Rxcver/NumDataBitReceived_r\(2),
  I2 => i4_U_Rxcver_n189_5,
  I3 => \i4/U_Rxcver/Rx_State\(0));
\i4/U_Rxcver/n273_s1\: LUT3
generic map (
  INIT => X"C5"
)
port map (
  F => i4_U_Rxcver_n273_4,
  I0 => i4_U_Rxcver_RxPrtyErr,
  I1 => i4_u_uart_sram_PE_re_Z,
  I2 => i4_U_Rxcver_ParityErr);
\i4/U_Rxcver/n273_s2\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_U_Rxcver_n273_5,
  I0 => i4_U_Rxcver_RxIdle1_r,
  I1 => i4_U_Rxcver_RxIdle_r);
\i4/U_Rxcver/n284_s1\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => i4_U_Rxcver_n284_4,
  I0 => i4_U_Rxcver_RxIdle_r_2,
  I1 => i4_U_Rxcver_RxIdle_r_1,
  I2 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_full);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_2_s1\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_2,
  I0 => i4_U_Rxcver_RxIdle_r_2,
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_full,
  I2 => i4_U_Rxcver_RxIdle_r_1,
  I3 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(0));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_3_s1\: LUT4
generic map (
  INIT => X"007F"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_3,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  I2 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_2,
  I3 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wfull_val_s1\: LUT3
generic map (
  INIT => X"69"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_4,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(3),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin\(4),
  I2 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_3);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wfull_val_s2\: LUT4
generic map (
  INIT => X"BDDB"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_5,
  I0 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_8,
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(0),
  I3 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_0);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wfull_val_s3\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_6,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(2),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(2));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wfull_val_s4\: LUT3
generic map (
  INIT => X"69"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_7,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(4),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbin\(4),
  I2 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_3);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext_0_s1\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_0,
  I0 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I1 => I_RX_EN,
  I2 => i4_u_uart_sram_RbrRDn_re_Z);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext_3_s1\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_3,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(0),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2),
  I3 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rgraynext_0);
\i4/U_Txmitt/n119_s2\: LUT3
generic map (
  INIT => X"E0"
)
port map (
  F => i4_U_Txmitt_n119_5,
  I0 => \i4/u_uart_sram/LCR\(2),
  I1 => \i4/U_Txmitt/Tx_State\(2),
  I2 => \i4/U_Txmitt/Tx_State\(1));
\i4/U_Txmitt/n237_s1\: LUT4
generic map (
  INIT => X"E01F"
)
port map (
  F => i4_U_Txmitt_n237_4,
  I0 => \i4/u_uart_sram/DataBits\(0),
  I1 => \i4/u_uart_sram/DataBits\(1),
  I2 => \i4/u_uart_sram/LCR\(2),
  I3 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wfull_val_s1\: LUT4
generic map (
  INIT => X"DEB7"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_4,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(3),
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(4),
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(3),
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(4));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wfull_val_s2\: LUT4
generic map (
  INIT => X"7DEB"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_5,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_6,
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(1),
  I2 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_1,
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2));
\i4/U_Rxcver/n195_s9\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_U_Rxcver_n195_16,
  I0 => i4_U_Rxcver_SIN1_rr,
  I1 => i4_U_Rxcver_RxIdle_r);
\i4/U_Rxcver/n198_s6\: LUT3
generic map (
  INIT => X"4B"
)
port map (
  F => i4_U_Rxcver_n198_10,
  I0 => \i4/U_Rxcver/Rx_State\(1),
  I1 => i4_U_Rxcver_SIN1_rr,
  I2 => i4_u_uart_sram_ParityEven);
\i4/U_Rxcver/n198_s7\: LUT3
generic map (
  INIT => X"5C"
)
port map (
  F => i4_U_Rxcver_n198_11,
  I0 => i4_u_uart_sram_ParityStick,
  I1 => \i4/U_Rxcver/Rx_State\(0),
  I2 => \i4/U_Rxcver/Rx_State\(1));
\i4/U_Rxcver/RBR_r_5_s4\: LUT3
generic map (
  INIT => X"35"
)
port map (
  F => i4_U_Rxcver_RBR_r_5,
  I0 => \i4/U_Rxcver/RSR\(6),
  I1 => \i4/U_Rxcver/RSR\(5),
  I2 => \i4/u_uart_sram/DataBits\(0));
\i4/U_Rxcver/RBR_r_4_s4\: LUT4
generic map (
  INIT => X"03F5"
)
port map (
  F => i4_U_Rxcver_RBR_r_4,
  I0 => \i4/U_Rxcver/RSR\(7),
  I1 => \i4/U_Rxcver/RSR\(6),
  I2 => \i4/u_uart_sram/DataBits\(1),
  I3 => \i4/u_uart_sram/DataBits\(0));
\i4/U_Rxcver/RBR_r_3_s4\: LUT4
generic map (
  INIT => X"03F5"
)
port map (
  F => i4_U_Rxcver_RBR_r_3,
  I0 => \i4/U_Rxcver/RSR\(6),
  I1 => \i4/U_Rxcver/RSR\(5),
  I2 => \i4/u_uart_sram/DataBits\(1),
  I3 => \i4/u_uart_sram/DataBits\(0));
\i4/U_Rxcver/RBR_r_2_s4\: LUT4
generic map (
  INIT => X"F503"
)
port map (
  F => i4_U_Rxcver_RBR_r_2,
  I0 => \i4/U_Rxcver/RSR\(4),
  I1 => \i4/U_Rxcver/RSR\(5),
  I2 => \i4/u_uart_sram/DataBits\(1),
  I3 => \i4/u_uart_sram/DataBits\(0));
\i4/U_Rxcver/RBR_r_1_s5\: LUT4
generic map (
  INIT => X"F503"
)
port map (
  F => i4_U_Rxcver_RBR_r_1,
  I0 => \i4/U_Rxcver/RSR\(3),
  I1 => \i4/U_Rxcver/RSR\(4),
  I2 => \i4/u_uart_sram/DataBits\(1),
  I3 => \i4/u_uart_sram/DataBits\(0));
\i4/U_Rxcver/RBR_r_0_s5\: LUT4
generic map (
  INIT => X"F503"
)
port map (
  F => i4_U_Rxcver_RBR_r_0,
  I0 => \i4/U_Rxcver/RSR\(2),
  I1 => \i4/U_Rxcver/RSR\(3),
  I2 => \i4/u_uart_sram/DataBits\(1),
  I3 => \i4/u_uart_sram/DataBits\(0));
\i4/U_Txmitt/n145_s14\: LUT4
generic map (
  INIT => X"BFFC"
)
port map (
  F => i4_U_Txmitt_n145_20,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I1 => \i4/U_Txmitt/Tx_State\(0),
  I2 => \i4/U_Txmitt/Tx_State\(2),
  I3 => \i4/U_Txmitt/Tx_State\(1));
\i4/U_Txmitt/n146_s11\: LUT3
generic map (
  INIT => X"80"
)
port map (
  F => i4_U_Txmitt_n146_17,
  I0 => i4_U_Txmitt_TxClkEnA,
  I1 => \i4/U_Txmitt/Tx_State\(0),
  I2 => \i4/U_Txmitt/Tx_State\(1));
\i4/U_Txmitt/n147_s23\: LUT4
generic map (
  INIT => X"9EF7"
)
port map (
  F => i4_U_Txmitt_n147_31,
  I0 => i4_U_Txmitt_n147_33,
  I1 => \i4/U_Txmitt/TxCNT_r\(1),
  I2 => \i4/u_uart_sram/DataBits\(0),
  I3 => \i4/U_Txmitt/TxCNT_r\(2));
\i4/U_Txmitt/n147_s24\: LUT4
generic map (
  INIT => X"A83F"
)
port map (
  F => i4_U_Txmitt_n147_32,
  I0 => \i4/U_Txmitt/Tx_State\(0),
  I1 => i4_U_Txmitt_n147_34,
  I2 => \i4/U_Txmitt/Tx_State\(2),
  I3 => \i4/U_Txmitt/Tx_State\(1));
\i4/U_Txmitt/n148_s19\: LUT4
generic map (
  INIT => X"00EF"
)
port map (
  F => i4_U_Txmitt_n148_25,
  I0 => \i4/U_Txmitt/Tx_State\(1),
  I1 => i4_U_Txmitt_n147_31,
  I2 => i4_u_uart_sram_ParityEnable,
  I3 => i4_U_Txmitt_n148_27);
\i4/U_Txmitt/n148_s20\: LUT4
generic map (
  INIT => X"4F13"
)
port map (
  F => i4_U_Txmitt_n148_26,
  I0 => i4_U_Txmitt_n148_28,
  I1 => i4_U_Txmitt_TxClkEnA,
  I2 => \i4/U_Txmitt/Tx_State\(2),
  I3 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/n149_s10\: LUT4
generic map (
  INIT => X"C500"
)
port map (
  F => i4_U_Txmitt_n149_14,
  I0 => i4_U_Txmitt_TxParity_r,
  I1 => i4_u_uart_sram_ParityEven,
  I2 => i4_u_uart_sram_ParityStick,
  I3 => \i4/U_Txmitt/Tx_State\(1));
\i4/U_Txmitt/n149_s11\: LUT4
generic map (
  INIT => X"233F"
)
port map (
  F => i4_U_Txmitt_n149_15,
  I0 => i4_U_Txmitt_TxClkEnA,
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I2 => \i4/U_Txmitt/Tx_State\(2),
  I3 => \i4/U_Txmitt/Tx_State\(1));
\i4/U_Txmitt/n149_s12\: LUT4
generic map (
  INIT => X"0CFA"
)
port map (
  F => i4_U_Txmitt_n149_16,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_fifomem/THRi\(0),
  I1 => \i4/U_Txmitt/TSR\(0),
  I2 => \i4/U_Txmitt/Tx_State\(1),
  I3 => \i4/U_Txmitt/Tx_State\(0));
\i4/U_Txmitt/n158_s9\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => i4_U_Txmitt_n158_13,
  I0 => i4_U_Txmitt_TxParity_r,
  I1 => \i4/U_Txmitt/TSR\(0));
\i4/u_baudset/rxclk_s4\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => i4_u_baudset_rxclk_6,
  I0 => \i4/u_baudset/cnt1\(1),
  I1 => \i4/u_baudset/cnt1\(0),
  I2 => i4_u_baudset_rxclk_7,
  I3 => \i4/u_baudset/cnt1\(2));
\i4/u_uart_sram/Int_State_0_s7\: LUT4
generic map (
  INIT => X"EF00"
)
port map (
  F => i4_u_uart_sram_Int_State_0_12,
  I0 => i4_u_uart_sram_n280_31,
  I1 => i4_u_uart_sram_Int_State_0_13,
  I2 => i4_u_uart_sram_Int_State_0_18,
  I3 => i4_u_uart_sram_Int_State_0_15);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_3_s4\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_3,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3),
  I3 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_2);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_1_s4\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_1,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_full,
  I1 => i4_u_uart_sram_ThrWRn_re_Z,
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(0),
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_3_s4\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_3,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2));
\i4/u_uart_sram/n280_s25\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_u_uart_sram_n280_31,
  I0 => i4_u_uart_sram_n280_33,
  I1 => \i4/u_uart_sram/IER\(2));
\i4/u_uart_sram/n280_s26\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => i4_u_uart_sram_n280_32,
  I0 => i4_U_Rxcver_RxRDY,
  I1 => \i4/u_uart_sram/IER\(0),
  I2 => \i4/u_uart_sram/IER\(1),
  I3 => i4_U_Txmitt_THRE);
\i4/U_Rxcver/n207_s5\: LUT3
generic map (
  INIT => X"80"
)
port map (
  F => i4_U_Rxcver_n207_11,
  I0 => \i4/U_Rxcver/NumDataBitReceived_r\(0),
  I1 => \i4/U_Rxcver/NumDataBitReceived_r\(1),
  I2 => \i4/U_Rxcver/NumDataBitReceived_r\(2));
\i4/u_uart_sram/reg_data_out_0_s2\: LUT4
generic map (
  INIT => X"030A"
)
port map (
  F => i4_u_uart_sram_reg_data_out_0,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/RBR\(0),
  I1 => NN,
  I2 => I_RADDR(2),
  I3 => I_RADDR(1));
\i4/u_uart_sram/reg_data_out_0_s3\: LUT4
generic map (
  INIT => X"0777"
)
port map (
  F => i4_u_uart_sram_reg_data_out_0_8,
  I0 => i4_u_uart_sram_n165,
  I1 => i4_U_Rxcver_RxRDY,
  I2 => \i4/U_Modem/MSR\(0),
  I3 => i4_u_uart_sram_n201);
\i4/u_uart_sram/reg_data_out_1_s2\: LUT4
generic map (
  INIT => X"08C0"
)
port map (
  F => i4_u_uart_sram_reg_data_out_1,
  I0 => i4_U_Rxcver_OverrunErr,
  I1 => i4_u_uart_sram_reg_data_out_1_8,
  I2 => I_RADDR(1),
  I3 => I_RADDR(0));
\i4/u_uart_sram/reg_data_out_2_s2\: LUT4
generic map (
  INIT => X"AC00"
)
port map (
  F => i4_u_uart_sram_reg_data_out_2,
  I0 => \i4/U_Modem/MSR\(2),
  I1 => i4_u_uart_sram_reg_data_out_2_9,
  I2 => I_RADDR(2),
  I3 => I_RADDR(1));
\i4/u_uart_sram/reg_data_out_2_s3\: LUT4
generic map (
  INIT => X"0777"
)
port map (
  F => i4_u_uart_sram_reg_data_out_2_8,
  I0 => i4_u_uart_sram_RbrRDn_re_Z,
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/RBR\(2),
  I2 => i4_U_Rxcver_ParityErr,
  I3 => i4_u_uart_sram_n165);
\i4/u_uart_sram/reg_data_out_3_s2\: LUT4
generic map (
  INIT => X"3F05"
)
port map (
  F => i4_u_uart_sram_reg_data_out_3,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/RBR\(3),
  I1 => \i4/U_Modem/MSR\(3),
  I2 => I_RADDR(1),
  I3 => I_RADDR(2));
\i4/u_uart_sram/reg_data_out_4_s2\: LUT4
generic map (
  INIT => X"0777"
)
port map (
  F => i4_u_uart_sram_reg_data_out_4,
  I0 => i4_u_uart_sram_RbrRDn_re_Z,
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/RBR\(4),
  I2 => i4_U_Rxcver_BreakInt,
  I3 => i4_u_uart_sram_n165);
\i4/u_uart_sram/reg_data_out_5_s2\: LUT4
generic map (
  INIT => X"0777"
)
port map (
  F => i4_u_uart_sram_reg_data_out_5,
  I0 => i4_u_uart_sram_RbrRDn_re_Z,
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/RBR\(5),
  I2 => i4_U_Txmitt_THRE,
  I3 => i4_u_uart_sram_n165);
\i4/u_uart_sram/reg_data_out_6_s2\: LUT4
generic map (
  INIT => X"0777"
)
port map (
  F => i4_u_uart_sram_reg_data_out_6,
  I0 => i4_u_uart_sram_RbrRDn_re_Z,
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/RBR\(6),
  I2 => \i4/U_Modem/MSR\(6),
  I3 => i4_u_uart_sram_n201);
\i4/u_uart_sram/reg_data_out_6_s3\: LUT3
generic map (
  INIT => X"80"
)
port map (
  F => i4_u_uart_sram_reg_data_out_6_8,
  I0 => i4_U_Txmitt_THRE,
  I1 => i4_U_Txmitt_TsrEmpty,
  I2 => i4_u_uart_sram_n165);
\i4/u_baudset/n33_s3\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => i4_u_baudset_n33_8,
  I0 => \i4/u_baudset/cnt1\(0),
  I1 => \i4/u_baudset/cnt1\(1),
  I2 => \i4/u_baudset/cnt1\(2),
  I3 => \i4/u_baudset/cnt1\(3));
\i4/U_Rxcver/n40_s3\: LUT3
generic map (
  INIT => X"80"
)
port map (
  F => i4_U_Rxcver_n40_8,
  I0 => \i4/U_Rxcver/CNT_r\(0),
  I1 => \i4/U_Rxcver/CNT_r\(1),
  I2 => \i4/U_Rxcver/CNT_r\(2));
\i4/u_uart_sram/n258_s2\: LUT4
generic map (
  INIT => X"BB0F"
)
port map (
  F => i4_u_uart_sram_n258_7,
  I0 => i4_u_uart_sram_IirRDn_re,
  I1 => i4_U_Txmitt_THRE,
  I2 => i4_U_Rxcver_RxRDY,
  I3 => \i4/u_uart_sram/Int_State\(0));
\i4/u_baudset/n31_s3\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => i4_u_baudset_n31_8,
  I0 => \i4/u_baudset/cnt1\(5),
  I1 => \i4/u_baudset/cnt1\(6),
  I2 => \i4/u_baudset/cnt1\(3),
  I3 => \i4/u_baudset/cnt1\(4));
\i4/U_Txmitt/Tx_State_1_s5\: LUT3
generic map (
  INIT => X"7C"
)
port map (
  F => i4_U_Txmitt_Tx_State_1_10,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I1 => \i4/U_Txmitt/Tx_State\(1),
  I2 => \i4/U_Txmitt/Tx_State\(2));
\i4/U_Rxcver/n189_s2\: LUT4
generic map (
  INIT => X"9009"
)
port map (
  F => i4_U_Rxcver_n189_5,
  I0 => \i4/U_Rxcver/NumDataBitReceived_r\(0),
  I1 => \i4/u_uart_sram/DataBits\(0),
  I2 => \i4/U_Rxcver/NumDataBitReceived_r\(1),
  I3 => \i4/u_uart_sram/DataBits\(1));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wfull_val_s5\: LUT4
generic map (
  INIT => X"B44B"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_8,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_2,
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(1),
  I3 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wfull_val_s3\: LUT4
generic map (
  INIT => X"4BB4"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wfull_val_6,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_1,
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_r2w/wq2_rptr_Z\(2),
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3));
\i4/U_Txmitt/n147_s25\: LUT4
generic map (
  INIT => X"A335"
)
port map (
  F => i4_U_Txmitt_n147_33,
  I0 => \i4/U_Txmitt/TxCNT_r\(1),
  I1 => \i4/u_uart_sram/DataBits\(1),
  I2 => \i4/u_uart_sram/DataBits\(0),
  I3 => \i4/U_Txmitt/TxCNT_r\(0));
\i4/U_Txmitt/n147_s26\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => i4_U_Txmitt_n147_34,
  I0 => \i4/u_uart_sram/LCR\(2),
  I1 => i4_U_Txmitt_TxClkEnA,
  I2 => \i4/U_Txmitt/Tx_State\(2));
\i4/U_Txmitt/n148_s21\: LUT4
generic map (
  INIT => X"E000"
)
port map (
  F => i4_U_Txmitt_n148_27,
  I0 => \i4/u_uart_sram/DataBits\(1),
  I1 => \i4/u_uart_sram/DataBits\(0),
  I2 => \i4/u_uart_sram/LCR\(2),
  I3 => \i4/U_Txmitt/Tx_State\(1));
\i4/U_Txmitt/n148_s22\: LUT3
generic map (
  INIT => X"BC"
)
port map (
  F => i4_U_Txmitt_n148_28,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I1 => \i4/U_Txmitt/Tx_State\(0),
  I2 => \i4/U_Txmitt/Tx_State\(1));
\i4/u_baudset/rxclk_s5\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => i4_u_baudset_rxclk_7,
  I0 => \i4/u_baudset/cnt1\(3),
  I1 => \i4/u_baudset/cnt1\(6),
  I2 => \i4/u_baudset/cnt1\(5),
  I3 => \i4/u_baudset/cnt1\(4));
\i4/u_uart_sram/Int_State_0_s8\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_u_uart_sram_Int_State_0_13,
  I0 => i4_u_uart_sram_Int_State_0_16,
  I1 => \i4/u_uart_sram/IER\(3));
\i4/u_uart_sram/Int_State_0_s10\: LUT4
generic map (
  INIT => X"F0BB"
)
port map (
  F => i4_u_uart_sram_Int_State_0_15,
  I0 => i4_u_uart_sram_LsrRDn_re_Z,
  I1 => \i4/u_uart_sram/Int_State\(0),
  I2 => i4_u_uart_sram_n258_7,
  I3 => \i4/u_uart_sram/Int_State\(1));
\i4/u_uart_sram/n280_s27\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => i4_u_uart_sram_n280_33,
  I0 => i4_U_Rxcver_OverrunErr,
  I1 => i4_U_Rxcver_ParityErr,
  I2 => i4_U_Rxcver_FrameErr,
  I3 => i4_U_Rxcver_BreakInt);
\i4/u_uart_sram/reg_data_out_1_s3\: LUT4
generic map (
  INIT => X"FA0C"
)
port map (
  F => i4_u_uart_sram_reg_data_out_1_8,
  I0 => \i4/U_Modem/MSR\(1),
  I1 => i4_u_uart_sram_reg_data_out_1_9,
  I2 => I_RADDR(0),
  I3 => I_RADDR(2));
\i4/u_uart_sram/reg_data_out_2_s4\: LUT3
generic map (
  INIT => X"14"
)
port map (
  F => i4_u_uart_sram_reg_data_out_2_9,
  I0 => \i4/u_uart_sram/Int_State\(2),
  I1 => \i4/u_uart_sram/Int_State\(0),
  I2 => \i4/u_uart_sram/Int_State\(1));
\i4/u_uart_sram/n257_s3\: LUT4
generic map (
  INIT => X"0777"
)
port map (
  F => i4_u_uart_sram_n257_8,
  I0 => \i4/u_uart_sram/IER\(1),
  I1 => i4_U_Txmitt_THRE,
  I2 => \i4/u_uart_sram/IER\(0),
  I3 => i4_U_Rxcver_RxRDY);
\i4/u_uart_sram/Int_State_0_s11\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => i4_u_uart_sram_Int_State_0_16,
  I0 => \i4/U_Modem/MSR\(0),
  I1 => \i4/U_Modem/MSR\(1),
  I2 => \i4/U_Modem/MSR\(2),
  I3 => \i4/U_Modem/MSR\(3));
\i4/u_uart_sram/reg_data_out_1_s4\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => i4_u_uart_sram_reg_data_out_1_9,
  I0 => \i4/u_uart_sram/Int_State\(2),
  I1 => \i4/u_uart_sram/Int_State\(0));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_1_s1\: LUT3
generic map (
  INIT => X"96"
)
port map (
  F => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(1),
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_2,
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(2));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_3_s5\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(3),
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_1,
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2),
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(3));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_2_s1\: LUT3
generic map (
  INIT => X"96"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(2),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_1,
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(3));
\i4/u_uart_sram/n257_s4\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => i4_u_uart_sram_n257_10,
  I0 => i4_u_uart_sram_n280_31,
  I1 => i4_u_uart_sram_Int_State_0_16,
  I2 => \i4/u_uart_sram/IER\(3),
  I3 => i4_u_uart_sram_n257_8);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_0_s2\: LUT4
generic map (
  INIT => X"5455"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_0,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(0),
  I1 => i4_U_Rxcver_RxIdle_r_2,
  I2 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_full,
  I3 => i4_U_Rxcver_RxIdle_r_1);
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_0_s4\: LUT4
generic map (
  INIT => X"A9AA"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_0,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_wptr_full/waddr\(0),
  I1 => i4_U_Rxcver_RxIdle_r_2,
  I2 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_wptr_full_full,
  I3 => i4_U_Rxcver_RxIdle_r_1);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext_2_s1\: LUT4
generic map (
  INIT => X"8778"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(2),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_1,
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2),
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(3));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext_1_s1\: LUT4
generic map (
  INIT => X"956A"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(1),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(1),
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  I2 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_1,
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(2));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_1_s5\: LUT4
generic map (
  INIT => X"0400"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_1,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(0),
  I2 => i4_U_Txmitt_fifo_rd3,
  I3 => i4_U_Txmitt_fifo_rd2);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_0_s4\: LUT4
generic map (
  INIT => X"EF10"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_0,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I1 => i4_U_Txmitt_fifo_rd3,
  I2 => i4_U_Txmitt_fifo_rd2,
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(0));
\i4/U_Rxcver/Hunt_r_s4\: LUT3
generic map (
  INIT => X"EF"
)
port map (
  F => i4_U_Rxcver_Hunt_r_10,
  I0 => i4_U_Rxcver_n336,
  I1 => i4_U_Rxcver_SIN1_rr,
  I2 => i4_U_Rxcver_RxIdle_r);
\i4/U_Rxcver/n43_s2\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => i4_U_Rxcver_n43_6,
  I0 => i4_U_Rxcver_Hunt_r,
  I1 => \i4/U_Rxcver/Rx_State\(0),
  I2 => \i4/U_Rxcver/Rx_State\(1));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_3_s1\: LUT4
generic map (
  INIT => X"8778"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(3),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(2),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_1,
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(3),
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext\(4));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_1_s2\: LUT4
generic map (
  INIT => X"00BF"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wgraynext_1,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_full,
  I1 => i4_u_uart_sram_ThrWRn_re_Z,
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(0),
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wbinnext_0_s4\: LUT3
generic map (
  INIT => X"9A"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_wbinnext_0,
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(0),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_full,
  I2 => i4_u_uart_sram_ThrWRn_re_Z);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext_0_s1\: LUT4
generic map (
  INIT => X"45BA"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/wgraynext\(0),
  I0 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(0),
  I1 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_wptr_full_full,
  I2 => i4_u_uart_sram_ThrWRn_re_Z,
  I3 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_wptr_full/waddr\(1));
\i4/u_uart_sram/n258_s4\: LUT4
generic map (
  INIT => X"0045"
)
port map (
  F => i4_u_uart_sram_n258_10,
  I0 => \i4/u_uart_sram/Int_State\(0),
  I1 => i4_u_uart_sram_n280_33,
  I2 => \i4/u_uart_sram/IER\(2),
  I3 => i4_u_uart_sram_n257_8);
\i4/u_uart_sram/Int_State_0_s12\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => i4_u_uart_sram_Int_State_0_18,
  I0 => \i4/u_uart_sram/Int_State\(0),
  I1 => \i4/u_uart_sram/Int_State\(1),
  I2 => i4_u_uart_sram_n257_8);
\i4/u_uart_sram/INTR_d_s1\: LUT3
generic map (
  INIT => X"56"
)
port map (
  F => NN,
  I0 => \i4/u_uart_sram/Int_State\(2),
  I1 => \i4/u_uart_sram/Int_State\(0),
  I2 => \i4/u_uart_sram/Int_State\(1));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext_0_s4\: LUT4
generic map (
  INIT => X"9AAA"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_0,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(0),
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I2 => I_RX_EN,
  I3 => i4_u_uart_sram_RbrRDn_re_Z);
\i4/u_uart_sram/n201_s2\: LUT4
generic map (
  INIT => X"2000"
)
port map (
  F => i4_u_uart_sram_n201_6,
  I0 => I_RX_EN,
  I1 => I_RADDR(0),
  I2 => I_RADDR(1),
  I3 => I_RADDR(2));
\i4/u_uart_sram/reg_data_out_3_s4\: LUT4
generic map (
  INIT => X"2000"
)
port map (
  F => i4_u_uart_sram_reg_data_out_3_10,
  I0 => i4_U_Rxcver_FrameErr,
  I1 => I_RADDR(1),
  I2 => I_RADDR(0),
  I3 => I_RADDR(2));
\i4/u_uart_sram/n165_s2\: LUT4
generic map (
  INIT => X"2000"
)
port map (
  F => i4_u_uart_sram_n165_6,
  I0 => I_RX_EN,
  I1 => I_RADDR(1),
  I2 => I_RADDR(0),
  I3 => I_RADDR(2));
\i4/u_uart_sram/reg_data_out_7_s3\: LUT4
generic map (
  INIT => X"0002"
)
port map (
  F => i4_u_uart_sram_reg_data_out_7,
  I0 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_fifomem/RBR\(7),
  I1 => I_RADDR(0),
  I2 => I_RADDR(1),
  I3 => I_RADDR(2));
\i4/u_uart_sram/RbrRDn_re_Z_s1\: LUT4
generic map (
  INIT => X"0002"
)
port map (
  F => i4_u_uart_sram_RbrRDn_re_Z_5,
  I0 => I_RX_EN,
  I1 => I_RADDR(0),
  I2 => I_RADDR(1),
  I3 => I_RADDR(2));
\i4/U_Txmitt/TxCNT_r_0_s3\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/U_Txmitt/TxCNT_r\(0),
  D => i4_U_Txmitt_n161,
  CLK => i4_u_baudset_rxclk_Z,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/MSReg_3_s4\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/U_Modem/MSR\(3),
  D => i4_U_Modem_n26,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/MSReg_2_s4\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/U_Modem/MSR\(2),
  D => i4_U_Modem_n26_18,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/MSReg_1_s4\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/U_Modem/MSR\(1),
  D => i4_U_Modem_n26_21,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Modem/MSReg_0_s4\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \i4/U_Modem/MSR\(0),
  D => i4_U_Modem_n26_24,
  CLK => I_CLK,
  CLEAR => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Rxcver/RxIdle_r_s5\: DFFPE
generic map (
  INIT => '1'
)
port map (
  Q => i4_U_Rxcver_RxIdle_r,
  D => i4_U_Rxcver_n99,
  CLK => I_CLK,
  PRESET => i4_u_uart_sram_n14,
  CE => VCC_0);
\i4/U_Txmitt/n161_s12\: LUT4
generic map (
  INIT => X"7580"
)
port map (
  F => i4_U_Txmitt_n161,
  I0 => i4_U_Txmitt_TSR_6,
  I1 => i4_U_Txmitt_n147_31,
  I2 => \i4/U_Txmitt/Tx_State\(0),
  I3 => \i4/U_Txmitt/TxCNT_r\(0));
\i4/U_Txmitt/TxCNT_r_2_s5\: LUT3
generic map (
  INIT => X"B0"
)
port map (
  F => i4_U_Txmitt_TxCNT_r_2,
  I0 => i4_U_Txmitt_n147_31,
  I1 => \i4/U_Txmitt/Tx_State\(0),
  I2 => i4_U_Txmitt_TSR_6);
\i4/U_Modem/n26_s8\: LUT4
generic map (
  INIT => X"00BE"
)
port map (
  F => i4_U_Modem_n26,
  I0 => \i4/U_Modem/MSR\(3),
  I1 => DCDn,
  I2 => i4_U_Modem_DCDn1,
  I3 => i4_u_uart_sram_MsrRDn_re_Z);
\i4/U_Modem/n26_s10\: LUT4
generic map (
  INIT => X"00F4"
)
port map (
  F => i4_U_Modem_n26_18,
  I0 => i4_U_Modem_RIn1,
  I1 => RIn,
  I2 => \i4/U_Modem/MSR\(2),
  I3 => i4_u_uart_sram_MsrRDn_re_Z);
\i4/U_Modem/n26_s11\: LUT4
generic map (
  INIT => X"00BE"
)
port map (
  F => i4_U_Modem_n26_21,
  I0 => \i4/U_Modem/MSR\(1),
  I1 => DSRn,
  I2 => i4_U_Modem_DSRn1,
  I3 => i4_u_uart_sram_MsrRDn_re_Z);
\i4/U_Modem/n26_s12\: LUT4
generic map (
  INIT => X"00BE"
)
port map (
  F => i4_U_Modem_n26_24,
  I0 => \i4/U_Modem/MSR\(0),
  I1 => CTSn,
  I2 => i4_U_Modem_CTSn1,
  I3 => i4_u_uart_sram_MsrRDn_re_Z);
\i4/U_Rxcver/n99_s4\: LUT4
generic map (
  INIT => X"1F11"
)
port map (
  F => i4_U_Rxcver_n99,
  I0 => \i4/U_Rxcver/Rx_State\(1),
  I1 => \i4/U_Rxcver/Rx_State\(0),
  I2 => \i4/U_Rxcver/CNT_r\(2),
  I3 => i4_U_Rxcver_RxIdle_r);
\i4/U_Rxcver/n99_s5\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => i4_U_Rxcver_n99_12,
  I0 => \i4/U_Rxcver/Rx_State\(0),
  I1 => \i4/U_Rxcver/Rx_State\(1));
\i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rempty_val_s1\: LUT3
generic map (
  INIT => X"41"
)
port map (
  F => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_rempty_val,
  I0 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_n53_3,
  I1 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(4),
  I2 => \i4/U_Rxcver/Rx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(4));
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rempty_val_s1\: LUT3
generic map (
  INIT => X"41"
)
port map (
  F => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rempty_val,
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_n53_3,
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_sync_w2r/rq2_wptr_Z\(4),
  I2 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rbinnext\(4));
\i4/U_Rxcver/OverrunErr_r_s4\: LUT4
generic map (
  INIT => X"FFEA"
)
port map (
  F => i4_U_Rxcver_OverrunErr_r,
  I0 => i4_u_uart_sram_OE_re_Z,
  I1 => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_empty,
  I2 => i4_u_uart_sram_RbrRDn_re_Z_5,
  I3 => i4_U_Rxcver_n284_4);
\i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext_0_s1\: LUT3
generic map (
  INIT => X"96"
)
port map (
  F => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/rgraynext\(0),
  I0 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_0,
  I1 => \i4/U_Txmitt/Tx_FIFO/u_uart_fifo/u_rptr_empty/raddr\(1),
  I2 => i4_U_Txmitt_Tx_FIFO_u_uart_fifo_u_rptr_empty_rbinnext_1);
\i4/TxRDYn_d_s0\: INV
port map (
  O => TxRDYn,
  I => i4_U_Txmitt_THRE);
\i4/RxRDYn_d_s0\: INV
port map (
  O => RxRDYn,
  I => i4_U_Rxcver_RxRDY);
\i4/u_uart_sram/n14_s2\: INV
port map (
  O => i4_u_uart_sram_n14,
  I => I_RESETN);
\i4/u_uart_sram/DDIS_d_s0\: INV
port map (
  O => DDIS,
  I => I_RX_EN);
\i4/U_Modem/DTRn_d_s0\: INV
port map (
  O => DTRn,
  I => \i4/u_uart_sram/MCR_Z\(0));
\i4/U_Modem/RTSn_d_s0\: INV
port map (
  O => RTSn,
  I => \i4/u_uart_sram/MCR_Z\(1));
\i4/U_Txmitt/n272_s4\: INV
port map (
  O => i4_U_Txmitt_n272,
  I => \i4/U_Txmitt/Count_vr\(0));
\i4/U_Rxcver/n82_s3\: INV
port map (
  O => i4_U_Rxcver_n82,
  I => i4_U_Rxcver_Rx_FIFO_u_uart_fifo_u_rptr_empty_empty);
\i4/U_Rxcver/n74_s3\: INV
port map (
  O => i4_U_Rxcver_n74,
  I => i4_U_Rxcver_Hunt_r);
\i4/U_Txmitt/n200_s3\: INV
port map (
  O => i4_U_Txmitt_n200,
  I => i4_u_uart_sram_ThrWRn_re_Z);
\i4/u_baudset/n38_s2\: INV
port map (
  O => i4_u_baudset_n38,
  I => \i4/u_baudset/cnt1\(0));
GND_s14: GND
port map (
  G => GND_0);
VCC_s5: VCC
port map (
  V => VCC_0);
GSR_0: GSR
port map (
  GSRI => VCC_0);
  INTR <= NN;
end beh;
