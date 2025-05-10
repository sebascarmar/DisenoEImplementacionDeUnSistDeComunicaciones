//============================================================
// SNR to Variance table in S(8,7) format
// -----------------------------------------------------------
// SNR (dB)     Variance σ       σ (hex)    S(8,7) format
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


module tb_qpsk_comm_sys;

  // PRBS
  parameter PRBS_SEED_I       = 9'h1AA;
  parameter PRBS_SEED_Q       = 9'h1FE;
  // TRANSMITTER FILTER
  parameter TXFILT_COEFF_FILE = "./../../../../../../../fixed_point/logs/coeffs_txf.dat";
  parameter NBT_TXFILT_COEF   = 8;
  parameter NBF_TXFILT_COEF   = 7;
  parameter NBT_TXFILT_OUT    = 8;
  parameter NBF_TXFILT_OUT    = 7;  
  parameter NBAUD             = 6;
  parameter OVERSAMP          = 4;
  // NOISE
  parameter NOISE_SEED1_I     = 64'd5030521883283424767;
  parameter NOISE_SEED2_I     = 64'd18445829279364155008;
  parameter NOISE_SEED3_I     = 64'd18436106298727503359;
  parameter NOISE_SEED1_Q     = 64'd14533118196545751551;
  parameter NOISE_SEED2_Q     = 64'd18444914485018758400;
  parameter NOISE_SEED3_Q     = 64'd18425749998705519615;
  parameter SIGMA             = 8'sh1d;
  parameter NBT_SIGMA         = 8;
  parameter NBF_SIGMA         = 7;
  parameter NBT_NOISE         = 8;
  parameter NBF_NOISE         = 7;
  parameter NBT_NOISY_SYM     = 8;
  parameter NBF_NOISY_SYM     = 7;
  // CHANNEL FILTER
  parameter NUM_CHFILT_COEF   = 17;
  parameter CHFILT_COEFF_FILE = "./../../../../../../../fixed_point/logs/coeffs_chfilt.dat";
  parameter NBT_CHFILT_COEF   =  8;
  parameter NBF_CHFILT_COEF   =  7;
  parameter NBT_CHFILT_OUT    =  8;
  parameter NBF_CHFILT_OUT    =  7;
  // ANTI-ALIAS FILTER
  parameter NUM_AAFILT_COEF   = 17;
  parameter AAFILT_COEFF_FILE = "./../../../../../../../fixed_point/logs/coeffs_aafilt.dat";
  parameter NBT_AAFILT_COEF   =  8;
  parameter NBF_AAFILT_COEF   =  7;
  parameter NBT_AAFILT_OUT    =  8;
  parameter NBF_AAFILT_OUT    =  7;
  //FSE & LMS
  parameter LMS_STEP          = 12'sh001;
  parameter LMS_LEAK          = 11'sh001;
  parameter NBT_LMS_STEP      = 12      ;
  parameter NBF_LMS_STEP      = 11      ;
  parameter NBT_LMS_LEAK      = 11      ;
  parameter NBF_LMS_LEAK      = 10      ;
  //----
  parameter NUM_FSE_TAPS      =  9      ;
  parameter NBT_LMS_TAPS      = 20      ;
  parameter NBF_LMS_TAPS      = 17      ;
  parameter NBT_FSE_TAPS      = 10      ;
  parameter NBF_FSE_TAPS      =  7      ;
  parameter NBT_FSE_OUT       = 12      ;
  parameter NBF_FSE_OUT       =  9      ;
  parameter NBT_TAPS_ERR      =  9      ;
  parameter NBF_TAPS_ERR      =  7      ;
  // BER
  parameter PRBS_MAX_CYCLES   = 511                ;
  parameter START_SYN         = PRBS_MAX_CYCLES*690;
  parameter START_CNT         = START_SYN + 511*511;


  // Signals
  reg clk;
  reg i_reset;
  reg i_sw;
  wire [1:0] o_normal_led;
  wire       o_rgb_led3_b;
  wire       o_rgb_led2_b;
  wire       o_rgb_led1_g;
  wire       o_rgb_led0_g;
  
  // Instantiate the Device Under Test (DUT)
  qpsk_comm_sys #(
        .PRBS_SEED_I       (PRBS_SEED_I      ),
        .PRBS_SEED_Q       (PRBS_SEED_Q      ),
        .NBAUD             (NBAUD            ),
        .OVERSAMP          (OVERSAMP         ),
        .TXFILT_COEFF_FILE (TXFILT_COEFF_FILE),
        .NBT_TXFILT_COEF   (NBT_TXFILT_COEF  ),
        .NBF_TXFILT_COEF   (NBF_TXFILT_COEF  ),
        .NBT_TXFILT_OUT    (NBT_TXFILT_OUT   ),
        .NBF_TXFILT_OUT    (NBF_TXFILT_OUT   ),
        .NOISE_SEED1_I     (NOISE_SEED1_I    ),
        .NOISE_SEED2_I     (NOISE_SEED2_I    ),
        .NOISE_SEED3_I     (NOISE_SEED3_I    ),
        .NOISE_SEED1_Q     (NOISE_SEED1_Q    ),
        .NOISE_SEED2_Q     (NOISE_SEED2_Q    ),
        .NOISE_SEED3_Q     (NOISE_SEED3_Q    ),
        .SIGMA             (SIGMA            ),
        .NBT_SIGMA         (NBT_SIGMA        ),
        .NBF_SIGMA         (NBF_SIGMA        ),
        .NBT_NOISE         (NBT_NOISE        ),
        .NBF_NOISE         (NBF_NOISE        ),
        .NBT_NOISY_SYM     (NBT_NOISY_SYM    ),
        .NBF_NOISY_SYM     (NBF_NOISY_SYM    ),
        .NUM_CHFILT_COEF   (NUM_CHFILT_COEF  ),
        .CHFILT_COEFF_FILE (CHFILT_COEFF_FILE),
        .NBT_CHFILT_COEF   (NBT_CHFILT_COEF  ),
        .NBF_CHFILT_COEF   (NBF_CHFILT_COEF  ),
        .NBT_CHFILT_OUT    (NBT_CHFILT_OUT   ),
        .NBF_CHFILT_OUT    (NBF_CHFILT_OUT   ),
        .NUM_AAFILT_COEF   (NUM_AAFILT_COEF  ),
        .AAFILT_COEFF_FILE (AAFILT_COEFF_FILE),
        .NBT_AAFILT_COEF   (NBT_AAFILT_COEF  ),
        .NBF_AAFILT_COEF   (NBF_AAFILT_COEF  ),
        .NBT_AAFILT_OUT    (NBT_AAFILT_OUT   ),
        .NBF_AAFILT_OUT    (NBF_AAFILT_OUT   ),
        .LMS_STEP          (LMS_STEP         ),
        .LMS_LEAK          (LMS_LEAK         ),
        .NBT_LMS_STEP      (NBT_LMS_STEP     ),
        .NBF_LMS_STEP      (NBF_LMS_STEP     ),
        .NBT_LMS_LEAK      (NBT_LMS_LEAK     ),
        .NBF_LMS_LEAK      (NBF_LMS_LEAK     ),
        .NUM_FSE_TAPS      (NUM_FSE_TAPS     ),
        .NBT_LMS_TAPS      (NBT_LMS_TAPS     ),
        .NBF_LMS_TAPS      (NBF_LMS_TAPS     ),
        .NBT_FSE_TAPS      (NBT_FSE_TAPS     ),
        .NBF_FSE_TAPS      (NBF_FSE_TAPS     ),
        .NBT_FSE_OUT       (NBT_FSE_OUT      ),
        .NBF_FSE_OUT       (NBF_FSE_OUT      ),
        .NBT_TAPS_ERR      (NBT_TAPS_ERR     ),
        .NBF_TAPS_ERR      (NBF_TAPS_ERR     ),
        .PRBS_MAX_CYCLES   (PRBS_MAX_CYCLES  ),
        .START_SYN         (START_SYN        ),
        .START_CNT         (START_CNT        )
  ) dut (
    .o_normal_led  (o_normal_led ),
    .o_rgb_led3_b  (o_rgb_led3_b ),
    .o_rgb_led2_b  (o_rgb_led2_b ),
    .o_rgb_led1_g  (o_rgb_led1_g ),
    .o_rgb_led0_g  (o_rgb_led0_g ),
    .i_sw          (i_sw         ),
    .i_reset       (i_reset      ),
    .clk           (clk          )
  );

  
  integer file_sim_data     ;
  integer file_rx_symI_dwr2 ;
  integer file_rx_symQ_dwr2 ;
  integer file_rx_symI_fse  ;
  integer file_rx_symQ_fse  ;
  integer file_rx_symI_dwr1 ;
  integer file_rx_symQ_dwr1 ;
  integer file_rx_symI_slcr ;
  integer file_rx_symQ_slcr ;
  integer file_fse_taps_I   ;
  integer file_fse_taps_Q   ;

  integer nsymb    = 1000000;
  integer log_step = 500    ;


  integer i;
  integer k;
  wire signed [         NBT_AAFILT_OUT-1:0] dwI_r2                   ;
  wire signed [         NBT_AAFILT_OUT-1:0] dwQ_r2                   ;
  wire signed [            NBT_FSE_OUT-1:0] symI_fse                 ;
  wire signed [            NBT_FSE_OUT-1:0] symQ_fse                 ;
  wire signed [            NBT_FSE_OUT-1:0] dwI_r1                   ;
  wire signed [            NBT_FSE_OUT-1:0] dwQ_r1                   ;
  wire signed [            NBT_FSE_OUT-1:0] symI_slcr                ;
  wire signed [            NBT_FSE_OUT-1:0] symQ_slcr                ;
  wire signed [           NBT_FSE_TAPS-1:0] taps_I [NUM_FSE_TAPS-1:0];
  wire signed [           NBT_FSE_TAPS-1:0] taps_Q [NUM_FSE_TAPS-1:0];
  wire        [                       63:0] bit_err_I                ;
  wire        [                       63:0] bit_err_Q                ;
  wire        [                       63:0] bit_tot                  ;
  wire        [$clog2(PRBS_MAX_CYCLES)-1:0] latency                  ;


  assign dwI_r2    = dut.u_dwsamp_r2_I.o_os_data                    ;
  assign dwQ_r2    = dut.u_dwsamp_r2_Q.o_os_data                    ;
  assign symI_fse  = dut.u_adaptive_filter.u_fse.o_os_data_I        ;
  assign symQ_fse  = dut.u_adaptive_filter.u_fse.o_os_data_Q        ;
  assign dwI_r1    = dut.u_adaptive_filter.u_dwsamp_r1_I.r_dwsamp   ;
  assign dwQ_r1    = dut.u_adaptive_filter.u_dwsamp_r1_Q.r_dwsamp   ;
  assign symI_slcr = dut.u_adaptive_filter.o_os_data_I              ;
  assign symQ_slcr = dut.u_adaptive_filter.o_os_data_Q              ;

  assign latency   = dut.u_ber_IjQ.u_bit_error_counter_I.r_lat      ;
  assign bit_err_I = dut.u_ber_IjQ.u_bit_error_counter_I.r_accum_err;
  assign bit_err_Q = dut.u_ber_IjQ.u_bit_error_counter_Q.r_accum_err;
  assign bit_tot   = dut.u_ber_IjQ.u_bit_error_counter_Q.r_accum_tot;


  genvar idx;
  generate
    for (idx=0; idx<NUM_FSE_TAPS ; idx=idx+1) begin
      assign taps_I[idx] = dut.u_adaptive_filter.u_fse.r_taps_I[idx];
      assign taps_Q[idx] = dut.u_adaptive_filter.u_fse.r_taps_Q[idx];
    end
  endgenerate

  // Clock generation
  always begin
    #2.5 clk = ~clk; // 100 MHz clock, period = 10ns
  end

  // Test sequence
  initial begin
      file_sim_data     = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_sim_data.txt"    , "wb");
      file_rx_symI_dwr2 = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_rx_symI_dwr2.txt", "wb");
      file_rx_symQ_dwr2 = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_rx_symQ_dwr2.txt", "wb");
      file_rx_symI_fse  = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_rx_symI_fse.txt" , "wb");
      file_rx_symQ_fse  = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_rx_symQ_fse.txt" , "wb");
      file_rx_symI_dwr1 = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_rx_symI_dwr1.txt", "wb");
      file_rx_symQ_dwr1 = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_rx_symQ_dwr1.txt", "wb");
      file_rx_symI_slcr = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_rx_symI_slcr.txt", "wb");
      file_rx_symQ_slcr = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_rx_symQ_slcr.txt", "wb");
      file_fse_taps_I   = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_fse_taps_I.txt"  , "wb");
      file_fse_taps_Q   = $fopen("./../../../../../../testbench/tb_qpsk_comm_sys/script_py/logs/file_fse_taps_Q.txt"  , "wb");
      
      
      // Initialize signals
      clk     = 0;
      i_reset = 0;
      i_sw    = 0;
     
      #100;
      i_reset = 1;
      i_sw    = 1;
      
      for (i=0 ; i < 4*nsymb ; i=i+1) begin
          if (i%2 == 0 ) begin
            $fwrite(file_rx_symI_dwr2 , "%d\n", dwI_r2    );
            $fwrite(file_rx_symQ_dwr2 , "%d\n", dwQ_r2    );
            $fwrite(file_rx_symI_fse  , "%d\n", symI_fse  );
            $fwrite(file_rx_symQ_fse  , "%d\n", symQ_fse  );
          end
          if (i%4 == 0 ) begin
            $fwrite(file_rx_symI_dwr1 , "%d\n", dwI_r1   );
            $fwrite(file_rx_symQ_dwr1 , "%d\n", dwQ_r1   );
            $fwrite(file_rx_symI_slcr , "%d\n", symI_slcr);
            $fwrite(file_rx_symQ_slcr , "%d\n", symQ_slcr);
          end
          if (i%(4*log_step) == 0) begin
              for (k = 0; k < NUM_FSE_TAPS; k = k + 1) begin
                  $fwrite(file_fse_taps_I , "%d\n", taps_I[k]);
                  $fwrite(file_fse_taps_Q , "%d\n", taps_Q[k]);
              end
          end  
          #5; 
      end 
      
      
      $fwrite(file_sim_data , "%d\n", nsymb         );
      $fwrite(file_sim_data , "%d\n", SIGMA         );
      $fwrite(file_sim_data , "%d\n", NBF_SIGMA     );
      $fwrite(file_sim_data , "%d\n", NBF_AAFILT_OUT);
      $fwrite(file_sim_data , "%d\n", LMS_STEP      );
      $fwrite(file_sim_data , "%d\n", NBF_LMS_STEP  );
      $fwrite(file_sim_data , "%d\n", LMS_LEAK      );
      $fwrite(file_sim_data , "%d\n", NBF_LMS_LEAK  );
      $fwrite(file_sim_data , "%d\n", NUM_FSE_TAPS  );
      $fwrite(file_sim_data , "%d\n", NBT_LMS_TAPS  );
      $fwrite(file_sim_data , "%d\n", NBF_LMS_TAPS  );
      $fwrite(file_sim_data , "%d\n", NBT_FSE_TAPS  );
      $fwrite(file_sim_data , "%d\n", NBF_FSE_TAPS  );
      $fwrite(file_sim_data , "%d\n", NBF_FSE_OUT   );
      $fwrite(file_sim_data , "%d\n", log_step      );
      $fwrite(file_sim_data , "%d\n", latency       );
      $fwrite(file_sim_data , "%d\n", bit_err_I     );
      $fwrite(file_sim_data , "%d\n", bit_err_Q     );
      $fwrite(file_sim_data , "%d\n", bit_tot       );
      
      
      
      
      $fclose(file_sim_data    );
      $fclose(file_rx_symI_dwr2);
      $fclose(file_rx_symQ_dwr2);
      $fclose(file_rx_symI_fse );
      $fclose(file_rx_symQ_fse );
      $fclose(file_rx_symI_dwr1);
      $fclose(file_rx_symQ_dwr1);
      $fclose(file_rx_symI_slcr);
      $fclose(file_rx_symQ_slcr);
      $fclose(file_fse_taps_I  );
      $fclose(file_fse_taps_Q  );
      
      
      // End simulation
      $finish;
  end


endmodule


