//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
//Date        : Sun Apr 20 16:46:52 2025
//Host        : carmar running 64-bit Ubuntu 20.04.6 LTS
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
    probe5_0);
  input clk_0;
  input [0:0]probe0_0;
  input [0:0]probe1_0;
  input [0:0]probe2_0;
  input [0:0]probe3_0;
  input [0:0]probe4_0;
  input [0:0]probe5_0;

  wire clk_0;
  wire [0:0]probe0_0;
  wire [0:0]probe1_0;
  wire [0:0]probe2_0;
  wire [0:0]probe3_0;
  wire [0:0]probe4_0;
  wire [0:0]probe5_0;

  ila ila_i
       (.clk_0(clk_0),
        .probe0_0(probe0_0),
        .probe1_0(probe1_0),
        .probe2_0(probe2_0),
        .probe3_0(probe3_0),
        .probe4_0(probe4_0),
        .probe5_0(probe5_0));
endmodule
