`timescale 1ns/1ps


module top_vio_ila
 (
  output [3:0] o_normal_led        ,

  input        i_sw                ,
  input        i_reset             ,
  input        clk
 );

  // SEÑALES DE CONTROL PARA USO DE VIO
  wire [3:0] w_normal_led     ;
  wire       w_reset          ;
  wire       w_sw             ;
  wire       w_select_from_vio;
  wire       w_reset_from_vio ;
  wire       w_sw_from_vio    ;
    
  // SELECCIONA ENTRE MANEJO FÍSICO DE LA FPGA O MEDIANTE VIO
  assign w_reset  = w_select_from_vio ? ~w_reset_from_vio : ~i_reset;
  assign w_sw     = w_select_from_vio ? w_sw_from_vio : i_sw        ;


  //ila_a
  ila_k
    u_ila (
    //.clk_100MHz(clk         ),
    .clk_200MHz(clk         ),
    .probe0_0  (w_normal_led)
  );

  //vio_a
  vio_k
    u_vio (
    //.clk_100MHz  (clk              ),
    .clk_200MHz  (clk              ),
    .probe_in0_0 (w_normal_led     ),
    .probe_out0_0(w_select_from_vio),
    .probe_out1_0(w_reset_from_vio ),
    .probe_out2_0(w_sw_from_vio    )
  );

  qpsk_comm_sys #(
  ) u_qpsk_comm_sys (
    .o_normal_led(w_normal_led),
    .i_sw        (w_sw        ),
    .i_reset     (w_reset     ),
    .clk         (clk         ) 
  );

  assign o_normal_led = w_normal_led;


 endmodule
