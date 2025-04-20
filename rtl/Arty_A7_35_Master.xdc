## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { i_clk }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { i_clk }];

## Switches
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { i_sw }]; #IO_L12N_T1_MRCC_16 Sch=sw[0]

## LEDs
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { o_normal_led[0] }]; #IO_L24P_T3_A01_D17_14 Sch=led[6]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { o_normal_led[1] }]; #IO_L24N_T3_A00_D16_14 Sch=led[7]

## RGB LEDs
set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33 } [get_ports { o_rgb_led3_b }]; #IO_L23P_T3_35 Sch=led3_b
set_property -dict { PACKAGE_PIN J3    IOSTANDARD LVCMOS33 } [get_ports { o_rgb_led2_b }]; #IO_L21N_T3_DQS_35 Sch=led2_b
set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports { o_rgb_led1_g }]; #IO_L21P_T3_DQS_35 Sch=led1_g
set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVCMOS33 } [get_ports { o_rgb_led0_g }]; #IO_L19N_T3_VREF_35 Sch=led0_g

## Misc. ChipKit Ports
set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { i_reset }]; #IO_L16P_T2_35 Sch=ck_rst

### USB-UART Interface
#set_property -dict { PACKAGE_PIN A9   IOSTANDARD LVCMOS33 } [get_ports { i_rx_uart }]; #IO_L19N_T3_VREF_16 Sch=uart_rxd_out
#set_property -dict { PACKAGE_PIN D10    IOSTANDARD LVCMOS33 } [get_ports { o_tx_uart }]; #IO_L14N_T2_SRCC_16 Sch=uart_txd_in


#connect_debug_port dbg_hub/clk [get_nets clk]
#set_switching_activity -static_probability 0.0 -toggle_rate 0.0 [get_ports i_reset]

