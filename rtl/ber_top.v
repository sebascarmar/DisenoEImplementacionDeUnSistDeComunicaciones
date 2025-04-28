`timescale 1ns/1ps


module ber_top #(
  parameter PRBS_SEED_I     = 9'h1AA             ,
  parameter PRBS_SEED_Q     = 9'h1FE             ,
  parameter PRBS_MAX_CYCLES = 511                ,
  parameter START_SYN       = PRBS_MAX_CYCLES*690,
  parameter START_CNT       = START_SYN + 511*511
)
(
  // Ports to uBlaze
  output [63:0] o_accum_err_I ,
  output [63:0] o_accum_tot_I ,
  output [63:0] o_accum_err_Q ,
  output [63:0] o_accum_tot_Q ,
  //
  output o_sync_done_I ,
  output o_sync_done_Q ,
  output o_ber_ok_led_I,
  output o_ber_ok_led_Q,
  
  input  i_rx_bit_I    ,
  input  i_rx_bit_Q    ,
  input  i_en_rate1    , 
  input  i_en_rx       , 
  input  i_reset       , 
  input  clk       
);

  // Internal registers and wires
  wire w_start_sync       ;
  wire w_prbs_cmp_done    ;
  wire w_start_ber_count  ;
  wire w_prbs_ctrl        ;
  wire w_prbsI_bit_to_berI;
  wire w_prbsQ_bit_to_berQ;
  wire w_sync_done_I      ;
  wire w_sync_done_Q      ;
  wire w_ber_ok_led_I     ;
  wire w_ber_ok_led_Q     ;


  // Control module for syncrhonization and ber counting
  ber_control #(
    .PRBS_MAX_CYCLES(PRBS_MAX_CYCLES),
    .START_SYN      (START_SYN      ),
    .START_CNT      (START_CNT      ) 
  ) u_ber_control (
    .o_start_synchro          (w_start_sync     ),
    .o_prbs_cmp_curr_addr_done(w_prbs_cmp_done  ),
    .o_start_ber_counter      (w_start_ber_count),
    .i_ctrl                   (i_en_rate1       ), 
    .i_en_rx                  (i_en_rx          ), 
    .i_reset                  (i_reset          ), 
    .clk                      (clk              )
  );


  // Receiver PRBS's  
  assign w_prbs_ctrl = i_en_rate1 & (w_start_sync||w_start_ber_count);

  prbs9 #(
    .SEED(PRBS_SEED_I)
  ) u_rx_prbs9_I (
    .o_new_bit(w_prbsI_bit_to_berI),
    .i_ctrl   (w_prbs_ctrl        ),
    .i_en     (i_en_rx            ), 
    .i_reset  (i_reset            ),  
    .clk      (clk                )            
  );
  
  prbs9 #(
    .SEED(PRBS_SEED_Q)
  ) u_rx_prbs9_Q (
    .o_new_bit(w_prbsQ_bit_to_berQ),
    .i_ctrl   (w_prbs_ctrl        ),
    .i_en     (i_en_rx            ), 
    .i_reset  (i_reset            ),  
    .clk      (clk                )            
  );



  // BER counters
  ber_counter #(
    .PRBS_MAX_CYCLES(PRBS_MAX_CYCLES)
  ) u_bit_error_counter_I (
    // BER data to uBlaze
    .o_accum_err(o_accum_err_I),
    .o_accum_tot(o_accum_tot_I),
    //
    .o_sync_done_led          (w_sync_done_I      ),
    .o_ber_ok_led             (w_ber_ok_led_I     ),
    .i_ctrl                   (i_en_rate1         ),
    .i_rx_bit                 (i_rx_bit_I         ),
    .i_new_bit_from_prbs      (w_prbsI_bit_to_berI),
    .i_synchro_en             (w_start_sync       ),
    .i_prbs_cmp_curr_addr_done(w_prbs_cmp_done    ),
    .i_ber_counter_en         (w_start_ber_count  ),
    .i_en_rx                  (i_en_rx            ), 
    .i_reset                  (i_reset            ), 
    .clk                      (clk                )
  );

  ber_counter #(
    .PRBS_MAX_CYCLES(PRBS_MAX_CYCLES)
  ) u_bit_error_counter_Q (
    // BER data to uBlaze
    .o_accum_err(o_accum_err_Q),
    .o_accum_tot(o_accum_tot_Q),
    //
    .o_sync_done_led          (w_sync_done_Q      ),
    .o_ber_ok_led             (w_ber_ok_led_Q     ),
    .i_ctrl                   (i_en_rate1         ),
    .i_rx_bit                 (i_rx_bit_Q         ),
    .i_new_bit_from_prbs      (w_prbsQ_bit_to_berQ),
    .i_synchro_en             (w_start_sync       ),
    .i_prbs_cmp_curr_addr_done(w_prbs_cmp_done    ),
    .i_ber_counter_en         (w_start_ber_count  ),
    .i_en_rx                  (i_en_rx            ), 
    .i_reset                  (i_reset            ), 
    .clk                      (clk                )
  );


  // Output assignments
  assign o_sync_done_I  = w_sync_done_I ;
  assign o_sync_done_Q  = w_sync_done_Q ;
  assign o_ber_ok_led_I = w_ber_ok_led_I;
  assign o_ber_ok_led_Q = w_ber_ok_led_Q;


endmodule

