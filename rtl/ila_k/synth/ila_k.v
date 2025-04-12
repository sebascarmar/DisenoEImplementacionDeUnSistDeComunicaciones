//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
//Date        : Sat Apr 12 12:20:27 2025
//Host        : carmar running 64-bit Ubuntu 20.04.6 LTS
//Command     : generate_target ila_k.bd
//Design      : ila_k
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "ila_k,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=ila_k,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=1,numReposBlks=1,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,da_clkrst_cnt=1,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "ila_k.hwdef" *) 
module ila_k
   (clk_200MHz,
    probe0_0);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_200MHZ CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_200MHZ, CLK_DOMAIN ila_k_clk_200MHz, FREQ_HZ 200000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input clk_200MHz;
  input [3:0]probe0_0;

  wire clk_200MHz_1;
  wire [3:0]probe0_0_1;

  assign clk_200MHz_1 = clk_200MHz;
  assign probe0_0_1 = probe0_0[3:0];
  ila_k_ila_0_0 ila_0
       (.clk(clk_200MHz_1),
        .probe0(probe0_0_1));
endmodule
