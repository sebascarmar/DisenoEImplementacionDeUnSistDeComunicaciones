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

    // Señales
    reg clk;
    reg i_reset;
    wire signed [NBT_AAFILT_OUT-1:0] symI_dw_r2;
    wire signed [NBT_AAFILT_OUT-1:0] symQ_dw_r2;

    // Instancia del módulo bajo prueba (DUT)
    tmp_top_tx_noise_chfil_aafilt #(
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
        .i_reset(i_reset),
        .clk(clk),
        .symI_dw_r2(symI_dw_r2),
        .symQ_dw_r2(symQ_dw_r2)
    );



    integer file_rx_symI_dw_r2  ;
    integer file_rx_symQ_dw_r2  ;
    integer file_tx_bitI_prbs ;
    integer file_tx_bitQ_prbs ;
    integer i                 ;
    integer n_logs = 4*1000000;
    
    
    wire prbsI_new_bit;
    wire prbsQ_new_bit;
    assign prbsI_new_bit = dut.u_tx_prbs9_I.o_new_bit;
    assign prbsQ_new_bit = dut.u_tx_prbs9_Q.o_new_bit;



    // Generación de reloj
    always #5 clk = ~clk;

    // Procedimiento de prueba
    initial begin
        file_rx_symI_dw_r2 = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_test/scripts_py/file_rx_symI_dw_r2.txt", "wb");
        file_rx_symQ_dw_r2 = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_test/scripts_py/file_rx_symQ_dw_r2.txt", "wb");
        file_tx_bitI_prbs   = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_test/scripts_py/file_tx_bitI_prbs.txt", "wb");
        file_tx_bitQ_prbs   = $fopen("./../../../../../../tmp_tx_noise_chfilt_aafilt_dwr2_test/scripts_py/file_tx_bitQ_prbs.txt", "wb");
        // Inicialización
        clk = 0;
        i_reset = 0;
        
        #100;
        // Liberar reset
        i_reset = 1;

        for (i = 0; i < n_logs; i = i + 1) begin
          if (i%2 == 0 ) begin
            $fwrite(file_rx_symI_dw_r2 , "%d\n", symI_dw_r2);
            $fwrite(file_rx_symQ_dw_r2 , "%d\n", symQ_dw_r2);
          end
          if (i%4 == 0 ) begin
            $fwrite(file_tx_bitI_prbs , "%d\n",  prbsI_new_bit);
            $fwrite(file_tx_bitQ_prbs , "%d\n",  prbsQ_new_bit);
          end
          #10; 
        end 
        
        $fclose(file_rx_symI_dw_r2);
        $fclose(file_rx_symQ_dw_r2);
        $fclose(file_tx_bitI_prbs);
        $fclose(file_tx_bitQ_prbs);


        // Finalizar simulación
        $stop;
    end
endmodule

