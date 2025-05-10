//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
//Date        : Fri May  2 21:49:25 2025
//Host        : daniel-lmint running 64-bit Linux Mint 20.3
//Command     : generate_target ila_wrapper.bd
//Design      : ila_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ila_wrapper
   (clk_0,
    probe0_0,
    probe1_0,
    probe2_0,
    probe3_0,
    probe4_0,
    probe5_0,
    probe6_0,
    probe7_0);
  input clk_0;
  input [7:0]probe0_0;
  input [7:0]probe1_0;
  input [11:0]probe2_0;
  input [11:0]probe3_0;
  input [89:0]probe4_0;
  input [89:0]probe5_0;
  input [31:0]probe6_0;
  input [31:0]probe7_0;

  wire clk_0;
  wire [7:0]probe0_0;
  wire [7:0]probe1_0;
  wire [11:0]probe2_0;
  wire [11:0]probe3_0;
  wire [89:0]probe4_0;
  wire [89:0]probe5_0;
  wire [31:0]probe6_0;
  wire [31:0]probe7_0;

  ila ila_i
       (.clk_0(clk_0),
        .probe0_0(probe0_0),
        .probe1_0(probe1_0),
        .probe2_0(probe2_0),
        .probe3_0(probe3_0),
        .probe4_0(probe4_0),
        .probe5_0(probe5_0),
        .probe6_0(probe6_0),
        .probe7_0(probe7_0));
endmodule
