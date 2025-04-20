`timescale 1ns/1ps


module top_vio_ila
 (
//  output [2:0] o_normal_led, // Agregar al VIO/ILA una salida más
  output [1:0] o_normal_led,
  output       o_rgb_led3_b,
  output       o_rgb_led2_b,
  output       o_rgb_led1_g,
  output       o_rgb_led0_g,

  input        i_sw        ,
  input        i_reset     ,
  input        i_clk
 );

  // Internal wires
  wire       w_reset          ;
  wire       w_sw             ;
  wire       w_select_from_vio;
  wire       w_reset_from_vio ;
  wire       w_sw_from_vio    ;
  wire [1:0] w_normal_led     ;
  //wire [2:0] w_normal_led     ;
  wire       w_sync_done_I    ;
  wire       w_sync_done_Q    ;
  wire       w_ber_ok_led_I   ;
  wire       w_ber_ok_led_Q   ;
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
    .clk_0   (i_clk         ),
    .probe0_0(w_reset       ),
    .probe1_0(w_sw          ),
    .probe2_0(w_sync_done_I ),
    .probe3_0(w_sync_done_Q ),
    .probe4_0(w_ber_ok_led_I),
    .probe5_0(w_ber_ok_led_Q)
  );

  // Virtual Input/Output IP Core
  vio
    u_vio (
    .clk_0       (i_clk            ),
    .probe_in0_0 (w_reset          ),
    .probe_in1_0 (w_sw             ),
    .probe_in2_0 (w_sync_done_I    ),
    .probe_in3_0 (w_sync_done_Q    ),
    .probe_in4_0 (w_ber_ok_led_I   ),
    .probe_in5_0 (w_ber_ok_led_Q   ),
    .probe_out0_0(w_select_from_vio),
    .probe_out1_0(w_reset_from_vio ),
    .probe_out2_0(w_sw_from_vio    )
  );

  // Communication system
  qpsk_comm_sys #(
  ) u_qpsk_comm_sys (
    .o_normal_led(w_normal_led  ),
    .o_rgb_led3_b(w_sync_done_I ),
    .o_rgb_led2_b(w_sync_done_Q ),
    .o_rgb_led1_g(w_ber_ok_led_I),
    .o_rgb_led0_g(w_ber_ok_led_Q),
    .i_sw        (w_sw          ),
    .i_reset     (~w_reset      ),
    .clk         (i_clk         ) 
  );

  // Output assignments
  //assign o_normal_led[2] = w_locked      ;
  assign o_normal_led[1] = w_reset       ;
  assign o_normal_led[0] = i_sw          ;
  assign o_rgb_led3_b    = w_sync_done_I ;
  assign o_rgb_led2_b    = w_sync_done_Q ;
  assign o_rgb_led1_g    = w_ber_ok_led_I;
  assign o_rgb_led0_g    = w_ber_ok_led_Q;


 endmodule

