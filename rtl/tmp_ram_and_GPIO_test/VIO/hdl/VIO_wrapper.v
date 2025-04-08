//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
//Date        : Sun Mar 23 15:17:17 2025
//Host        : daniel-lmint running 64-bit Linux Mint 20.3
//Command     : generate_target VIO_wrapper.bd
//Design      : VIO_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module VIO_wrapper
   (clk_0,
    probe_out0_0);
  input clk_0;
  output [0:0]probe_out0_0;

  wire clk_0;
  wire [0:0]probe_out0_0;

  VIO VIO_i
       (.clk_0(clk_0),
        .probe_out0_0(probe_out0_0));
endmodule
