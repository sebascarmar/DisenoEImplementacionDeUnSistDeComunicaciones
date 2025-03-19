`timescale 1ns/1ps


`define OVERSAMP_DSP    2
// PRBS
`define PRBS_SEED_I     9'h1AA
`define PRBS_SEED_Q     9'h1FE
// TRANSMITTER FILTER
`define NBAUD           5+1
`define OVERSAMP        4
`define NBT_TXFILT_COEF 8
`define NBF_TXFILT_COEF 7
`define NBT_TXFILT_OUT  8
`define NBF_TXFILT_OUT  7

// NOISE
`define NOISE_SEED1_I 64'd5030521883283424767 
`define NOISE_SEED2_I 64'd18445829279364155008 
`define NOISE_SEED3_I 64'd18436106298727503359 
`define NOISE_SEED1_Q 64'd14533118196545751551 
`define NOISE_SEED2_Q 64'd18444914485018758400 
`define NOISE_SEED3_Q 64'd18425749998705519615 
`define SIGMA         8'sh1c                  
`define NBT_SIGMA     8 
`define NBF_SIGMA     7 
`define NBT_NOISE     8
`define NBF_NOISE     7 
`define NBT_NOISY_SYM 8
`define NBF_NOISY_SYM 7


module tmp_top_tx_noise
#(
  parameter PRBS_SEED_I     = `PRBS_SEED_I    ,
  parameter PRBS_SEED_Q     = `PRBS_SEED_Q    ,
  parameter NBAUD           = `NBAUD          ,
  parameter OVERSAMP        = `OVERSAMP       ,
  parameter NBT_TXFILT_COEF = `NBT_TXFILT_COEF,
  parameter NBF_TXFILT_COEF = `NBF_TXFILT_COEF,
  parameter NBT_TXFILT_OUT  = `NBT_TXFILT_OUT ,
  parameter NBF_TXFILT_OUT  = `NBF_TXFILT_OUT ,
  parameter NOISE_SEED1_I   = `NOISE_SEED1_I  ,
  parameter NOISE_SEED2_I   = `NOISE_SEED2_I  ,
  parameter NOISE_SEED3_I   = `NOISE_SEED3_I  ,
  parameter NOISE_SEED1_Q   = `NOISE_SEED1_Q  ,
  parameter NOISE_SEED2_Q   = `NOISE_SEED2_Q  ,
  parameter NOISE_SEED3_Q   = `NOISE_SEED3_Q  ,
  parameter SIGMA           = `SIGMA          ,
  parameter NBT_SIGMA       = `NBT_SIGMA      , 
  parameter NBF_SIGMA       = `NBF_SIGMA      , 
  parameter NBT_NOISE       = `NBT_NOISE      , 
  parameter NBF_NOISE       = `NBF_NOISE      ,
  parameter NBT_NOISY_SYM   = `NBT_NOISY_SYM  ,
  parameter NBF_NOISY_SYM   = `NBF_NOISY_SYM
 )
 (
  //output        [          3:0] o_normal_led               ,
  // temporales
  output signed [NBT_TXFILT_OUT-1:0] symI_noisy,
  output signed [NBT_TXFILT_OUT-1:0] symQ_noisy,
  
  //input  [                 3:0]  i_sw        ,
  input                          i_reset     ,
  input                          clk
 );
  
  
  // SEÑALES Y REGISTROS
  wire       w_reset                        ;
  wire [1:0] control_for_T_over_4_rate      ;
  wire       control_for_T_rate             ;
  wire       new_bit_from_prbsI_tx_to_filter;
  wire       new_bit_from_prbsQ_tx_to_filter;
  wire signed [NBT_TXFILT_OUT-1:0] w_out_from_tx_filtI_to_noiseI;
  wire signed [NBT_TXFILT_OUT-1:0] w_out_from_tx_filtQ_to_noiseQ;
  wire signed [     NBT_NOISE-1:0] w_noise_I_to_be_added        ;
  wire signed [     NBT_NOISE-1:0] w_noise_Q_to_be_added        ;
  wire signed [ NBT_NOISY_SYM-1:0] w_tx_filtI_plus_noiseI       ;
  wire signed [ NBT_NOISY_SYM-1:0] w_tx_filtQ_plus_noiseQ       ;
  
  
  // SELECCIONA ENTRE MANEJO FÍSICO DE LA FPGA O MEDIANTE VIO
  assign w_reset  = ~i_reset;
  
  
  
  // INTANCIACIÓN DEL CONTROL
  control
    u_control (
      .o_count    (control_for_T_over_4_rate),
      .o_count_max(control_for_T_rate       ),
      .i_reset    (w_reset                  ),
      .clk        (clk                      )
    );
  
  // INSTANCIACIÓN DE LAS PRBS DEL Tx
  prbs9#(
    .SEED (PRBS_SEED_I)
  ) u_prbs9I_tx (
    .o_new_bit(new_bit_from_prbsI_tx_to_filter),
    .i_ctrl   (control_for_T_rate             ),
    .i_reset  (w_reset                        ),  
    .clk      (clk                            )            
  );
  
  prbs9#(
    .SEED (PRBS_SEED_Q)
  ) u_prbs9Q_tx (
    .o_new_bit(new_bit_from_prbsQ_tx_to_filter),
    .i_ctrl   (control_for_T_rate             ),
    .i_reset  (w_reset                        ),  
    .clk      (clk                            )            
  );
  
  // INSTANCIACIÓN DE LOS FILTROS PARA I y Q
  polyph_filter#(
    .NBT_OUT  (NBT_TXFILT_OUT ),
    .NBF_OUT  (NBF_TXFILT_OUT ),
    .NBT_COEF (NBT_TXFILT_COEF),
    .NBF_COEF (NBF_TXFILT_COEF),
    .NBAUD    (NBAUD          ),
    .OS       (OVERSAMP       )
  ) u_filter_I (
    .o_os_data           (w_out_from_tx_filtI_to_noiseI  ),
    .i_is_data           (new_bit_from_prbsI_tx_to_filter),
    .i_phase_num_of_coeff(control_for_T_over_4_rate      ),
    .i_ctrl              (control_for_T_rate             ),
    .i_reset             (w_reset                        ),            
    .clk                 (clk                            )
  );
  
  
  polyph_filter#(
    .NBT_OUT  (NBT_TXFILT_OUT ),
    .NBF_OUT  (NBF_TXFILT_OUT ),
    .NBT_COEF (NBT_TXFILT_COEF),
    .NBF_COEF (NBF_TXFILT_COEF),
    .NBAUD    (NBAUD          ),
    .OS       (OVERSAMP       )
  ) u_filter_Q (
    .o_os_data           (w_out_from_tx_filtQ_to_noiseQ  ),
    .i_is_data           (new_bit_from_prbsQ_tx_to_filter),
    .i_phase_num_of_coeff(control_for_T_over_4_rate      ),
    .i_ctrl              (control_for_T_rate             ),
    .i_reset             (w_reset                        ),            
    .clk                 (clk                            )
  );
  
  
  gng_top#(
    .Z1_I     (NOISE_SEED1_I), 
    .Z2_I     (NOISE_SEED2_I), 
    .Z3_I     (NOISE_SEED3_I), 
    .Z1_Q     (NOISE_SEED1_Q), 
    .Z2_Q     (NOISE_SEED2_Q), 
    .Z3_Q     (NOISE_SEED3_Q), 
    .SIGMA    (SIGMA        ), 
    .NBT_SIGMA(NBT_SIGMA    ), 
    .NBF_SIGMA(NBF_SIGMA    ), 
    .NBT_NOISE(NBT_NOISE    ), 
    .NBF_NOISE(NBF_NOISE    ) 
  ) u_gng_top (
    .o_noise_I(w_noise_I_to_be_added),
    .o_noise_Q(w_noise_Q_to_be_added),
    .i_reset  (i_reset              ),
    .clk      (clk                  )
  );
  
  assign w_tx_filtI_plus_noiseI = w_out_from_tx_filtI_to_noiseI + w_noise_I_to_be_added;
  assign w_tx_filtQ_plus_noiseQ = w_out_from_tx_filtQ_to_noiseQ + w_noise_Q_to_be_added;
  
  assign symI_noisy = w_tx_filtI_plus_noiseI;
  assign symQ_noisy = w_tx_filtQ_plus_noiseQ;
  


endmodule


