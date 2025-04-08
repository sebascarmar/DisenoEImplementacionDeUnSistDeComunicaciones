//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
//Date        : Sun Mar 23 15:17:15 2025
//Host        : daniel-lmint running 64-bit Linux Mint 20.3
//Command     : generate_target ILA_wrapper.bd
//Design      : ILA_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ILA_wrapper
   (clk_0,
    probe0_0,
    probe1_0,
    probe2_0,
    probe3_0,
    probe4_0);
  input clk_0;
  input [7:0]probe0_0;
  input [7:0]probe1_0;
  input [31:0]probe2_0;
  input [7:0]probe3_0;
  input [7:0]probe4_0;

  wire clk_0;
  wire [7:0]probe0_0;
  wire [7:0]probe1_0;
  wire [31:0]probe2_0;
  wire [7:0]probe3_0;
  wire [7:0]probe4_0;

  ILA ILA_i
       (.clk_0(clk_0),
        .probe0_0(probe0_0),
        .probe1_0(probe1_0),
        .probe2_0(probe2_0),
        .probe3_0(probe3_0),
        .probe4_0(probe4_0));
endmodule
