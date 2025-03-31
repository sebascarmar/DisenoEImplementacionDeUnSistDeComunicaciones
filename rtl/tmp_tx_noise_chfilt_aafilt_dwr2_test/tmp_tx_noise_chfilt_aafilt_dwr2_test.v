`timescale 1ns/1ps


`define OVERSAMP_DSP    2
// PRBS
`define PRBS_SEED_I     9'h1AA
`define PRBS_SEED_Q     9'h1FE
// TRANSMITTER FILTER
//`define TXFILT_COEFF_FILE "./../../../../../../../fixed_point/logs/coeffs_txf.dat"
`define TXFILT_COEFF_FILE "/home/sebastian/Repositorios/CorreccionDeEfectosDeCanal/fixed_point/logs/coeffs_txf.dat"
`define NBT_TXFILT_COEF   8
`define NBF_TXFILT_COEF   7
`define NBT_TXFILT_OUT    8
`define NBF_TXFILT_OUT    7
`define NBAUD             5+1
`define OVERSAMP          4

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
// Channel Filter
`define NUM_CHFILT_COEF  17
//`define CHFILT_COEFF_FILE "./../../../../../../../fixed_point/logs/coeffs_chfilt.dat"
`define CHFILT_COEFF_FILE "/home/sebastian/Repositorios/CorreccionDeEfectosDeCanal/fixed_point/logs/coeffs_chfilt.dat"
`define NBT_CHFILT_COEF   8
`define NBF_CHFILT_COEF   7
`define NBT_CHFILT_OUT    8
`define NBF_CHFILT_OUT    7


// Anti-alias Filter
`define NUM_AAFILT_COEF  17
//`define AAFILT_COEFF_FILE "./../../../../../../../fixed_point/logs/coeffs_aafilt.dat"
`define AAFILT_COEFF_FILE "/home/sebastian/Repositorios/CorreccionDeEfectosDeCanal/fixed_point/logs/coeffs_aafilt.dat"
`define NBT_AAFILT_COEF   8
`define NBF_AAFILT_COEF   7
`define NBT_AAFILT_OUT    8
`define NBF_AAFILT_OUT    7


module tmp_top_tx_noise_chfil_aafilt
#(
  parameter PRBS_SEED_I       = `PRBS_SEED_I      ,
  parameter PRBS_SEED_Q       = `PRBS_SEED_Q      ,
  parameter NBAUD             = `NBAUD            ,
  parameter OVERSAMP          = `OVERSAMP         ,
  parameter TXFILT_COEFF_FILE = `TXFILT_COEFF_FILE,
  parameter NBT_TXFILT_COEF   = `NBT_TXFILT_COEF  ,
  parameter NBF_TXFILT_COEF   = `NBF_TXFILT_COEF  ,
  parameter NBT_TXFILT_OUT    = `NBT_TXFILT_OUT   ,
  parameter NBF_TXFILT_OUT    = `NBF_TXFILT_OUT   ,
  parameter NOISE_SEED1_I     = `NOISE_SEED1_I    ,
  parameter NOISE_SEED2_I     = `NOISE_SEED2_I    ,
  parameter NOISE_SEED3_I     = `NOISE_SEED3_I    ,
  parameter NOISE_SEED1_Q     = `NOISE_SEED1_Q    ,
  parameter NOISE_SEED2_Q     = `NOISE_SEED2_Q    ,
  parameter NOISE_SEED3_Q     = `NOISE_SEED3_Q    ,
  parameter SIGMA             = `SIGMA            ,
  parameter NBT_SIGMA         = `NBT_SIGMA        , 
  parameter NBF_SIGMA         = `NBF_SIGMA        , 
  parameter NBT_NOISE         = `NBT_NOISE        , 
  parameter NBF_NOISE         = `NBF_NOISE        ,
  parameter NBT_NOISY_SYM     = `NBT_NOISY_SYM    ,
  parameter NBF_NOISY_SYM     = `NBF_NOISY_SYM    ,
  parameter NUM_CHFILT_COEF   = `NUM_CHFILT_COEF  , 
  parameter CHFILT_COEFF_FILE = `CHFILT_COEFF_FILE, 
  parameter NBT_CHFILT_COEF   = `NBT_CHFILT_COEF  , 
  parameter NBF_CHFILT_COEF   = `NBF_CHFILT_COEF  , 
  parameter NBT_CHFILT_OUT    = `NBT_CHFILT_OUT   , 
  parameter NBF_CHFILT_OUT    = `NBF_CHFILT_OUT   , 
  parameter NUM_AAFILT_COEF   = `NUM_AAFILT_COEF  ,
  parameter AAFILT_COEFF_FILE = `AAFILT_COEFF_FILE,
  parameter NBT_AAFILT_COEF   = `NBT_AAFILT_COEF  ,
  parameter NBF_AAFILT_COEF   = `NBF_AAFILT_COEF  ,
  parameter NBT_AAFILT_OUT    = `NBT_AAFILT_OUT   ,
  parameter NBF_AAFILT_OUT    = `NBF_AAFILT_OUT   
 )
 (
  //output        [          3:0] o_normal_led               ,
  // temporales
  output signed [NBT_CHFILT_OUT-1:0] symI_dw_r2,
  output signed [NBT_CHFILT_OUT-1:0] symQ_dw_r2,
  
  //input  [                 3:0]  i_sw        ,
  input                          i_reset     ,
  input                          clk
 );
  
  
  // SEÑALES Y REGISTROS
  wire       w_reset                        ;
  wire [1:0] w_control_phase_select         ;
  wire       w_control_for_rate_1           ;
  wire       w_control_for_rate_2           ;
  wire       new_bit_from_prbsI_tx_to_filter;
  wire       new_bit_from_prbsQ_tx_to_filter;
  wire signed [NBT_TXFILT_OUT-1:0] w_out_from_tx_filtI_to_noiseI;
  wire signed [NBT_TXFILT_OUT-1:0] w_out_from_tx_filtQ_to_noiseQ;
  wire signed [     NBT_NOISE-1:0] w_noise_I_to_be_added        ;
  wire signed [     NBT_NOISE-1:0] w_noise_Q_to_be_added        ;
  wire signed [ NBT_NOISY_SYM-1:0] w_tx_filtI_plus_noiseI       ;
  wire signed [ NBT_NOISY_SYM-1:0] w_tx_filtQ_plus_noiseQ       ;
  wire signed [NBT_CHFILT_OUT-1:0] w_ch_filtI_out_to_aa_filtI   ;
  wire signed [NBT_CHFILT_OUT-1:0] w_ch_filtQ_out_to_aa_filtQ   ;
  wire signed [NBT_AAFILT_OUT-1:0] w_aa_filtI_out_to_dw_r2I;
  wire signed [NBT_AAFILT_OUT-1:0] w_aa_filtQ_out_to_dw_r2Q;
  wire signed [NBT_AAFILT_OUT-1:0] w_dw_r2I_to_fse;
  wire signed [NBT_AAFILT_OUT-1:0] w_dw_r2Q_to_fse;
  
  

  
  // SELECCIONA ENTRE MANEJO FÍSICO DE LA FPGA O MEDIANTE VIO
  assign w_reset  = ~i_reset;
  
  // Intanciación del control
  control
    u_control (
      .o_counter          (w_control_phase_select),
      .o_count_max        (w_control_for_rate_1  ),
      .o_count_half_or_max(w_control_for_rate_2  ),
      .i_reset            (w_reset               ),
      .clk                (clk                   )
    );
  
  

  /////////////////////////////////////////////////////////////
  //////////////////////// TRANSMITTER ////////////////////////
  /////////////////////////////////////////////////////////////
  // Instanciación de las prbs del tx
  prbs9 #(
    .SEED(PRBS_SEED_I)
  ) u_tx_prbs9_I (
    .o_new_bit(new_bit_from_prbsI_tx_to_filter),
    .i_ctrl   (w_control_for_rate_1           ),
    .i_reset  (w_reset                        ),  
    .clk      (clk                            )            
  );
  
  prbs9#(
    .SEED(PRBS_SEED_Q)
  ) u_tx_prbs9_Q (
    .o_new_bit(new_bit_from_prbsQ_tx_to_filter),
    .i_ctrl   (w_control_for_rate_1           ),
    .i_reset  (w_reset                        ),  
    .clk      (clk                            )            
  );
  

  // Instanciación de los filtros para i y q
  polyph_filter #(
    .FILE_COEFF(TXFILT_COEFF_FILE),
    .NBT_COEF  (NBT_TXFILT_COEF  ),
    .NBF_COEF  (NBF_TXFILT_COEF  ),
    .NBT_OUT   (NBT_TXFILT_OUT   ),
    .NBF_OUT   (NBF_TXFILT_OUT   ),
    .NBAUD     (NBAUD            ),
    .OS        (OVERSAMP         )
  ) u_tx_filter_I (
    .o_os_data           (w_out_from_tx_filtI_to_noiseI  ),
    .i_is_data           (new_bit_from_prbsI_tx_to_filter),
    .i_phase_num_of_coeff(w_control_phase_select         ),
    .i_ctrl              (w_control_for_rate_1           ),
    .i_reset             (w_reset                        ),            
    .clk                 (clk                            )
  );
  
  polyph_filter #(
    .FILE_COEFF(TXFILT_COEFF_FILE),
    .NBT_COEF  (NBT_TXFILT_COEF  ),
    .NBF_COEF  (NBF_TXFILT_COEF  ),
    .NBT_OUT   (NBT_TXFILT_OUT   ),
    .NBF_OUT   (NBF_TXFILT_OUT   ),
    .NBAUD     (NBAUD            ),
    .OS        (OVERSAMP         )
  ) u_tx_filter_Q (
    .o_os_data           (w_out_from_tx_filtQ_to_noiseQ  ),
    .i_is_data           (new_bit_from_prbsQ_tx_to_filter),
    .i_phase_num_of_coeff(w_control_phase_select         ),
    .i_ctrl              (w_control_for_rate_1           ),
    .i_reset             (w_reset                        ),            
    .clk                 (clk                            )
  );
  
  
  /////////////////////////////////////////////////////////////
  ////////////////////////// CHANNEL //////////////////////////
  /////////////////////////////////////////////////////////////
  // Noise addition
  gng_top #(
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
  ) u_ch_gng_top (
    .o_noise_I(w_noise_I_to_be_added),
    .o_noise_Q(w_noise_Q_to_be_added),
    .i_reset  (i_reset              ),
    .clk      (clk                  )
  );
  // Agrega ruido a la señal de salida del transmisor
  assign w_tx_filtI_plus_noiseI = w_out_from_tx_filtI_to_noiseI + w_noise_I_to_be_added;
  assign w_tx_filtQ_plus_noiseQ = w_out_from_tx_filtQ_to_noiseQ + w_noise_Q_to_be_added;


  // Channel filter: ISI model
  fir_filter #(
    .NUM_COEFF (NUM_CHFILT_COEF ), 
    .FILE_COEFF(CHFILT_COEFF_FILE),
    .NBT_IN    (NBT_NOISY_SYM   ), 
    .NBF_IN    (NBF_NOISY_SYM   ), 
    .NBT_COEFF (NBT_CHFILT_COEF ),
    .NBF_COEFF (NBF_CHFILT_COEF ), 
    .NBT_OUT   (NBT_CHFILT_OUT  ), 
    .NBF_OUT   (NBF_CHFILT_OUT  ) 
  ) u_ch_filt_I (
    .o_os_data(w_ch_filtI_out_to_aa_filtI),
    .i_is_data(w_tx_filtI_plus_noiseI    ),
    .i_reset  (w_reset                   ),
    .clk      (clk                       ) 
  );

  fir_filter #(
    .NUM_COEFF (NUM_CHFILT_COEF ), 
    .FILE_COEFF(CHFILT_COEFF_FILE),
    .NBT_IN    (NBT_NOISY_SYM   ), 
    .NBF_IN    (NBF_NOISY_SYM   ), 
    .NBT_COEFF (NBT_CHFILT_COEF ),
    .NBF_COEFF (NBF_CHFILT_COEF ), 
    .NBT_OUT   (NBT_CHFILT_OUT  ), 
    .NBF_OUT   (NBF_CHFILT_OUT  ) 
  ) u_ch_filt_Q (
    .o_os_data(w_ch_filtQ_out_to_aa_filtQ),
    .i_is_data(w_tx_filtQ_plus_noiseQ    ),
    .i_reset  (w_reset                   ),
    .clk      (clk                       ) 
  );



  /////////////////////////////////////////////////////////////
  ///////////////////////// RECEIVER //////////////////////////
  /////////////////////////////////////////////////////////////
  // Anti-alias filter
  fir_filter #(
    .NUM_COEFF (NUM_AAFILT_COEF ), 
    .FILE_COEFF(AAFILT_COEFF_FILE),
    .NBT_IN    (NBT_CHFILT_OUT  ), 
    .NBF_IN    (NBF_CHFILT_OUT  ), 
    .NBT_COEFF (NBT_AAFILT_COEF ),
    .NBF_COEFF (NBF_AAFILT_COEF ), 
    .NBT_OUT   (NBT_AAFILT_OUT  ), 
    .NBF_OUT   (NBF_AAFILT_OUT  ) 
  ) u_aa_filt_I (
    .o_os_data(w_aa_filtI_out_to_dw_r2I  ),
    .i_is_data(w_ch_filtI_out_to_aa_filtI),
    .i_reset  (w_reset                   ),
    .clk      (clk                       ) 
  );

  fir_filter #(
    .NUM_COEFF (NUM_AAFILT_COEF ), 
    .FILE_COEFF(AAFILT_COEFF_FILE),
    .NBT_IN    (NBT_CHFILT_OUT  ), 
    .NBF_IN    (NBF_CHFILT_OUT  ), 
    .NBT_COEFF (NBT_AAFILT_COEF ),
    .NBF_COEFF (NBF_AAFILT_COEF ), 
    .NBT_OUT   (NBT_AAFILT_OUT  ), 
    .NBF_OUT   (NBF_AAFILT_OUT  ) 
  ) u_aa_filt_Q (
    .o_os_data(w_aa_filtQ_out_to_dw_r2Q  ),
    .i_is_data(w_ch_filtQ_out_to_aa_filtQ),
    .i_reset  (w_reset                   ),
    .clk      (clk                       ) 
  );


  downsamp #(
    .NBT_IN_OUT(NBT_AAFILT_OUT), 
    .NBF_IN_OUT(NBT_AAFILT_OUT)
  ) u_dwsamp_r2_I (
    .o_os_data(w_dw_r2I_to_fse         ) ,  // Output sample
    .i_is_data(w_aa_filtI_out_to_dw_r2I), // Input sample
    .i_en     (w_control_for_rate_2    ) ,
    .i_reset  (w_reset                 ),
    .clk      (clk                     ) 
  );

  downsamp #(
    .NBT_IN_OUT (NBT_AAFILT_OUT), 
    .NBF_IN_OUT (NBT_AAFILT_OUT)
  ) u_dwsamp_r2_Q (
    .o_os_data(w_dw_r2Q_to_fse         ),  // Output sample
    .i_is_data(w_aa_filtQ_out_to_dw_r2Q), // Input sample
    .i_en     (w_control_for_rate_2    ),
    .i_reset  (w_reset                 ),
    .clk      (clk                     ) 
  );

  assign symI_dw_r2 = w_dw_r2I_to_fse;
  assign symQ_dw_r2 = w_dw_r2Q_to_fse;


endmodule

