//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
//Date        : Sat Apr 19 20:17:45 2025
//Host        : carmar running 64-bit Ubuntu 20.04.6 LTS
//Command     : generate_target clk_mngr_wrapper.bd
//Design      : clk_mngr_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module clk_mngr_wrapper
   (clk_out1_0,
    locked_0,
    reset,
    sys_clock);
  output clk_out1_0;
  output locked_0;
  input reset;
  input sys_clock;

  wire clk_out1_0;
  wire locked_0;
  wire reset;
  wire sys_clock;

  clk_mngr clk_mngr_i
       (.clk_out1_0(clk_out1_0),
        .locked_0(locked_0),
        .reset(reset),
        .sys_clock(sys_clock));
endmodule
