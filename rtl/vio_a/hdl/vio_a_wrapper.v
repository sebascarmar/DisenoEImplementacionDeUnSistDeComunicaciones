//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
//Date        : Thu Apr 10 23:52:01 2025
//Host        : carmar running 64-bit Ubuntu 20.04.6 LTS
//Command     : generate_target vio_a_wrapper.bd
//Design      : vio_a_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module vio_a_wrapper
   (clk_100MHz,
    probe_in0_0,
    probe_out0_0,
    probe_out1_0,
    probe_out2_0);
  input clk_100MHz;
  input [3:0]probe_in0_0;
  output [0:0]probe_out0_0;
  output [0:0]probe_out1_0;
  output [0:0]probe_out2_0;

  wire clk_100MHz;
  wire [3:0]probe_in0_0;
  wire [0:0]probe_out0_0;
  wire [0:0]probe_out1_0;
  wire [0:0]probe_out2_0;

  vio_a vio_a_i
       (.clk_100MHz(clk_100MHz),
        .probe_in0_0(probe_in0_0),
        .probe_out0_0(probe_out0_0),
        .probe_out1_0(probe_out1_0),
        .probe_out2_0(probe_out2_0));
endmodule
