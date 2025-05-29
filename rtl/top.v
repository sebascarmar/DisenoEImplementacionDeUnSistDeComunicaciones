`define SIGMA             8'sh1C
`define	NBT_I_EQLZR         8	
`define	NBT_O_EQLZR        12	
`define	NUM_TAPS            9	
`define	NBT_TAPS           10	
`define	NBT_GPIOS          32	
`define	NBT_COUNT_BITS_ERR 64 
`define N_DELAY           500
// for RAM module 
`define RAM_WIDTH        32                    
`define RAM_DEPTH        32768                       
`define RAM_PERFORMANCE  "LOW_LATENCY"
`define INIT_FILE        ""           

`timescale 1ns/1ps


module top #(
  parameter SIGMA              = `SIGMA             , 
  parameter NBT_I_EQLZR        = `NBT_I_EQLZR       ,	 
  parameter NBT_O_EQLZR        = `NBT_O_EQLZR       ,
  parameter NBT_TAPS           = `NBT_TAPS          ,
  parameter NBT_GPIOS          = `NBT_GPIOS         ,
  parameter NBT_COUNT_BITS_ERR = `NBT_COUNT_BITS_ERR,	
  parameter NUM_TAPS           = `NUM_TAPS          ,
  parameter N_DELAY            = `N_DELAY           ,
  parameter RAM_WIDTH          = `RAM_WIDTH         ,            
  parameter RAM_DEPTH          = `RAM_DEPTH         ,                  
  parameter RAM_PERFORMANCE    = `RAM_PERFORMANCE   ,
  parameter INIT_FILE          = `INIT_FILE                   
)
( 
  output       o_tx_uart   ,
  output [1:0] o_normal_led,
  output       o_rgb_led3_r,
  output       o_rgb_led2_r,
  output       o_rgb_led1_b,
  output       o_rgb_led0_b,

  input        i_rx_uart   ,
  input        i_sw        ,
  input        i_reset     ,	
  input        i_clk         
);

  //////////////// Internal wires
  wire                                  w_reset             ;
  wire                                  w_sw                ;
  wire                                  w_select_from_vio   ;
  wire                                  w_reset_from_vio    ;
  wire                                  w_sw_from_vio       ;
  wire       [                     1:0] w_normal_led        ;
  wire                                  w_sync_done_I       ;
  wire                                  w_sync_done_Q       ;
  wire                                  w_ber_ok_led_I      ;
  wire                                  w_ber_ok_led_Q      ;
//  wire                                  w_locked            ;
//  wire                                  clk                 ;
  wire signed [          NBT_GPIOS-1:0] w_regf_to_gpio      ;	
  wire        [          NBT_GPIOS-1:0] w_gpio_to_regf      ;	
  wire                                  w_rst_soft          ;
  wire                                  w_en_rx_soft        ; 
  wire        [                    1:0] w_sel_ch_taps       ;
  wire signed [                    7:0] w_sigma             ; 
  wire                                  w_en_write          ; 
  wire                                  w_en_read_from_ram  ;
  wire        [                    2:0] w_data_sel_for_log  ;
  wire        [  $clog2(RAM_DEPTH)-1:0] w_read_adrs         ;
  wire signed [         NBT_GPIOS-1 :0] w_data_ram_for_read ;			 
  wire signed [       NBT_I_EQLZR-1 :0] w_data_i_eqlzr_I    ;	
  wire signed [       NBT_I_EQLZR-1 :0] w_data_i_eqlzr_Q    ;	
  wire signed [       NBT_O_EQLZR-1 :0] w_data_o_eqlzr_I    ;									
  wire signed [       NBT_O_EQLZR-1 :0] w_data_o_eqlzr_Q    ;		
  wire signed [ NBT_TAPS*NUM_TAPS-1 :0] w_data_taps_I       ;		
  wire signed [ NBT_TAPS*NUM_TAPS-1 :0] w_data_taps_Q       ;	
  wire        [NBT_COUNT_BITS_ERR-1 :0] w_accum_err_Q       ;
  wire        [NBT_COUNT_BITS_ERR-1 :0] w_accum_err_I       ;
  wire        [NBT_COUNT_BITS_ERR-1 :0] w_accum_bit_Q       ;
  wire        [NBT_COUNT_BITS_ERR-1 :0] w_accum_bit_I       ;
  wire                                  w_control_for_rate_2;
  wire                                  w_control_for_rate_1;


  // Select between control via VIO or physical FPGA inputs
  assign w_reset  = w_select_from_vio ? ~w_reset_from_vio : ~i_reset;
  assign w_sw     = w_select_from_vio ? w_sw_from_vio : i_sw;


  ///////////////////////////////////////////////////////////////////////////
  //                            CLOCK MANAGER                              //
  ///////////////////////////////////////////////////////////////////////////

//  clk_mngr
//    u_clk_mngr (
//    .clk_out1_0(clk     ),
//    .locked_0  (w_locked),
//    .reset     (~w_reset ),
//    .sys_clock (i_clk   )
//  );


  ///////////////////////////////////////////////////////////////////////////
  //                                VIO/ILA                                //
  ///////////////////////////////////////////////////////////////////////////
  
  ila
    u_ila (
    .clk_0   (i_clk           ),  
    .probe0_0(w_data_i_eqlzr_I),    
    .probe1_0(w_data_i_eqlzr_Q),     
    .probe2_0(w_data_o_eqlzr_I),  
    .probe3_0(w_data_o_eqlzr_Q),  
    .probe4_0(w_data_taps_I   ),  
    .probe5_0(w_data_taps_Q   ),
    .probe6_0(w_regf_to_gpio  ),
    .probe7_0(w_gpio_to_regf  )
  );
  
  vio
    u_vio (
    .clk_0       (i_clk                 ),
    .probe_in0_0 (w_reset || ~w_rst_soft),
    .probe_in1_0 (w_sw && w_en_rx_soft  ),
    .probe_in2_0 (w_sync_done_I         ),
    .probe_in3_0 (w_sync_done_Q         ),
    .probe_in4_0 (w_ber_ok_led_I        ),
    .probe_in5_0 (w_ber_ok_led_Q        ),
    .probe_out0_0(w_select_from_vio     ),
    .probe_out1_0(w_reset_from_vio      ),
    .probe_out2_0(w_sw_from_vio         )
  );


  ///////////////////////////////////////////////////////////////////////////
  //                             MICROBLAZE                                //
  ///////////////////////////////////////////////////////////////////////////

  uBlaze    
    u_uBlaze (
    .gpio_rtl_tri_i  (w_regf_to_gpio           ),
    .gpio_rtl_tri_o  (w_gpio_to_regf           ),   
    .reset           (~(w_reset || ~w_rst_soft)),
    .Clk             (i_clk                    ),
    .usb_uart_rxd    (i_rx_uart                ),
    .usb_uart_txd    (o_tx_uart                )
  );

  ///////////////////////////////////////////////////////////////////////////
  //                        MEMORY AND CONTROL                             //
  ///////////////////////////////////////////////////////////////////////////

  //////////////// Register file
  reg_file #(
    .SIGMA             (SIGMA             ), 
    .NBT_GPIOS         (NBT_GPIOS         ),
    .RAM_DEPTH         (RAM_DEPTH         ),
    .NBT_COUNT_BITS_ERR(NBT_COUNT_BITS_ERR) 
  ) u_reg_file ( 
    .o_read_adrs        (w_read_adrs           ),
    .o_regf_to_gpio     (w_regf_to_gpio        ),
    .o_data_sel_for_log (w_data_sel_for_log    ),
    .o_en_write         (w_en_write            ),
    .o_en_read_from_ram (w_en_read_from_ram    ),
    .o_rst_soft         (w_rst_soft            ),
    .o_en_rx_soft       (w_en_rx_soft          ),  
    .o_sigma            (w_sigma               ), 
    .o_sel_ch_taps      (w_sel_ch_taps         ),
    .i_accum_err_Q      (w_accum_err_Q         ),
    .i_accum_err_I      (w_accum_err_I         ),
    .i_accum_bit_Q      (w_accum_bit_Q         ),
    .i_accum_bit_I      (w_accum_bit_I         ),
    .i_data_ram_for_read(w_data_ram_for_read   ),
    .i_gpio_to_regf     (w_gpio_to_regf        ), 
    .i_reset            (w_reset || ~w_rst_soft),
    .clk                (i_clk                 ) 
  );


  //////////////// RAM control
  block_ram_control #(
    .NBT_I_EQLZR    (NBT_I_EQLZR    ),	 
    .NBT_O_EQLZR    (NBT_O_EQLZR    ),
    .NBT_TAPS       (NBT_TAPS       ),
    .NUM_TAPS       (NUM_TAPS       ),
    .N_DELAY        (N_DELAY        ),
    .RAM_WIDTH      (RAM_WIDTH      ),            
    .RAM_DEPTH      (RAM_DEPTH      ),                  
    .RAM_PERFORMANCE(RAM_PERFORMANCE),
    .INIT_FILE      (INIT_FILE      )   
  ) u_block_ram_control ( 
    .o_data_for_read     (w_data_ram_for_read    ),				
    .i_data_sel_for_log  (w_data_sel_for_log     ), 
    .i_en_write          (w_en_write             ),
    .i_en_read           (w_en_read_from_ram     ),
    .i_read_adrs         (w_read_adrs            ), 
    .i_data_i_eqlzr_i    (w_data_i_eqlzr_I       ),
    .i_data_i_eqlzr_q    (w_data_i_eqlzr_Q       ),			
    .i_data_o_eqlzr_i    (w_data_o_eqlzr_I       ),	
    .i_data_o_eqlzr_q    (w_data_o_eqlzr_Q       ),	
    .i_data_taps_i       (w_data_taps_I          ),
    .i_data_taps_q       (w_data_taps_Q          ),
    .i_control_for_rate_2(w_control_for_rate_2   ),
    .i_control_for_rate_1(w_control_for_rate_1   ),
    .i_reset             (w_reset  || ~w_rst_soft),
    .clk                 (i_clk                  )
  );


  ///////////////////////////////////////////////////////////////////////////
  //                        COMMUNICATION SYSTEM                           //
  ///////////////////////////////////////////////////////////////////////////

  qpsk_comm_sys
    u_qpsk_comm_sys (
    .o_data_i_eqlzr_I    (w_data_i_eqlzr_I         ),
    .o_data_i_eqlzr_Q    (w_data_i_eqlzr_Q         ),
    .o_data_o_eqlzr_I    (w_data_o_eqlzr_I         ),
    .o_data_o_eqlzr_Q    (w_data_o_eqlzr_Q         ),
    .o_data_taps_I       (w_data_taps_I            ),
    .o_data_taps_Q       (w_data_taps_Q            ),
    .o_accum_err_I       (w_accum_err_I            ),
    .o_accum_tot_I       (w_accum_bit_I            ),
    .o_accum_err_Q       (w_accum_err_Q            ),
    .o_accum_tot_Q       (w_accum_bit_Q            ),
    .o_control_for_rate_2(w_control_for_rate_2     ),
    .o_control_for_rate_1(w_control_for_rate_1     ),
    .o_normal_led        (w_normal_led             ),
    .o_rgb_led3_r        (w_sync_done_I            ),
    .o_rgb_led2_r        (w_sync_done_Q            ),
    .o_rgb_led1_b        (w_ber_ok_led_I           ),
    .o_rgb_led0_b        (w_ber_ok_led_Q           ),
    .i_sel_ch_taps       (w_sel_ch_taps            ),  
    .i_sigma             (w_sigma                  ), 
    .i_sw                (w_sw && w_en_rx_soft     ),
    .i_reset             (~(w_reset || ~w_rst_soft)),
    .clk                 (i_clk                    ) 
  );


  //////////////// Assign outpus 
  //  assign o_normal_led[2] = w_locked            ;
  assign o_normal_led[1] = w_reset || ~w_rst_soft;
  assign o_normal_led[0] = i_sw && w_en_rx_soft  ;
  assign o_rgb_led3_r    = w_sync_done_I         ;
  assign o_rgb_led2_r    = w_sync_done_Q         ;
  assign o_rgb_led1_b    = w_ber_ok_led_I        ;
  assign o_rgb_led0_b    = w_ber_ok_led_Q        ;


endmodule

