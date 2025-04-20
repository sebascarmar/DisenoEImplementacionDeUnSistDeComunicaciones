`timescale 1ns/1ps


module top_vio_ila
 (
  output [3:0] o_normal_led        ,
//  output       o_rgb0_led          , // Agregar al VIO/ILA una salida más

  input        i_sw                ,
  input        i_reset             ,
  input        i_clk
 );

  // Internal wires
  wire       w_reset          ;
  wire       w_sw             ;
  wire       w_select_from_vio;
  wire       w_reset_from_vio ;
  wire       w_sw_from_vio    ;
  wire [3:0] w_normal_led     ;
//  wire       w_locked         ;
//  wire       clk              ;
    
  // Select between control via VIO or physical FPGA inputs
  assign w_reset  = w_select_from_vio ? ~w_reset_from_vio : ~i_reset;
  assign w_sw     = w_select_from_vio ? w_sw_from_vio : i_sw        ;

//  // Clock Manager
//  clk_mngr
//    u_clk_mngr (
//    .clk_out1_0(clk     ),
//    .locked_0  (w_locked),
//    .reset     (~w_reset ),
//    .sys_clock (i_clk   )
//  );

  // Integrated Logic Analyzer
  ila
    u_ila (
    .clk_0   (i_clk       ),
    .probe0_0(w_normal_led)
  );

  // Virtual Input/Output IP Core
  vio
    u_vio (
    .clk_0       (i_clk            ),
    .probe_in0_0 (w_normal_led     ),
    .probe_out0_0(w_select_from_vio),
    .probe_out1_0(w_reset_from_vio ),
    .probe_out2_0(w_sw_from_vio    )
  );

  // Communication system
  qpsk_comm_sys #(
  ) u_qpsk_comm_sys (
    .o_normal_led(w_normal_led),
    .i_sw        (w_sw        ),
    .i_reset     (~w_reset    ),
    .clk         (i_clk       ) 
  );

  // Output assignments
  assign o_normal_led = w_normal_led;
  //assign o_rgb0_led   = w_locked    ;


 endmodule

