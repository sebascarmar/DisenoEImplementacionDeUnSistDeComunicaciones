//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
//Date        : Thu Apr 10 23:49:12 2025
//Host        : carmar running 64-bit Ubuntu 20.04.6 LTS
//Command     : generate_target ila_a_wrapper.bd
//Design      : ila_a_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ila_a_wrapper
   (clk_100MHz,
    probe0_0);
  input clk_100MHz;
  input [3:0]probe0_0;

  wire clk_100MHz;
  wire [3:0]probe0_0;

  ila_a ila_a_i
       (.clk_100MHz(clk_100MHz),
        .probe0_0(probe0_0));
endmodule
