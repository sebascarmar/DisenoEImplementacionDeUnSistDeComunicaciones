`timescale 1ns/1ps

module tb_tmp_top_tx_noise;
    // Parámetros
  parameter PRBS_SEED_I       = 9'h1AA;
  parameter PRBS_SEED_Q       = 9'h1FE;
  parameter NBAUD             = 6;
  parameter OVERSAMP          = 4;
  parameter TXFILT_COEFF_FILE = "./../../../../../../../fixed_point/logs/coeffs_txf.dat";
  parameter NBT_TXFILT_COEF   = 8;
  parameter NBF_TXFILT_COEF   = 7;
  parameter NBT_TXFILT_OUT    = 8;
  parameter NBF_TXFILT_OUT    = 7;  
  parameter NOISE_SEED1_I     = 64'd5030521883283424767;
  parameter NOISE_SEED2_I     = 64'd18445829279364155008;
  parameter NOISE_SEED3_I     = 64'd18436106298727503359;
  parameter NOISE_SEED1_Q     = 64'd14533118196545751551;
  parameter NOISE_SEED2_Q     = 64'd18444914485018758400;
  parameter NOISE_SEED3_Q     = 64'd18425749998705519615;
  parameter SIGMA             = 8'sh1C;
  parameter NBT_SIGMA         = 8;
  parameter NBF_SIGMA         = 7;
  parameter NBT_NOISE         = 8;
  parameter NBF_NOISE         = 7;
  parameter NBT_NOISY_SYM     = 8;
  parameter NBF_NOISY_SYM     = 7;
  parameter NUM_CHFILT_COEF   = 17;
  parameter CHFILT_COEFF_FILE = "./../../../../../../../fixed_point/logs/coeffs_chfilt.dat";
  parameter NBT_CHFILT_COEF   =  8;
  parameter NBF_CHFILT_COEF   =  7;
  parameter NBT_CHFILT_OUT    =  8;
  parameter NBF_CHFILT_OUT    =  7;
  parameter NUM_AAFILT_COEF   =  17;
  parameter AAFILT_COEFF_FILE =  "./../../../../../../../fixed_point/logs/coeffs_aafilt.dat";
  parameter NBT_AAFILT_COEF   =  8;
  parameter NBF_AAFILT_COEF   =  7;
  parameter NBT_AAFILT_OUT    =  8;
  parameter NBF_AAFILT_OUT    =  7;
  parameter LMS_STEP          = 12'sh001;
  parameter LMS_LEAK          = 11'sh001;
  parameter NBT_LMS_STEP      = 12      ;
  parameter NBF_LMS_STEP      = 11      ;
  parameter NBT_LMS_LEAK      = 11      ;
  parameter NBF_LMS_LEAK      = 10      ;
  parameter NUM_FSE_TAPS      = 11      ;
  parameter NBT_FSE_TAPS      = 28      ;
  parameter NBF_FSE_TAPS      = 25      ;
  parameter NBT_FSE_OUT       = 12      ;
  parameter NBF_FSE_OUT       =  9      ;
  parameter NBT_TAPS_ERR      = 12      ;
  parameter NBF_TAPS_ERR      =  9      ;


    // Señales
    reg clk;
    reg i_reset;
    wire signed [NBT_FSE_OUT-1:0] symI_slcr;
    wire signed [NBT_FSE_OUT-1:0] symQ_slcr;

    // Instancia del módulo bajo prueba (DUT)
    tmp_top_tx_noise_chfil_aafilt_dwr2_fse_lms_dwr1_slc #(
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
        .NBF_AAFILT_OUT    (NBF_AAFILT_OUT   )
    ) dut (
        .symI_slcr(symI_slcr),
        .symQ_slcr(symQ_slcr),
        .i_reset(i_reset),
        .clk(clk)
    );



    integer file_rx_symI_fse  ;
    integer file_rx_symQ_fse  ;
    integer file_rx_symI_dwr1 ;
    integer file_rx_symQ_dwr1 ;
    integer file_rx_symI_slcr ;
    integer file_rx_symQ_slcr ;
    integer file_tx_bitI_prbs ;
    integer file_tx_bitQ_prbs ;
    integer file_error_I ;
    integer file_error_Q ;
    integer file_fse_taps_I;
    integer file_fse_taps_Q;

    integer i                 ;
    integer k                 ;
    integer n_logs = 4*1000000;
    
    
    wire prbsI_new_bit;
    wire prbsQ_new_bit;
    wire signed [NBT_TAPS_ERR-1:0]  err_I;
    wire signed [NBT_TAPS_ERR-1:0]  err_Q;
    wire signed [NBT_FSE_OUT-1:0]  symI_fse;
    wire signed [NBT_FSE_OUT-1:0]  symQ_fse;
    wire signed [NBT_FSE_OUT-1:0]  dwI_r1;
    wire signed [NBT_FSE_OUT-1:0]  dwQ_r1;
    wire signed [NBT_FSE_TAPS-1:0] taps_I         [NUM_FSE_TAPS-1:0];
    wire signed [NBT_FSE_TAPS-1:0] taps_Q         [NUM_FSE_TAPS-1:0];
    assign prbsI_new_bit = dut.u_tx_prbs9_I.o_new_bit;
    assign prbsQ_new_bit = dut.u_tx_prbs9_Q.o_new_bit;
    assign err_I = dut.u_adaptive_filter.w_err_I;
    assign err_Q = dut.u_adaptive_filter.w_err_Q;
    assign symI_fse = dut.u_adaptive_filter.u_fse.o_os_data_I;
    assign symQ_fse = dut.u_adaptive_filter.u_fse.o_os_data_Q;
    assign dwI_r1 = dut.u_adaptive_filter.u_dwsamp_r1_I.r_dwsamp;
    assign dwQ_r1 = dut.u_adaptive_filter.u_dwsamp_r1_Q.r_dwsamp;

    assign taps_I[0] = dut.u_adaptive_filter.u_lms.r_taps_I[0];
    assign taps_I[1] = dut.u_adaptive_filter.u_lms.r_taps_I[1];
    assign taps_I[2] = dut.u_adaptive_filter.u_lms.r_taps_I[2];
    assign taps_I[3] = dut.u_adaptive_filter.u_lms.r_taps_I[3];
    assign taps_I[4] = dut.u_adaptive_filter.u_lms.r_taps_I[4];
    assign taps_I[5] = dut.u_adaptive_filter.u_lms.r_taps_I[5];
    assign taps_I[6] = dut.u_adaptive_filter.u_lms.r_taps_I[6];
    assign taps_I[7] = dut.u_adaptive_filter.u_lms.r_taps_I[7];
    assign taps_I[8] = dut.u_adaptive_filter.u_lms.r_taps_I[8];
    assign taps_I[9] = dut.u_adaptive_filter.u_lms.r_taps_I[9];
    assign taps_I[10] = dut.u_adaptive_filter.u_lms.r_taps_I[10];
    assign taps_Q[0] = dut.u_adaptive_filter.u_lms.r_taps_Q[0];
    assign taps_Q[1] = dut.u_adaptive_filter.u_lms.r_taps_Q[1];
    assign taps_Q[2] = dut.u_adaptive_filter.u_lms.r_taps_Q[2];
    assign taps_Q[3] = dut.u_adaptive_filter.u_lms.r_taps_Q[3];
    assign taps_Q[4] = dut.u_adaptive_filter.u_lms.r_taps_Q[4];
    assign taps_Q[5] = dut.u_adaptive_filter.u_lms.r_taps_Q[5];
    assign taps_Q[6] = dut.u_adaptive_filter.u_lms.r_taps_Q[6];
    assign taps_Q[7] = dut.u_adaptive_filter.u_lms.r_taps_Q[7];
    assign taps_Q[8] = dut.u_adaptive_filter.u_lms.r_taps_Q[8];
    assign taps_Q[9] = dut.u_adaptive_filter.u_lms.r_taps_Q[9];
    assign taps_Q[10] = dut.u_adaptive_filter.u_lms.r_taps_Q[10];



    // Generación de reloj
    always #5 clk = ~clk;

    // Procedimiento de prueba
    initial begin
        file_rx_symI_fse = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_rx_symI_fse.txt", "wb");
        file_rx_symQ_fse = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_rx_symQ_fse.txt", "wb");
        file_rx_symI_dwr1 = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_rx_symI_dwr4.txt", "wb");
        file_rx_symQ_dwr1 = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_rx_symQ_dwr4.txt", "wb");
        file_rx_symI_slcr = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_rx_symI_slcr.txt", "wb");
        file_rx_symQ_slcr = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_rx_symQ_slcr.txt", "wb");
        file_tx_bitI_prbs   = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_tx_bitI_prbs.txt", "wb");
        file_tx_bitQ_prbs   = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_tx_bitQ_prbs.txt", "wb");
        file_error_I   = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_rx_error_I.txt", "wb");
        file_error_Q   = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_rx_error_Q.txt", "wb");
        file_fse_taps_I   = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_fse_taps_I.txt", "wb");
        file_fse_taps_Q   = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_fse_lms_dwsr1_slcr_test/scripts_py/file_fse_taps_Q.txt", "wb");
        // Inicialización
        clk = 0;
        i_reset = 0;
        
        #100;
        // Liberar reset
        i_reset = 1;

        for (i = 0; i < n_logs; i = i + 1) begin
          if (i%2 == 0 ) begin
            $fwrite(file_rx_symI_fse , "%d\n", symI_fse);
            $fwrite(file_rx_symQ_fse , "%d\n", symQ_fse);
          end
          if (i%4 == 0 ) begin
            $fwrite(file_rx_symI_dwr1 , "%d\n",  dwI_r1);
            $fwrite(file_rx_symQ_dwr1 , "%d\n",  dwQ_r1);
            $fwrite(file_rx_symI_slcr , "%d\n",  symI_slcr);
            $fwrite(file_rx_symQ_slcr , "%d\n",  symQ_slcr);
            $fwrite(file_error_I , "%d\n",  err_I);
            $fwrite(file_error_Q , "%d\n",  err_Q);
            $fwrite(file_tx_bitI_prbs , "%d\n",  prbsI_new_bit);
            $fwrite(file_tx_bitQ_prbs , "%d\n",  prbsQ_new_bit);
          end
          if (i%(500*4) == 0) begin
              for (k = 0; k < NUM_FSE_TAPS; k = k + 1) begin
                  $fwrite(file_fse_taps_I , "%d\n",  taps_I[k]);
                  $fwrite(file_fse_taps_Q , "%d\n",  taps_Q[k]);
              end
          end  
          #10; 
        end 
        
        $fclose(file_rx_symI_fse);
        $fclose(file_rx_symQ_fse);
        $fclose(file_rx_symI_dwr1);
        $fclose(file_rx_symQ_dwr1);
        $fclose(file_rx_symI_slcr);
        $fclose(file_rx_symQ_slcr);
        $fclose(file_tx_bitI_prbs);
        $fclose(file_tx_bitQ_prbs);
        $fclose(file_error_I);
        $fclose(file_error_Q);
        $fclose(file_fse_taps_I);
        $fclose(file_fse_taps_Q);

        #600;
        // Finalizar simulación
        $stop;
    end
endmodule

