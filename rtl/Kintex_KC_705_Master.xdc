
## Clock signal
#set_property -dict { PACKAGE_PIN AD12 IOSTANDARD LVDS} [get_ports i_clk_p]
#set_property -dict { PACKAGE_PIN AD11 IOSTANDARD LVDS} [get_ports i_clk_n]
set_property -dict { PACKAGE_PIN AD12 IOSTANDARD DIFF_SSTL15} [get_ports i_clk_p]
set_property -dict { PACKAGE_PIN AD11 IOSTANDARD DIFF_SSTL15} [get_ports i_clk_n]
create_clock -add -name sys_clk_pin -period 5.00 -waveform {0 2.5} [get_ports { i_clk_p }];

## Switches
set_property -dict { PACKAGE_PIN Y29 IOSTANDARD LVCMOS25 } [get_ports { i_sw }]; #IO_L12N_T1_MRCC_16 Sch=i_sw[0]

## LEDs
set_property -dict {PACKAGE_PIN AB8 IOSTANDARD LVCMOS15} [get_ports {o_normal_led[0]}]; #IO_L12P_T1_MRCC_35 Sch=o_normal_led[0]
set_property -dict {PACKAGE_PIN AA8 IOSTANDARD LVCMOS15} [get_ports {o_normal_led[1]}]; #IO_L12N_T1_MRCC_35 Sch=o_normal_led[1]
set_property -dict {PACKAGE_PIN AC9 IOSTANDARD LVCMOS15} [get_ports {o_normal_led[2]}]; #IO_L12P_T1_MRCC_35 Sch=o_normal_led[2]
set_property -dict {PACKAGE_PIN AB9 IOSTANDARD LVCMOS15} [get_ports {o_normal_led[3]}]; #IO_L12N_T1_MRCC_35 Sch=o_normal_led[3]

#set_property SLEW SLOW [get_ports {o_normal_led[0]}]
#set_property SLEW SLOW [get_ports {o_normal_led[1]}]
#set_property SLEW SLOW [get_ports {o_normal_led[2]}]
#set_property SLEW SLOW [get_ports {o_normal_led[3]}]
#
#set_property DRIVE 4 [get_ports {o_normal_led[0]}]
#set_property DRIVE 4 [get_ports {o_normal_led[1]}]
#set_property DRIVE 4 [get_ports {o_normal_led[2]}]
#set_property DRIVE 4 [get_ports {o_normal_led[3]}]

## Reset
#set_property -dict {PACKAGE_PIN AA12 IOSTANDARD LVCMOS15} [get_ports {i_reset}]; #IO_L12P_T1_MRCC_35 Sch=i_reset
set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS15} [get_ports {i_reset}]; 

## USB-UART Interface
set_property -dict { PACKAGE_PIN M19  IOSTANDARD LVCMOS25 } [get_ports { i_rx_uart }]; #IO_L19N_T3_VREF_16 Sch=i_rx_uart 
set_property -dict { PACKAGE_PIN K24  IOSTANDARD LVCMOS25 } [get_ports { o_tx_uart }]; #IO_L14N_T2_SRCC_16 Sch=o_tx_uart


