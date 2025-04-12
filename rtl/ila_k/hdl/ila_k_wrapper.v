//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
//Date        : Sat Apr 12 12:20:27 2025
//Host        : carmar running 64-bit Ubuntu 20.04.6 LTS
//Command     : generate_target ila_k_wrapper.bd
//Design      : ila_k_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ila_k_wrapper
   (clk_200MHz,
    probe0_0);
  input clk_200MHz;
  input [3:0]probe0_0;

  wire clk_200MHz;
  wire [3:0]probe0_0;

  ila_k ila_k_i
       (.clk_200MHz(clk_200MHz),
        .probe0_0(probe0_0));
endmodule
