`timescale 1ns/1ps

module tb_tmp_top_tx_noise;
    // Parámetros
    parameter PRBS_SEED_I      = 9'h1AA;
    parameter PRBS_SEED_Q      = 9'h1FE;
    parameter NBAUD            = 6;
    parameter OVERSAMP         = 4;
    parameter NBT_TXFILT_COEF  = 8;
    parameter NBF_TXFILT_COEF  = 7;
    parameter NBT_TXFILT_OUT   = 8;
    parameter NBF_TXFILT_OUT   = 7;
    parameter NOISE_SEED1_I    = 64'd5030521883283424767;
    parameter NOISE_SEED2_I    = 64'd18445829279364155008;
    parameter NOISE_SEED3_I    = 64'd18436106298727503359;
    parameter NOISE_SEED1_Q    = 64'd14533118196545751551;
    parameter NOISE_SEED2_Q    = 64'd18444914485018758400;
    parameter NOISE_SEED3_Q    = 64'd18425749998705519615;
    parameter SIGMA            = 8'sh1C;
    parameter NBT_SIGMA        = 8;
    parameter NBF_SIGMA        = 7;
    parameter NBT_NOISE        = 8;
    parameter NBF_NOISE        = 7;
    parameter NBT_NOISY_SYM    = 8;
    parameter NBF_NOISY_SYM    = 7;
    parameter NUM_CHFILT_COEF  = 17;
    parameter CHFILT_INIT_FILE = "./../../../../../../../fixed_point/logs/coeffs_chfilt.dat";
    parameter NBT_CHFILT_COEF  = 8;
    parameter NBF_CHFILT_COEF  = 7;
    parameter NBT_CHFILT_OUT   = 8;
    parameter NBF_CHFILT_OUT   = 7;

    // Señales
    reg clk;
    reg i_reset;
    wire signed [NBT_CHFILT_OUT-1:0] symI_chan_filter;
    wire signed [NBT_CHFILT_OUT-1:0] symQ_chan_filter;

    // Instancia del módulo bajo prueba (DUT)
    tmp_top_tx_noise #(
        .PRBS_SEED_I(PRBS_SEED_I),
        .PRBS_SEED_Q(PRBS_SEED_Q),
        .NBAUD(NBAUD),
        .OVERSAMP(OVERSAMP),
        .NBT_TXFILT_COEF(NBT_TXFILT_COEF),
        .NBF_TXFILT_COEF(NBF_TXFILT_COEF),
        .NBT_TXFILT_OUT(NBT_TXFILT_OUT),
        .NBF_TXFILT_OUT(NBF_TXFILT_OUT),
        .NOISE_SEED1_I(NOISE_SEED1_I),
        .NOISE_SEED2_I(NOISE_SEED2_I),
        .NOISE_SEED3_I(NOISE_SEED3_I),
        .NOISE_SEED1_Q(NOISE_SEED1_Q),
        .NOISE_SEED2_Q(NOISE_SEED2_Q),
        .NOISE_SEED3_Q(NOISE_SEED3_Q),
        .SIGMA(SIGMA),
        .NBT_SIGMA(NBT_SIGMA),
        .NBF_SIGMA(NBF_SIGMA),
        .NBT_NOISE(NBT_NOISE),
        .NBF_NOISE(NBF_NOISE),
        .NBT_NOISY_SYM(NBT_NOISY_SYM),
        .NBF_NOISY_SYM(NBF_NOISY_SYM),
        .NUM_CHFILT_COEF(NUM_CHFILT_COEF),
        .CHFILT_INIT_FILE(CHFILT_INIT_FILE),
        .NBT_CHFILT_COEF(NBT_CHFILT_COEF),
        .NBF_CHFILT_COEF(NBF_CHFILT_COEF),
        .NBT_CHFILT_OUT(NBT_CHFILT_OUT),
        .NBF_CHFILT_OUT(NBF_CHFILT_OUT)
    ) dut (
        .i_reset(i_reset),
        .clk(clk),
        .symI_chan_filter(symI_chan_filter),
        .symQ_chan_filter(symQ_chan_filter)
    );


    integer file_ch_symI_chfilt  ;
    integer file_ch_symQ_chfilt  ;
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
        file_ch_symI_chfilt = $fopen("./../../../../../../tmp_tx_noise_chfilt_test/scripts_py/file_ch_symI_chfilt.txt", "wb");
        file_ch_symQ_chfilt = $fopen("./../../../../../../tmp_tx_noise_chfilt_test/scripts_py/file_ch_symQ_chfilt.txt", "wb");
        file_tx_bitI_prbs   = $fopen("./../../../../../../tmp_tx_noise_chfilt_test/scripts_py/file_tx_bitI_prbs.txt", "wb");
        file_tx_bitQ_prbs   = $fopen("./../../../../../../tmp_tx_noise_chfilt_test/scripts_py/file_tx_bitQ_prbs.txt", "wb");
        // Inicialización
        clk = 0;
        i_reset = 0;
        
        #100;
        // Liberar reset
        i_reset = 1;

        for (i = 0; i < n_logs; i = i + 1) begin
          $fwrite(file_ch_symI_chfilt , "%d\n", symI_chan_filter);
          $fwrite(file_ch_symQ_chfilt , "%d\n", symQ_chan_filter);
          if (i%4 == 0 ) begin
            $fwrite(file_tx_bitI_prbs , "%d\n",  prbsI_new_bit);
            $fwrite(file_tx_bitQ_prbs , "%d\n",  prbsQ_new_bit);
          end
          #10; 
        end 
        
        $fclose(file_ch_symI_chfilt);
        $fclose(file_ch_symQ_chfilt);
        $fclose(file_tx_bitI_prbs);
        $fclose(file_tx_bitQ_prbs);
        
        
        $stop;
    end
endmodule

