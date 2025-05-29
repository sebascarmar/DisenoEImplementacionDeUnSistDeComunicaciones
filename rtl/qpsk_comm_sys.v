//============================================================
// SNR to Variance table in S(8,7) format
// -----------------------------------------------------------
// SNR (dB)      Variance σ     σ (hex)    S(8,7) format
// -----------------------------------------------------------
//       7         0.21875         8'h1c         00011100
//       8       0.1953125         8'h19         00011001
//       9        0.171875         8'h16         00010110
//      10         0.15625         8'h14         00010100
//      11        0.140625         8'h12         00010010
//      12           0.125         8'h10         00010000
// -----------------------------------------------------------
//============================================================
`timescale 1ns/1ps


// PRBS
`define PRBS_SEED_I     9'h1AA
`define PRBS_SEED_Q     9'h1FE

// TRANSMITTER FILTER
//`define TXFILT_COEFF_FILE "./../../../../../../../fixed_point/logs/coeffs_txf.dat"
`define TXFILT_COEFF_FILE "/home/danielito/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/rtl/coeffs_txf.dat"
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
`define NBT_SIGMA     8 
`define NBF_SIGMA     7 
`define NBT_NOISE     8
`define NBF_NOISE     7 
`define NBT_NOISY_SYM 8
`define NBF_NOISY_SYM 7

// CHANNEL FILTER
`define NUM_CHFILT_COEF  17
//`define CHFIL_COEF_FILE_0 "./../../../../../../../fixed_point/logs/coeffs_chfilt.dat"
`define CHFIL_COEF_FILE_0 "/home/danielito/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/rtl/coeffs_chfilt_12M.dat"
`define CHFIL_COEF_FILE_1 "/home/danielito/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/rtl/coeffs_chfilt_impulso.dat"
`define CHFIL_COEF_FILE_2 "/home/danielito/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/rtl/coeffs_chfilt_10M.dat"
`define CHFIL_COEF_FILE_3 "/home/danielito/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/rtl/coeffs_chfilt_12M.dat"
`define NBT_CHFILT_COEF   8
`define NBF_CHFILT_COEF   7
`define NBT_CHFILT_OUT    8
`define NBF_CHFILT_OUT    7

// ANTI-ALIAS FILTER
`define NUM_AAFILT_COEF  17
//`define AAFILT_COEFF_FILE "./../../../../../../../fixed_point/logs/coeffs_aafilt.dat"
`define AAFILT_COEFF_FILE "/home/danielito/Escritorio/DisenoEImplementacionDeUnSistDeComunicaciones/rtl/coeffs_aafilt.dat"
`define NBT_AAFILT_COEF   8
`define NBF_AAFILT_COEF   7
`define NBT_AAFILT_OUT    8
`define NBF_AAFILT_OUT    7

//FSE & LMS
`define LMS_STEP     12'sh001
`define LMS_LEAK     11'sh001
`define NBT_LMS_STEP 12
`define NBF_LMS_STEP 11
`define NBT_LMS_LEAK 11
`define NBF_LMS_LEAK 10
//----
`define NUM_FSE_TAPS  9
`define NBT_LMS_TAPS 20
`define NBF_LMS_TAPS 17
`define NBT_FSE_TAPS 10
`define NBF_FSE_TAPS  7
`define NBT_FSE_OUT  12
`define NBF_FSE_OUT   9
`define NBT_TAPS_ERR  9
`define NBF_TAPS_ERR  7

// BER
`define PRBS_MAX_CYCLES  511                
`define START_SYN        PRBS_MAX_CYCLES*690
`define START_CNT        START_SYN + 511*511



module qpsk_comm_sys
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
//  parameter SIGMA             = `SIGMA            ,
  parameter NBT_SIGMA         = `NBT_SIGMA        , 
  parameter NBF_SIGMA         = `NBF_SIGMA        , 
  parameter NBT_NOISE         = `NBT_NOISE        , 
  parameter NBF_NOISE         = `NBF_NOISE        ,
  parameter NBT_NOISY_SYM     = `NBT_NOISY_SYM    ,
  parameter NBF_NOISY_SYM     = `NBF_NOISY_SYM    ,
  parameter NUM_CHFILT_COEF   = `NUM_CHFILT_COEF  , 
  parameter CHFIL_COEF_FILE_0 = `CHFIL_COEF_FILE_0, 
  parameter CHFIL_COEF_FILE_1 = `CHFIL_COEF_FILE_1, 
  parameter CHFIL_COEF_FILE_2 = `CHFIL_COEF_FILE_2, 
  parameter CHFIL_COEF_FILE_3 = `CHFIL_COEF_FILE_3, 
  parameter NBT_CHFILT_COEF   = `NBT_CHFILT_COEF  , 
  parameter NBF_CHFILT_COEF   = `NBF_CHFILT_COEF  , 
  parameter NBT_CHFILT_OUT    = `NBT_CHFILT_OUT   , 
  parameter NBF_CHFILT_OUT    = `NBF_CHFILT_OUT   , 
  parameter NUM_AAFILT_COEF   = `NUM_AAFILT_COEF  ,
  parameter AAFILT_COEFF_FILE = `AAFILT_COEFF_FILE,
  parameter NBT_AAFILT_COEF   = `NBT_AAFILT_COEF  ,
  parameter NBF_AAFILT_COEF   = `NBF_AAFILT_COEF  ,
  parameter NBT_AAFILT_OUT    = `NBT_AAFILT_OUT   ,
  parameter NBF_AAFILT_OUT    = `NBF_AAFILT_OUT   ,
  parameter LMS_STEP          = `LMS_STEP         ,
  parameter LMS_LEAK          = `LMS_LEAK         ,
  parameter NBT_LMS_STEP      = `NBT_LMS_STEP     ,
  parameter NBF_LMS_STEP      = `NBF_LMS_STEP     ,
  parameter NBT_LMS_LEAK      = `NBT_LMS_LEAK     ,
  parameter NBF_LMS_LEAK      = `NBF_LMS_LEAK     ,
  parameter NUM_FSE_TAPS      = `NUM_FSE_TAPS     ,
  parameter NBT_LMS_TAPS      = `NBT_LMS_TAPS     ,
  parameter NBF_LMS_TAPS      = `NBF_LMS_TAPS     ,
  parameter NBT_FSE_TAPS      = `NBT_FSE_TAPS     ,
  parameter NBF_FSE_TAPS      = `NBF_FSE_TAPS     ,
  parameter NBT_FSE_OUT       = `NBT_FSE_OUT      ,
  parameter NBF_FSE_OUT       = `NBF_FSE_OUT      ,
  parameter NBT_TAPS_ERR      = `NBT_TAPS_ERR     ,
  parameter NBF_TAPS_ERR      = `NBF_TAPS_ERR     ,
  parameter PRBS_MAX_CYCLES   = `PRBS_MAX_CYCLES  ,
  parameter START_SYN         = `START_SYN        ,
  parameter START_CNT         = `START_CNT        
 )
 (
  // Ports to uBlaze
  output signed [             NBT_AAFILT_OUT-1:0] o_data_i_eqlzr_I    ,
  output signed [             NBT_AAFILT_OUT-1:0] o_data_i_eqlzr_Q    ,
  output signed [                NBT_FSE_OUT-1:0] o_data_o_eqlzr_I    ,
  output signed [                NBT_FSE_OUT-1:0] o_data_o_eqlzr_Q    ,
  output signed [(NUM_FSE_TAPS*NBT_FSE_TAPS)-1:0] o_data_taps_I       ,
  output signed [(NUM_FSE_TAPS*NBT_FSE_TAPS)-1:0] o_data_taps_Q       ,
  output        [                           63:0] o_accum_err_I       ,
  output        [                           63:0] o_accum_tot_I       ,
  output        [                           63:0] o_accum_err_Q       ,
  output        [                           63:0] o_accum_tot_Q       ,
  output                                          o_control_for_rate_2,
  output                                          o_control_for_rate_1,
  //
  output       [1:0] o_normal_led ,
  output             o_rgb_led3_r ,
  output             o_rgb_led2_r ,
  output             o_rgb_led1_b ,
  output             o_rgb_led0_b ,

  input        [1:0] i_sel_ch_taps, 
  input signed [7:0] i_sigma      , 
  input              i_sw         ,
  input              i_reset      ,
  input              clk
 );
  
  
  //////////////// Internal wires
  wire                             w_reset                   ;
  wire [                      1:0] w_control_phase_select    ;
  wire                             w_control_poly_filt       ;
  wire                             w_control_for_rate_2      ;
  wire                             w_control_for_rate_1      ;
  wire                             w_save_fse_shifters       ;
  wire                             w_tx_prbsI_bit_to_tx_filtI;
  wire                             w_tx_prbsQ_bit_to_tx_filtQ;
  wire signed [NBT_TXFILT_OUT-1:0] w_tx_filtI_to_noiseI      ;
  wire signed [NBT_TXFILT_OUT-1:0] w_tx_filtQ_to_noiseQ      ;
  wire signed [     NBT_NOISE-1:0] w_noiseI_to_add           ;
  wire signed [     NBT_NOISE-1:0] w_noiseQ_to_add           ;
  wire signed [ NBT_NOISY_SYM-1:0] w_ch_nsigI_to_chfiltI     ;
  wire signed [ NBT_NOISY_SYM-1:0] w_ch_nsigQ_to_chfiltQ     ;
  wire signed [NBT_CHFILT_OUT-1:0] w_ch_filtI_to_aa_filtI    ;
  wire signed [NBT_CHFILT_OUT-1:0] w_ch_filtQ_to_aa_filtQ    ;
  wire signed [NBT_AAFILT_OUT-1:0] w_rx_aa_filtI_to_dwr2I    ;
  wire signed [NBT_AAFILT_OUT-1:0] w_rx_aa_filtQ_to_dwr2Q    ;
  wire signed [NBT_AAFILT_OUT-1:0] w_rx_dwr2I_to_fse         ;
  wire signed [NBT_AAFILT_OUT-1:0] w_rx_dwr2Q_to_fse         ;
  wire signed [   NBT_FSE_OUT-1:0] w_rx_symI_to_demapI       ;
  wire signed [   NBT_FSE_OUT-1:0] w_rx_symQ_to_demapQ       ;
  wire                             w_rx_bitI_to_ber          ;
  wire                             w_rx_bitQ_to_ber          ;
  wire                             w_sync_done_I             ;
  wire                             w_sync_done_Q             ;
  wire                             w_ber_ok_led_I            ;
  wire                             w_ber_ok_led_Q            ;
  

  ////////////////  Convert reset signal from active-low to active-high
  assign w_reset  = ~i_reset;
  

  //////////////// Generate control signals for differentes rates
  control
    u_control (
      .o_counter          (w_control_phase_select),
      .o_count_max        (w_control_poly_filt   ),
      .o_count_half_or_max(w_control_for_rate_2  ),
      .o_count_max_rate1  (w_control_for_rate_1  ),
      .o_save_fse_shifters(w_save_fse_shifters   ),
      .i_reset            (w_reset               ),
      .clk                (clk                   )
    );
  
  

  ///////////////////////////////////////////////////////////////////////////
  //                              TRANSMITTER                              //
  ///////////////////////////////////////////////////////////////////////////

  //////////////// PRBS generator for I and Q channels
  prbs9 #(
    .SEED(PRBS_SEED_I)
  ) u_tx_prbs9_I (
    .o_new_bit(w_tx_prbsI_bit_to_tx_filtI),
    .i_ctrl   (w_control_for_rate_1      ),
    .i_en     (1'b1                      ), 
    .i_reset  (w_reset                   ),  
    .clk      (clk                       )            
  );
  
  prbs9#(
    .SEED(PRBS_SEED_Q)
  ) u_tx_prbs9_Q (
    .o_new_bit(w_tx_prbsQ_bit_to_tx_filtQ),
    .i_ctrl   (w_control_for_rate_1      ),
    .i_en     (1'b1                      ), 
    .i_reset  (w_reset                   ),  
    .clk      (clk                       )            
  );


  //////////////// Polyphase filters for interpolation and shaping  
  polyph_filter #(
    .FILE_COEFF(TXFILT_COEFF_FILE),
    .NBT_COEF  (NBT_TXFILT_COEF  ),
    .NBF_COEF  (NBF_TXFILT_COEF  ),
    .NBT_OUT   (NBT_TXFILT_OUT   ),
    .NBF_OUT   (NBF_TXFILT_OUT   ),
    .NBAUD     (NBAUD            ),
    .OS        (OVERSAMP         )
  ) u_tx_filter_I (
    .o_os_data           (w_tx_filtI_to_noiseI      ),
    .i_is_data           (w_tx_prbsI_bit_to_tx_filtI),
    .i_phase_num_of_coeff(w_control_phase_select    ),
    .i_ctrl              (w_control_poly_filt       ),
    .i_reset             (w_reset                   ),            
    .clk                 (clk                       )
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
    .o_os_data           (w_tx_filtQ_to_noiseQ      ),
    .i_is_data           (w_tx_prbsQ_bit_to_tx_filtQ),
    .i_phase_num_of_coeff(w_control_phase_select    ),
    .i_ctrl              (w_control_poly_filt       ),
    .i_reset             (w_reset                   ),            
    .clk                 (clk                       )
  );
  
  

  ///////////////////////////////////////////////////////////////////////////
  //                                CHANNEL                                //
  ///////////////////////////////////////////////////////////////////////////

   //////////////// Generate and add Gaussian noise to the transmitted signal
  // Generate noise
  gng_top #(
    .Z1_I     (NOISE_SEED1_I), 
    .Z2_I     (NOISE_SEED2_I), 
    .Z3_I     (NOISE_SEED3_I), 
    .Z1_Q     (NOISE_SEED1_Q), 
    .Z2_Q     (NOISE_SEED2_Q), 
    .Z3_Q     (NOISE_SEED3_Q), 
//    .SIGMA    (SIGMA        ), 
    .NBT_SIGMA(NBT_SIGMA    ), 
    .NBF_SIGMA(NBF_SIGMA    ), 
    .NBT_NOISE(NBT_NOISE    ), 
    .NBF_NOISE(NBF_NOISE    ) 
  ) u_ch_gng_top (
    .o_noise_I  (w_noiseI_to_add),
    .o_noise_Q  (w_noiseQ_to_add),
    .i_sigma    (i_sigma        ),
    .i_reset    (i_reset        ),
    .clk        (clk            )
  );
  
  // Add noise to signal
  assign w_ch_nsigI_to_chfiltI = w_tx_filtI_to_noiseI + w_noiseI_to_add;
  assign w_ch_nsigQ_to_chfiltQ = w_tx_filtQ_to_noiseQ + w_noiseQ_to_add;


  //////////////// FIR Channel filters to model ISI
  fir_filter_multi #(
    .NUM_COEFF   (NUM_CHFILT_COEF  ), 
    .FILE_COEFF_0(CHFIL_COEF_FILE_0),
    .FILE_COEFF_1(CHFIL_COEF_FILE_1),
    .FILE_COEFF_2(CHFIL_COEF_FILE_2),
    .FILE_COEFF_3(CHFIL_COEF_FILE_3),
    .NBT_IN      (NBT_NOISY_SYM    ), 
    .NBF_IN      (NBF_NOISY_SYM    ), 
    .NBT_COEFF   (NBT_CHFILT_COEF  ),
    .NBF_COEFF   (NBF_CHFILT_COEF  ), 
    .NBT_OUT     (NBT_CHFILT_OUT   ), 
    .NBF_OUT     (NBF_CHFILT_OUT   ) 
  ) u_ch_filt_I (
    .o_os_data (w_ch_filtI_to_aa_filtI),
    .i_sel_taps(i_sel_ch_taps         ),
    .i_is_data (w_ch_nsigI_to_chfiltI ),
    .i_en      (1'b1                  ),
    .i_reset   (w_reset               ),
    .clk       (clk                   ) 
  );

  fir_filter_multi #(
    .NUM_COEFF   (NUM_CHFILT_COEF  ), 
    .FILE_COEFF_0(CHFIL_COEF_FILE_0),
    .FILE_COEFF_1(CHFIL_COEF_FILE_1),
    .FILE_COEFF_2(CHFIL_COEF_FILE_2),
    .FILE_COEFF_3(CHFIL_COEF_FILE_3),
    .NBT_IN      (NBT_NOISY_SYM    ), 
    .NBF_IN      (NBF_NOISY_SYM    ), 
    .NBT_COEFF   (NBT_CHFILT_COEF  ),
    .NBF_COEFF   (NBF_CHFILT_COEF  ), 
    .NBT_OUT     (NBT_CHFILT_OUT   ), 
    .NBF_OUT     (NBF_CHFILT_OUT   ) 
  ) u_ch_filt_Q (
    .o_os_data (w_ch_filtQ_to_aa_filtQ),
    .i_sel_taps(i_sel_ch_taps         ),
    .i_is_data (w_ch_nsigQ_to_chfiltQ ),
    .i_en      (1'b1                  ),
    .i_reset   (w_reset               ),
    .clk       (clk                   ) 
  );



  ///////////////////////////////////////////////////////////////////////////
  //                                RECEIVER                               //
  ///////////////////////////////////////////////////////////////////////////

  //////////////// FIR filters to reduce Aliasing Effects
  fir_filter #(
    .NUM_COEFF (NUM_AAFILT_COEF  ), 
    .FILE_COEFF(AAFILT_COEFF_FILE),
    .NBT_IN    (NBT_CHFILT_OUT   ), 
    .NBF_IN    (NBF_CHFILT_OUT   ), 
    .NBT_COEFF (NBT_AAFILT_COEF  ),
    .NBF_COEFF (NBF_AAFILT_COEF  ), 
    .NBT_OUT   (NBT_AAFILT_OUT   ), 
    .NBF_OUT   (NBF_AAFILT_OUT   ) 
  ) u_aa_filt_I (
    .o_os_data(w_rx_aa_filtI_to_dwr2I),
    .i_is_data(w_ch_filtI_to_aa_filtI),
    .i_en     (i_sw                  ),
    .i_reset  (w_reset               ),
    .clk      (clk                   ) 
  );

  fir_filter #(
    .NUM_COEFF (NUM_AAFILT_COEF  ), 
    .FILE_COEFF(AAFILT_COEFF_FILE),
    .NBT_IN    (NBT_CHFILT_OUT   ), 
    .NBF_IN    (NBF_CHFILT_OUT   ), 
    .NBT_COEFF (NBT_AAFILT_COEF  ),
    .NBF_COEFF (NBF_AAFILT_COEF  ), 
    .NBT_OUT   (NBT_AAFILT_OUT   ), 
    .NBF_OUT   (NBF_AAFILT_OUT   ) 
  ) u_aa_filt_Q (
    .o_os_data(w_rx_aa_filtQ_to_dwr2Q),
    .i_is_data(w_ch_filtQ_to_aa_filtQ),
    .i_en     (i_sw                  ),
    .i_reset  (w_reset               ),
    .clk      (clk                   ) 
  );


  //////////////// Downsample the received signal by a factor of 2
  downsamp #(
    .NBT_IN_OUT(NBT_AAFILT_OUT), 
    .NBF_IN_OUT(NBT_AAFILT_OUT)
  ) u_dwsamp_r2_I (
    .o_os_data(w_rx_dwr2I_to_fse     ),
    .i_is_data(w_rx_aa_filtI_to_dwr2I), 
    .i_ctrl   (w_control_for_rate_2  ),
    .i_en     (i_sw                  ),
    .i_reset  (w_reset               ),
    .clk      (clk                   ) 
  );

  downsamp #(
    .NBT_IN_OUT (NBT_AAFILT_OUT), 
    .NBF_IN_OUT (NBT_AAFILT_OUT)
  ) u_dwsamp_r2_Q (
    .o_os_data(w_rx_dwr2Q_to_fse     ),
    .i_is_data(w_rx_aa_filtQ_to_dwr2Q),
    .i_ctrl   (w_control_for_rate_2  ),
    .i_en     (i_sw                  ),
    .i_reset  (w_reset               ),
    .clk      (clk                   ) 
  );


  //////////////// Adaptive Filter: FSE with LMS adaptation
  adaptive_filter #(
    .STEP        (LMS_STEP      ),
    .LEAK        (LMS_LEAK      ),
    .NBT_STEP    (NBT_LMS_STEP  ),
    .NBF_STEP    (NBF_LMS_STEP  ),
    .NBT_LEAK    (NBT_LMS_LEAK  ),
    .NBF_LEAK    (NBF_LMS_LEAK  ),
    .NUM_TAPS    (NUM_FSE_TAPS  ),
    .NBT_IN      (NBT_AAFILT_OUT),
    .NBF_IN      (NBF_AAFILT_OUT),
    .NBT_LMS_TAPS(NBT_LMS_TAPS  ),
    .NBF_LMS_TAPS(NBF_LMS_TAPS  ),
    .NBT_FSE_TAPS(NBT_FSE_TAPS  ),
    .NBF_FSE_TAPS(NBF_FSE_TAPS  ),
    .NBT_OUT     (NBT_FSE_OUT   ),
    .NBF_OUT     (NBF_FSE_OUT   ),
    .NBT_ERR     (NBT_TAPS_ERR  ),
    .NBF_ERR     (NBF_TAPS_ERR  )
  ) u_adaptive_filter (
    // FSE data to uBlaze
    .o_data_o_eqlzr_I(o_data_o_eqlzr_I),
    .o_data_o_eqlzr_Q(o_data_o_eqlzr_Q),
    .o_taps_I        (o_data_taps_I   ),
    .o_taps_Q        (o_data_taps_Q   ),
    //
    .o_os_data_I (w_rx_symI_to_demapI ),
    .o_os_data_Q (w_rx_symQ_to_demapQ ),
    .i_is_data_I (w_rx_dwr2I_to_fse   ),
    .i_is_data_Q (w_rx_dwr2Q_to_fse   ),
    .i_en_rate2  (w_control_for_rate_2),
    .i_en_rate1  (w_control_for_rate_1),
    .i_save_shtrs(w_save_fse_shifters ),
    .i_en_rx     (i_sw                ),
    .i_reset     (w_reset             ),
    .clk         (clk                 )
  );


  //////////////// Demap bits from received QPSK symbols 
  assign w_rx_bitI_to_ber = w_rx_symI_to_demapI[NBT_FSE_OUT-1];
  assign w_rx_bitQ_to_ber = w_rx_symQ_to_demapQ[NBT_FSE_OUT-1];


  //////////////// BER Control measurement and validation
  ber_top #(
    .PRBS_SEED_I    (PRBS_SEED_I    ),
    .PRBS_SEED_Q    (PRBS_SEED_Q    ),
    .PRBS_MAX_CYCLES(PRBS_MAX_CYCLES),
    .START_SYN      (START_SYN      ),
    .START_CNT      (START_CNT      )
  ) u_ber_IjQ (
    // BER data to uBlaze
    .o_accum_err_I (o_accum_err_I       ),
    .o_accum_tot_I (o_accum_tot_I       ),
    .o_accum_err_Q (o_accum_err_Q       ),
    .o_accum_tot_Q (o_accum_tot_Q       ),
    //
    .o_sync_done_I (w_sync_done_I       ),
    .o_sync_done_Q (w_sync_done_Q       ),
    .o_ber_ok_led_I(w_ber_ok_led_I      ),
    .o_ber_ok_led_Q(w_ber_ok_led_Q      ),
    .i_rx_bit_I    (w_rx_bitI_to_ber    ),
    .i_rx_bit_Q    (w_rx_bitQ_to_ber    ),
    .i_en_rate1    (w_control_for_rate_1), 
    .i_en_rx       (i_sw                ),
    .i_reset       (w_reset             ), 
    .clk           (clk                 ) 
  );


  //////////////// Assign processed signals to output ports  
  assign o_normal_led[1] = w_reset       ;
  assign o_normal_led[0] = i_sw          ;
  assign o_rgb_led3_r    = w_sync_done_I ;
  assign o_rgb_led2_r    = w_sync_done_Q ;
  assign o_rgb_led1_b    = w_ber_ok_led_I;
  assign o_rgb_led0_b    = w_ber_ok_led_Q;

  // Data assignments to uBlaze
  assign o_control_for_rate_2 = w_control_for_rate_2;
  assign o_control_for_rate_1 = w_control_for_rate_1;
  assign o_data_i_eqlzr_I     = w_rx_dwr2I_to_fse   ;
  assign o_data_i_eqlzr_Q     = w_rx_dwr2Q_to_fse   ;


endmodule

